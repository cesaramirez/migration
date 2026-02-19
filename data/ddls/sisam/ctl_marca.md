# DDL: ctl_marca

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS ctl_marca_id_seq;

CREATE TABLE "public"."ctl_marca" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_marca_id_seq'::regclass),
    "nombre" varchar NOT NULL,
    "id_modulo" int4,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."ctl_marca"."id" IS 'Este campo es la llave primaria de la tabla ctl_marca.';
COMMENT ON COLUMN "public"."ctl_marca"."nombre" IS 'Este campo posee el nombre de las marcas que existen en el pais.';
COMMENT ON TABLE "public"."ctl_marca" IS 'Esta tabla es un catalogo de las diferentes marcas que existen en el pais.';
```

## Índices

```sql

```
