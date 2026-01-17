-- =============================================================================
-- PASO 2A: CREAR TABLA TEMPORAL EN SDT (ejecutar en SDT DEV)
-- =============================================================================

DROP TABLE IF EXISTS migration_alim_producto_temp;

CREATE TABLE migration_alim_producto_temp (
    original_id integer NOT NULL,
    nombre varchar(600),
    tipo_producto varchar(100),
    num_partida_arancelaria varchar(14),
    fecha_emision_registro text,
    fecha_vigencia_registro text,
    num_autorizacion_reconocimiento varchar,
    num_registro_sanitario varchar(15),
    estado_producto varchar(30),
    pais varchar(150),
    sub_grupo varchar(300)
);

-- =============================================================================
-- INSTRUCCIONES:
-- 1. Ejecutar este script primero
-- 2. Luego, importar el archivo exportado de SISAM (migration_source_data.sql)
--    Nota: Cambiar el nombre de la tabla en el INSERT a: migration_alim_producto_temp
-- 3. Finalmente ejecutar 02_migrate_from_temp.sql
-- =============================================================================
