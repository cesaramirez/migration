-- =============================================================================
-- SCRIPT: 00_setup_temp_catalogs.sql
-- DESCRIPCIÓN: Crea las tablas de catálogo necesarias en la BD local ('z11_db')
--              para permitir que el script de migración haga JOINs.
--              Estas tablas existen originalmente en 'data_center'.
-- =============================================================================

-- 1. Tabla: srs_sub_grupo_alimenticio
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.srs_sub_grupo_alimenticio (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre                    VARCHAR(300) NOT NULL,
    clasificacion_alimenticia VARCHAR(200) NOT NULL,
    tipo_riesgo               VARCHAR(100),
    legacy_id                 VARCHAR(20) NOT NULL UNIQUE,
    created_at                TIMESTAMP DEFAULT NOW(),
    updated_at                TIMESTAMP DEFAULT NOW(),
    deleted_at                TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_sub_grupo_legacy ON srs_sub_grupo_alimenticio(legacy_id);

-- 2. Tabla: paises (Simplificada para migración)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.paises (
    id uuid NOT NULL PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamp(0),
    updated_at timestamp(0),
    nombre varchar(255),
    iso_2_code varchar(255),
    iso_3_code varchar(255),
    iso_number int4,
    activo bool,
    reconocimiento_mutuo_centroamericano bool
);

CREATE INDEX IF NOT EXISTS idx_paises_iso_number ON paises(iso_number);

-- 3. Tabla: srs_certificado_libre_venta
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.srs_certificado_libre_venta (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo                    VARCHAR(100) NOT NULL,
    pais                      VARCHAR(100) NOT NULL,
    fecha_emision             VARCHAR(10) NOT NULL,
    autoridad_sanitaria       VARCHAR(250) NOT NULL,
    legacy_id                 VARCHAR(20) NOT NULL UNIQUE,
    created_at                TIMESTAMP DEFAULT NOW(),
    updated_at                TIMESTAMP DEFAULT NOW(),
    deleted_at                TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_clv_legacy ON srs_certificado_libre_venta(legacy_id);

-- =============================================================================
-- INSTRUCCIONES PARA POBLAR DATOS
-- =============================================================================
--
-- Ahora necesitas copiar los datos desde la BD 'data_center' a estas tablas en 'z11_db'.
--
-- OPCIÓN A: Exportar/Importar CSV (Recomendado si usas TablePlus/DBeaver)
-- 1. En 'data_center': Exporta cada tabla a CSV.
-- 2. En 'z11_db': Importa esos CSVs en las tablas recién creadas.
--
-- OPCIÓN B: Insertar datos manualmente (Si tienes los INSERTs)
--
-- Una vez pobladas estas 3 tablas, puedes ejecutar '02_migrate_from_temp_optimized.sql'.
