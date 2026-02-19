-- =============================================================================
-- ROLLBACK COMPLETO: Solicitud de Importación de Productos Especiales
-- =============================================================================
-- Entidad: Importación de productos especiales
-- Este script revierte TODO lo creado por los scripts 12 o 13:
--   - Elimina valores de campos (registry_fields)
--   - Elimina registros (registries)
--   - Elimina campos de entidad (entity_fields) - OPCIONAL
--   - Elimina la entidad - OPCIONAL
--
-- ⚠️  PELIGRO: Este script es DESTRUCTIVO. Revisa bien antes de ejecutar.
--
-- Ejecutar en: Base de datos CORE
-- =============================================================================

-- =============================================================================
-- CONFIGURACIÓN: Elegir modo de rollback
-- =============================================================================
-- Modo 1: Rollback por nombre de entidad (si usaste script 12)
-- Modo 2: Rollback por UUID (si usaste script 13 o conoces el UUID)

-- ⚠️  DESCOMENTAR SOLO UNA OPCIÓN:

-- OPCIÓN A: Usar nombre de entidad
-- \set ROLLBACK_MODE 'BY_NAME'
-- \set ENTITY_NAME 'Importación de productos especiales'

-- OPCIÓN B: Usar UUID específico
-- \set ROLLBACK_MODE 'BY_UUID'
-- \set ENTITY_UUID 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'

-- =============================================================================
-- PASO 0: VERIFICACIÓN PREVIA (ejecutar antes del BEGIN)
-- =============================================================================

-- Verificar qué se va a eliminar (POR NOMBRE)
SELECT
    e.id as entity_uuid,
    e.name as entidad,
    COUNT(DISTINCT r.id) as registros,
    COUNT(rf.id) as valores_campos
FROM expedient_base_entities e
LEFT JOIN expedient_base_registries r ON r.expedient_base_entity_id = e.id
LEFT JOIN expedient_base_registry_fields rf ON rf.expedient_base_registry_id = r.id
WHERE e.name = 'Importación de productos especiales'
GROUP BY e.id, e.name;

-- Verificar con legacy_id pattern (SIMP-*)
SELECT
    'Registros con legacy_id SIMP-*' as descripcion,
    COUNT(*) as total
FROM expedient_base_registries
WHERE legacy_id LIKE 'SIMP-%';

-- =============================================================================
-- ⚠️  CONFIRMAR QUE LOS NÚMEROS SON CORRECTOS ANTES DE CONTINUAR
-- =============================================================================

BEGIN;

-- =============================================================================
-- PASO 1: Eliminar valores de campos (registry_fields)
-- =============================================================================
-- Esto SOLO elimina los valores migrados, no los campos ni la entidad

DELETE FROM expedient_base_registry_fields
WHERE expedient_base_registry_id IN (
    SELECT r.id
    FROM expedient_base_registries r
    JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
    WHERE e.name = 'Importación de productos especiales'
);

-- Verificar eliminación
SELECT 'Valores de campos eliminados' as paso;

-- =============================================================================
-- PASO 2: Eliminar registros (registries)
-- =============================================================================
-- Esto elimina los registros que identificamos por legacy_id

DELETE FROM expedient_base_registries
WHERE legacy_id LIKE 'SIMP-%';

-- Alternativa: Eliminar por entidad
/*
DELETE FROM expedient_base_registries
WHERE expedient_base_entity_id IN (
    SELECT id FROM expedient_base_entities
    WHERE name = 'Importación de productos especiales'
);
*/

-- Verificar eliminación
SELECT 'Registros eliminados' as paso;

-- =============================================================================
-- PASO 3 (OPCIONAL): Eliminar campos de la entidad
-- =============================================================================
-- ⚠️  Solo descomenta si quieres eliminar también los campos

/*
DELETE FROM expedient_base_entity_fields
WHERE expedient_base_entity_id IN (
    SELECT id FROM expedient_base_entities
    WHERE name = 'Importación de productos especiales'
);

SELECT 'Campos de entidad eliminados' as paso;
*/

-- =============================================================================
-- PASO 4 (OPCIONAL): Eliminar la entidad
-- =============================================================================
-- ⚠️  Solo descomenta si quieres eliminar también la entidad

/*
DELETE FROM expedient_base_entities
WHERE name = 'Importación de productos especiales';

SELECT 'Entidad eliminada' as paso;
*/

-- =============================================================================
-- PASO 5: Verificación Final
-- =============================================================================

-- 5.1 Verificar que no quedan registros
SELECT
    'Registros restantes' as descripcion,
    COUNT(*) as total
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'Importación de productos especiales';

-- 5.2 Verificar que no quedan valores de campos
SELECT
    'Valores de campos restantes' as descripcion,
    COUNT(*) as total
FROM expedient_base_registry_fields rf
WHERE rf.expedient_base_registry_id IN (
    SELECT r.id
    FROM expedient_base_registries r
    JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
    WHERE e.name = 'Importación de productos especiales'
);

-- 5.3 Estado de la entidad
SELECT
    'Estado de entidad' as descripcion,
    CASE WHEN COUNT(*) > 0 THEN 'Existe' ELSE 'Eliminada' END as status
FROM expedient_base_entities
WHERE name = 'Importación de productos especiales';

-- 5.4 Verificar legacy_id pattern
SELECT
    'legacy_id SIMP-* restantes' as descripcion,
    COUNT(*) as total
FROM expedient_base_registries
WHERE legacy_id LIKE 'SIMP-%';

-- =============================================================================
-- DECISIÓN FINAL
-- =============================================================================
COMMIT;  -- Confirmar eliminación
-- ROLLBACK;  -- Descomenta para cancelar

-- =============================================================================
-- NOTAS POST-ROLLBACK
-- =============================================================================
-- 1. La tabla temporal migration_solicitud_importacion_temp NO se elimina
--    Esto permite re-ejecutar la migración si es necesario
--
-- 2. Para limpiar completamente, ejecuta:
--    DROP TABLE IF EXISTS migration_solicitud_importacion_temp;
--
-- 3. Si eliminaste la entidad (Paso 4), verifica que no hay referencias
--    huérfanas en otras tablas del sistema
-- =============================================================================
