# DDL: alim_detalle_solicitud_prod_reg

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_detalle_solicitud_prod_reg_id_seq;

CREATE TABLE "public"."alim_detalle_solicitud_prod_reg" (
    "id" int4 NOT NULL DEFAULT nextval('alim_detalle_solicitud_prod_reg_id_seq'::regclass),
    "cantidad_producto" float8 NOT NULL,
    "costo_producto" float8 NOT NULL,
    "id_ctl_unidad_medida" int4 NOT NULL,
    "id_alim_producto" int4 NOT NULL,
    "id_alim_solicitud_importacion_minsal" int4 NOT NULL,
    "lotes" varchar,
    "fecha_caducidad" date,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_reg"."id" IS 'Llave primaria de la tabla detalle_solicitud_prod_reg';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_reg"."cantidad_producto" IS 'Campo donde se almacen la cantidad de productos de la solicitud.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_reg"."costo_producto" IS 'Campo donde se guarda el costo total de los productos de la solicitud.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_reg"."id_ctl_unidad_medida" IS 'Este campo es la llave primaria de la tabla ctl_unidad_medida.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_reg"."id_alim_producto" IS 'Este campo es la llave primaria de la tabla producto.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_reg"."id_alim_solicitud_importacion_minsal" IS 'Este campo es la llave primaria de la tabla solicitud_importacion.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_reg"."lotes" IS 'Este campo almacena el número de lote de los productos';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_reg"."fecha_caducidad" IS 'Este campo almacena la fecha de caducidad del producto';
COMMENT ON TABLE "public"."alim_detalle_solicitud_prod_reg" IS 'Esta tabla contiene el detalle de las solicitudes de importacion de los productos registrados.';
```

## Índices

```sql

```
