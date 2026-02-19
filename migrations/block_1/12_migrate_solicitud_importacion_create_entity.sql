-- =============================================================================
-- ESCENARIO A: CREAR ENTIDAD + CAMPOS + MIGRAR DATOS
-- =============================================================================
-- Entidad: Importación de productos especiales
-- Este script:
--   1. Crea la entidad expedient_base_entity
--   2. Crea todos los campos (entity_fields) según mapeo
--   3. Migra los registros desde tabla temporal
--   4. Migra los valores de cada campo
--
-- PRERREQUISITOS:
--   - Tabla migration_solicitud_importacion_temp debe existir con datos
--   - Catálogos de Centro de Datos disponibles (paises, departamentos, municipios)
--
-- Ejecutar en: Base de datos CORE
-- =============================================================================

-- =============================================================================
-- PASO 0: VALIDACIONES PREVIAS
-- =============================================================================

-- Verificar tabla temporal con datos
SELECT
    CASE WHEN COUNT(*) > 0 THEN '✅ Datos disponibles: ' || COUNT(*) || ' registros'
         ELSE '❌ ERROR: No hay datos en migration_solicitud_importacion_temp'
    END AS validacion
FROM migration_solicitud_importacion_temp;

-- Verificar que no existe una entidad con el mismo nombre
SELECT
    CASE WHEN COUNT(*) = 0 THEN '✅ Nombre de entidad disponible'
         ELSE '⚠️  ADVERTENCIA: Ya existe entidad con nombre similar'
    END AS validacion,
    id, name
FROM expedient_base_entities
WHERE name ILIKE '%Importación de productos especiales%'
   OR name ILIKE '%Importacion de productos especiales%'
GROUP BY id, name;

-- =============================================================================
-- ⚠️  REVISAR VALIDACIONES ANTES DE CONTINUAR
-- =============================================================================

BEGIN;

-- =============================================================================
-- PASO 1: Crear función para generar unique_code (si no existe)
-- =============================================================================
CREATE OR REPLACE FUNCTION generate_unique_code()
RETURNS VARCHAR(12) AS $$
BEGIN
    RETURN UPPER(encode(gen_random_bytes(6), 'hex'));
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- PASO 2: Crear la Entidad
-- =============================================================================
INSERT INTO expedient_base_entities (
    id,
    name,
    description,
    status,
    version,
    metadata,
    created_at,
    updated_at
)
VALUES (
    gen_random_uuid(),
    'Importación de productos especiales',
    'Expediente SDT para solicitudes de importación de productos especiales del sistema SISAM-CIEX',
    'active',
    1,
    jsonb_build_object(
        'source_system', 'SISAM',
        'source_tables', ARRAY['alim_solicitud_importacion_bcr', 'alim_solicitud_importacion_minsal'],
        'migration_date', NOW()::text,
        'created_by', 'migration_script'
    ),
    NOW(),
    NOW()
)
ON CONFLICT DO NOTHING
RETURNING id, name;

-- Guardar el UUID para uso posterior
DO $$
DECLARE
    v_entity_id UUID;
BEGIN
    SELECT id INTO v_entity_id
    FROM expedient_base_entities
    WHERE name = 'Importación de productos especiales';

    IF v_entity_id IS NULL THEN
        RAISE EXCEPTION 'No se pudo crear o encontrar la entidad';
    END IF;

    RAISE NOTICE 'Entity UUID: %', v_entity_id;
END $$;

-- =============================================================================
-- PASO 3: Crear los Campos de la Entidad (entity_fields)
-- =============================================================================
-- Campos según mapeo de la imagen proporcionada

INSERT INTO expedient_base_entity_fields (
    id,
    expedient_base_entity_id,
    name,
    field_type,
    is_required,
    "order",
    metadata,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid(),
    e.id,
    f.name,
    f.field_type,
    f.is_required,
    f.field_order,
    f.metadata,
    NOW(),
    NOW()
FROM expedient_base_entities e
CROSS JOIN (
    VALUES
        -- Campos de BCR
        ('nombre_importador', 'TEXT', true, 1, '{"source_table": "alim_solicitud_importacion_bcr", "source_column": "nombre_importador"}'::jsonb),
        ('nit_importador', 'TEXT', false, 2, '{"source_table": "alim_solicitud_importacion_bcr", "source_column": "nit_importador"}'::jsonb),
        ('fecha_registro_bcr', 'DATE', true, 3, '{"source_table": "alim_solicitud_importacion_bcr", "source_column": "fecha_registro_bcr", "format": "DD/MM/YYYY"}'::jsonb),
        ('numero_de_solicitud', 'TEXT', true, 4, '{"source_table": "alim_solicitud_importacion_bcr", "source_column": "numero_solicitud", "transformation": "rename"}'::jsonb),

        -- Campos de MINSAL
        ('estado_de_solicitud', 'SELECT', true, 5, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "estado_solicitud", "enum_values": ["Iniciada", "Aprobada", "Rechazada", "Cancelada", "En proceso"]}'::jsonb),
        ('direccion_importador', 'TEXT', false, 6, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "direccion_importador"}'::jsonb),
        ('departamento', 'TEXT', false, 7, '{"source_table": "ctl_departamento", "source_column": "nombre", "note": "Desnormalizado"}'::jsonb),
        ('municipio', 'TEXT', false, 8, '{"source_table": "ctl_municipio", "source_column": "nombre", "note": "Desnormalizado"}'::jsonb),
        ('nombre_del_tramitador', 'TEXT', false, 9, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "nombre_tramitador", "transformation": "rename"}'::jsonb),
        ('tipo_documento_usuario', 'TEXT', false, 10, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "tipo_documento_tramitador", "note": "Nombre desnormalizado del tipo de documento"}'::jsonb),
        ('numero_documento_del_tramitador', 'TEXT', false, 11, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "numero_documento_tramitador", "transformation": "rename"}'::jsonb),
        ('pais', 'TEXT', false, 12, '{"source_table": "ctl_pais", "source_column": "nombre", "note": "Desnormalizado"}'::jsonb),
        ('numero_solicitud_minsal', 'TEXT', false, 13, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "numero_solicitud_minsal"}'::jsonb),

        -- Campos adicionales
        ('fecha_registro_minsal', 'DATE', false, 14, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "fecha_registro_minsal"}'::jsonb),
        ('fecha_resolucion_minsal', 'DATE', false, 15, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "fecha_resolucion_minsal"}'::jsonb),
        ('justificacion_resolucion', 'TEXTAREA', false, 16, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "justificacion_resolucion"}'::jsonb),
        ('estado_externo', 'SELECT', false, 17, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "estado_externo", "enum_values": ["Liquidado Aprobado", "Liquidado Denegado", "Espera de Respuesta", "Sin Estado"]}'::jsonb),
        ('fecha_estado_externo', 'DATE', false, 18, '{"source_table": "alim_solicitud_importacion_minsal", "source_column": "fecha_estado_externo"}'::jsonb),

        -- Campos de relación con Centro de Datos
        ('id_pais', 'RELATION', false, 19, '{"relation_table": "paises", "note": "UUID del país en Centro de Datos"}'::jsonb),
        ('id_departamento', 'RELATION', false, 20, '{"relation_table": "departamentos", "note": "UUID del departamento en Centro de Datos"}'::jsonb),
        ('id_municipio', 'RELATION', false, 21, '{"relation_table": "municipios", "note": "UUID del municipio en Centro de Datos"}'::jsonb),
        ('id_tipo_documento_usuario', 'RELATION', false, 22, '{"relation_table": "tipo_documento_usuario", "note": "UUID del tipo de documento en Centro de Datos", "cruce_por": "nombre"}'::jsonb)
) AS f(name, field_type, is_required, field_order, metadata)
WHERE e.name = 'Importación de productos especiales'
ON CONFLICT DO NOTHING;

-- Verificar campos creados
SELECT
    'Campos creados' as descripcion,
    COUNT(*) as total
FROM expedient_base_entity_fields f
JOIN expedient_base_entities e ON e.id = f.expedient_base_entity_id
WHERE e.name = 'Importación de productos especiales';

-- =============================================================================
-- PASO 4: Asegurar columna legacy_id en registries
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
-- PASO 5: Migrar Registros (expedient_base_registries)
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
    COALESCE(NULLIF(TRIM(t.nombre_importador), ''), 'Solicitud ' || t.numero_solicitud)  as name,
    jsonb_build_object(
        'original_id', t.original_id,
        'original_bcr_id', t.original_bcr_id,
        'source', 'alim_solicitud_importacion_minsal',
        'migration_type', 'create_entity',
        'migration_date', NOW()::text
    ),
    e.id,
    generate_unique_code(),
    'SIMP-' || t.original_id,
    NOW(),
    NOW()
FROM migration_solicitud_importacion_temp t
CROSS JOIN expedient_base_entities e
WHERE e.name = 'Importación de productos especiales'
ON CONFLICT (legacy_id) DO NOTHING;

-- Verificar registros migrados
SELECT
    'Registros creados' as descripcion,
    COUNT(*) as total
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'Importación de productos especiales';

-- =============================================================================
-- PASO 6: Migrar Valores de Campos
-- =============================================================================
-- Usar variable para el entity_id

-- 6.1 nombre_importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nombre_importador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'nombre_importador'
WHERE t.nombre_importador IS NOT NULL AND t.nombre_importador != '';

-- 6.2 nit_importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nit_importador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'nit_importador'
WHERE t.nit_importador IS NOT NULL AND t.nit_importador != '';

-- 6.3 fecha_registro_bcr
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_registro_bcr || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'fecha_registro_bcr'
WHERE t.fecha_registro_bcr IS NOT NULL AND t.fecha_registro_bcr != '';

-- 6.4 numero_de_solicitud
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.numero_solicitud || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'numero_de_solicitud'
WHERE t.numero_solicitud IS NOT NULL AND t.numero_solicitud != '';

-- 6.5 estado_de_solicitud (ENUM transformado)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.estado_de_solicitud || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'estado_de_solicitud'
WHERE t.estado_de_solicitud IS NOT NULL;

-- 6.6 direccion_importador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.direccion_importador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'direccion_importador'
WHERE t.direccion_importador IS NOT NULL AND t.direccion_importador != '';

-- 6.7 departamento (nombre desnormalizado)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.departamento || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'departamento'
WHERE t.departamento IS NOT NULL AND t.departamento != '';

-- 6.8 municipio (nombre desnormalizado)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.municipio || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'municipio'
WHERE t.municipio IS NOT NULL AND t.municipio != '';

-- 6.9 nombre_del_tramitador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nombre_del_tramitador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'nombre_del_tramitador'
WHERE t.nombre_del_tramitador IS NOT NULL AND t.nombre_del_tramitador != '';

-- 6.10 tipo_documento_usuario (texto plano, sin catálogo)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.tipo_documento_usuario || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'tipo_documento_usuario'
WHERE t.tipo_documento_usuario IS NOT NULL AND t.tipo_documento_usuario != '';

-- 6.11 numero_documento_del_tramitador
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.numero_documento_del_tramitador || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'numero_documento_del_tramitador'
WHERE t.numero_documento_del_tramitador IS NOT NULL AND t.numero_documento_del_tramitador != '';

-- 6.12 pais (nombre desnormalizado)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.pais || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'pais'
WHERE t.pais IS NOT NULL AND t.pais != '';

-- 6.13 numero_solicitud_minsal
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.numero_solicitud_minsal || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'numero_solicitud_minsal'
WHERE t.numero_solicitud_minsal IS NOT NULL AND t.numero_solicitud_minsal != '';

-- 6.14 fecha_registro_minsal
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_registro_minsal || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'fecha_registro_minsal'
WHERE t.fecha_registro_minsal IS NOT NULL AND t.fecha_registro_minsal != '';

-- 6.15 fecha_resolucion_minsal
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_resolucion_minsal || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'fecha_resolucion_minsal'
WHERE t.fecha_resolucion_minsal IS NOT NULL AND t.fecha_resolucion_minsal != '';

-- 6.16 justificacion_resolucion
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.justificacion_resolucion || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'justificacion_resolucion'
WHERE t.justificacion_resolucion IS NOT NULL AND t.justificacion_resolucion != '';

-- 6.17 estado_externo
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.estado_externo || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'estado_externo'
WHERE t.estado_externo IS NOT NULL AND t.estado_externo != '';

-- 6.18 fecha_estado_externo
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_estado_externo || '"', NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'fecha_estado_externo'
WHERE t.fecha_estado_externo IS NOT NULL AND t.fecha_estado_externo != '';

-- =============================================================================
-- PASO 7: Migrar Campos de Relación (IDs de Centro de Datos)
-- =============================================================================

-- 7.1 id_pais (con fallback: iso_number → iso_2_code → iso_3_code)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'id_pais'
LEFT JOIN paises dest ON
    dest.iso_number = t.original_pais_iso_number
    OR dest.iso_2_code = t.original_pais_iso_2
    OR dest.iso_3_code = t.original_pais_iso_3
WHERE t.original_pais_id IS NOT NULL;

-- 7.2 id_departamento
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'id_departamento'
LEFT JOIN departamentos dest ON dest.legacy_id = 'DEP-' || t.original_departamento_id
WHERE t.original_departamento_id IS NOT NULL;

-- 7.3 id_municipio
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'id_municipio'
LEFT JOIN municipios dest ON dest.legacy_id = 'MUN-' || t.original_municipio_id
WHERE t.original_municipio_id IS NOT NULL;

-- 7.4 id_tipo_documento_usuario (cruce por nombre normalizado)
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
FROM migration_solicitud_importacion_temp t
JOIN expedient_base_registries r ON r.legacy_id = 'SIMP-' || t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id AND e.name = 'Importación de productos especiales'
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'id_tipo_documento_usuario'
LEFT JOIN tipo_documento_usuario dest ON UPPER(dest.nombre) = UPPER(t.tipo_documento_usuario)
WHERE t.tipo_documento_usuario IS NOT NULL AND t.tipo_documento_usuario != '';

-- =============================================================================
-- PASO 8: Verificación Final
-- =============================================================================

-- 8.1 Resumen de migración
SELECT 'Entidad creada' as metrica, COUNT(*) as total
FROM expedient_base_entities
WHERE name = 'Importación de productos especiales'
UNION ALL
SELECT 'Campos creados', COUNT(*)
FROM expedient_base_entity_fields f
JOIN expedient_base_entities e ON e.id = f.expedient_base_entity_id
WHERE e.name = 'Importación de productos especiales'
UNION ALL
SELECT 'Registros migrados', COUNT(DISTINCT r.id)
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'Importación de productos especiales'
UNION ALL
SELECT 'Valores de campos', COUNT(*)
FROM expedient_base_registry_fields rf
JOIN expedient_base_registries r ON r.id = rf.expedient_base_registry_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'Importación de productos especiales';

-- 8.2 Detalle por campo
SELECT
    f.name as campo,
    f."order" as orden,
    COUNT(rf.id) as registros_con_valor
FROM expedient_base_entity_fields f
JOIN expedient_base_entities e ON e.id = f.expedient_base_entity_id
LEFT JOIN expedient_base_registry_fields rf ON rf.expedient_base_entity_field_id = f.id
WHERE e.name = 'Importación de productos especiales'
GROUP BY f.name, f."order"
ORDER BY f."order";

-- 8.3 Muestra de datos migrados
SELECT
    r.unique_code,
    r.name as nombre_importador,
    r.legacy_id,
    (r.metadata->>'original_id') as id_original
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'Importación de productos especiales'
LIMIT 5;

-- 8.4 UUID de la entidad creada (guardar para referencia)
SELECT
    '⭐ UUID de la entidad creada' as nota,
    id as entity_uuid,
    name
FROM expedient_base_entities
WHERE name = 'Importación de productos especiales';

-- 8.5 Comparación origen vs destino
SELECT
    'Origen (temp table)' as fuente,
    COUNT(*) as registros
FROM migration_solicitud_importacion_temp
UNION ALL
SELECT
    'Destino (registries)',
    COUNT(*)
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'Importación de productos especiales';

-- =============================================================================
-- DECISIÓN FINAL
-- =============================================================================
COMMIT;  -- Guardar cambios permanentemente
-- ROLLBACK;  -- Descomenta para revertir

-- =============================================================================
-- POST-MIGRACIÓN: Guardar el UUID generado
-- =============================================================================
-- El UUID de la entidad creada aparece en el resultado 8.4
-- Guárdalo para usarlo en:
--   - 13_migrate_solicitud_importacion_by_uuid.sql (si necesitas re-ejecutar)
--   - Scripts de rollback
--   - Referencia en documentación
-- =============================================================================
