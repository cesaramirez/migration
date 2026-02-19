-- =============================================================================
-- MIGRACIÓN: Relaciones Producto → Presentación (Parte 2)
-- =============================================================================
-- Base de Datos: CORE
-- Prerrequisito: Haber ejecutado 08_migrate_presentacion_relations.sql en Centro de Datos
-- y tener el archivo presentacion_producto_mapping.csv

-- Crear tabla temporal para mapeo
CREATE TEMP TABLE IF NOT EXISTS migration_presentacion_mapping (
    presentacion_uuid UUID,
    id_alim_producto INT
);

-- Importar mapeo
\COPY migration_presentacion_mapping(presentacion_uuid, id_alim_producto)
FROM '/Users/heycsar/tmp/presentacion_producto_mapping.csv'
WITH CSV HEADER;

-- Insertar relaciones
INSERT INTO expedient_base_registry_relation (
    expedient_base_registry_id,
    relation_id,
    source,
    reference_name,
    relation_type,
    created_at,
    updated_at
)
SELECT
    r.id AS expedient_base_registry_id,
    pm.presentacion_uuid AS relation_id,
    'data_center' AS source,
    'presentaciones_registro_sanitario' AS reference_name,
    'data_center' AS relation_type,
    NOW() AS created_at,
    NOW() AS updated_at
FROM migration_presentacion_mapping pm
JOIN expedient_base_registries r
    ON r.legacy_id = 'PRD-' || pm.id_alim_producto
JOIN expedient_base_entities e
    ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- =============================================================================
-- VALIDACIÓN
-- =============================================================================

SELECT COUNT(*) as total_relaciones_creadas
FROM expedient_base_registry_relation
WHERE reference_name = 'presentaciones_registro_sanitario';

SELECT
    (SELECT COUNT(*) FROM migration_presentacion_mapping) as origen,
    (SELECT COUNT(*) FROM expedient_base_registry_relation
     WHERE reference_name = 'presentaciones_registro_sanitario') as destino;

-- Productos con más presentaciones
SELECT
    r.unique_code,
    r.name as producto,
    COUNT(*) as num_presentaciones
FROM expedient_base_registry_relation rel
JOIN expedient_base_registries r ON r.id = rel.expedient_base_registry_id
WHERE rel.reference_name = 'presentaciones_registro_sanitario'
GROUP BY r.id, r.unique_code, r.name
ORDER BY num_presentaciones DESC
LIMIT 10;
