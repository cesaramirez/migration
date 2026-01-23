# DDL: alim_producto_solicitud

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_producto_solicitud_id_seq;

CREATE TABLE "public"."alim_producto_solicitud" (
    "id" int4 NOT NULL DEFAULT nextval('alim_producto_solicitud_id_seq'::regclass),
    "id_alim_producto" int4 NOT NULL,
    "id_alim_solicitud" int4 NOT NULL,
    "permiso_provisional" boolean DEFAULT false,
    "omision_de_analisis" boolean DEFAULT false,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_producto_solicitud"."id" IS 'Llave primaria de la tabla alim_producto_solicitud';
COMMENT ON COLUMN "public"."alim_producto_solicitud"."id_alim_producto" IS 'Este campo es la llave primaria de la tabla producto.';
COMMENT ON COLUMN "public"."alim_producto_solicitud"."id_alim_solicitud" IS 'Llave primaria de la tabla solicitud.';
COMMENT ON TABLE "public"."alim_producto_solicitud" IS 'Tabla intermedia en la que se almacenan los diferentes productos que pertenecen a una solicitud.';
```

## Índices

```sql

```
