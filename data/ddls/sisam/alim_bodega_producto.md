# DDL: alim_bodega_producto

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_bodega_producto_id_seq;

CREATE TABLE "public"."alim_bodega_producto" (
    "id_alim_bodega_producto" int4 NOT NULL DEFAULT nextval('alim_bodega_producto_id_seq'::regclass),
    "fecha_registro" date NOT NULL,
    "fecha_traslado" date,
    "id_alim_producto" int4 NOT NULL,
    "id_alim_bodega" int4 NOT NULL,
    PRIMARY KEY ("id_alim_bodega_producto")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_bodega_producto"."id_alim_bodega_producto" IS 'Campo que es la llave primaria de la tabla bodega_producto.';
COMMENT ON COLUMN "public"."alim_bodega_producto"."fecha_registro" IS 'Campo donde se almacena la fecha en que un producto se registro en una determinada bodega.';
COMMENT ON COLUMN "public"."alim_bodega_producto"."fecha_traslado" IS 'Campo donde se almacena la fecha en que un producto se traslado a otra bodega.';
COMMENT ON COLUMN "public"."alim_bodega_producto"."id_alim_producto" IS 'Este campo es la llave primaria de la tabla producto.';
COMMENT ON COLUMN "public"."alim_bodega_producto"."id_alim_bodega" IS 'Este campo es el llave primaria de la tabla bodega.';
COMMENT ON TABLE "public"."alim_bodega_producto" IS 'Tabla intermedia para asociar una bodega con un producto.';
```

## Índices

```sql

```
