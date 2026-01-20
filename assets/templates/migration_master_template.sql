/**
 * PLANTILLA MAESTRA DE MIGRACIÓN DE ENTIDADES
 * ===========================================
 * Este script migra una entidad completa en 3 pasos:
 * 1. Registros (Padre)
 * 2. Campos (Valores)
 * 3. Relaciones (Conectores)
 *
 * USO:
 * - Reemplazar [TU_TABLA_ORIGEN] con la tabla fuente.
 * - Ajustar v_entity_id con el UUID de la entidad destino.
 * - Mapear columnas en las secciones de CASE.
 */

DO $$
DECLARE
    -- [CONFIGURACIÓN]
    -- UUID de la Entidad Destino (Requerido)
    v_entity_id UUID := 'PONER_AQUI_EL_UUID_DE_LA_ENTIDAD';

    -- Variables auxiliares para IDs de campos de relación (No tocar)
    v_field_marcas_id UUID;
    v_field_bodegas_id UUID;

BEGIN
    -- [PREPARACIÓN] Obtener IDs de campos de relación automáticamente
    SELECT id INTO v_field_marcas_id FROM expedient_base_entity_fields WHERE expedient_base_entity_id = v_entity_id AND name = 'Marcas';
    SELECT id INTO v_field_bodegas_id FROM expedient_base_entity_fields WHERE expedient_base_entity_id = v_entity_id AND name = 'Bodegas';

    RAISE NOTICE 'Iniciando migración para Entidad: %', v_entity_id;


    -- [PASO 1] Insertar Registros (expedient_base_registries)
    -- -------------------------------------------------------------------------
    INSERT INTO expedient_base_registries (
        id, expedient_base_entity_id, name, unique_code, metadata, legacy_id, created_at, updated_at
    )
    SELECT
        gen_random_uuid(),
        v_entity_id,
        s.nombre_producto,  -- [EDITAR] Columna Nombre
        s.codigo_unico,     -- [EDITAR] Columna Código
        '{}'::jsonb,
        'PRD-' || s.id,     -- [EDITAR] Prefijo Legacy ID
        NOW(), NOW()
    FROM [TU_TABLA_ORIGEN] s  -- [EDITAR] Tabla Origen
    ON CONFLICT (legacy_id) DO NOTHING;

    RAISE NOTICE 'Paso 1: Registros insertados.';


    -- [PASO 2] Insertar Campos de Valor (expedient_base_registry_fields)
    -- -------------------------------------------------------------------------
    INSERT INTO expedient_base_registry_fields (
        expedient_base_registry_id, expedient_base_entity_field_id, value, created_at, updated_at
    )
    SELECT
        r.id,
        f.id,
        CASE f.name
            -- [EDITAR] Mapeo de Campos: CASE 'NombreCampoDestino' WHEN s.ColumnaOrigen ...
            WHEN 'Nombre del Producto' THEN s.nombre_producto::text
            WHEN 'Registro Sanitario'  THEN s.num_registro_sanitario::text
            WHEN 'Estado'              THEN s.estado::text
        END,
        NOW(), NOW()
    FROM [TU_TABLA_ORIGEN] s
    JOIN expedient_base_registries r ON r.legacy_id = 'PRD-' || s.id
    JOIN expedient_base_entity_fields f ON f.expedient_base_entity_id = v_entity_id
    WHERE f.name IN (
        -- [EDITAR] Lista blanca de campos a migrar
        'Nombre del Producto', 'Registro Sanitario', 'Estado'
    );

    RAISE NOTICE 'Paso 2: Campos poblados.';


    -- [PASO 3] Insertar Relaciones (expedient_base_registry_relation)
    -- -------------------------------------------------------------------------

    -- A) Relaciones vinculadas a Campos (Input UI)
    -- Ejemplo: Marcas
    IF v_field_marcas_id IS NOT NULL THEN
        INSERT INTO expedient_base_registry_relation (
            expedient_base_registry_id, expedient_base_entity_field_id, relation_id,
            relation_type, source, reference_name, created_at, updated_at
        )
        SELECT
            r.id,
            v_field_marcas_id,
            m_map.marca_uuid,
            'field_value',
            'data_center',
            'srs_marca',
            NOW(), NOW()
        FROM migration_marca_producto mmp -- [EDITAR] Tabla Intermedia
        JOIN expedient_base_registries r ON r.legacy_id = 'PRD-' || mmp.id_alim_producto
        JOIN srs_marca m_map ON m_map.legacy_id = 'MARCA-' || mmp.id_ctl_marca;
    END IF;

    -- B) Relaciones Directas (Sin Input UI)
    -- Ejemplo: Presentaciones
    INSERT INTO expedient_base_registry_relation (
        expedient_base_registry_id, expedient_base_entity_field_id, relation_id,
        relation_type, source, reference_name, created_at, updated_at
    )
    SELECT
        r.id,
        NULL,
        pmap.presentacion_uuid,
        'data_center',
        'data_center',
        'presentaciones_registro_sanitario',
        NOW(), NOW()
    FROM migration_presentacion_mapping pmap -- [EDITAR] Tabla Mapping
    JOIN expedient_base_registries r ON r.legacy_id = 'PRD-' || pmap.id_alim_producto;

    RAISE NOTICE 'Paso 3: Relaciones creadas. Migración finalizada con éxito.';

END $$;
