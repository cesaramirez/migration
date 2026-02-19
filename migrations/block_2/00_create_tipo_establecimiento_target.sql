-- Script: Create target table for tipo_establecimiento
-- Database: Centro de Datos
-- Source Database: tramites-srs

CREATE TABLE IF NOT EXISTS public.srs_tramites_tipo_establecimiento (
  id integer NOT NULL PRIMARY KEY,            -- Maps to establet_id
  tipo character varying(255),              -- Maps to establet_tipo
  descripcion text,                         -- Maps to establet_descripcion
  form_id character varying(50),            -- Maps to form_id
  tramite_abreviado character varying(50),  -- Maps to tramite_abreviado
  activo_cnr boolean,                       -- Maps to activo_cnr

  -- Traceability field
  legacy_id character varying(50)
);

-- Indices
CREATE UNIQUE INDEX IF NOT EXISTS pk_srs_tramites_tipo_establecimiento ON public.srs_tramites_tipo_establecimiento USING btree (id);
CREATE INDEX IF NOT EXISTS idx_srs_tramites_tipo_establecimiento_legacy_id ON public.srs_tramites_tipo_establecimiento USING btree (legacy_id);

-- Comments
COMMENT ON TABLE public.srs_tramites_tipo_establecimiento IS 'Catálogo de tipos de establecimientos migrado desde tramites-srs';
COMMENT ON COLUMN public.srs_tramites_tipo_establecimiento.id IS 'Identificador original (establet_id)';
COMMENT ON COLUMN public.srs_tramites_tipo_establecimiento.legacy_id IS 'ID de trazabilidad para la migración, formato: TIPO_EST-{id}';
