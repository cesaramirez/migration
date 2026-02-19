# DDL: alim_presentacion_producto

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_presentacion_producto_id_seq;

CREATE TABLE "public"."alim_presentacion_producto" (
    "id" int4 NOT NULL DEFAULT nextval('alim_presentacion_producto_id_seq'::regclass),
    "cantidad" varchar(20) NOT NULL,
    "ruta_archivo_vineta" varchar(256),
    "estado_presentacion_producto" int4 NOT NULL,
    "id_ctl_unidad_medida" int4 NOT NULL,
    "id_alim_producto" int4 NOT NULL,
    "id_alim_envase_producto" int4 NOT NULL,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_presentacion_producto"."id" IS 'Este campo es la llave primaria de la tabla presentacion_producto.';
COMMENT ON COLUMN "public"."alim_presentacion_producto"."cantidad" IS 'Este campo almacena la cantidad que posee de material una presentacion de un producto, asociada a una unidad de medida especifica.';
COMMENT ON COLUMN "public"."alim_presentacion_producto"."ruta_archivo_vineta" IS 'Campo que almacena la ruta en la cual se encuentra almacenada la viñeta de una presentacion.';
COMMENT ON COLUMN "public"."alim_presentacion_producto"."estado_presentacion_producto" IS 'Campo que indica el estado de una determinada presentacion de un producto; puede ser 1=activo o 2=inactivo.';
COMMENT ON COLUMN "public"."alim_presentacion_producto"."id_ctl_unidad_medida" IS 'Este campo es la llave primaria de la tabla ctl_unidad_medida.';
COMMENT ON COLUMN "public"."alim_presentacion_producto"."id_alim_producto" IS 'Este campo es la llave primaria de la tabla producto.';
COMMENT ON COLUMN "public"."alim_presentacion_producto"."id_alim_envase_producto" IS 'Este campo es la llave primaria de la tabla id_alim_envase_producto';
COMMENT ON TABLE "public"."alim_presentacion_producto" IS 'Esta tabla almacena las distintas presentaciones (de venta) que puede tener un producto.';
```

## Índices

```sql

```
