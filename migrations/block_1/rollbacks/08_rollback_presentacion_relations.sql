-- =============================================================================
-- ROLLBACK: Relaciones Producto → Presentación
-- =============================================================================
-- Ejecutar en: CORE Database
-- Elimina SOLO relaciones de productos migrados (legacy_id LIKE 'PRD-%')
-- NO afecta relaciones creadas por la aplicación después de la migración
-- =============================================================================

-- Vista previa de relaciones a eliminar
SELECT COUNT(*) as total_a_eliminar
FROM expedient_base_registry_relation rel
JOIN expedient_base_registries r ON r.id = rel.expedient_base_registry_id
WHERE rel.reference_name = 'presentaciones_registro_sanitario'
  AND r.legacy_id LIKE 'PRD-%';  -- Solo productos migrados

-- Ver relaciones que NO se eliminarán (creadas por app)
SELECT COUNT(*) as relaciones_preservadas
FROM expedient_base_registry_relation rel
JOIN expedient_base_registries r ON r.id = rel.expedient_base_registry_id
WHERE rel.reference_name = 'presentaciones_registro_sanitario'
  AND (r.legacy_id IS NULL OR r.legacy_id NOT LIKE 'PRD-%');

-- Eliminar relaciones de productos MIGRADOS solamente
DELETE FROM expedient_base_registry_relation
WHERE id IN (
    SELECT rel.id
    FROM expedient_base_registry_relation rel
    JOIN expedient_base_registries r ON r.id = rel.expedient_base_registry_id
    WHERE rel.reference_name = 'presentaciones_registro_sanitario'
      AND r.legacy_id LIKE 'PRD-%'
);

-- Verificar eliminación
SELECT COUNT(*) as total_despues_rollback
FROM expedient_base_registry_relation
WHERE reference_name = 'presentaciones_registro_sanitario';
