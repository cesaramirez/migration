# DDL: alim_producto_certificado_libre_venta

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_producto_certificado_libre_venta_id_seq;

CREATE TABLE "public"."alim_producto_certificado_libre_venta" (
    "id" int4 NOT NULL DEFAULT nextval('alim_producto_certificado_libre_venta_id_seq'::regclass),
    "fecha_vigencia" date NOT NULL,
    "nombre_prod_segun_clv" varchar(600) NOT NULL,
    "id_alim_certificado_libre_venta" int4 NOT NULL,
    "id_ctl_estado_proceso" int4 NOT NULL,
    "id_alim_producto" int4 NOT NULL,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_producto_certificado_libre_venta"."id" IS 'Este campo es la llave primaria de la tabla producto_certificado_libre_venta.';
COMMENT ON COLUMN "public"."alim_producto_certificado_libre_venta"."fecha_vigencia" IS 'Este campo contiene la fecha hasta que dura la vigencia del certificado de libre venta, la cual puede variar entre paises de la union aduanera y los periodos establecidos por la ley. Esta fecha varia segun cada producto.';
COMMENT ON COLUMN "public"."alim_producto_certificado_libre_venta"."nombre_prod_segun_clv" IS 'Campo para almacenar el nombre del producto segun se especifica en el CLV.(Nuevo campo que solicito jasmin u.u)';
COMMENT ON COLUMN "public"."alim_producto_certificado_libre_venta"."id_alim_certificado_libre_venta" IS 'Esta campo es la llave primaria de la tabla certificado_libre_venta.';
COMMENT ON COLUMN "public"."alim_producto_certificado_libre_venta"."id_ctl_estado_proceso" IS 'Este campo es la llave primaria de la tabla ctl_estado_proceso.';
COMMENT ON COLUMN "public"."alim_producto_certificado_libre_venta"."id_alim_producto" IS 'Este campo es la llave primaria de la tabla producto.';
COMMENT ON TABLE "public"."alim_producto_certificado_libre_venta" IS 'Esta es una tabla intermedia que representa la relacion que hay entre productos y certificados de libre venta nacionales y extranjeros.';
```

## Índices

```sql

```
