-- =============================================================================
-- MIGRACIÓN: Presentaciones de Productos → presentaciones_registro_sanitario
-- =============================================================================
-- Ejecutar en: Centro de Datos Database
-- Prerrequisito: Tener los CSV cargados en tablas temporales
-- (Ver assets/guides/migration_presentaciones.md para carga de CSVs)

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
    mm.material_uuid::text AS id_material,
    um.unidad_uuid::text AS id_unidad_medida,
    mp.unidad,
    NOW() AS created_at,
    NOW() AS updated_at
FROM migration_presentaciones mp
JOIN migration_material_mapping mm
    ON mm.legacy_id = 'MAT-' || mp.id_ctl_material
JOIN migration_unidad_mapping um
    ON um.legacy_id = 'UM-' || mp.id_ctl_unidad_medida;

-- =============================================================================
-- VALIDACIÓN
-- =============================================================================

SELECT COUNT(*) as total_presentaciones
FROM presentaciones_registro_sanitario;

SELECT
    (SELECT COUNT(*) FROM migration_presentaciones) as origen,
    (SELECT COUNT(*) FROM presentaciones_registro_sanitario) as destino;
