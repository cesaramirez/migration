# DDL: alim_solicitud_importacion_bcr

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_solicitud_importacion_bcr_id_seq;

CREATE TABLE "public"."alim_solicitud_importacion_bcr" (
    "id" int4 NOT NULL DEFAULT nextval('alim_solicitud_importacion_bcr_id_seq'::regclass),
    "fecha_registro_bcr" date NOT NULL,
    "numero_solicitud" varchar(30),
    "tipo_solicitud" bpchar(1),
    "nombre_importador" varchar(156),
    "nit_importador" varchar(20),
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_solicitud_importacion_bcr"."id" IS 'Llave primaria de la tabla';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_bcr"."fecha_registro_bcr" IS 'Campo donde se almacena la fecha en que el BCR registro la solicitud.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_bcr"."numero_solicitud" IS 'Campo donde se almacena el numero de solicitud que envia el BCR cuando se registra la solcitud.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_bcr"."tipo_solicitud" IS 'Campo donde se almacena el tipo de solicitud;
1: Autorización de solicitud con registro.
2: Autorización de solicitud especial.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_bcr"."nombre_importador" IS 'Almacena el nombre de la empresa o persona natural(nacional o extranjera); Esta es la informacion de la figura de importador para el BCR. Este campo se llenara solo en caso de una solicitud especial.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_bcr"."nit_importador" IS 'Almacena el tipo de documento de la empresa o persona natural(nacional o extranjera); esta es la informacion de la figura de importador para el BCR. Este campo se llenara solo en caso de una solicitud especial.';
COMMENT ON TABLE "public"."alim_solicitud_importacion_bcr" IS 'Tabla donde se almacena la informacion general y que no ha de modificarse de las solicitudes de importacion.';
```

## Índices

```sql

```
