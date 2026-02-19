# DDL: ctl_tipo_riesgo

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS ctl_tipo_riesgo_id_seq;

CREATE TABLE "public"."ctl_tipo_riesgo" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_tipo_riesgo_id_seq'::regclass),
    "nombre" bpchar(1) NOT NULL,
    "descripcion" varchar(500) NOT NULL,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."ctl_tipo_riesgo"."id" IS 'Este campo es la llave primaria de la tabla ctl_tipo_riesgo.';
COMMENT ON COLUMN "public"."ctl_tipo_riesgo"."nombre" IS 'Este campo almacena el tipo de riesgo de un producto.';
COMMENT ON COLUMN "public"."ctl_tipo_riesgo"."descripcion" IS 'Este campo almacena la descripcion de un tipo de riesgo de un producto.';
COMMENT ON TABLE "public"."ctl_tipo_riesgo" IS 'Esta tabla contiene los tipos de riesgo que puede tener un producto especifico.';
```

## Índices

```sql
CREATE UNIQUE INDEX ctl_tipo_riesgo_idx ON public.ctl_tipo_riesgo USING btree (nombre);
```
