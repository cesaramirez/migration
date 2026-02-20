-- Script: Export table tipo_establecimiento
-- Source Database: tramites-srs

-- Note: We map the exact columns directly to make n8n ingestion easier
SELECT
    establet_tipo AS nombre,
    establet_descripcion AS code,
    CONCAT('TIPO_EST-', establet_id) AS legacy_id
FROM
    public.tipo_establecimiento
WHERE
    establet_id IN (285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302);
