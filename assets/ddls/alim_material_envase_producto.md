# DDL: alim_material_envase_producto

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_material_envase_producto_id_seq;

CREATE TABLE "public"."alim_material_envase_producto" (
    "id" int4 NOT NULL DEFAULT nextval('alim_material_envase_producto_id_seq'::regclass),
    "id_ctl_material" int4 NOT NULL,
    "id_alim_envase_producto" int4 NOT NULL,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_material_envase_producto"."id" IS 'Llave primaria de la tabla';
COMMENT ON COLUMN "public"."alim_material_envase_producto"."id_ctl_material" IS 'Este campo es la llave primaria de la tabla ctl_material.';
COMMENT ON COLUMN "public"."alim_material_envase_producto"."id_alim_envase_producto" IS 'Contiene la llave primaria de la tabla alim_envase_producto';

```

## Índices

```sql

```
