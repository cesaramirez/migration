-- =============================================================================
-- EXPORTAR RELACIONES PRODUCTO → MARCA (SOLO PRODUCTOS APROBADOS)
-- =============================================================================
-- Ejecutar en: SISAM
-- Filtro: Solo productos cuya solicitud tenga estado actual = 8 (Aprobada)
-- =============================================================================

WITH ultimo_estado_solicitud AS (
    -- Obtener el último estado de cada solicitud (el más reciente por fecha)
    SELECT DISTINCT ON (mes.id_alim_solicitud)
        mes.id_alim_solicitud,
        mes.id_ctl_estado_solicitud
    FROM alim_movimiento_estado_solicitud mes
    ORDER BY mes.id_alim_solicitud, mes.fecha DESC
),
productos_aprobados AS (
    -- Filtrar solo productos cuya solicitud tenga estado = 8 (Aprobada)
    SELECT DISTINCT ps.id_alim_producto
    FROM alim_producto_solicitud ps
    JOIN alim_solicitud s ON s.id = ps.id_alim_solicitud
    JOIN ultimo_estado_solicitud ues ON ues.id_alim_solicitud = s.id
    WHERE ues.id_ctl_estado_solicitud = 8  -- Estado APROBADA
)
SELECT
    mp.id_alim_producto,
    mp.id_ctl_marca
FROM alim_marca_producto mp
-- ⭐ FILTRO: Solo productos con solicitud aprobada
INNER JOIN productos_aprobados pa ON pa.id_alim_producto = mp.id_alim_producto
ORDER BY mp.id_alim_producto, mp.id_ctl_marca;

-- =============================================================================
-- QUERY DE VALIDACIÓN: Comparar conteos
-- =============================================================================

/*
-- Relaciones totales (sin filtro)
SELECT 'Sin filtro' as criterio, COUNT(*) as relaciones
FROM alim_marca_producto;

-- Relaciones de productos aprobados
WITH ultimo_estado_solicitud AS (
    SELECT DISTINCT ON (mes.id_alim_solicitud)
        mes.id_alim_solicitud,
        mes.id_ctl_estado_solicitud
    FROM alim_movimiento_estado_solicitud mes
    ORDER BY mes.id_alim_solicitud, mes.fecha DESC
),
productos_aprobados AS (
    SELECT DISTINCT ps.id_alim_producto
    FROM alim_producto_solicitud ps
    JOIN ultimo_estado_solicitud ues ON ues.id_alim_solicitud = ps.id_alim_solicitud
    WHERE ues.id_ctl_estado_solicitud = 8
)
SELECT 'Solo aprobados (estado 8)' as criterio, COUNT(*) as relaciones
FROM alim_marca_producto mp
INNER JOIN productos_aprobados pa ON pa.id_alim_producto = mp.id_alim_producto;
*/

-- =============================================================================
-- INSTRUCCIONES:
-- =============================================================================
-- 1. Ejecutar este query en SISAM
-- 2. Exportar resultado como CSV
-- 3. Importar en Core como: migration_marca_producto
-- 4. Ejecutar: 06_migrate_marca_relations.sql
-- =============================================================================
