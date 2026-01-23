# DDL: alim_solicitud

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_solicitud_id_seq;

CREATE TABLE "public"."alim_solicitud" (
    "id" int4 NOT NULL DEFAULT nextval('alim_solicitud_id_seq'::regclass),
    "codigo_solicitud" varchar NOT NULL,
    "fecha_solicitud" date NOT NULL,
    "motivo_cambio" varchar(250),
    "ruta_archivo_escritura_publica_traspaso" varchar,
    "id_ctl_tipo_solicitud" int4 NOT NULL,
    "id_alim_empresa" int4,
    "id_alim_persona" int4,
    "num_certificacion" varchar(5),
    "id_usuario" int4,
    "ruta_archivo_soporte_pago" varchar(250),
    "id_alim_persona_firma" int4,
    "pagador" varchar(100),
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_solicitud"."id" IS 'Llave primaria de la tabla solicitud.';
COMMENT ON COLUMN "public"."alim_solicitud"."codigo_solicitud" IS 'Este campo almacena el codigo de la solicitud de registro de producto.';
COMMENT ON COLUMN "public"."alim_solicitud"."fecha_solicitud" IS 'Este campo almacena la fecha y hora en que se creo la solicitud.';
COMMENT ON COLUMN "public"."alim_solicitud"."motivo_cambio" IS 'Campo donde se guarda el motivo del porque se realiza una solicitud especial.';
COMMENT ON COLUMN "public"."alim_solicitud"."ruta_archivo_escritura_publica_traspaso" IS 'campo que almacena la ruta donde se almacenara la escritura publica de traspaso, cuando se trate de una solicitud de traspaso de registro.';
COMMENT ON COLUMN "public"."alim_solicitud"."id_ctl_tipo_solicitud" IS 'Este campo es la llave primaria de la tabla ctl_tipo_solicitud.';
COMMENT ON COLUMN "public"."alim_solicitud"."id_alim_empresa" IS 'Este campo es la llave primaria de la tabla empresa.';
COMMENT ON COLUMN "public"."alim_solicitud"."id_alim_persona" IS 'Llave primaria del la tabla alim_persona';
COMMENT ON COLUMN "public"."alim_solicitud"."id_usuario" IS 'Contiene la llave primaria de tabla fos user user, es el id del usuario que realiza la solicitud';
COMMENT ON COLUMN "public"."alim_solicitud"."ruta_archivo_soporte_pago" IS 'Campo donde se almacena la ruta del comprobante de pago de la solicitud, esto en el caso que el pago se realice de forma manual.';
COMMENT ON COLUMN "public"."alim_solicitud"."id_alim_persona_firma" IS 'Contiene la llave primaria de la tabla alim_person, es el id de la persona que firma la solicitud';
COMMENT ON COLUMN "public"."alim_solicitud"."pagador" IS 'Campo donde se almacenará a nombre de quien saldrá el mandamiento de pago, luego esto se guardará en la tabla de pago.';
COMMENT ON TABLE "public"."alim_solicitud" IS 'Esta tabla contiene la informacion de las solicitudes que las empresas realizan para registrar sus productos, tanto nacionales como de importacion.';
```

## Índices

```sql
CREATE UNIQUE INDEX solicitud_idx ON public.alim_solicitud USING btree (codigo_solicitud);
```
