-- Script: Export table tipo_establecimiento
-- Source Database: tramites-srs

-- Note: We map the exact columns directly to make n8n ingestion easier
SELECT
    establet_id as id,
    establet_tipo as tipo,
    establet_descripcion as descripcion,
    form_id,
    tramite_abreviado,
    activo_cnr,
    CONCAT('TIPO_EST-', establet_id) as legacy_id
FROM
    public.tipo_establecimiento;
