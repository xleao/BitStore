-- =====================================================
-- 5. PRODUCTO (versión actual con ofertas)
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

    precio               NUMERIC(10,2) NOT NULL
                         CHECK (precio >= 0),
    stock_actual         INTEGER NOT NULL DEFAULT 0
                         CHECK (stock_actual >= 0),

    imagen_principal_url TEXT,
    modelo_3d_url        TEXT,

    estado_producto      VARCHAR(20) NOT NULL DEFAULT 'ACTIVO'
                         CHECK (estado_producto IN ('ACTIVO', 'INACTIVO', 'AGOTADO')),

    destacado            BOOLEAN NOT NULL DEFAULT FALSE,

    -- 🔹 Campos nuevos para ofertas
    es_oferta            BOOLEAN NOT NULL DEFAULT FALSE,
    tipo_descuento_oferta VARCHAR(20)
        CHECK (tipo_descuento_oferta IN ('PORCENTAJE', 'MONTO_FIJO')),
    valor_descuento_oferta NUMERIC(10,2)
        CHECK (valor_descuento_oferta IS NULL OR valor_descuento_oferta >= 0),

    fecha_creacion       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Coherencia entre es_oferta y los campos de descuento
    CONSTRAINT ck_oferta_coherente
        CHECK (
            -- Caso 1: no es oferta → no debe tener tipo ni valor
            (es_oferta = FALSE
             AND tipo_descuento_oferta IS NULL
             AND valor_descuento_oferta IS NULL)
            OR
            -- Caso 2: sí es oferta → tipo y valor obligatorios
            (es_oferta = TRUE
             AND tipo_descuento_oferta IS NOT NULL
             AND valor_descuento_oferta IS NOT NULL)
        )
);

-- Índices
CREATE INDEX idx_producto_categoria_marca
    ON public.producto (id_categoria, id_marca);

CREATE INDEX idx_producto_estado_destacado
    ON public.producto (estado_producto, destacado);
