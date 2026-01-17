# DDL: ctl_clasificacion_grupo_alimenticio

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS ctl_clasificacion_grupo_alimenticio_id_seq;

CREATE TABLE "public"."ctl_clasificacion_grupo_alimenticio" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_clasificacion_grupo_alimenticio_id_seq'::regclass),
    "nombre" varchar(100) NOT NULL,
    "activo" boolean DEFAULT true,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."ctl_clasificacion_grupo_alimenticio"."id" IS 'Este campo es la llave primaria de la tabla ctl_clasificacion_grupo_alimenticio.';
COMMENT ON COLUMN "public"."ctl_clasificacion_grupo_alimenticio"."nombre" IS 'Este campo contiene el nombre de la clasificacion de grupo alimenticio de los diferentes productos.';
COMMENT ON TABLE "public"."ctl_clasificacion_grupo_alimenticio" IS 'Esta tabla contiene los grupos alimenticios clasificados.';
```

## Índices

```sql

```
