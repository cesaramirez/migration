-- =============================================================================
-- Script: 06_export_marca_producto.sql
-- Propósito: Exportar catálogo de marcas y relaciones desde SISAM
-- Base de datos: sisam (local)
-- Fecha: 2026-01-18
-- =============================================================================

-- =============================================================================
-- PARTE A: CATÁLOGO DE MARCAS (ctl_marca)
-- =============================================================================
-- Exportar a: /Users/heycsar/tmp/ctl_marca.csv

-- Query 1: Export de ctl_marca
SELECT
    id,
    nombre,
    id_modulo
FROM ctl_marca
ORDER BY id;

-- Verificación
SELECT COUNT(*) as total_marcas FROM ctl_marca;

-- =============================================================================
-- PARTE B: RELACIONES MARCA-PRODUCTO (alim_marca_producto)
-- =============================================================================
-- Exportar a: /Users/heycsar/tmp/alim_marca_producto.csv

-- Query 2: Export de relaciones (con filtro de productos válidos + deduplicación)
SELECT DISTINCT
    mp.id_alim_producto,
    mp.id_ctl_marca,
    COALESCE(MAX(mp.estado_marca_producto), 1) as estado_marca_producto
FROM alim_marca_producto mp
JOIN alim_producto p ON p.id = mp.id_alim_producto
WHERE p.estado_registro = 1
  AND p.fecha_emision_registro IS NOT NULL
  AND p.fecha_vigencia_registro IS NOT NULL
  AND p.num_registro_sanitario IS NOT NULL
GROUP BY mp.id_alim_producto, mp.id_ctl_marca
ORDER BY mp.id_alim_producto, mp.id_ctl_marca;

-- =============================================================================
-- VERIFICACIÓN: Conteos esperados
-- =============================================================================
SELECT
    'ctl_marca' as tabla,
    COUNT(*) as registros
FROM ctl_marca
UNION ALL
SELECT
    'alim_marca_producto (filtrado)',
    COUNT(*)
FROM (
    SELECT DISTINCT mp.id_alim_producto, mp.id_ctl_marca
    FROM alim_marca_producto mp
    JOIN alim_producto p ON p.id = mp.id_alim_producto
    WHERE p.estado_registro = 1
      AND p.fecha_emision_registro IS NOT NULL
      AND p.fecha_vigencia_registro IS NOT NULL
      AND p.num_registro_sanitario IS NOT NULL
) sub;
