# DDL: alim_empresa_persona_aux_funcion_producto

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_empresa_persona_aux_funcion_producto_id_seq;

CREATE TABLE "public"."alim_empresa_persona_aux_funcion_producto" (
    "id" int4 NOT NULL DEFAULT nextval('alim_empresa_persona_aux_funcion_producto_id_seq'::regclass),
    "id_ctl_funcion_empresa_persona" int4 NOT NULL,
    "id_alim_producto" int4 NOT NULL,
    "id_alim_empresa_persona_aux" int4 NOT NULL,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_empresa_persona_aux_funcion_producto"."id" IS 'Llave primaria de la tabla alim empresa persona aux funcion producto';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux_funcion_producto"."id_ctl_funcion_empresa_persona" IS 'Este campo almacena información de la función que tiene la empresa en relación al producto. 1= Fabricante, 2= Distribuidor, 3=Envasador, 5= Importador, 4= Propietario de registro sanitario';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux_funcion_producto"."id_alim_producto" IS 'Este campo es la llave primaria de la tabla producto.';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux_funcion_producto"."id_alim_empresa_persona_aux" IS 'Contiene la llave primaria de la tabla alim empresa persona aux';
COMMENT ON TABLE "public"."alim_empresa_persona_aux_funcion_producto" IS 'Tabla donde se almacena las funciones que tiene una empresa o persona natural sobre un determinado producto';
```

## Índices

```sql

```
