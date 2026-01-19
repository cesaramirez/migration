-- =============================================================================
-- MIGRACIÓN DE RELACIONES PRODUCTO → MARCA
-- =============================================================================
-- Ejecutar en: CORE Database
-- Prerrequisito: Tener los CSV cargados en tablas temporales
-- (Ver assets/guides/migration_marca_producto_relations.md para carga de CSVs)

INSERT INTO expedient_base_registry_relation (
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    relation_id,
    relation_type,
    source,
    reference_name,
    created_at,
    updated_at
)
SELECT
    r.id AS expedient_base_registry_id,
    f.id AS expedient_base_entity_field_id,
    mm.marca_uuid AS relation_id,
    'field_value' AS relation_type,
    'data_center' AS source,
    'srs_marca' AS reference_name,
    NOW() AS created_at,
    NOW() AS updated_at
FROM migration_marca_producto mmp
JOIN expedient_base_registries r
    ON r.legacy_id = 'PRD-' || mmp.id_alim_producto
JOIN migration_marca_mapping mm
    ON mm.legacy_id = 'MARCA-' || mmp.id_ctl_marca
JOIN expedient_base_entities e
    ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f
    ON f.expedient_base_entity_id = e.id
    AND f.name = 'Marcas';

-- =============================================================================
-- VALIDACIÓN
-- =============================================================================

SELECT COUNT(*) as total_relaciones
FROM expedient_base_registry_relation
WHERE relation_type = 'field_value'
  AND source = 'data_center'
  AND reference_name = 'srs_marca';

SELECT
    (SELECT COUNT(*) FROM migration_marca_producto) as origen,
    (SELECT COUNT(*) FROM expedient_base_registry_relation
     WHERE reference_name = 'srs_marca') as destino;
