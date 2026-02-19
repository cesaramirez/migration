-- =============================================================================
-- PASO 2: CREAR TABLA TEMPORAL PARA SOLICITUDES DE IMPORTACIÓN
-- =============================================================================
-- Entidad: Expediente SDT - Importación de productos especiales
-- Esta tabla recibe el CSV exportado desde SISAM
--
-- Ejecutar en: Base de datos CORE
-- =============================================================================

-- Eliminar tabla temporal si existe (para re-ejecución)
DROP TABLE IF EXISTS migration_solicitud_importacion_temp;

-- Crear tabla temporal con estructura que coincide con el export
CREATE TABLE migration_solicitud_importacion_temp (
    -- Identificadores
    original_id INTEGER PRIMARY KEY,
    original_bcr_id INTEGER,

    -- Campos de BCR
    nombre_importador VARCHAR(156),
    nit_importador VARCHAR(20),
    fecha_registro_bcr VARCHAR(10),  -- DD/MM/YYYY
    numero_solicitud VARCHAR(30),

    -- Campos de MINSAL
    estado_solicitud_raw INTEGER,
    estado_de_solicitud VARCHAR(20),
    direccion_importador VARCHAR(500),
    departamento VARCHAR(100),
    municipio VARCHAR(100),
    nombre_del_tramitador VARCHAR(100),
    tipo_documento_tramitador_raw VARCHAR(50),
    tipo_documento_usuario VARCHAR(50),
    numero_documento_del_tramitador VARCHAR(14),
    pais VARCHAR(100),
    numero_solicitud_minsal VARCHAR(30),

    -- Campos adicionales
    fecha_registro_minsal VARCHAR(10),
    fecha_resolucion_minsal VARCHAR(10),
    justificacion_resolucion VARCHAR(750),
    estado_externo_raw VARCHAR(2),
    estado_externo VARCHAR(50),
    fecha_estado_externo VARCHAR(10),

    -- IDs para cruce con Centro de Datos
    original_pais_id INTEGER,
    original_pais_iso_number VARCHAR(10),
    original_pais_iso_2 VARCHAR(2),
    original_pais_iso_3 VARCHAR(3),
    original_departamento_id INTEGER,
    original_municipio_id INTEGER
);

-- Crear índices para optimizar JOINs durante migración
CREATE INDEX idx_msit_original_id ON migration_solicitud_importacion_temp(original_id);
CREATE INDEX idx_msit_estado_solicitud ON migration_solicitud_importacion_temp(estado_solicitud_raw);
CREATE INDEX idx_msit_pais_iso ON migration_solicitud_importacion_temp(original_pais_iso_number);

-- =============================================================================
-- IMPORTAR DATOS DESDE CSV
-- =============================================================================
-- Opción 1: Usando COPY (desde terminal psql)
/*
\COPY migration_solicitud_importacion_temp FROM '/path/to/solicitud_importacion_export.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');
*/

-- Opción 2: Usando TablePlus
-- 1. Click derecho en tabla migration_solicitud_importacion_temp
-- 2. Import from CSV...
-- 3. Seleccionar archivo solicitud_importacion_export.csv
-- 4. Marcar "First row is header"
-- 5. Click Import

-- =============================================================================
-- VALIDACIÓN POST-IMPORT
-- =============================================================================

-- Verificar conteo de registros importados
SELECT 'Registros importados' as descripcion, COUNT(*) as total
FROM migration_solicitud_importacion_temp;

-- Verificar distribución de estados
SELECT
    estado_de_solicitud,
    COUNT(*) as total
FROM migration_solicitud_importacion_temp
GROUP BY estado_de_solicitud
ORDER BY total DESC;

-- Verificar campos nulos
SELECT
    'nombre_importador NULL' as campo,
    COUNT(*) as total
FROM migration_solicitud_importacion_temp
WHERE nombre_importador IS NULL OR nombre_importador = ''
UNION ALL
SELECT
    'numero_solicitud NULL',
    COUNT(*)
FROM migration_solicitud_importacion_temp
WHERE numero_solicitud IS NULL OR numero_solicitud = ''
UNION ALL
SELECT
    'pais NULL',
    COUNT(*)
FROM migration_solicitud_importacion_temp
WHERE pais IS NULL OR pais = '';

-- Muestra de datos importados
SELECT
    original_id,
    nombre_importador,
    numero_solicitud,
    estado_de_solicitud,
    pais,
    departamento
FROM migration_solicitud_importacion_temp
LIMIT 10;

-- =============================================================================
-- SIGUIENTE PASO:
-- =============================================================================
-- Elegir uno de los siguientes scripts según tu escenario:
--
-- Escenario A: Crear nueva entidad y campos
--   → Ejecutar: 12_migrate_solicitud_importacion_create_entity.sql
--
-- Escenario B: Usar entidad existente (UUID conocido)
--   → Ejecutar: 13_migrate_solicitud_importacion_by_uuid.sql
--   → Necesitarás proporcionar el UUID de la entidad destino
-- =============================================================================
