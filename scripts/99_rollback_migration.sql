-- =============================================================================
-- ROLLBACK: Revertir migración de alim_producto
-- =============================================================================
-- Ejecutar en SDT DEV para eliminar todos los datos migrados de "T81 - Registro Sanitario Alimentos"
-- CUIDADO: Este script elimina datos permanentemente
-- =============================================================================

BEGIN;

-- Paso 1: Eliminar valores de campos (registry_fields)
DELETE FROM expedient_base_registry_fields
WHERE expedient_base_registry_id IN (
    SELECT r.id
    FROM expedient_base_registries r
    JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
    WHERE e.name = 'T81 - Registro Sanitario Alimentos'
);

-- Paso 2: Eliminar registros (registries)
DELETE FROM expedient_base_registries
WHERE expedient_base_entity_id IN (
    SELECT id FROM expedient_base_entities WHERE name = 'T81 - Registro Sanitario Alimentos'
);

-- Paso 3: Eliminar campos de la entidad (entity_fields)
DELETE FROM expedient_base_entity_fields
WHERE expedient_base_entity_id IN (
    SELECT id FROM expedient_base_entities WHERE name = 'T81 - Registro Sanitario Alimentos'
);

-- Paso 4: Eliminar la entidad
DELETE FROM expedient_base_entities WHERE name = 'T81 - Registro Sanitario Alimentos';

-- Paso 5: Eliminar tabla temporal
DROP TABLE IF EXISTS migration_alim_producto_temp;

-- Verificar que todo fue eliminado
SELECT 'Entidades restantes' as check, COUNT(*) as total FROM expedient_base_entities WHERE name = 'T81 - Registro Sanitario Alimentos'
UNION ALL
SELECT 'Registros restantes', COUNT(*) FROM expedient_base_registries r
    JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- =============================================================================
-- DECISIÓN FINAL
-- =============================================================================
COMMIT;  -- Ejecutar rollback permanente
-- ROLLBACK;  -- Si quieres cancelar y no eliminar nada
