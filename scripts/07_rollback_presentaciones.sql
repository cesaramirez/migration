-- =============================================================================
-- ROLLBACK: Presentaciones de Productos
-- =============================================================================
-- Ejecutar en: Centro de Datos Database
-- IMPORTANTE: Ajustar la fecha/hora al momento en que se ejecutó la migración

-- Ver registros actuales
SELECT COUNT(*) as total_actual FROM presentaciones_registro_sanitario;

-- Eliminar solo registros creados después de cierta fecha
-- AJUSTAR LA FECHA/HORA según cuando ejecutaste el INSERT
DELETE FROM presentaciones_registro_sanitario
WHERE created_at >= '2026-01-18 18:00:00';  -- ⚠️ CAMBIAR ESTA FECHA

-- Verificar eliminación
SELECT COUNT(*) as total_despues_rollback FROM presentaciones_registro_sanitario;
