# DDL: alim_bodega

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_bodega_id_seq;

CREATE TABLE "public"."alim_bodega" (
    "id" int4 NOT NULL DEFAULT nextval('alim_bodega_id_seq'::regclass),
    "codigo_bodega" varchar(15) NOT NULL,
    "nombre" varchar(100) NOT NULL,
    "estado_bodega" int4 NOT NULL,
    "direccion" varchar(300) NOT NULL,
    "id_ctl_municipio" int4 NOT NULL,
    "id_ctl_tipo_bodega" int4,
    "id_ctl_grupo_bodega" int4,
    "tipo_establecimiento" varchar(1) NOT NULL,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_bodega"."id" IS 'Este campo es el llave primaria de la tabla bodega.';
COMMENT ON COLUMN "public"."alim_bodega"."codigo_bodega" IS 'Campo que contiene el codigo de una determinada bodega, el cual identificara de forma unica a cada una de estas.';
COMMENT ON COLUMN "public"."alim_bodega"."nombre" IS 'Este campo contiene los nombres de las bodegas.';
COMMENT ON COLUMN "public"."alim_bodega"."estado_bodega" IS 'Campo que almacena el estado de una determinada bodega:
1: Actico, 2: Inactivo';
COMMENT ON COLUMN "public"."alim_bodega"."direccion" IS 'Este campo contiene la direccion de las bodegas.';
COMMENT ON COLUMN "public"."alim_bodega"."id_ctl_municipio" IS 'Este campo es la llave primaria de la tabla ctl_municipio.';
COMMENT ON COLUMN "public"."alim_bodega"."id_ctl_tipo_bodega" IS 'Este campo es la llaver primaria de la tabla ctl_tipo_bodega.';
COMMENT ON COLUMN "public"."alim_bodega"."id_ctl_grupo_bodega" IS 'Este campo es la llave primaria de la tabla ctl_grupo_establecimiento.';
COMMENT ON COLUMN "public"."alim_bodega"."tipo_establecimiento" IS 'Campo que nos indica el tipo de establecimiento:
'B' => 'Bodega', 'F' => 'Fábrica', 'T'=>'Tienda Comercial'';
COMMENT ON TABLE "public"."alim_bodega" IS 'Esta tabla contiene la informacion de las bodegas que posee una empresa. Una empresa puede tener cero o mas bodegas.';
```

## Índices

```sql
CREATE UNIQUE INDEX alim_bodega_idx ON public.alim_bodega USING btree (codigo_bodega);
```
