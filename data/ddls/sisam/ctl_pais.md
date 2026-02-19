```sql
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS ctl_pais_id_seq;

-- Table Definition
CREATE TABLE "public"."ctl_pais" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_pais_id_seq'::regclass),
    "nombre" varchar(150) NOT NULL,
    "dominio2" varchar(2) NOT NULL,
    "dominio3" varchar(3) NOT NULL,
    "isonumero" int4 NOT NULL,
    "union_aduanera" bool NOT NULL DEFAULT false,
    "activo" bool,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."ctl_pais"."id" IS 'Este campo es la llave primaria de la tabla ctl_pais.';
COMMENT ON COLUMN "public"."ctl_pais"."nombre" IS 'Este campo contiene los nombres de los paises de todo el mundo.';
COMMENT ON COLUMN "public"."ctl_pais"."dominio2" IS 'abreviatura dominio2 según ISO 3166-1 alfa-2';
COMMENT ON COLUMN "public"."ctl_pais"."dominio3" IS 'Abreviatura de dominio3 según ISO 3166-1 alfa-3';
COMMENT ON COLUMN "public"."ctl_pais"."isonumero" IS 'Este campo contiene la primera parte del estándar internacional de normalización ISO 3166';
COMMENT ON COLUMN "public"."ctl_pais"."union_aduanera" IS 'Este campo contiene una bandera que indica si el pais pertenece a la union aduanera para el reconocimiento de los certificados de libre venta.';
COMMENT ON COLUMN "public"."ctl_pais"."activo" IS 'Identificador estado del país true o false';


-- Comments
COMMENT ON TABLE "public"."ctl_pais" IS 'Esta tabla es un catalogo de los paises del mundo.';
```
