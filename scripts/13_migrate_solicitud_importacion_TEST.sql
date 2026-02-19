-- =============================================================================
-- MIGRACIÓN DE PRUEBA - SOLO 1,000 REGISTROS
-- =============================================================================
-- Entidad: Importación de productos especiales
-- UUID DEV: 3fa9e361-7973-4d80-9b49-89009ffa4199
--
-- PROPÓSITO: Validar que la migración funciona antes de procesar 577K registros
-- EJECUTAR CON: psql -h <host> -U <user> -d <db> -f 13_migrate_solicitud_importacion_TEST.sql
-- =============================================================================

\timing on
\set ENTITY_UUID '3fa9e361-7973-4d80-9b49-89009ffa4199'
\set TEST_LIMIT 1000

\echo '=========================================='
\echo 'MIGRACIÓN DE PRUEBA - 1,000 REGISTROS'
\echo '=========================================='

-- Verificación previa
SELECT 'Total en tabla temporal:' as info, COUNT(*) as total FROM migration_solicitud_importacion_temp;
SELECT 'Ya migrados:' as info, COUNT(*) as total FROM expedient_base_registries WHERE expedient_base_entity_id = :'ENTITY_UUID'::uuid;

-- Crear función si no existe
CREATE OR REPLACE FUNCTION generate_unique_code()
RETURNS VARCHAR(12) AS $$
BEGIN
    RETURN UPPER(encode(gen_random_bytes(6), 'hex'));
END;
$$ LANGUAGE plpgsql;

-- Asegurar columna legacy_id
ALTER TABLE expedient_base_registries ADD COLUMN IF NOT EXISTS legacy_id VARCHAR(30);

BEGIN;

\echo ''
\echo 'Insertando 1000 registros de prueba...'

-- Insertar solo 1000 registros
INSERT INTO expedient_base_registries (
    id, name, metadata, expedient_base_entity_id, unique_code, legacy_id, created_at, updated_at
)
SELECT
    gen_random_uuid(),
    COALESCE(NULLIF(TRIM(t.nombre_importador), ''), 'Solicitud ' || t.numero_solicitud),
    jsonb_build_object(
        'original_id', t.original_id,
        'original_bcr_id', t.original_bcr_id,
        'source', 'alim_solicitud_importacion_minsal',
        'migration_type', 'test',
        'entity_uuid', :'ENTITY_UUID',
        'migration_date', NOW()::text
    ),
    :'ENTITY_UUID'::uuid,
    generate_unique_code(),
    'SIMP-' || t.original_id,
    NOW(),
    NOW()
FROM (
    SELECT * FROM migration_solicitud_importacion_temp
    ORDER BY original_id
    LIMIT :TEST_LIMIT
) t
ON CONFLICT (legacy_id) DO NOTHING;

\echo '✓ Registries insertados'

-- Insertar campos para los 1000 registros de prueba
\echo ''
\echo 'Insertando campos...'

-- nombre_importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || REPLACE(t.nombre_importador, '"', '\"') || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'nombre_importador'
WHERE r.expedient_base_entity_id = :'ENTITY_UUID'::uuid
  AND t.nombre_importador IS NOT NULL AND t.nombre_importador != ''
  AND t.original_id IN (SELECT original_id FROM migration_solicitud_importacion_temp ORDER BY original_id LIMIT :TEST_LIMIT);
\echo '  ✓ nombre_importador'

-- nit_importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nit_importador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'nit_importador'
WHERE r.expedient_base_entity_id = :'ENTITY_UUID'::uuid
  AND t.nit_importador IS NOT NULL AND t.nit_importador != ''
  AND t.original_id IN (SELECT original_id FROM migration_solicitud_importacion_temp ORDER BY original_id LIMIT :TEST_LIMIT);
\echo '  ✓ nit_importador'

-- fecha_registro_bcr
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_registro_bcr || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'fecha_registro_bcr'
WHERE r.expedient_base_entity_id = :'ENTITY_UUID'::uuid
  AND t.fecha_registro_bcr IS NOT NULL AND t.fecha_registro_bcr != ''
  AND t.original_id IN (SELECT original_id FROM migration_solicitud_importacion_temp ORDER BY original_id LIMIT :TEST_LIMIT);
\echo '  ✓ fecha_registro_bcr'

-- numero_de_solicitud
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.numero_solicitud || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'numero_de_solicitud'
WHERE r.expedient_base_entity_id = :'ENTITY_UUID'::uuid
  AND t.numero_solicitud IS NOT NULL AND t.numero_solicitud != ''
  AND t.original_id IN (SELECT original_id FROM migration_solicitud_importacion_temp ORDER BY original_id LIMIT :TEST_LIMIT);
\echo '  ✓ numero_de_solicitud'

-- estado_de_solicitud
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.estado_de_solicitud || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'estado_de_solicitud'
WHERE r.expedient_base_entity_id = :'ENTITY_UUID'::uuid
  AND t.estado_de_solicitud IS NOT NULL
  AND t.original_id IN (SELECT original_id FROM migration_solicitud_importacion_temp ORDER BY original_id LIMIT :TEST_LIMIT);
\echo '  ✓ estado_de_solicitud'

-- Verificación
\echo ''
\echo '=========================================='
\echo 'VERIFICACIÓN'
\echo '=========================================='

SELECT 'Registries insertados:' as metrica, COUNT(*) as total
FROM expedient_base_registries WHERE expedient_base_entity_id = :'ENTITY_UUID'::uuid
UNION ALL
SELECT 'Registry fields insertados:', COUNT(*)
FROM expedient_base_registry_fields rf
JOIN expedient_base_registries r ON r.id = rf.expedient_base_registry_id
WHERE r.expedient_base_entity_id = :'ENTITY_UUID'::uuid;

-- Muestra de datos
SELECT r.unique_code, r.name, r.legacy_id
FROM expedient_base_registries r
WHERE r.expedient_base_entity_id = :'ENTITY_UUID'::uuid
LIMIT 5;

\echo ''
\echo '=========================================='
\echo 'DECISIÓN'
\echo '=========================================='
\echo 'Si los datos se ven correctos, ejecuta: COMMIT;'
\echo 'Si hay errores, ejecuta: ROLLBACK;'
\echo ''

-- Dejar la transacción abierta para revisión
-- COMMIT;
-- ROLLBACK;
