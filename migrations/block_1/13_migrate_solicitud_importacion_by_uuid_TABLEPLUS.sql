-- =============================================================================
-- ESCENARIO B: MIGRAR USANDO UUID DE ENTIDAD EXISTENTE
-- =============================================================================
-- Entidad: Importación de productos especiales
-- Este script:
--   - NO crea la entidad (debe existir previamente)
--   - NO crea los campos (ya deben estar configurados)
--   - Referencia la entidad directamente por UUID
--   - Incluye validaciones de compatibilidad
--
-- PRERREQUISITOS:
--   1. La entidad con el UUID especificado DEBE existir
--   2. Los campos (entity_fields) ya deben estar creados
--   3. La tabla migration_solicitud_importacion_temp debe existir con datos
--
-- Ejecutar en: Base de datos CORE
-- =============================================================================

-- =============================================================================
-- CONFIGURACIÓN: UUID de la entidad destino
-- =============================================================================
-- Entorno DEV: Importación de productos especiales
-- UUID: 3fa9e361-7973-4d80-9b49-89009ffa4199

-- Si ya ejecutaste 12_migrate_solicitud_importacion_create_entity.sql,
-- puedes obtener el UUID con:
/*
SELECT id FROM expedient_base_entities
WHERE name = 'Importación de productos especiales';
*/

-- =============================================================================
-- PASO 0: VALIDACIONES PREVIAS (ejecutar antes del BEGIN)
-- =============================================================================

-- 0.1 Verificar que la entidad existe
SELECT
    CASE WHEN COUNT(*) = 1 THEN '✅ Entidad encontrada'
         ELSE '❌ ERROR: Entidad no existe con UUID 3fa9e361-7973-4d80-9b49-89009ffa4199'
    END AS validacion,
    id, name, status, version
FROM expedient_base_entities
WHERE id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
GROUP BY id, name, status, version;

-- 0.2 Listar campos disponibles en la entidad destino
SELECT
    f.name AS campo_destino,
    f.field_type AS tipo,
    f."order" AS orden,
    f.is_required AS requerido
FROM expedient_base_entity_fields f
WHERE f.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
ORDER BY f."order";

-- 0.3 Verificar campos requeridos para la migración
WITH campos_requeridos AS (
    SELECT unnest(ARRAY[
        'nombre_importador',
        'nit_importador',
        'fecha_registro_bcr',
        'numero_de_solicitud',
        'estado_de_solicitud',
        'direccion_importador',
        'departamento',
        'municipio',
        'nombre_del_tramitador',
        'tipo_documento_usuario',
        'numero_documento_del_tramitador',
        'pais',
        'numero_solicitud_minsal',
        'id_tipo_documento_usuario'
    ]) AS campo_esperado
),
campos_existentes AS (
    SELECT f.name AS campo_existente
    FROM expedient_base_entity_fields f
    WHERE f.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
)
SELECT
    cr.campo_esperado,
    CASE WHEN ce.campo_existente IS NOT NULL THEN '✅' ELSE '❌ FALTA' END AS status
FROM campos_requeridos cr
LEFT JOIN campos_existentes ce ON cr.campo_esperado = ce.campo_existente
ORDER BY cr.campo_esperado;

-- 0.4 Verificar tabla temporal con datos
SELECT
    CASE WHEN COUNT(*) > 0 THEN '✅ Datos disponibles: ' || COUNT(*) || ' registros'
         ELSE '❌ ERROR: No hay datos en migration_solicitud_importacion_temp'
    END AS validacion
FROM migration_solicitud_importacion_temp;

-- =============================================================================
-- ⚠️  REVISAR LAS VALIDACIONES ANTERIORES ANTES DE CONTINUAR
-- =============================================================================

BEGIN;

-- =============================================================================
-- PASO 1: Función para generar unique_code (si no existe)
-- =============================================================================
CREATE OR REPLACE FUNCTION generate_unique_code()
RETURNS VARCHAR(12) AS $$
BEGIN
    RETURN UPPER(encode(gen_random_bytes(6), 'hex'));
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- PASO 2: Asegurar columna legacy_id (si no existe)
-- =============================================================================
ALTER TABLE expedient_base_registries
ADD COLUMN IF NOT EXISTS legacy_id VARCHAR(30);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uk_ebr_legacy_id'
    ) THEN
        ALTER TABLE expedient_base_registries
        ADD CONSTRAINT uk_ebr_legacy_id UNIQUE (legacy_id);
    END IF;
EXCEPTION WHEN duplicate_object THEN
    NULL;
END $$;

-- =============================================================================
-- PASO 3: Migrar Registros usando UUID directo
-- =============================================================================
INSERT INTO expedient_base_registries (
    id,
    name,
    metadata,
    expedient_base_entity_id,
    unique_code,
    legacy_id,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid(),
    COALESCE(NULLIF(TRIM(t.nombre_importador), ''), 'Solicitud ' || t.numero_solicitud),
    jsonb_build_object(
        'original_id', t.original_id,
        'original_bcr_id', t.original_bcr_id,
        'source', 'alim_solicitud_importacion_minsal',
        'migration_type', 'uuid_based',
        'entity_uuid', '3fa9e361-7973-4d80-9b49-89009ffa4199',
        'migration_date', NOW()::text
    ),
    '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid,
    generate_unique_code(),
    'SIMP-' || t.original_id,
    NOW(),
    NOW()
FROM migration_solicitud_importacion_temp t
ON CONFLICT (legacy_id) DO NOTHING;

-- Verificar registros migrados
SELECT COUNT(*) as total_registries_migrados
FROM expedient_base_registries r
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid;

-- =============================================================================
-- PASO 4: Migrar Valores de Campos (usando UUID directo)
-- =============================================================================

-- 4.1 nombre_importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nombre_importador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'nombre_importador'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.nombre_importador IS NOT NULL AND t.nombre_importador != '';

-- 4.2 nit_importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nit_importador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'nit_importador'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.nit_importador IS NOT NULL AND t.nit_importador != '';

-- 4.3 fecha_registro_bcr
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_registro_bcr || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'fecha_registro_bcr'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.fecha_registro_bcr IS NOT NULL AND t.fecha_registro_bcr != '';

-- 4.4 numero_de_solicitud
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.numero_solicitud || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'numero_de_solicitud'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.numero_solicitud IS NOT NULL AND t.numero_solicitud != '';

-- 4.5 estado_de_solicitud
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.estado_de_solicitud || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'estado_de_solicitud'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.estado_de_solicitud IS NOT NULL;

-- 4.6 direccion_importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.direccion_importador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'direccion_importador'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.direccion_importador IS NOT NULL AND t.direccion_importador != '';

-- 4.7 departamento
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.departamento || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'departamento'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.departamento IS NOT NULL AND t.departamento != '';

-- 4.8 municipio
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.municipio || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'municipio'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.municipio IS NOT NULL AND t.municipio != '';

-- 4.9 nombre_del_tramitador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nombre_del_tramitador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'nombre_del_tramitador'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.nombre_del_tramitador IS NOT NULL AND t.nombre_del_tramitador != '';

-- 4.10 tipo_documento_usuario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.tipo_documento_usuario || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'tipo_documento_usuario'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.tipo_documento_usuario IS NOT NULL AND t.tipo_documento_usuario != '';

-- 4.11 numero_documento_del_tramitador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.numero_documento_del_tramitador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'numero_documento_del_tramitador'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.numero_documento_del_tramitador IS NOT NULL AND t.numero_documento_del_tramitador != '';

-- 4.12 pais
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.pais || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'pais'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.pais IS NOT NULL AND t.pais != '';

-- 4.13 numero_solicitud_minsal
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.numero_solicitud_minsal || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'numero_solicitud_minsal'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.numero_solicitud_minsal IS NOT NULL AND t.numero_solicitud_minsal != '';

-- 4.14 fecha_registro_minsal
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_registro_minsal || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'fecha_registro_minsal'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.fecha_registro_minsal IS NOT NULL AND t.fecha_registro_minsal != '';

-- 4.15 fecha_resolucion_minsal
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_resolucion_minsal || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'fecha_resolucion_minsal'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.fecha_resolucion_minsal IS NOT NULL AND t.fecha_resolucion_minsal != '';

-- 4.16 justificacion_resolucion
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.justificacion_resolucion || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'justificacion_resolucion'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.justificacion_resolucion IS NOT NULL AND t.justificacion_resolucion != '';

-- 4.17 estado_externo
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.estado_externo || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'estado_externo'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.estado_externo IS NOT NULL AND t.estado_externo != '';

-- 4.18 fecha_estado_externo
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_estado_externo || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'fecha_estado_externo'
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.fecha_estado_externo IS NOT NULL AND t.fecha_estado_externo != '';

-- =============================================================================
-- PASO 5: Campos de Relación (IDs de Centro de Datos)
-- =============================================================================

-- 5.1 id_pais (con fallback: iso_number → iso_2_code → iso_3_code)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'id_pais'
LEFT JOIN paises dest ON
    dest.iso_number = t.original_pais_iso_number
    OR dest.iso_2_code = t.original_pais_iso_2
    OR dest.iso_3_code = t.original_pais_iso_3
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.original_pais_id IS NOT NULL;

-- 5.2 id_departamento
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'id_departamento'
LEFT JOIN departamentos dest ON dest.legacy_id = 'DEP-' || t.original_departamento_id
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.original_departamento_id IS NOT NULL;

-- 5.3 id_municipio
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'id_municipio'
LEFT JOIN municipios dest ON dest.legacy_id = 'MUN-' || t.original_municipio_id
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.original_municipio_id IS NOT NULL;

-- 5.4 id_tipo_documento_usuario (cruce por nombre normalizado)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'id_tipo_documento_usuario'
LEFT JOIN tipo_documento_usuario dest ON UPPER(dest.nombre) = UPPER(t.tipo_documento_usuario)
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
  AND t.tipo_documento_usuario IS NOT NULL AND t.tipo_documento_usuario != '';

-- =============================================================================
-- PASO 6: Verificación Final
-- =============================================================================

-- 6.1 Resumen de migración
SELECT 'Registros migrados' as metrica, COUNT(DISTINCT r.id) as total
FROM expedient_base_registries r
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
UNION ALL
SELECT 'Valores de campos' as metrica, COUNT(*) as total
FROM expedient_base_registry_fields rf
JOIN expedient_base_registries r ON r.id = rf.expedient_base_registry_id
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid;

-- 6.2 Detalle por campo
SELECT f.name as campo, f."order" as orden, COUNT(rf.id) as registros_con_valor
FROM expedient_base_entity_fields f
LEFT JOIN expedient_base_registry_fields rf ON rf.expedient_base_entity_field_id = f.id
WHERE f.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
GROUP BY f.name, f."order"
ORDER BY f."order";

-- 6.3 Muestra de datos migrados
SELECT r.unique_code, r.name as nombre_importador, r.legacy_id, (r.metadata->>'original_id') as id_original
FROM expedient_base_registries r
WHERE r.expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid
LIMIT 5;

-- 6.4 Comparación origen vs destino
SELECT
    'Origen (temp table)' as fuente,
    COUNT(*) as registros
FROM migration_solicitud_importacion_temp
UNION ALL
SELECT
    'Destino (registries)',
    COUNT(*)
FROM expedient_base_registries
WHERE expedient_base_entity_id = '3fa9e361-7973-4d80-9b49-89009ffa4199'::uuid;

-- =============================================================================
-- DECISIÓN FINAL
-- =============================================================================
COMMIT;  -- Guardar cambios
-- ROLLBACK;  -- Descomenta para revertir
