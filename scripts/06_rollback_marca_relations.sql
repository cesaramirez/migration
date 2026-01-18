-- =============================================================================
-- ROLLBACK: Relaciones Producto → Marca
-- =============================================================================
-- Ejecutar en: CORE Database
-- Propósito: Revertir la migración de relaciones marca-producto
-- =============================================================================

BEGIN;

-- 1. Verificar conteo antes de eliminar
SELECT COUNT(*) as relaciones_a_eliminar
FROM expedient_base_registry_relation
WHERE reference_name = 'srs_marca'
  AND relation_type = 'selected_option'
  AND source = 'data_center';

-- 2. Eliminar relaciones de marcas
DELETE FROM expedient_base_registry_relation
WHERE reference_name = 'srs_marca'
  AND relation_type = 'selected_option'
  AND source = 'data_center';

-- 3. Verificación final (debe ser 0)
SELECT COUNT(*) as relaciones_restantes
FROM expedient_base_registry_relation
WHERE reference_name = 'srs_marca';

COMMIT;

-- Si algo sale mal, ejecutar: ROLLBACK;
