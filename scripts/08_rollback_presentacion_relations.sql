-- =============================================================================
-- ROLLBACK FASE 2: Relaciones Producto → Presentación
-- =============================================================================
-- Base de Datos: CORE
-- IMPORTANTE: Ajustar la fecha/hora al momento en que se ejecutó la migración

-- Ver relaciones actuales
SELECT COUNT(*) as total_relaciones_actual
FROM expedient_base_registry_relation
WHERE reference_name = 'presentaciones_registro_sanitario';

-- Eliminar solo relaciones creadas después de cierta fecha
-- ⚠️ AJUSTAR LA FECHA/HORA según cuando ejecutaste el INSERT
DELETE FROM expedient_base_registry_relation
WHERE reference_name = 'presentaciones_registro_sanitario'
  AND created_at >= '2026-01-18 23:00:00';  -- ⚠️ CAMBIAR ESTA FECHA

-- Verificar eliminación
SELECT COUNT(*) as total_relaciones_despues_rollback
FROM expedient_base_registry_relation
WHERE reference_name = 'presentaciones_registro_sanitario';
