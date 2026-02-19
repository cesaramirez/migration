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
	-- PASO 0.1: Agregar columna legacy_id si no existe
	-- =============================================================================
	ALTER TABLE expedient_base_registries
	ADD COLUMN IF NOT EXISTS legacy_id VARCHAR(30);

	-- Agregar constraint UNIQUE para ON CONFLICT (si no existe)
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
	    ('Razón social del propietario', 'TEXT', false, 20, '{"show_in_summary":false,"section":{"title":"Datos de la empresa o persona propietaria del Registro Sanitario","order":3},"key":"razon_social_propietario","placeholder":"Razón social del propietario","maxLength":"255","buttonEnabled":false,"type":"text"}'),
	    -- Fabricante
	    ('Nombre del fabricante', 'TEXT', false, 21, '{"show_in_summary":false,"section":{"title":"Datos del Fabricante","order":4},"key":"nombre_fabricante","placeholder":"Nombre del fabricante","maxLength":"500","buttonEnabled":false,"type":"text"}'),
	    ('NIT del fabricante', 'TEXT', false, 22, '{"show_in_summary":false,"section":{"title":"Datos del Fabricante","order":4},"key":"nit_fabricante","placeholder":"NIT del fabricante","maxLength":"50","buttonEnabled":false,"type":"text"}'),
	    ('Correo del fabricante', 'EMAIL', false, 23, '{"show_in_summary":false,"section":{"title":"Datos del Fabricante","order":4},"key":"correo_fabricante","placeholder":"Correo del fabricante","maxLength":"255","buttonEnabled":false,"type":"email"}'),
	    ('Dirección del fabricante', 'TEXTAREA', false, 24, '{"show_in_summary":false,"section":{"title":"Datos del Fabricante","order":4},"key":"direccion_fabricante","placeholder":"Dirección del fabricante","maxLength":"500","buttonEnabled":false,"type":"textarea"}'),
	    ('País del fabricante', 'TEXT', false, 25, '{"show_in_summary":false,"section":{"title":"Datos del Fabricante","order":4},"key":"pais_fabricante","placeholder":"País del fabricante","maxLength":"255","buttonEnabled":false,"type":"text"}'),
	    ('Razón social del fabricante', 'TEXT', false, 26, '{"show_in_summary":false,"section":{"title":"Datos del Fabricante","order":4},"key":"razon_social_fabricante","placeholder":"Razón social del fabricante","maxLength":"255","buttonEnabled":false,"type":"text"}'),
	    -- Distribuidor
	    ('Nombre del distribuidor', 'TEXT', false, 27, '{"show_in_summary":false,"section":{"title":"Datos del Distribuidor","order":5},"key":"nombre_distribuidor","placeholder":"Nombre del distribuidor","maxLength":"500","buttonEnabled":false,"type":"text"}'),
	    ('NIT del distribuidor', 'TEXT', false, 28, '{"show_in_summary":false,"section":{"title":"Datos del Distribuidor","order":5},"key":"nit_distribuidor","placeholder":"NIT del distribuidor","maxLength":"50","buttonEnabled":false,"type":"text"}'),
	    ('Correo del distribuidor', 'EMAIL', false, 29, '{"show_in_summary":false,"section":{"title":"Datos del Distribuidor","order":5},"key":"correo_distribuidor","placeholder":"Correo del distribuidor","maxLength":"255","buttonEnabled":false,"type":"email"}'),
	    ('Dirección del distribuidor', 'TEXTAREA', false, 30, '{"show_in_summary":false,"section":{"title":"Datos del Distribuidor","order":5},"key":"direccion_distribuidor","placeholder":"Dirección del distribuidor","maxLength":"500","buttonEnabled":false,"type":"textarea"}'),
	    ('País del distribuidor', 'TEXT', false, 31, '{"show_in_summary":false,"section":{"title":"Datos del Distribuidor","order":5},"key":"pais_distribuidor","placeholder":"País del distribuidor","maxLength":"255","buttonEnabled":false,"type":"text"}'),
	    ('Razón social del distribuidor', 'TEXT', false, 32, '{"show_in_summary":false,"section":{"title":"Datos del Distribuidor","order":5},"key":"razon_social_distribuidor","placeholder":"Razón social del distribuidor","maxLength":"255","buttonEnabled":false,"type":"text"}'),
	    -- Envasador
	    ('Nombre del envasador', 'TEXT', false, 33, '{"show_in_summary":false,"section":{"title":"Datos del Envasador","order":6},"key":"nombre_envasador","placeholder":"Nombre del envasador","maxLength":"500","buttonEnabled":false,"type":"text"}'),
	    ('NIT del envasador', 'TEXT', false, 34, '{"show_in_summary":false,"section":{"title":"Datos del Envasador","order":6},"key":"nit_envasador","placeholder":"NIT del envasador","maxLength":"50","buttonEnabled":false,"type":"text"}'),
	    ('Correo del envasador', 'EMAIL', false, 35, '{"show_in_summary":false,"section":{"title":"Datos del Envasador","order":6},"key":"correo_envasador","placeholder":"Correo del envasador","maxLength":"255","buttonEnabled":false,"type":"email"}'),
	    ('Dirección del envasador', 'TEXTAREA', false, 36, '{"show_in_summary":false,"section":{"title":"Datos del Envasador","order":6},"key":"direccion_envasador","placeholder":"Dirección del envasador","maxLength":"500","buttonEnabled":false,"type":"textarea"}'),
	    ('País del envasador', 'TEXT', false, 37, '{"show_in_summary":false,"section":{"title":"Datos del Envasador","order":6},"key":"pais_envasador","placeholder":"País del envasador","maxLength":"255","buttonEnabled":false,"type":"text"}'),
	    ('Razón social del envasador', 'TEXT', false, 38, '{"show_in_summary":false,"section":{"title":"Datos del Envasador","order":6},"key":"razon_social_envasador","placeholder":"Razón social del envasador","maxLength":"255","buttonEnabled":false,"type":"text"}'),
	    -- Importador
	    ('Nombre del importador', 'TEXT', false, 39, '{"show_in_summary":false,"section":{"title":"Datos del Importador","order":7},"key":"nombre_importador","placeholder":"Nombre del importador","maxLength":"500","buttonEnabled":false,"type":"text"}'),
	    ('NIT del importador', 'TEXT', false, 40, '{"show_in_summary":false,"section":{"title":"Datos del Importador","order":7},"key":"nit_importador","placeholder":"NIT del importador","maxLength":"50","buttonEnabled":false,"type":"text"}'),
	    ('Correo del importador', 'EMAIL', false, 41, '{"show_in_summary":false,"section":{"title":"Datos del Importador","order":7},"key":"correo_importador","placeholder":"Correo del importador","maxLength":"255","buttonEnabled":false,"type":"email"}'),
	    ('Dirección del importador', 'TEXTAREA', false, 42, '{"show_in_summary":false,"section":{"title":"Datos del Importador","order":7},"key":"direccion_importador","placeholder":"Dirección del importador","maxLength":"500","buttonEnabled":false,"type":"textarea"}'),
	    ('País del importador', 'TEXT', false, 43, '{"show_in_summary":false,"section":{"title":"Datos del Importador","order":7},"key":"pais_importador","placeholder":"País del importador","maxLength":"255","buttonEnabled":false,"type":"text"}'),
	    ('Razón social del importador', 'TEXT', false, 44, '{"show_in_summary":false,"section":{"title":"Datos del Importador","order":7},"key":"razon_social_importador","placeholder":"Razón social del importador","maxLength":"255","buttonEnabled":false,"type":"text"}'),
	    -- Relaciones
	    ('id_sub_grupo_alimenticio', 'TEXT', false, 45, '{"show_in_summary":false,"section":{"title":"Relaciones","order":8},"key":"id_sub_grupo_alimenticio","placeholder":"ID Subgrupo Alimenticio","maxLength":"50","buttonEnabled":false,"type":"text"}'),
	    ('id_pais_fabricacion', 'TEXT', false, 46, '{"show_in_summary":false,"section":{"title":"Relaciones","order":8},"key":"id_pais_fabricacion","placeholder":"ID País Fabricación","maxLength":"50","buttonEnabled":false,"type":"text"}'),
	    ('id_clv', 'TEXT', false, 47, '{"show_in_summary":false,"section":{"title":"Relaciones","order":8},"key":"id_clv","placeholder":"ID CLV","maxLength":"50","buttonEnabled":false,"type":"text"}'),
	    ('Marcas', 'MULTISELECT', false, 48, '{"key":"marcas","type":"select","section":{"order":8,"title":"Marcas"},"placeholder":"Selecciona las marcas","buttonEnabled":false,"options_root_table":"srs_marca","options_root_column":"nombre","options_root_source":"database","multipleSelection":true,"can_expand":false,"show_in_summary":true}'),
	    ('Bodegas', 'MULTISELECT', false, 49, '{"key":"bodegas","type":"select","section":{"order":9,"title":"Bodegas"},"placeholder":"Selecciona las bodegas","buttonEnabled":false,"options_root_table":"srs_bodega","options_root_column":"nombre","options_root_source":"database","multipleSelection":true,"can_expand":false,"show_in_summary":true}')
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
	        'migration_date', NOW()::text
	    ),
	    e.id,
	    generate_unique_code(),
	    'PRD-' || t.original_id,  -- legacy_id para JOINs rápidos
	    NOW(),
	    NOW()
	FROM migration_alim_producto_temp t
	CROSS JOIN expedient_base_entities e
	WHERE e.name = 'T81 - Registro Sanitario Alimentos'
	ON CONFLICT (legacy_id) DO NOTHING;

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

	-- 4.21 Nombre del fabricante
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_nombre || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Nombre del fabricante'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.fabricante_nombre IS NOT NULL;

	-- 4.22 NIT del fabricante
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_nit || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'NIT del fabricante'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.fabricante_nit IS NOT NULL;

	-- 4.23 Correo del fabricante
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_correo || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Correo del fabricante'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.fabricante_correo IS NOT NULL;

	-- 4.24 Dirección del fabricante
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_direccion || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Dirección del fabricante'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.fabricante_direccion IS NOT NULL;

	-- 4.25 País del fabricante
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_pais || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'País del fabricante'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.fabricante_pais IS NOT NULL;

	-- 4.26 Razón social del fabricante
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.fabricante_razon_social || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Razón social del fabricante'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.fabricante_razon_social IS NOT NULL;

	-- 4.27 Nombre del distribuidor
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_nombre || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Nombre del distribuidor'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.distribuidor_nombre IS NOT NULL;

	-- 4.28 NIT del distribuidor
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_nit || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'NIT del distribuidor'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.distribuidor_nit IS NOT NULL;

	-- 4.29 Correo del distribuidor
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_correo || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Correo del distribuidor'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.distribuidor_correo IS NOT NULL;

	-- 4.30 Dirección del distribuidor
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_direccion || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Dirección del distribuidor'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.distribuidor_direccion IS NOT NULL;

	-- 4.31 País del distribuidor
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_pais || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'País del distribuidor'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.distribuidor_pais IS NOT NULL;

	-- 4.32 Razón social del distribuidor
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.distribuidor_razon_social || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Razón social del distribuidor'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.distribuidor_razon_social IS NOT NULL;

	-- 4.33 Nombre del envasador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_nombre || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Nombre del envasador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.envasador_nombre IS NOT NULL;

	-- 4.34 NIT del envasador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_nit || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'NIT del envasador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.envasador_nit IS NOT NULL;

	-- 4.35 Correo del envasador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_correo || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Correo del envasador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.envasador_correo IS NOT NULL;

	-- 4.36 Dirección del envasador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_direccion || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Dirección del envasador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.envasador_direccion IS NOT NULL;

	-- 4.37 País del envasador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_pais || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'País del envasador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.envasador_pais IS NOT NULL;

	-- 4.38 Razón social del envasador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.envasador_razon_social || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Razón social del envasador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.envasador_razon_social IS NOT NULL;

	-- 4.39 Nombre del importador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_nombre || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Nombre del importador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.importador_nombre IS NOT NULL;

	-- 4.40 NIT del importador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_nit || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'NIT del importador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.importador_nit IS NOT NULL;

	-- 4.41 Correo del importador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_correo || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Correo del importador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.importador_correo IS NOT NULL;

	-- 4.42 Dirección del importador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_direccion || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Dirección del importador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.importador_direccion IS NOT NULL;

	-- 4.43 País del importador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_pais || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'País del importador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.importador_pais IS NOT NULL;

	-- 4.44 Razón social del importador
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '"' || t.importador_razon_social || '"', NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Razón social del importador'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos' AND t.importador_razon_social IS NOT NULL;

	-- 4.45 id_sub_grupo_alimenticio (inserta "" si no hay subgrupo)
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'id_sub_grupo_alimenticio'
	LEFT JOIN srs_sub_grupo_alimenticio dest ON dest.legacy_id = 'SGR-' || t.original_sub_id
	WHERE e.name = 'T81 - Registro Sanitario Alimentos';

	-- 4.46 id_pais_fabricacion (inserta "" si no hay país)
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'id_pais_fabricacion'
	LEFT JOIN paises dest ON dest.iso_number = t.original_pais_iso
	WHERE e.name = 'T81 - Registro Sanitario Alimentos';

	-- 4.47 id_clv (inserta "" si no hay CLV)
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, COALESCE('"' || dest.id || '"', '""'), NOW(), NOW()
	FROM migration_alim_producto_temp t
	JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = t.original_id
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'id_clv'
	LEFT JOIN srs_certificado_libre_venta dest ON dest.legacy_id = 'CLV-' || t.original_clv_id
	WHERE e.name = 'T81 - Registro Sanitario Alimentos';

	-- 4.48 Marcas (insertar vacío, las relaciones van en expedient_base_registry_relation)
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '""', NOW(), NOW()
	FROM expedient_base_registries r
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Marcas'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos';

	-- 4.49 Bodegas (insertar vacío, las relaciones van en expedient_base_registry_relation)
	INSERT INTO expedient_base_registry_fields (id, expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at)
	SELECT gen_random_uuid(), r.id, f.id, '""', NOW(), NOW()
	FROM expedient_base_registries r
	JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
	JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = e.id AND f.name = 'Bodegas'
	WHERE e.name = 'T81 - Registro Sanitario Alimentos';

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
