# DDL: ctl_municipio

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS ctl_municipio_id_seq;

CREATE TABLE "public"."ctl_municipio" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_municipio_id_seq'::regclass),
    "abreviatura" varchar(60) NOT NULL,
    "nombre" varchar(150) NOT NULL,
    "codigo_cnr" varchar(5) NOT NULL,
    "id_ctl_departamento" int4 NOT NULL,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."ctl_municipio"."id" IS 'Este campo es la llave primaria de la tabla ctl_municipio.';
COMMENT ON COLUMN "public"."ctl_municipio"."abreviatura" IS 'Campo que contiene las diferentes abreviaturas de los municipios.';
COMMENT ON COLUMN "public"."ctl_municipio"."nombre" IS 'En este campo se almacenan los nombres de los diferentes municipios del pais.';
COMMENT ON COLUMN "public"."ctl_municipio"."codigo_cnr" IS 'Campo que especifica el codigo asignado por el cnr a un municipio.';
COMMENT ON COLUMN "public"."ctl_municipio"."id_ctl_departamento" IS 'Este campo es la llave primaria de la tabla ctl_departamento.';
COMMENT ON TABLE "public"."ctl_municipio" IS 'Esta tabla es un catalogo de los municipios del pais El Salvador.';
```

## Índices

```sql

```
