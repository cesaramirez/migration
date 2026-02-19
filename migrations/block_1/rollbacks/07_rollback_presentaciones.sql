-- =============================================================================
-- ROLLBACK: Presentaciones de Productos
-- =============================================================================
-- Ejecutar en: Centro de Datos Database
-- Elimina registros migrados identificados por legacy_id
-- =============================================================================

-- Vista previa de registros a eliminar
SELECT COUNT(*) as total_a_eliminar
FROM presentaciones_registro_sanitario
WHERE legacy_id LIKE 'PRES-%';

-- Eliminar registros migrados
DELETE FROM presentaciones_registro_sanitario
WHERE legacy_id LIKE 'PRES-%';

-- Verificar eliminación
SELECT COUNT(*) as total_despues_rollback FROM presentaciones_registro_sanitario;
