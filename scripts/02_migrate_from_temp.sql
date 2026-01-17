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
-- PASO 2: Crear Campos de la Entidad (10 campos TEXT/DATE)
-- =============================================================================
INSERT INTO expedient_base_entity_fields (
    id,
    expedient_base_entity_id,
    name,
    field_type,
    is_required,
    "order",
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
    NOW(),
    NOW()
FROM expedient_base_entities e
CROSS JOIN (VALUES
    ('Nombre del producto', 'TEXT', true, 1),
    ('Número de registro sanitario', 'TEXT', false, 2),
    ('Tipo de producto', 'TEXT', true, 3),
    ('Número de partida arancelaria', 'TEXT', false, 4),
    ('Fecha de emisión del registro', 'DATE', false, 5),
    ('Fecha de vigencia del registro', 'DATE', false, 6),
    ('Estado', 'TEXT', false, 7),
    ('Subgrupo alimenticio', 'TEXT', false, 8),
    ('Clasificación alimenticia', 'TEXT', false, 9),
    ('Riesgo', 'TEXT', false, 10),
    ('País de fabricación', 'TEXT', true, 11)
) AS field(name, field_type, is_required, ord)
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
