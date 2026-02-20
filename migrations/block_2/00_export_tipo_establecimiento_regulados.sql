-- Script: Export table tipo_establecimiento
-- Source Database: tramites-srs

-- Note: We map the exact columns directly to make n8n ingestion easier
SELECT
    establet_id as id,
    establet_tipo as nombre,
    establet_descripcion as codigo,
    CONCAT('TIPO_EST-', establet_id) as legacy_id
FROM
    public.tipo_establecimiento;
