-- =============================================================================
-- ROLLBACK: Relaciones Producto → Bodega
-- =============================================================================
-- Ejecutar en: CORE Database
-- Propósito: Revertir la migración de relaciones producto-bodega
-- =============================================================================

-- =============================================================================
-- OPCIÓN 1: Rollback Completo (elimina TODAS las relaciones bodega)
-- =============================================================================

BEGIN;

-- Verificar cantidad antes de eliminar
SELECT COUNT(*) as relaciones_a_eliminar
FROM expedient_base_registry_relation
WHERE relation_type = 'field_value'
  AND source = 'data_center'
  AND reference_name = 'srs_bodega';

-- Ejecutar DELETE
DELETE FROM expedient_base_registry_relation
WHERE relation_type = 'field_value'
  AND source = 'data_center'
  AND reference_name = 'srs_bodega';

-- Verificar que se eliminaron
SELECT COUNT(*) as relaciones_restantes
FROM expedient_base_registry_relation
WHERE reference_name = 'srs_bodega';
-- Debe ser 0

COMMIT;
-- Si algo salió mal, usar: ROLLBACK;

-- =============================================================================
-- OPCIÓN 2: Rollback por Fecha (solo relaciones creadas después de X fecha)
-- =============================================================================

/*
DELETE FROM expedient_base_registry_relation
WHERE relation_type = 'field_value'
  AND source = 'data_center'
  AND reference_name = 'srs_bodega'
  AND created_at >= '2026-01-18 00:00:00';  -- Ajustar fecha
*/

-- =============================================================================
-- OPCIÓN 3: Rollback por Producto Específico
-- =============================================================================

/*
DELETE FROM expedient_base_registry_relation
WHERE expedient_base_registry_id = (
    SELECT id FROM expedient_base_registries
    WHERE legacy_id = 'PRD-12345'  -- Cambiar ID
)
AND reference_name = 'srs_bodega';
*/

-- =============================================================================
-- OPCIÓN 4: Rollback Idempotente (seguro para ejecutar múltiples veces)
-- =============================================================================

/*
DO $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM expedient_base_registry_relation
    WHERE relation_type = 'field_value'
      AND source = 'data_center'
      AND reference_name = 'srs_bodega';

    RAISE NOTICE 'Relaciones bodega a eliminar: %', v_count;

    IF v_count > 0 THEN
        DELETE FROM expedient_base_registry_relation
        WHERE relation_type = 'field_value'
          AND source = 'data_center'
          AND reference_name = 'srs_bodega';

        RAISE NOTICE 'Rollback completado: % relaciones eliminadas', v_count;
    ELSE
        RAISE NOTICE 'No hay relaciones bodega para eliminar';
    END IF;
END $$;
*/
