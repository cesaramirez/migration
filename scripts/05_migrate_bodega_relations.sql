-- =============================================================================
-- MIGRACIÓN DE RELACIONES PRODUCTO → BODEGA
-- =============================================================================
-- Ejecutar en: CORE Database

INSERT INTO expedient_base_registry_relation (
    expedient_base_registry_id,
    relation_id,
    relation_type,
    reference_name,
    created_at,
    updated_at
)
SELECT
    r.id AS expedient_base_registry_id,
    bm.bodega_uuid AS relation_id,
    'data_center' AS relation_type,
    'srs_bodega' AS reference_name,
    COALESCE(mbp.fecha_registro::timestamp, NOW()) AS created_at,
    NOW() AS updated_at
FROM migration_bodega_producto mbp
JOIN expedient_base_registries r
    ON r.legacy_id = 'PRD-' || mbp.id_alim_producto
JOIN migration_bodega_mapping bm
    ON bm.legacy_id = 'BOD-' || mbp.id_alim_bodega;

-- =============================================================================
-- VALIDACIÓN
-- =============================================================================

SELECT COUNT(*) as total_relaciones
FROM expedient_base_registry_relation
WHERE relation_type = 'data_center'
  AND reference_name = 'srs_bodega';

SELECT
    (SELECT COUNT(*) FROM migration_bodega_producto) as origen,
    (SELECT COUNT(*) FROM expedient_base_registry_relation
     WHERE reference_name = 'srs_bodega') as destino;
