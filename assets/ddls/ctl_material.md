# DDL: ctl_material

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS ctl_material_id_seq;

CREATE TABLE "public"."ctl_material" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_material_id_seq'::regclass),
    "nombre" varchar(30) NOT NULL,
    "activo" boolean NOT NULL DEFAULT false,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."ctl_material"."id" IS 'Este campo es la llave primaria de la tabla ctl_material.';
COMMENT ON COLUMN "public"."ctl_material"."nombre" IS 'Este campo contiene el nombre de los diferentes materiales que se usa en una presentacion de un producto.';
COMMENT ON TABLE "public"."ctl_material" IS 'Esta tabla es un catalogo de que contiene los tipos de materiales de los que esta fabricado una presentacion de un producto.';
```

## Índices

```sql

```
