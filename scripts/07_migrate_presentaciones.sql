-- =============================================================================
-- MIGRACIÓN FASE 1: Presentaciones → presentaciones_registro_sanitario
-- =============================================================================
-- Base de Datos: Centro de Datos
-- Prerrequisito: Tener los CSV cargados en tablas temporales
-- (Ver assets/guides/migration_presentaciones.md para carga de CSVs)

-- IMPORTANTE: Crear tabla temporal para mapeo de IDs
CREATE TEMP TABLE IF NOT EXISTS temp_presentacion_mapping (
    id_presentacion INT,
    presentacion_uuid UUID,
    id_alim_producto INT
);

-- Insertar presentaciones y guardar mapeo
INSERT INTO presentaciones_registro_sanitario (
    id,
    id_material,
    id_unidad_medida,
    unidad,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid() AS id,
    mm.material_uuid AS id_material,
    um.unidad_uuid AS id_unidad_medida,
    mp.unidad,
    NOW() AS created_at,
    NOW() AS updated_at
FROM migration_presentaciones mp
JOIN migration_material_mapping mm
    ON mm.legacy_id = 'MAT-' || mp.id_ctl_material
JOIN migration_unidad_mapping um
    ON um.legacy_id = 'UM-' || mp.id_ctl_unidad_medida
RETURNING id, id_material, id_unidad_medida, unidad;

-- Poblar tabla de mapeo (necesitamos re-hacer el SELECT para obtener los UUIDs generados)
INSERT INTO temp_presentacion_mapping (id_presentacion, presentacion_uuid, id_alim_producto)
SELECT
    mp.id_presentacion,
    prs.id,
    mp.id_alim_producto
FROM migration_presentaciones mp
JOIN migration_material_mapping mm ON mm.legacy_id = 'MAT-' || mp.id_ctl_material
JOIN migration_unidad_mapping um ON um.legacy_id = 'UM-' || mp.id_ctl_unidad_medida
JOIN presentaciones_registro_sanitario prs
    ON prs.id_material = mm.material_uuid
    AND prs.id_unidad_medida = um.unidad_uuid
    AND prs.unidad = mp.unidad
WHERE prs.created_at >= (SELECT MAX(created_at) - INTERVAL '5 minutes' FROM presentaciones_registro_sanitario);

-- =============================================================================
-- VALIDACIÓN FASE 1
-- =============================================================================

SELECT COUNT(*) as total_presentaciones_creadas
FROM presentaciones_registro_sanitario
WHERE created_at >= NOW() - INTERVAL '5 minutes';

SELECT
    (SELECT COUNT(*) FROM migration_presentaciones) as origen,
    (SELECT COUNT(*) FROM temp_presentacion_mapping) as mapeadas;

-- =============================================================================
-- EXPORTAR MAPEO PARA FASE 2 (Core Database)
-- =============================================================================

-- Exportar mapeo de presentaciones con productos
\COPY (SELECT pm.presentacion_uuid, pm.id_alim_producto FROM temp_presentacion_mapping pm) TO '/Users/heycsar/tmp/presentaciones_mapping.csv' WITH CSV HEADER;

SELECT 'Mapeo exportado a /Users/heycsar/tmp/presentaciones_mapping.csv' as mensaje;
