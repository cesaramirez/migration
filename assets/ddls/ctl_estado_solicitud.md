# DDL: ctl_estado_solicitud

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS ctl_estado_solicitud_id_seq;

CREATE TABLE "public"."ctl_estado_solicitud" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_estado_solicitud_id_seq'::regclass),
    "nombre" varchar(100) NOT NULL,
    "codigo" varchar(4),
    "id_ctl_modulo" int4,
    "icono" varchar(50),
    "estados_permitidos" varchar,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."ctl_estado_solicitud"."id" IS 'Este campo es la llave primaria de la tabla ctl_estado_solicitud.';
COMMENT ON COLUMN "public"."ctl_estado_solicitud"."nombre" IS 'Este campo almacena los diferentes estados de un solicitud de registro de producto:
1: Aprobada, 2: En proceso, 3: Observaciones, 4: Rechazada';
COMMENT ON COLUMN "public"."ctl_estado_solicitud"."codigo" IS 'Este campo almacena el codigo abreviado del estado de una solicitud';
COMMENT ON COLUMN "public"."ctl_estado_solicitud"."id_ctl_modulo" IS 'Campo que nos indica a que módulo pertenece el estado';
COMMENT ON COLUMN "public"."ctl_estado_solicitud"."icono" IS 'Campo donde se almacena el nombre del ícono a presentar en dashboard de cada uno de los perfiles de usuario.';
COMMENT ON COLUMN "public"."ctl_estado_solicitud"."estados_permitidos" IS 'Estados permitidos para una solicitud';
COMMENT ON TABLE "public"."ctl_estado_solicitud" IS 'Esta tabla posee los estados que puede tener una solicitud de registro de producto.';
```

## Índices

```sql

```
