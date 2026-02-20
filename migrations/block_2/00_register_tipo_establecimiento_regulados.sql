-- Script: Register table in data_center_tables
-- Database: SDT

DELETE FROM public.data_center_tables WHERE name = 'srs_tipo_establecimiento_regulados';

INSERT INTO public.data_center_tables (id, name, description, columns, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'srs_tipo_establecimiento_regulados',
    'Catálogo de tipos de establecimientos migrado desde tramites-srs',
    '[{"id": "7e93c44b-ff9a-4136-92c5-ed2604c4d00c", "name": "id", "type": "UUID"}, {"id": "48f5df64-f3ff-4d6b-a45a-c3cfe8726e82", "name": "code", "type": "STRING"}, {"id": "c9cbab98-76a7-4616-9ca0-5ed8baaf6052", "name": "nombre", "type": "STRING"}, {"id": "0ac6c9f2-1a41-4c17-8149-d04b6b6cc38a", "name": "legacy_id", "type": "STRING"}, {"name": "created_at", "type": "TIMESTAMP"}, {"name": "updated_at", "type": "TIMESTAMP"}, {"name": "deleted_at", "type": "TIMESTAMP"}]'::jsonb,
    NOW(),
    NOW()
);
