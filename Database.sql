-- =====================================================
-- ESQUEMA E-COMMERCE TIENDA DE EQUIPOS DE CÓMPUTO
-- Supabase (PostgreSQL)
-- =====================================================

-- =====================================================
-- 1. USUARIO
-- =====================================================
CREATE TABLE public.usuario (
    id               BIGSERIAL PRIMARY KEY,
    auth_user_id     UUID UNIQUE
                     REFERENCES auth.users (id) ON DELETE CASCADE,
    nombres          VARCHAR(100) NOT NULL,
    apellidos        VARCHAR(100) NOT NULL,
    email            VARCHAR(255) NOT NULL UNIQUE,
    telefono         VARCHAR(30),
    rol              VARCHAR(20) NOT NULL DEFAULT 'CLIENTE'
                     CHECK (rol IN ('CLIENTE', 'ADMIN')),
    estado           VARCHAR(20) NOT NULL DEFAULT 'ACTIVO'
                     CHECK (estado IN ('ACTIVO', 'INACTIVO', 'PENDIENTE')),
    avatar_url       TEXT,
    fecha_registro   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fuente_trafico   VARCHAR(30) DEFAULT 'OTRO'
                     CHECK (fuente_trafico IN ('ORGANICO', 'REDES_SOCIALES', 'DIRECTO', 'OTRO'))
);

CREATE INDEX idx_usuario_rol_estado
    ON public.usuario (rol, estado);

-- =====================================================
-- 2. CATEGORIA  (categorías y subcategorías)
-- =====================================================
CREATE TABLE public.categoria (
    id          BIGSERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    descripcion TEXT,
    parent_id   BIGINT REFERENCES public.categoria (id) ON DELETE SET NULL,
    icono       VARCHAR(50),
    orden       INTEGER,
    activo      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX idx_categoria_parent_activo
    ON public.categoria (parent_id, activo);

-- =====================================================
-- 3. MARCA
-- =====================================================
CREATE TABLE public.marca (
    id          BIGSERIAL PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL UNIQUE,
    descripcion TEXT,
    icono       VARCHAR(50),
    activo      BOOLEAN NOT NULL DEFAULT TRUE
);

-- =====================================================
-- 4. CUPON
-- =====================================================
CREATE TABLE public.cupon (
    id               BIGSERIAL PRIMARY KEY,
    codigo           VARCHAR(50) NOT NULL UNIQUE,
    tipo_descuento   VARCHAR(20) NOT NULL
                     CHECK (tipo_descuento IN ('PORCENTAJE', 'MONTO_FIJO')),
    valor_descuento  NUMERIC(10,2) NOT NULL CHECK (valor_descuento >= 0),
    monto_minimo     NUMERIC(10,2) CHECK (monto_minimo IS NULL OR monto_minimo >= 0),
    fecha_inicio     DATE,
    fecha_fin        DATE,
    activo           BOOLEAN NOT NULL DEFAULT TRUE,
    limite_uso       INTEGER CHECK (limite_uso IS NULL OR limite_uso > 0)
);

CREATE INDEX idx_cupon_activo_fechas
    ON public.cupon (activo, fecha_inicio, fecha_fin);

-- =====================================================
-- 5. PRODUCTO
-- =====================================================
CREATE TABLE public.producto (
    id                   BIGSERIAL PRIMARY KEY,
    id_categoria         BIGINT NOT NULL
                         REFERENCES public.categoria (id),
    id_marca             BIGINT
                         REFERENCES public.marca (id),
    nombre               VARCHAR(150) NOT NULL,
    descripcion          TEXT,
    sku                  VARCHAR(50) UNIQUE,
    precio               NUMERIC(10,2) NOT NULL CHECK (precio >= 0),
    stock_actual         INTEGER NOT NULL DEFAULT 0 CHECK (stock_actual >= 0),
    imagen_principal_url TEXT,
    modelo_3d_url        TEXT,
    estado_producto      VARCHAR(20) NOT NULL DEFAULT 'ACTIVO'
                         CHECK (estado_producto IN ('ACTIVO', 'INACTIVO', 'AGOTADO')),
    destacado            BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_creacion       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_producto_categoria_marca
    ON public.producto (id_categoria, id_marca);

CREATE INDEX idx_producto_estado_destacado
    ON public.producto (estado_producto, destacado);

-- =====================================================
-- 6. DIRECCION_ENVIO
-- =====================================================
CREATE TABLE public.direccion_envio (
    id             BIGSERIAL PRIMARY KEY,
    id_usuario     BIGINT NOT NULL
                   REFERENCES public.usuario (id) ON DELETE CASCADE,
    alias          VARCHAR(50),
    linea1         VARCHAR(200) NOT NULL,
    linea2         VARCHAR(200),
    distrito       VARCHAR(100),
    ciudad         VARCHAR(100) NOT NULL,
    region         VARCHAR(100),
    referencia     TEXT,
    es_principal   BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_direccion_usuario
    ON public.direccion_envio (id_usuario);

-- =====================================================
-- 7. PEDIDO
-- =====================================================
CREATE TABLE public.pedido (
    id                 BIGSERIAL PRIMARY KEY,
    id_usuario         BIGINT NOT NULL
                       REFERENCES public.usuario (id),
    id_direccion_envio BIGINT
                       REFERENCES public.direccion_envio (id),
    fecha_creacion     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estado_pedido      VARCHAR(20) NOT NULL DEFAULT 'CARRITO'
                       CHECK (estado_pedido IN (
                           'CARRITO',
                           'PENDIENTE_PAGO',
                           'PAGADO',
                           'EN_ENVIO',
                           'COMPLETADO',
                           'CANCELADO'
                       )),
    metodo_envio       VARCHAR(50),
    metodo_pago        VARCHAR(50),
    estado_pago        VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                       CHECK (estado_pago IN ('PENDIENTE', 'APROBADO', 'RECHAZADO')),
    codigo_transaccion VARCHAR(100),
    subtotal           NUMERIC(10,2) NOT NULL DEFAULT 0,
    impuesto           NUMERIC(10,2) NOT NULL DEFAULT 0,
    total              NUMERIC(10,2) NOT NULL DEFAULT 0,
    id_cupon           BIGINT REFERENCES public.cupon (id),
    fuente_trafico     VARCHAR(30) DEFAULT 'OTRO'
                       CHECK (fuente_trafico IN ('ORGANICO', 'REDES_SOCIALES', 'DIRECTO', 'OTRO'))
);

CREATE INDEX idx_pedido_usuario_estado
    ON public.pedido (id_usuario, estado_pedido);

CREATE INDEX idx_pedido_fecha
    ON public.pedido (fecha_creacion);

-- =====================================================
-- 8. PEDIDO_DETALLE
-- =====================================================
CREATE TABLE public.pedido_detalle (
    id              BIGSERIAL PRIMARY KEY,
    id_pedido       BIGINT NOT NULL
                    REFERENCES public.pedido (id) ON DELETE CASCADE,
    id_producto     BIGINT NOT NULL
                    REFERENCES public.producto (id),
    cantidad        INTEGER NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal_item   NUMERIC(10,2) NOT NULL CHECK (subtotal_item >= 0)
);

CREATE INDEX idx_pedido_detalle_pedido
    ON public.pedido_detalle (id_pedido);

-- =====================================================
-- 9. CONTACTO
-- =====================================================
CREATE TABLE public.contacto (
    id           BIGSERIAL PRIMARY KEY,
    nombre       VARCHAR(150) NOT NULL,
    email        VARCHAR(255) NOT NULL,
    asunto       VARCHAR(200) NOT NULL,
    mensaje      TEXT NOT NULL,
    fecha_envio  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estado       VARCHAR(20) NOT NULL DEFAULT 'NUEVO'
                 CHECK (estado IN ('NUEVO', 'EN_PROCESO', 'CERRADO'))
);

CREATE INDEX idx_contacto_estado
    ON public.contacto (estado);

-- =====================================================
-- 10. FAVORITO (wishlist)
-- =====================================================
CREATE TABLE public.favorito (
    id             BIGSERIAL PRIMARY KEY,
    id_usuario     BIGINT NOT NULL
                   REFERENCES public.usuario (id) ON DELETE CASCADE,
    id_producto    BIGINT NOT NULL
                   REFERENCES public.producto (id) ON DELETE CASCADE,
    fecha_agregado TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unico_favorito UNIQUE (id_usuario, id_producto)
);

CREATE INDEX idx_favorito_usuario
    ON public.favorito (id_usuario);

-- =====================================================
-- 11. VALORACION_PRODUCTO
-- =====================================================
CREATE TABLE public.valoracion_producto (
    id               BIGSERIAL PRIMARY KEY,
    id_usuario       BIGINT NOT NULL
                     REFERENCES public.usuario (id) ON DELETE CASCADE,
    id_producto      BIGINT NOT NULL
                     REFERENCES public.producto (id) ON DELETE CASCADE,
    puntuacion       INTEGER NOT NULL CHECK (puntuacion BETWEEN 1 AND 5),
    comentario       TEXT,
    fecha_valoracion TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    estado           VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                     CHECK (estado IN ('PUBLICADA', 'PENDIENTE', 'RECHAZADA')),
    CONSTRAINT unica_valoracion_usuario_producto
        UNIQUE (id_usuario, id_producto)
);

CREATE INDEX idx_valoracion_producto
    ON public.valoracion_producto (id_producto);

-- =====================================================
-- 12. MOVIMIENTO_STOCK
-- =====================================================
CREATE TABLE public.movimiento_stock (
    id               BIGSERIAL PRIMARY KEY,
    id_producto      BIGINT NOT NULL
                     REFERENCES public.producto (id),
    tipo_movimiento  VARCHAR(20) NOT NULL
                     CHECK (tipo_movimiento IN ('INGRESO', 'SALIDA', 'AJUSTE')),
    cantidad         INTEGER NOT NULL CHECK (cantidad > 0),
    motivo           TEXT,
    fecha_movimiento TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    id_pedido        BIGINT REFERENCES public.pedido (id)
);

CREATE INDEX idx_movimiento_stock_producto
    ON public.movimiento_stock (id_producto, fecha_movimiento);

-- =====================================================
-- 13. CUPON_USO
-- =====================================================
CREATE TABLE public.cupon_uso (
    id                       BIGSERIAL PRIMARY KEY,
    id_cupon                 BIGINT NOT NULL
                             REFERENCES public.cupon (id),
    id_usuario               BIGINT NOT NULL
                             REFERENCES public.usuario (id),
    id_pedido                BIGINT NOT NULL
                             REFERENCES public.pedido (id),
    fecha_uso                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    monto_descuento_aplicado NUMERIC(10,2) NOT NULL
                             CHECK (monto_descuento_aplicado >= 0),
    CONSTRAINT unico_cupon_por_pedido
        UNIQUE (id_cupon, id_pedido, id_usuario)
);

CREATE INDEX idx_cupon_uso_usuario
    ON public.cupon_uso (id_usuario);

-- =====================================================
-- 14. NOTIFICACION
-- =====================================================
CREATE TABLE public.notificacion (
    id              BIGSERIAL PRIMARY KEY,
    id_usuario      BIGINT NOT NULL
                    REFERENCES public.usuario (id) ON DELETE CASCADE,
    titulo          VARCHAR(150) NOT NULL,
    mensaje         TEXT NOT NULL,
    tipo            VARCHAR(50) NOT NULL
                    CHECK (tipo IN (
                        'PEDIDO_NUEVO',
                        'PEDIDO_ESTADO_CAMBIO',
                        'NUEVO_MENSAJE_CONTACTO',
                        'NUEVO_CUPON',
                        'GENERAL'
                    )),
    canal           VARCHAR(20) NOT NULL DEFAULT 'IN_APP'
                    CHECK (canal IN ('IN_APP', 'EMAIL', 'AMBOS')),
    leida           BOOLEAN NOT NULL DEFAULT FALSE,
    link_url        TEXT,
    id_pedido       BIGINT REFERENCES public.pedido (id),
    id_producto     BIGINT REFERENCES public.producto (id),
    fecha_creacion  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notificacion_usuario_fecha
    ON public.notificacion (id_usuario, fecha_creacion DESC);
