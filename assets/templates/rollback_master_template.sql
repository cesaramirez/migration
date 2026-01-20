/**
 * PLANTILLA MAESTRA DE ROLLBACK
 * =============================
 * Limpia todos los datos asociados a una entidad específica usando el Legacy ID prefix.
 * Orden de eliminación: Relaciones -> Campos -> Registros.
 */

DO $$
DECLARE
    -- [CONFIGURACIÓN]
    v_entity_id UUID := 'PONER_AQUI_EL_UUID_DE_LA_ENTIDAD';
    v_legacy_prefix TEXT := 'PRD-%'; -- Prefijo usado en el legacy_id
BEGIN

    RAISE NOTICE 'Iniciando Rollback para Entidad: %', v_entity_id;

    -- 1. Eliminar Relaciones
    DELETE FROM expedient_base_registry_relation
    WHERE expedient_base_registry_id IN (
        SELECT id FROM expedient_base_registries
        WHERE expedient_base_entity_id = v_entity_id
          AND legacy_id LIKE v_legacy_prefix
    );
    RAISE NOTICE 'Relaciones eliminadas.';

    -- 2. Eliminar Campos (Values)
    DELETE FROM expedient_base_registry_fields
    WHERE expedient_base_registry_id IN (
        SELECT id FROM expedient_base_registries
        WHERE expedient_base_entity_id = v_entity_id
          AND legacy_id LIKE v_legacy_prefix
    );
    RAISE NOTICE 'Campos eliminados.';

    -- 3. Eliminar Registros (Padre)
    DELETE FROM expedient_base_registries
    WHERE expedient_base_entity_id = v_entity_id
      AND legacy_id LIKE v_legacy_prefix;

    RAISE NOTICE 'Registros eliminados. Rollback completado.';

END $$;
