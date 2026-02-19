-- =============================================================================
-- MIGRACIÓN: Relaciones Producto → Presentación
-- =============================================================================
-- Base de Datos: Centro de Datos
-- Prerrequisito: Tener migration_presentaciones cargada
-- y presentaciones_registro_sanitario ya migradas

-- =============================================================================
-- PASO 1: Generar mapeo presentación → producto
-- =============================================================================

-- Exportar mapeo para Core
\COPY (
    SELECT
        prs.id AS presentacion_uuid,
        mp.id_alim_producto
    FROM migration_presentaciones mp
    JOIN migration_material_mapping mm ON mm.legacy_id = 'MAT-' || mp.id_ctl_material
    JOIN migration_unidad_mapping um ON um.legacy_id = 'UM-' || mp.id_ctl_unidad_medida
    JOIN presentaciones_registro_sanitario prs
        ON prs.id_material = mm.material_uuid
        AND prs.id_unidad_medida = um.unidad_uuid
        AND prs.unidad = mp.unidad
) TO '/Users/heycsar/tmp/presentacion_producto_mapping.csv' WITH CSV HEADER;

SELECT 'Mapeo exportado. Ahora ejecuta 08b en Core.' as siguiente_paso;
