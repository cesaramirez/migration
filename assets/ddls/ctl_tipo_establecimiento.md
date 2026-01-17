```sql
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS ctl_tipo_establecimiento_id_seq;

-- Table Definition
CREATE TABLE "public"."ctl_tipo_establecimiento" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_tipo_establecimiento_id_seq'::regclass),
    "nombre" varchar(150) NOT NULL,
    "codigo" varchar(4) NOT NULL,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."ctl_tipo_establecimiento"."id" IS 'Llave primaria de la tabla ctl_tipo_establecimiento';
COMMENT ON COLUMN "public"."ctl_tipo_establecimiento"."nombre" IS 'Este campo contiene el nombre de la clasificación del establecimiento';
COMMENT ON COLUMN "public"."ctl_tipo_establecimiento"."codigo" IS 'Este campo contiene el codigo de la clasificación del establecimiento';


-- Comments
COMMENT ON TABLE "public"."ctl_tipo_establecimiento" IS 'Catalogo de las diferentes clasificaciones de establecimientos que existen dentro del ministerio de salud.';


-- Indices
CREATE UNIQUE INDEX pk_ctl_tipo_establecimiento ON public.ctl_tipo_establecimiento USING btree (id);
```
