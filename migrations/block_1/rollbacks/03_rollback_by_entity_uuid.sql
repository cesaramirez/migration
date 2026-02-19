-- =============================================================================
-- ROLLBACK PARA MIGRACIÓN BASADA EN UUID
-- =============================================================================
-- Revierte la migración realizada por: 03_migrate_by_entity_uuid.sql
-- UUID: af224c8b-ccdf-44ef-8e5d-58b8d7d70285
-- =============================================================================

-- PASO 0: Vista previa de lo que se eliminará
SELECT
    'Registros a eliminar' as accion,
    COUNT(*) as cantidad
FROM expedient_base_registries r
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND r.legacy_id LIKE 'PRD-%'
UNION ALL
SELECT
    'Valores de campos a eliminar',
    COUNT(*)
FROM expedient_base_registry_fields rf
JOIN expedient_base_registries r ON r.id = rf.expedient_base_registry_id
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND r.legacy_id LIKE 'PRD-%';

-- =============================================================================
-- ⚠️  CONFIRMAR ANTES DE EJECUTAR EL ROLLBACK
-- =============================================================================

BEGIN;

-- PASO 1: Eliminar valores de campos (registry_fields)
DELETE FROM expedient_base_registry_fields
WHERE expedient_base_registry_id IN (
    SELECT id
    FROM expedient_base_registries
    WHERE expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
      AND legacy_id LIKE 'PRD-%'
);

-- PASO 2: Eliminar relaciones (registry_relation)
DELETE FROM expedient_base_registry_relation
WHERE expedient_base_registry_id IN (
    SELECT id
    FROM expedient_base_registries
    WHERE expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
      AND legacy_id LIKE 'PRD-%'
);

-- PASO 3: Eliminar registros (registries)
DELETE FROM expedient_base_registries
WHERE expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND legacy_id LIKE 'PRD-%';

-- PASO 4: Verificación post-rollback
SELECT
    'Registros restantes' as metrica,
    COUNT(*) as cantidad
FROM expedient_base_registries
WHERE expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- =============================================================================
-- DECISIÓN FINAL
-- =============================================================================
COMMIT;  -- Confirmar rollback
-- ROLLBACK;  -- Cancelar el rollback
