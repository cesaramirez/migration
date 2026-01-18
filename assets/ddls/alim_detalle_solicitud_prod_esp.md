# DDL: alim_detalle_solicitud_prod_esp

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_detalle_solicitud_prod_esp_id_seq;

CREATE TABLE "public"."alim_detalle_solicitud_prod_esp" (
    "id" int4 NOT NULL DEFAULT nextval('alim_detalle_solicitud_prod_esp_id_seq'::regclass),
    "nombre_producto" varchar(750) NOT NULL,
    "marca_producto" varchar(500) NOT NULL,
    "cantidad_producto" float4 NOT NULL,
    "costo_producto_importado" float8 NOT NULL,
    "id_ctl_codigo_producto_especial" int4 NOT NULL,
    "id_ctl_pais" int4 NOT NULL,
    "id_ctl_unidad_medida" int4 NOT NULL,
    "id_alim_solicitud_importacion_minsal" int4 NOT NULL,
    "lotes" varchar,
    "fecha_caducidad" date,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."id" IS 'Este campo es la llave primaria de la tabla detalle_solicitud_prod_esp.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."nombre_producto" IS 'Campo donde se almacena el nombre del producto de la solicitud especial.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."marca_producto" IS 'Campo donde se almacena la marca del producto de una solicitud especial.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."cantidad_producto" IS 'Campo donde se guarda la cantidad de producto que se esta importando.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."costo_producto_importado" IS 'En este campo se almacena el costo total de los productos que se estan importando.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."id_ctl_codigo_producto_especial" IS 'Este campo es la llave primaria de la tabla ctl_codigo_producto_especial.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."id_ctl_pais" IS 'Este campo es la llave primaria de la tabla ctl_pais.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."id_ctl_unidad_medida" IS 'Este campo es la llave primaria de la tabla ctl_unidad_medida.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."id_alim_solicitud_importacion_minsal" IS 'Este campo es la llave primaria de la tabla solicitud_importacion.';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."lotes" IS 'Este campo contiene el numero de lotes de los productos especiales';
COMMENT ON COLUMN "public"."alim_detalle_solicitud_prod_esp"."fecha_caducidad" IS 'Este campo contiene la fecha de caducidad de los productos especiales';
COMMENT ON TABLE "public"."alim_detalle_solicitud_prod_esp" IS 'Esta tabla posee el detalle de una solicitud de importacion para productos especiales que no se tienen registrados.';
```

## Índices

```sql

```
