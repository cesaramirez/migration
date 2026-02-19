-- =============================================================================
-- PASO 1: EXPORTAR DE SISAM - SOLICITUDES DE IMPORTACIÓN DE PRODUCTOS ESPECIALES
-- =============================================================================
-- Entidad: Expediente SDT - Importación de productos especiales
-- Tablas origen:
--   - alim_solicitud_importacion_bcr (datos generales BCR)
--   - alim_solicitud_importacion_minsal (datos específicos MINSAL)
--
-- Este script extrae TODAS las solicitudes (sin filtro de estado)
-- =============================================================================

-- =============================================================================
-- QUERY DE DIAGNÓSTICO: Verificar distribución de estados
-- =============================================================================

/*
-- Ver distribución de estados de solicitud
SELECT
    sim.estado_solicitud,
    CASE sim.estado_solicitud
        WHEN 1 THEN 'Iniciada'
        WHEN 2 THEN 'Aprobada'
        WHEN 3 THEN 'Rechazada'
        WHEN 4 THEN 'Cancelada'
        WHEN 5 THEN 'En proceso'
        ELSE 'Desconocido'
    END as estado_nombre,
    COUNT(*) as total
FROM alim_solicitud_importacion_minsal sim
GROUP BY sim.estado_solicitud
ORDER BY sim.estado_solicitud;

-- Ver distribución de tipos de solicitud (BCR)
SELECT
    bcr.tipo_solicitud,
    CASE bcr.tipo_solicitud
        WHEN '1' THEN 'Autorización con registro'
        WHEN '2' THEN 'Autorización especial'
        ELSE 'Desconocido'
    END as tipo_nombre,
    COUNT(*) as total
FROM alim_solicitud_importacion_bcr bcr
GROUP BY bcr.tipo_solicitud
ORDER BY bcr.tipo_solicitud;

-- Verificar relaciones entre tablas
SELECT
    'alim_solicitud_importacion_bcr' as tabla,
    COUNT(*) as total
FROM alim_solicitud_importacion_bcr
UNION ALL
SELECT
    'alim_solicitud_importacion_minsal',
    COUNT(*)
FROM alim_solicitud_importacion_minsal;
*/

-- =============================================================================
-- QUERY PRINCIPAL: Extraer solicitudes de importación
-- =============================================================================

SELECT
    -- Identificadores
    sim.id as original_id,
    bcr.id as original_bcr_id,

    -- =========================================================================
    -- Campos de BCR (alim_solicitud_importacion_bcr)
    -- =========================================================================
    TRIM(bcr.nombre_importador) as nombre_importador,
    TRIM(bcr.nit_importador) as nit_importador,
    TO_CHAR(bcr.fecha_registro_bcr, 'DD/MM/YYYY') as fecha_registro_bcr,
    TRIM(bcr.numero_solicitud) as numero_solicitud,

    -- =========================================================================
    -- Campos de MINSAL (alim_solicitud_importacion_minsal)
    -- =========================================================================
    -- Estado de solicitud (transformación a ENUM)
    sim.estado_solicitud as estado_solicitud_raw,
    CASE sim.estado_solicitud
        WHEN 1 THEN 'Iniciada'
        WHEN 2 THEN 'Aprobada'
        WHEN 3 THEN 'Rechazada'
        WHEN 4 THEN 'Cancelada'
        WHEN 5 THEN 'En proceso'
        ELSE 'Desconocido'
    END as estado_de_solicitud,

    -- Dirección del importador
    TRIM(sim.direccion_importador) as direccion_importador,

    -- Datos del departamento (nombre desnormalizado)
    dep.nombre as departamento,

    -- Datos del municipio (nombre desnormalizado)
    mun.nombre as municipio,

    -- Datos del tramitador
    TRIM(sim.nombre_tramitador) as nombre_del_tramitador,
    TRIM(sim.tipo_documento_tramitador) as tipo_documento_tramitador_raw,
    -- Normalizar tipo de documento para cruce con catálogo
    CASE UPPER(TRIM(sim.tipo_documento_tramitador))
        WHEN 'DUI' THEN 'DUI'
        WHEN 'NIT' THEN 'NIT'
        WHEN 'PASAPORTE' THEN 'PASAPORTE'
        WHEN 'CARNET DE RESIDENTE' THEN 'CARNET DE RESIDENTE'
        WHEN 'CARNET' THEN 'CARNET DE RESIDENTE'
        WHEN 'RESIDENTE' THEN 'CARNET DE RESIDENTE'
        ELSE UPPER(TRIM(sim.tipo_documento_tramitador))
    END as tipo_documento_usuario,
    TRIM(sim.numero_documento_tramitador) as numero_documento_del_tramitador,

    -- País (nombre desnormalizado)
    pais.nombre as pais,

    -- Número de solicitud MINSAL
    TRIM(sim.numero_solicitud_minsal) as numero_solicitud_minsal,

    -- =========================================================================
    -- Campos adicionales (contexto y fechas)
    -- =========================================================================
    TO_CHAR(sim.fecha_registro_minsal, 'DD/MM/YYYY') as fecha_registro_minsal,
    TO_CHAR(sim.fecha_resolucion_minsal, 'DD/MM/YYYY') as fecha_resolucion_minsal,
    TRIM(sim.justificacion_resolucion) as justificacion_resolucion,

    -- Estado externo (BCR response)
    sim.estado_externo as estado_externo_raw,
    CASE TRIM(sim.estado_externo)
        WHEN 'LA' THEN 'Liquidado Aprobado'
        WHEN 'LD' THEN 'Liquidado Denegado'
        WHEN 'ER' THEN 'Espera de Respuesta'
        WHEN 'SE' THEN 'Sin Estado'
        ELSE NULLIF(TRIM(sim.estado_externo), '')
    END as estado_externo,
    TO_CHAR(sim.fecha_estado_externo, 'DD/MM/YYYY') as fecha_estado_externo,

    -- =========================================================================
    -- IDs para cruce con Centro de Datos
    -- =========================================================================
    sim.id_ctl_pais as original_pais_id,
    pais.isonumero as original_pais_iso_number,
    pais.dominio2 as original_pais_iso_2,
    pais.dominio3 as original_pais_iso_3,

    sim.id_ctl_departamento as original_departamento_id,
    sim.id_ctl_municipio as original_municipio_id

FROM alim_solicitud_importacion_minsal sim
-- JOIN con tabla de BCR
INNER JOIN alim_solicitud_importacion_bcr bcr
    ON bcr.id = sim.id_alim_solicitud_importacion_bcr
-- JOINs para catálogos
LEFT JOIN ctl_pais pais ON pais.id = sim.id_ctl_pais
LEFT JOIN ctl_departamento dep ON dep.id = sim.id_ctl_departamento
LEFT JOIN ctl_municipio mun ON mun.id = sim.id_ctl_municipio
ORDER BY sim.id;

-- =============================================================================
-- QUERY DE VALIDACIÓN: Verificar conteos antes de exportar
-- =============================================================================

/*
-- Total de registros a migrar
SELECT
    'Total solicitudes a migrar' as descripcion,
    COUNT(*) as total
FROM alim_solicitud_importacion_minsal sim
INNER JOIN alim_solicitud_importacion_bcr bcr
    ON bcr.id = sim.id_alim_solicitud_importacion_bcr;

-- Verificar campos nulos críticos
SELECT
    'Registros con nombre_importador NULL' as campo,
    COUNT(*) as total
FROM alim_solicitud_importacion_minsal sim
INNER JOIN alim_solicitud_importacion_bcr bcr
    ON bcr.id = sim.id_alim_solicitud_importacion_bcr
WHERE bcr.nombre_importador IS NULL OR TRIM(bcr.nombre_importador) = ''
UNION ALL
SELECT
    'Registros con numero_solicitud NULL',
    COUNT(*)
FROM alim_solicitud_importacion_minsal sim
INNER JOIN alim_solicitud_importacion_bcr bcr
    ON bcr.id = sim.id_alim_solicitud_importacion_bcr
WHERE bcr.numero_solicitud IS NULL OR TRIM(bcr.numero_solicitud) = '';
*/

-- =============================================================================
-- INSTRUCCIONES:
-- =============================================================================
-- 1. Ejecutar primero los queries de diagnóstico (descomentarlos)
-- 2. Verificar distribución de estados y tipos
-- 3. Ejecutar el query principal
-- 4. En TablePlus: Click derecho en resultado → Export → CSV
-- 5. Guardar como: solicitud_importacion_export.csv
-- 6. Continuar con: 11_create_temp_table_solicitud_importacion.sql
-- =============================================================================
