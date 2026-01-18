# DDL: alim_envase_producto

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_envase_producto_id_seq;

CREATE TABLE "public"."alim_envase_producto" (
    "id" int4 NOT NULL DEFAULT nextval('alim_envase_producto_id_seq'::regclass),
    "id_alim_producto" int4 NOT NULL,
    "estado_envase_producto" int4 NOT NULL,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_envase_producto"."id" IS 'Llave primaria de la tabla alim envase producto';
COMMENT ON COLUMN "public"."alim_envase_producto"."id_alim_producto" IS 'Este campo es la llave primaria de la tabla producto.';
COMMENT ON COLUMN "public"."alim_envase_producto"."estado_envase_producto" IS 'Campo que indica el estado de un determinado  envase de un producto; puede ser 1=activo o 2=inactivo.';
COMMENT ON TABLE "public"."alim_envase_producto" IS 'Esta tabla almacena la información de los envases de los productos';
```

## Índices

```sql

```
