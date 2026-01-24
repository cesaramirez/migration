-- =============================================================================
-- SCRIPT DE MIGRACIÓN BASADO EN UUID DE EXPEDIENT_BASE_ENTITY
-- =============================================================================
-- Tipo: Migración por UUID
-- Entidad: T81 - Registro Sanitario Alimentos
-- UUID: af224c8b-ccdf-44ef-8e5d-58b8d7d70285
--
-- PRERREQUISITOS:
--   1. La entidad con el UUID especificado DEBE existir
--   2. Los campos (entity_fields) ya deben estar creados por el equipo
--   3. La tabla migration_alim_producto_temp debe existir con datos
--
-- DIFERENCIAS CON 02_migrate_from_temp.sql:
--   - NO crea la entidad (ya existe)
--   - NO crea los campos (ya los creó otro equipo)
--   - Referencia la entidad directamente por UUID (más robusto)
--   - Incluye validaciones de compatibilidad de campos
-- =============================================================================

-- =============================================================================
-- CONFIGURACIÓN: UUID de la entidad destino
-- =============================================================================
-- Cambiar este UUID según la entidad destino deseada
\set ENTITY_UUID 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'

-- =============================================================================
-- PASO 0: VALIDACIONES PREVIAS (ejecutar antes del BEGIN)
-- =============================================================================

-- 0.1 Verificar que la entidad existe
SELECT
    CASE WHEN COUNT(*) = 1 THEN '✅ Entidad encontrada'
         ELSE '❌ ERROR: Entidad no existe con UUID ' || :'ENTITY_UUID'
    END AS validacion,
    id, name, status, version
FROM expedient_base_entities
WHERE id = :'ENTITY_UUID'::uuid
GROUP BY id, name, status, version;

-- 0.2 Listar campos disponibles en la entidad destino
SELECT
    f.name AS campo_destino,
    f.field_type AS tipo,
    f."order" AS orden,
    f.is_required AS requerido
FROM expedient_base_entity_fields f
WHERE f.expedient_base_entity_id = :'ENTITY_UUID'::uuid
ORDER BY f."order";

-- 0.3 Verificar campos requeridos para la migración
WITH campos_requeridos AS (
    SELECT unnest(ARRAY[
        'Nombre del producto',
        'Número de registro sanitario',
        'Tipo de producto',
        'País de fabricación',
        'Fecha de emisión del registro',
        'Fecha de vigencia del registro',
        'Estado'
    ]) AS campo_esperado
),
campos_existentes AS (
    SELECT f.name AS campo_existente
    FROM expedient_base_entity_fields f
    WHERE f.expedient_base_entity_id = :'ENTITY_UUID'::uuid
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
         ELSE '❌ ERROR: No hay datos en migration_alim_producto_temp'
    END AS validacion
FROM migration_alim_producto_temp;

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
END $$;

-- =============================================================================
-- PASO 3: Migrar Registros usando UUID directo
-- =============================================================================
-- NOTA: Usa el UUID directamente, sin JOIN por nombre
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
    t.nombre,
    jsonb_build_object(
        'original_id', t.original_id,
        'source', 'alim_producto',
        'migration_type', 'uuid_based',
        'entity_uuid', 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285',
        'migration_date', NOW()::text
    ),
    'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid,  -- UUID directo
    generate_unique_code(),
    'PRD-' || t.original_id,
    NOW(),
    NOW()
FROM migration_alim_producto_temp t
ON CONFLICT (legacy_id) DO NOTHING;

-- Verificar registros migrados
SELECT COUNT(*) as total_registries_migrados
FROM expedient_base_registries r
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- =============================================================================
-- PASO 4: Migrar Valores de Campos (usando UUID directo)
-- =============================================================================
-- Nota: Cada INSERT hace JOIN con entity_fields por UUID de entidad

-- 4.1 Nombre del producto (requerido)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nombre || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Nombre del producto'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- 4.2 Número de registro sanitario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.num_registro_sanitario || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Número de registro sanitario'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.num_registro_sanitario IS NOT NULL;

-- 4.3 Tipo de producto (requerido)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.tipo_producto || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Tipo de producto'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- 4.4 Número de partida arancelaria
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.num_partida_arancelaria || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Número de partida arancelaria'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.num_partida_arancelaria IS NOT NULL;

-- 4.5 Fecha de emisión del registro
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_emision_registro || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Fecha de emisión del registro'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.fecha_emision_registro IS NOT NULL;

-- 4.6 Fecha de vigencia del registro
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_vigencia_registro || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Fecha de vigencia del registro'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.fecha_vigencia_registro IS NOT NULL;

-- 4.7 Estado
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.estado_producto || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Estado'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.estado_producto IS NOT NULL;

-- 4.8 Subgrupo alimenticio
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.subgrupo_alimenticio || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Subgrupo alimenticio'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.subgrupo_alimenticio IS NOT NULL;

-- 4.9 Clasificación alimenticia
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.clasificacion_alimenticia || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Clasificación alimenticia'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.clasificacion_alimenticia IS NOT NULL;

-- 4.10 Riesgo
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.riesgo || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Riesgo'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.riesgo IS NOT NULL;

-- 4.11 País de fabricación (requerido)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.pais || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'País de fabricación'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.pais IS NOT NULL;

-- 4.12 Código de CLV
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.codigo_clv || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Código de CLV'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.codigo_clv IS NOT NULL;

-- 4.13 Nombre del producto según CLV
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nombre_producto_clv || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Nombre del producto según CLV'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.nombre_producto_clv IS NOT NULL;

-- 4.14 País de procedencia según CLV
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.pais_procedencia_clv || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'País de procedencia según CLV'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.pais_procedencia_clv IS NOT NULL;

-- 4.15 Nombre del propietario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_nombre || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Nombre del propietario'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.propietario_nombre IS NOT NULL;

-- 4.16 NIT del propietario del registro sanitario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_nit || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'NIT del propietario del registro sanitario'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.propietario_nit IS NOT NULL;

-- 4.17 Correo electrónico del propietario del registro
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_correo || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Correo electrónico del propietario del registro'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.propietario_correo IS NOT NULL;

-- 4.18 Dirección del propietario del registro sanitario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_direccion || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Dirección del propietario del registro sanitario'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.propietario_direccion IS NOT NULL;

-- 4.19 País de procedencia del propietario del registro
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_pais || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'País de procedencia del propietario del registro'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.propietario_pais IS NOT NULL;

-- 4.20 Razón social del propietario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_razon_social || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Razón social del propietario'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.propietario_razon_social IS NOT NULL;

-- 4.21 Nombre del fabricante
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_nombre || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Nombre del fabricante'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.fabricante_nombre IS NOT NULL;

-- 4.22 NIT del fabricante
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_nit || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'NIT del fabricante'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.fabricante_nit IS NOT NULL;

-- 4.23 Correo del fabricante
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_correo || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Correo del fabricante'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.fabricante_correo IS NOT NULL;

-- 4.24 Dirección del fabricante
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_direccion || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Dirección del fabricante'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.fabricante_direccion IS NOT NULL;

-- 4.25 País del fabricante
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_pais || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'País del fabricante'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.fabricante_pais IS NOT NULL;

-- 4.26 Razón social del fabricante
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_razon_social || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Razón social del fabricante'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.fabricante_razon_social IS NOT NULL;

-- 4.27 Nombre del distribuidor
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_nombre || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Nombre del distribuidor'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.distribuidor_nombre IS NOT NULL;

-- 4.28 NIT del distribuidor
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_nit || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'NIT del distribuidor'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.distribuidor_nit IS NOT NULL;

-- 4.29 Correo del distribuidor
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_correo || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Correo del distribuidor'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.distribuidor_correo IS NOT NULL;

-- 4.30 Dirección del distribuidor
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_direccion || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Dirección del distribuidor'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.distribuidor_direccion IS NOT NULL;

-- 4.31 País del distribuidor
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_pais || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'País del distribuidor'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.distribuidor_pais IS NOT NULL;

-- 4.32 Razón social del distribuidor
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_razon_social || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Razón social del distribuidor'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.distribuidor_razon_social IS NOT NULL;

-- 4.33 Nombre del envasador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_nombre || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Nombre del envasador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.envasador_nombre IS NOT NULL;

-- 4.34 NIT del envasador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_nit || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'NIT del envasador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.envasador_nit IS NOT NULL;

-- 4.35 Correo del envasador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_correo || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Correo del envasador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.envasador_correo IS NOT NULL;

-- 4.36 Dirección del envasador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_direccion || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Dirección del envasador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.envasador_direccion IS NOT NULL;

-- 4.37 País del envasador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_pais || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'País del envasador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.envasador_pais IS NOT NULL;

-- 4.38 Razón social del envasador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_razon_social || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Razón social del envasador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.envasador_razon_social IS NOT NULL;

-- 4.39 Nombre del importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_nombre || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Nombre del importador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.importador_nombre IS NOT NULL;

-- 4.40 NIT del importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_nit || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'NIT del importador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.importador_nit IS NOT NULL;

-- 4.41 Correo del importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_correo || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Correo del importador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.importador_correo IS NOT NULL;

-- 4.42 Dirección del importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_direccion || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Dirección del importador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.importador_direccion IS NOT NULL;

-- 4.43 País del importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_pais || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'País del importador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.importador_pais IS NOT NULL;

-- 4.44 Razón social del importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_razon_social || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Razón social del importador'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND t.importador_razon_social IS NOT NULL;

-- =============================================================================
-- PASO 5: Campos de Relación (IDs)
-- =============================================================================

-- 5.1 id_sub_grupo_alimenticio
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'id_sub_grupo_alimenticio'
LEFT JOIN srs_sub_grupo_alimenticio dest ON dest.legacy_id = 'SGR-' || t.original_sub_id
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- 5.2 id_pais_fabricacion (con fallback: iso_number → iso_2_code → iso_3_code)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'id_pais_fabricacion'
LEFT JOIN paises dest ON
    dest.iso_number = t.original_pais_iso_number  -- Cruce principal por iso_number
    OR dest.iso_2_code = t.original_pais_iso_2    -- Fallback por iso_2_code
    OR dest.iso_3_code = t.original_pais_iso_3    -- Fallback por iso_3_code
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- 5.3 id_clv
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'id_clv'
LEFT JOIN srs_certificado_libre_venta dest ON dest.legacy_id = 'CLV-' || t.original_clv_id
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- =============================================================================
-- PASO 6: Campos MULTISELECT (vacíos - relaciones van en otra tabla)
-- =============================================================================

-- 6.1 Marcas (vacío)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '""', NOW(), NOW()
FROM expedient_base_registries r
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Marcas'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- 6.2 Bodegas (vacío)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '""', NOW(), NOW()
FROM expedient_base_registries r
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = r.expedient_base_entity_id AND f.name = 'Bodegas'
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- =============================================================================
-- PASO 7: Verificación Final
-- =============================================================================

-- 7.1 Resumen de migración
SELECT 'Registros migrados' as metrica, COUNT(DISTINCT r.id) as total
FROM expedient_base_registries r
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
UNION ALL
SELECT 'Valores de campos' as metrica, COUNT(*) as total
FROM expedient_base_registry_fields rf
JOIN expedient_base_registries r ON r.id = rf.expedient_base_registry_id
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- 7.2 Detalle por campo
SELECT f.name as campo, f."order" as orden, COUNT(rf.id) as registros_con_valor
FROM expedient_base_entity_fields f
LEFT JOIN expedient_base_registry_fields rf ON rf.expedient_base_entity_field_id = f.id
WHERE f.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
GROUP BY f.name, f."order"
ORDER BY f."order";

-- 7.3 Muestra de datos migrados
SELECT r.unique_code, r.name as producto, r.legacy_id, (r.metadata->>'original_id') as id_original
FROM expedient_base_registries r
WHERE r.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
LIMIT 5;

-- 7.4 Comparación origen vs destino
SELECT
    'Origen (temp table)' as fuente,
    COUNT(*) as registros
FROM migration_alim_producto_temp
UNION ALL
SELECT
    'Destino (registries)',
    COUNT(*)
FROM expedient_base_registries
WHERE expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;

-- =============================================================================
-- DECISIÓN FINAL
-- =============================================================================
COMMIT;  -- Guardar los cambios permanentemente
-- ROLLBACK;  -- Descomenta si quieres revertir
