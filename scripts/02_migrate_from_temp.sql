-- =============================================================================
-- PASO 2B: MIGRAR DESDE TABLA TEMPORAL (ejecutar en SDT DEV)
-- =============================================================================
-- Requiere: 01_create_temp_table.sql ejecutado y datos importados

BEGIN;

-- =============================================================================
-- PASO 0: Función para generar unique_code
-- =============================================================================
CREATE OR REPLACE FUNCTION generate_unique_code()
RETURNS VARCHAR(12) AS $$
BEGIN
    RETURN UPPER(encode(gen_random_bytes(6), 'hex'));
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- PASO 1: Crear Entidad Base (si no existe)
-- =============================================================================
INSERT INTO expedient_base_entities (
    id,
    name,
    description,
    status,
    version,
    is_current_version,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid(),
    'T81 - Registro Sanitario Alimentos',
    'Productos alimenticios migrados del sistema SRS (Trámite 81)',
    'ACTIVE',
    1,
    true,
    NOW(),
    NOW()
WHERE NOT EXISTS (
    SELECT 1 FROM expedient_base_entities WHERE name = 'T81 - Registro Sanitario Alimentos'
);

-- Verificar entity creada
SELECT id, name FROM expedient_base_entities WHERE name = 'T81 - Registro Sanitario Alimentos';

-- =============================================================================
-- PASO 2: Crear Campos de la Entidad (14 campos TEXT/DATE)
-- =============================================================================
INSERT INTO expedient_base_entity_fields (
    id,
    expedient_base_entity_id,
    name,
    field_type,
    is_required,
    "order",
    configuration,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid(),
    e.id,
    field.name,
    field.field_type,
    field.is_required,
    field.ord,
    field.config::jsonb,
    NOW(),
    NOW()
FROM expedient_base_entities e
CROSS JOIN (VALUES
    ('Nombre del producto', 'TEXT', true, 1, '{"show_in_summary":true,"section":{"title":"Datos generales del producto","order":1},"key":"nombre_del_producto","placeholder":"Nombre del producto","maxLength":"1000","buttonEnabled":false,"type":"text"}'),
    ('Número de registro sanitario', 'TEXT', false, 2, '{"show_in_summary":true,"section":{"title":"Datos generales del producto","order":1},"key":"numero_registro_sanitario","placeholder":"Número de registro sanitario","maxLength":"50","buttonEnabled":false,"type":"text"}'),
    ('Tipo de producto', 'TEXT', true, 3, '{"show_in_summary":false,"section":{"title":"Datos generales del producto","order":1},"key":"tipo_de_producto","placeholder":"Tipo de producto","maxLength":"100","buttonEnabled":false,"type":"text"}'),
    ('Número de partida arancelaria', 'TEXT', false, 4, '{"show_in_summary":false,"section":{"title":"Datos generales del producto","order":1},"key":"numero_partida_arancelaria","placeholder":"Número de partida arancelaria","maxLength":"50","buttonEnabled":false,"type":"text"}'),
    ('Fecha de emisión del registro', 'DATE', false, 5, '{"show_in_summary":false,"section":{"title":"Datos generales del producto","order":1},"key":"fecha_emision_registro","placeholder":"Fecha de emisión del registro","buttonEnabled":false,"type":"date"}'),
    ('Fecha de vigencia del registro', 'DATE', false, 6, '{"show_in_summary":true,"section":{"title":"Datos generales del producto","order":1},"key":"fecha_vigencia_registro","placeholder":"Fecha de vigencia del registro","buttonEnabled":false,"type":"date"}'),
    ('Estado', 'TEXT', false, 7, '{"show_in_summary":true,"section":{"title":"Datos generales del producto","order":1},"key":"estado","placeholder":"Estado","maxLength":"50","buttonEnabled":false,"type":"text"}'),
    ('Subgrupo alimenticio', 'TEXT', false, 8, '{"show_in_summary":false,"section":{"title":"Datos generales del producto","order":1},"key":"subgrupo_alimenticio","placeholder":"Subgrupo alimenticio","maxLength":"500","buttonEnabled":false,"type":"text"}'),
    ('Clasificación alimenticia', 'TEXT', false, 9, '{"show_in_summary":false,"section":{"title":"Datos generales del producto","order":1},"key":"clasificacion_alimenticia","placeholder":"Clasificación alimenticia","maxLength":"500","buttonEnabled":false,"type":"text"}'),
    ('Riesgo', 'TEXT', false, 10, '{"show_in_summary":false,"section":{"title":"Datos generales del producto","order":1},"key":"riesgo","placeholder":"Riesgo","maxLength":"255","buttonEnabled":false,"type":"text"}'),
    ('País de fabricación', 'TEXT', true, 11, '{"show_in_summary":false,"section":{"title":"Datos generales del producto","order":1},"key":"pais_de_fabricacion","placeholder":"País de fabricación","maxLength":"255","buttonEnabled":false,"type":"text"}'),
    -- Certificado de Libre Venta
    ('Código de CLV', 'TEXT', false, 12, '{"show_in_summary":false,"section":{"title":"Certificado de Libre Venta","order":2},"key":"codigo_de_clv","placeholder":"Código de CLV","maxLength":"100","buttonEnabled":false,"type":"text"}'),
    ('Nombre del producto según CLV', 'TEXT', false, 13, '{"show_in_summary":false,"section":{"title":"Certificado de Libre Venta","order":2},"key":"nombre_producto_segun_clv","placeholder":"Nombre del producto según CLV","maxLength":"1000","buttonEnabled":false,"type":"text"}'),
    ('País de procedencia según CLV', 'TEXT', false, 14, '{"show_in_summary":false,"section":{"title":"Certificado de Libre Venta","order":2},"key":"pais_procedencia_clv","placeholder":"País de procedencia según CLV","maxLength":"255","buttonEnabled":false,"type":"text"}'),
    -- Propietario del Registro Sanitario
    ('Nombre del propietario', 'TEXT', false, 15, '{"show_in_summary":false,"section":{"title":"Datos de la empresa o persona propietaria del Registro Sanitario","order":3},"key":"nombre_propietario","placeholder":"Nombre del propietario","maxLength":"500","buttonEnabled":false,"type":"text"}'),
    ('NIT del propietario del registro sanitario', 'TEXT', false, 16, '{"show_in_summary":false,"section":{"title":"Datos de la empresa o persona propietaria del Registro Sanitario","order":3},"key":"nit_propietario","placeholder":"NIT del propietario del registro sanitario","maxLength":"50","buttonEnabled":false,"type":"text"}'),
    ('Correo electrónico del propietario del registro', 'EMAIL', false, 17, '{"show_in_summary":false,"section":{"title":"Datos de la empresa o persona propietaria del Registro Sanitario","order":3},"key":"correo_propietario","placeholder":"Correo electrónico del propietario del registro","maxLength":"255","buttonEnabled":false,"type":"email"}'),
    ('Dirección del propietario del registro sanitario', 'TEXTAREA', false, 18, '{"show_in_summary":false,"section":{"title":"Datos de la empresa o persona propietaria del Registro Sanitario","order":3},"key":"direccion_propietario","placeholder":"Dirección del propietario del registro sanitario","maxLength":"500","buttonEnabled":false,"type":"textarea"}'),
    ('País de procedencia del propietario del registro', 'TEXT', false, 19, '{"show_in_summary":false,"section":{"title":"Datos de la empresa o persona propietaria del Registro Sanitario","order":3},"key":"pais_propietario","placeholder":"País de procedencia del propietario del registro","maxLength":"255","buttonEnabled":false,"type":"text"}'),
    ('Razón social del propietario', 'TEXT', false, 20, '{"show_in_summary":false,"section":{"title":"Datos de la empresa o persona propietaria del Registro Sanitario","order":3},"key":"razon_social_propietario","placeholder":"Razón social del propietario","maxLength":"255","buttonEnabled":false,"type":"text"}')
) AS field(name, field_type, is_required, ord, config)
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
  AND NOT EXISTS (
      SELECT 1 FROM expedient_base_entity_fields ef
      WHERE ef.expedient_base_entity_id = e.id
  );

-- Verificar campos creados
SELECT ef.name, ef.field_type, ef."order"
FROM expedient_base_entity_fields ef
JOIN expedient_base_entities e ON e.id = ef.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
ORDER BY ef."order";

-- =============================================================================
-- PASO 3: Migrar Registros desde tabla temporal
-- =============================================================================
INSERT INTO expedient_base_registries (
    id,
    name,
    metadata,
    expedient_base_entity_id,
    unique_code,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid(),
    t.nombre,
    jsonb_build_object(
        'original_id', t.original_id,
        'source', 'alim_producto',
        'migration_date', NOW()::text
    ),
    e.id,
    generate_unique_code(),
    NOW(),
    NOW()
FROM migration_alim_producto_temp t
CROSS JOIN expedient_base_entities e
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- Verificar registros migrados
SELECT COUNT(*) as total_migrados
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- =============================================================================
-- PASO 4: Migrar Valores de Campos
-- =============================================================================

-- 4.1 Nombre del producto
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nombre || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Nombre del producto'
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- 4.2 Número de registro sanitario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.num_registro_sanitario || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Número de registro sanitario'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.num_registro_sanitario IS NOT NULL;

-- 4.3 Tipo de producto
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.tipo_producto || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Tipo de producto'
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- 4.4 Número de partida arancelaria
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.num_partida_arancelaria || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Número de partida arancelaria'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.num_partida_arancelaria IS NOT NULL;

-- 4.5 Fecha de emisión del registro
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_emision_registro || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Fecha de emisión del registro'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.fecha_emision_registro IS NOT NULL;

-- 4.6 Fecha de vigencia del registro
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.fecha_vigencia_registro || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Fecha de vigencia del registro'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.fecha_vigencia_registro IS NOT NULL;

-- 4.7 Estado
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.estado_producto || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Estado'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.estado_producto IS NOT NULL;

-- 4.8 Subgrupo alimenticio
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.subgrupo_alimenticio || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Subgrupo alimenticio'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.subgrupo_alimenticio IS NOT NULL;

-- 4.9 Clasificación alimenticia
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.clasificacion_alimenticia || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Clasificación alimenticia'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.clasificacion_alimenticia IS NOT NULL;

-- 4.10 Riesgo
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.riesgo || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Riesgo'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.riesgo IS NOT NULL;

-- 4.11 País de fabricación
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.pais || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'País de fabricación'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.pais IS NOT NULL;

-- 4.12 Código de CLV
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.codigo_clv || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Código de CLV'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.codigo_clv IS NOT NULL;

-- 4.13 Nombre del producto según CLV
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.nombre_producto_clv || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Nombre del producto según CLV'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.nombre_producto_clv IS NOT NULL;

-- 4.14 País de procedencia según CLV
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.pais_procedencia_clv || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'País de procedencia según CLV'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.pais_procedencia_clv IS NOT NULL;

-- 4.15 Nombre del propietario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_nombre || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Nombre del propietario'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.propietario_nombre IS NOT NULL;

-- 4.16 NIT del propietario del registro sanitario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_nit || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'NIT del propietario del registro sanitario'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.propietario_nit IS NOT NULL;

-- 4.17 Correo electrónico del propietario del registro
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_correo || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Correo electrónico del propietario del registro'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.propietario_correo IS NOT NULL;

-- 4.18 Dirección del propietario del registro sanitario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_direccion || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Dirección del propietario del registro sanitario'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.propietario_direccion IS NOT NULL;

-- 4.19 País de procedencia del propietario del registro
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_pais || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'País de procedencia del propietario del registro'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.propietario_pais IS NOT NULL;

-- 4.20 Razón social del propietario
INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
SELECT gen_random_uuid(), r.id, f.id, '"' || t.propietario_razon_social || '"', NOW(), NOW()
FROM migration_alim_producto_temp t
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Razón social del propietario'
WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.propietario_razon_social IS NOT NULL;

-- =============================================================================
-- PASO 5: Verificación
-- =============================================================================

-- Resumen
SELECT 'Registros migrados' as metrica, COUNT(DISTINCT r.id) as total
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
UNION ALL
SELECT 'Valores de campos' as metrica, COUNT(*) as total
FROM expedient_base_registry_fields rf
JOIN expedient_base_registries r ON r.id = rf.expedient_base_registry_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- Detalle por campo
SELECT f.name as campo, COUNT(rf.id) as registros_con_valor
FROM expedient_base_entity_fields f
JOIN expedient_base_entities e ON e.id = f.expedient_base_entity_id
LEFT JOIN expedient_base_registry_fields rf ON rf.expedient_base_entity_field_id = f.id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
GROUP BY f.name, f."order"
ORDER BY f."order";

-- Muestra de datos
SELECT r.unique_code, r.name as producto, (r.metadata->>'original_id') as id_original
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
LIMIT 5;

-- =============================================================================
-- DECISIÓN FINAL
-- =============================================================================
COMMIT;  -- Guardar los cambios permanentemente
-- ROLLBACK;  -- Descomenta esto si quieres revertir
