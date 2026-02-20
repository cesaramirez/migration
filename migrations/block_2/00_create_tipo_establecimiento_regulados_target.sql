-- Script: Create target table for tipo_establecimiento
-- Database: Centro de Datos
-- Source Database: tramites-srs

CREATE TABLE IF NOT EXISTS public.srs_tipo_establecimiento_regulados (
  id integer NOT NULL PRIMARY KEY,            -- Maps to establet_id
  nombre character varying(255),              -- Maps to establet_tipo
  codigo text,                                -- Maps to establet_descripcion

  -- Traceability field
  legacy_id character varying(50)
);

-- Indices
CREATE UNIQUE INDEX IF NOT EXISTS pk_srs_tipo_establecimiento_regulados ON public.srs_tipo_establecimiento_regulados USING btree (id);
CREATE INDEX IF NOT EXISTS idx_srs_tipo_establecimiento_regulados_legacy_id ON public.srs_tipo_establecimiento_regulados USING btree (legacy_id);

-- Comments
COMMENT ON TABLE public.srs_tipo_establecimiento_regulados IS 'Catálogo de tipos de establecimientos migrado desde tramites-srs';
COMMENT ON COLUMN public.srs_tipo_establecimiento_regulados.id IS 'Identificador original (establet_id)';
COMMENT ON COLUMN public.srs_tipo_establecimiento_regulados.legacy_id IS 'ID de trazabilidad para la migración, formato: TIPO_EST-{id}';
