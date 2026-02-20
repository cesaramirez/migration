-- Script: Register table in data_center_tables
-- Database: SDT

DELETE FROM public.data_center_tables WHERE name = 'srs_tipo_establecimiento_regulados';

INSERT INTO public.data_center_tables (id, name, description, columns, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'srs_tipo_establecimiento_regulados',
    'Catálogo de tipos de establecimientos migrado desde tramites-srs',
    '[{"name": "id", "type": "INTEGER"}, {"name": "nombre", "type": "VARCHAR"}, {"name": "codigo", "type": "TEXT"}, {"name": "legacy_id", "type": "VARCHAR"}]'::jsonb,
    NOW(),
    NOW()
);
