select count(*) from sisam.alim_producto;
-- =============================================================================
-- MIGRACIÓN: alim_producto → expedient_base (Prueba con 100 registros)
-- =============================================================================
-- INSTRUCCIONES:
-- 1. Ejecutar en la base de datos SDT (destino)
-- 2. Asegúrate de tener acceso a las tablas SRS via dblink o FDW
-- 3. Al final hay un ROLLBACK comentado, cambiarlo a COMMIT para persistir
-- =============================================================================

BEGIN;

-- =============================================================================
-- PASO 0: Crear función para generar unique_code (si no existe)
-- =============================================================================
CREATE OR REPLACE FUNCTION generate_unique_code()
RETURNS VARCHAR(12) AS $$
BEGIN
    RETURN UPPER(encode(gen_random_bytes(6), 'hex'));
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- PASO 1: Crear Entidad Base "T81 - Registro Sanitario Alimentos"
-- =============================================================================
INSERT INTO expedient_base_entities (
    id,
    name,
    description,
    status,
    version,
    is_current_version
)
VALUES (
    gen_random_uuid(),
    'T81 - Registro Sanitario Alimentos',
    'Productos alimenticios migrados del sistema SRS (Trámite 81)',
    'active',
    1,
    true
);

-- Guardar el ID de la entidad creada
DO $$
DECLARE
    v_entity_id UUID;
BEGIN
    SELECT id INTO v_entity_id
    FROM expedient_base_entities
    WHERE name = 'T81 - Registro Sanitario Alimentos'
    ORDER BY created_at DESC
    LIMIT 1;

    RAISE NOTICE 'Entity ID creado: %', v_entity_id;
END $$;

-- =============================================================================
-- PASO 2: Crear Campos de la Entidad (14 campos)
-- =============================================================================
INSERT INTO expedient_base_entity_fields (
    id,
    expedient_base_entity_id,
    name,
    field_type,
    is_required,
    "order"
)
SELECT
    gen_random_uuid(),
    e.id,
    field.name,
    field.field_type,
    field.is_required,
    field.ord
FROM expedient_base_entities e
CROSS JOIN (VALUES
    ('Nombre del Producto', 'TEXT', true, 1),
    ('Tipo de Producto', 'TEXT', true, 2),
    ('Partida Arancelaria', 'TEXT', false, 3),
    ('Fecha de Emisión del Registro', 'DATE', false, 4),
    ('Fecha de Vigencia del Registro', 'DATE', false, 5),
    ('Autorización de Reconocimiento', 'TEXT', false, 6),
    ('Registro Sanitario', 'TEXT', false, 7),
    ('Estado del Producto', 'TEXT', false, 8),
    ('País', 'TEXT', true, 9),
    ('Sub Grupo Alimenticio', 'TEXT', false, 10),
    ('Archivo Ingredientes', 'FILE', false, 11),
    ('Viñeta Reconocimiento', 'FILE', false, 12),
    ('Resolución Registro CA', 'FILE', false, 13),
    ('Declaración Jurada', 'FILE', false, 14)
) AS field(name, field_type, is_required, ord)
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- Verificar campos creados
SELECT ef.name, ef.field_type, ef.is_required, ef."order"
FROM expedient_base_entity_fields ef
JOIN expedient_base_entities e ON e.id = ef.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
ORDER BY ef."order";

-- =============================================================================
-- PASO 3: Migrar Registros (100 productos de prueba)
-- =============================================================================
-- NOTA: Ajustar el schema 'srs.' según tu configuración de acceso
-- Si usas dblink o FDW, ajustar la sintaxis

INSERT INTO expedient_base_registries (
    id,
    name,
    metadata,
    expedient_base_entity_id,
    unique_code
)
SELECT
    gen_random_uuid(),
    p.nombre,
    jsonb_build_object(
        'original_id', p.id,
        'source', 'alim_producto',
        'migration_date', NOW()::text
    ),
    e.id,
    generate_unique_code()
FROM srs.alim_producto p  -- Ajustar schema según tu config
CROSS JOIN expedient_base_entities e
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
  AND p.estado_registro = 1  -- Solo activos
ORDER BY p.id
LIMIT 100;  -- PRUEBA: Solo 100 registros

-- Verificar registros migrados
SELECT COUNT(*) as total_migrados
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- =============================================================================
-- PASO 4: Migrar Valores de Campos (campos TEXT)
-- =============================================================================

-- 4.1 Nombre del Producto
INSERT INTO expedient_base_registry_fields (
    id,
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    value
)
SELECT
    gen_random_uuid(),
    r.id,
    f.id,
    p.nombre
FROM srs.alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Nombre del Producto'
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- 4.2 Tipo de Producto (desnormalizar enum)
INSERT INTO expedient_base_registry_fields (
    id,
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    value
)
SELECT
    gen_random_uuid(),
    r.id,
    f.id,
    CASE p.tipo_producto
        WHEN 1 THEN 'Nacional'
        WHEN 2 THEN 'Importado Unión Aduanera'
        WHEN 3 THEN 'Importado Otros Países'
        ELSE 'Desconocido'
    END
FROM srs.alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Tipo de Producto'
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- 4.3 Partida Arancelaria
INSERT INTO expedient_base_registry_fields (
    id,
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    value
)
SELECT
    gen_random_uuid(),
    r.id,
    f.id,
    p.num_partida_arancelaria
FROM srs.alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Partida Arancelaria'
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
  AND p.num_partida_arancelaria IS NOT NULL;

-- 4.4 Fecha de Emisión del Registro
INSERT INTO expedient_base_registry_fields (
    id,
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    value
)
SELECT
    gen_random_uuid(),
    r.id,
    f.id,
    p.fecha_emision_registro::text
FROM srs.alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Fecha de Emisión del Registro'
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
  AND p.fecha_emision_registro IS NOT NULL;

-- 4.5 Fecha de Vigencia del Registro
INSERT INTO expedient_base_registry_fields (
    id,
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    value
)
SELECT
    gen_random_uuid(),
    r.id,
    f.id,
    p.fecha_vigencia_registro::text
FROM srs.alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Fecha de Vigencia del Registro'
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
  AND p.fecha_vigencia_registro IS NOT NULL;

-- 4.6 Autorización de Reconocimiento
INSERT INTO expedient_base_registry_fields (
    id,
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    value
)
SELECT
    gen_random_uuid(),
    r.id,
    f.id,
    p.num_autorizacion_reconocimiento
FROM srs.alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Autorización de Reconocimiento'
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
  AND p.num_autorizacion_reconocimiento IS NOT NULL;

-- 4.7 Registro Sanitario
INSERT INTO expedient_base_registry_fields (
    id,
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    value
)
SELECT
    gen_random_uuid(),
    r.id,
    f.id,
    p.num_registro_sanitario
FROM srs.alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Registro Sanitario'
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
  AND p.num_registro_sanitario IS NOT NULL;

-- 4.8 Estado del Producto (desnormalizar de ctl_estado_producto)
INSERT INTO expedient_base_registry_fields (
    id,
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    value
)
SELECT
    gen_random_uuid(),
    r.id,
    f.id,
    ep.nombre
FROM srs.alim_producto p
JOIN srs.ctl_estado_producto ep ON ep.id = p.id_ctl_estado_producto
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Estado del Producto'
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
  AND p.id_ctl_estado_producto IS NOT NULL;

-- 4.9 País (desnormalizar de ctl_pais)
INSERT INTO expedient_base_registry_fields (
    id,
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    value
)
SELECT
    gen_random_uuid(),
    r.id,
    f.id,
    pais.nombre
FROM srs.alim_producto p
JOIN srs.ctl_pais pais ON pais.id = p.id_ctl_pais
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'País'
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- 4.10 Sub Grupo Alimenticio (desnormalizar)
INSERT INTO expedient_base_registry_fields (
    id,
    expedient_base_registry_id,
    expedient_base_entity_field_id,
    value
)
SELECT
    gen_random_uuid(),
    r.id,
    f.id,
    sg.nombre
FROM srs.alim_producto p
JOIN srs.alim_sub_grupo_alimenticio sg ON sg.id = p.id_sub_grupo_alimenticio
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Sub Grupo Alimenticio'
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
  AND p.id_sub_grupo_alimenticio IS NOT NULL;

-- =============================================================================
-- PASO 5: Verificación
-- =============================================================================

-- Resumen de migración
SELECT
    'Registros migrados' as metrica,
    COUNT(DISTINCT r.id) as total
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'

UNION ALL

SELECT
    'Valores de campos migrados' as metrica,
    COUNT(*) as total
FROM expedient_base_registry_fields rf
JOIN expedient_base_registries r ON r.id = rf.expedient_base_registry_id
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- Detalle por campo
SELECT
    f.name as campo,
    COUNT(rf.id) as registros_con_valor
FROM expedient_base_entity_fields f
JOIN expedient_base_entities e ON e.id = f.expedient_base_entity_id
LEFT JOIN expedient_base_registry_fields rf ON rf.expedient_base_entity_field_id = f.id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
GROUP BY f.name, f."order"
ORDER BY f."order";

-- Muestra de datos migrados
SELECT
    r.unique_code,
    r.name as producto,
    (r.metadata->>'original_id') as id_original
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
LIMIT 5;

-- =============================================================================
-- DECISIÓN FINAL: ROLLBACK O COMMIT
-- =============================================================================
-- Si todo se ve bien, comentar ROLLBACK y descomentar COMMIT

ROLLBACK;  -- PRUEBA: Deshacer todo
-- COMMIT;  -- PRODUCCIÓN: Persistir cambios
