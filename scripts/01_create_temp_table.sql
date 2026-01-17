-- =============================================================================
-- PASO 2A: CREAR TABLA TEMPORAL EN SDT (ejecutar en SDT DEV)
-- =============================================================================

DROP TABLE IF EXISTS migration_alim_producto_temp;

CREATE TABLE migration_alim_producto_temp (
    original_id integer NOT NULL,
    nombre varchar(1000),
    tipo_producto varchar(100),
    num_partida_arancelaria varchar(50),
    fecha_emision_registro text,
    fecha_vigencia_registro text,
    num_registro_sanitario varchar(50),
    estado_producto varchar(50),
    pais varchar(255),
    subgrupo_alimenticio varchar(500),
    clasificacion_alimenticia varchar(500),
    riesgo varchar(255),
    -- Certificado de Libre Venta
    codigo_clv varchar(100),
    nombre_producto_clv varchar(1000),
    pais_procedencia_clv varchar(255),
    -- Propietario del Registro Sanitario
    propietario_nombre varchar(500),
    propietario_nit varchar(50),
    propietario_correo varchar(255),
    propietario_direccion varchar(500),
    propietario_pais varchar(255),
    propietario_razon_social varchar(255)
);

-- =============================================================================
-- INSTRUCCIONES:
-- 1. Ejecutar este script primero
-- 2. Luego, importar el archivo exportado de SISAM (migration_source_data.sql)
--    Nota: Cambiar el nombre de la tabla en el INSERT a: migration_alim_producto_temp
-- 3. Finalmente ejecutar 02_migrate_from_temp.sql
-- =============================================================================
