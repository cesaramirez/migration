-- =============================================================================
-- PASO 1: EXPORTAR DE SISAM (ejecutar en conexión SISAM Local)
-- =============================================================================
-- Después de ejecutar, exportar el resultado como SQL/JSON desde TablePlus

SELECT
    p.id as original_id,
    p.nombre,
    CASE p.tipo_producto
        WHEN 1 THEN 'Nacional'
        WHEN 2 THEN 'Importado Unión Aduanera'
        WHEN 3 THEN 'Importado Otros Países'
        ELSE 'Desconocido'
    END as tipo_producto,
    p.num_partida_arancelaria,
    p.fecha_emision_registro::text as fecha_emision_registro,
    p.fecha_vigencia_registro::text as fecha_vigencia_registro,
    p.num_autorizacion_reconocimiento,
    p.num_registro_sanitario,
    ep.nombre as estado_producto,
    pais.nombre as pais,
    sg.nombre as sub_grupo
FROM alim_producto p
LEFT JOIN ctl_estado_producto ep ON ep.id = p.id_ctl_estado_producto
LEFT JOIN ctl_pais pais ON pais.id = p.id_ctl_pais
LEFT JOIN alim_sub_grupo_alimenticio sg ON sg.id = p.id_sub_grupo_alimenticio
WHERE p.estado_registro = 1
ORDER BY p.id
LIMIT 100;

-- =============================================================================
-- NOTA: Los campos de archivos (ruta_archivo_*) se manejarán en una fase posterior
-- =============================================================================
-- INSTRUCCIONES:
-- 1. Ejecutar este query en SISAM Local
-- 2. En TablePlus: Click derecho en el resultado → Export → SQL (Insert)
-- 3. Guardar como: migration_source_data.sql
-- 4. Editar el archivo: Cambiar el nombre de tabla a "migration_alim_producto_temp"
-- 5. Ir a la conexión SDT DEV
-- 6. Ejecutar 01_create_temp_table.sql
-- 7. Ejecutar el archivo exportado (migration_source_data.sql)
-- 8. Ejecutar 02_migrate_from_temp.sql
-- =============================================================================
