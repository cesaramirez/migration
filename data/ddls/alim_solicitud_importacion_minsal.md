# DDL: alim_solicitud_importacion_minsal

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_solicitud_importacion_minsal_id_seq;

CREATE TABLE "public"."alim_solicitud_importacion_minsal" (
    "id" int4 NOT NULL DEFAULT nextval('alim_solicitud_importacion_minsal_id_seq'::regclass),
    "estado_solicitud" int4 NOT NULL,
    "justificacion_resolucion" varchar(750),
    "fecha_registro_minsal" date NOT NULL,
    "fecha_resolucion_minsal" date,
    "estado_externo" bpchar(2),
    "fecha_estado_externo" date,
    "id_alim_solicitud_importacion_bcr" int4 NOT NULL,
    "id_ctl_pais" int4 NOT NULL,
    "nombre_tramitador" varchar(100),
    "tipo_documento_tramitador" varchar,
    "numero_documento_tramitador" varchar(14),
    "id_alim_empresa_persona_aux" int4,
    "id_fos_user_user" int4,
    "numero_solicitud_minsal" varchar(30),
    "id_usuario_autorizador" int4,
    "id_ctl_departamento" int4,
    "id_ctl_municipio" int4,
    "direccion_importador" varchar,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."id" IS 'Este campo es la llave primaria de la tabla solicitud_importacion.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."estado_solicitud" IS 'Campo que nos indica el estado de una solicitud (1=iniciada. 2=aprobada, 3=rechazada, 4=cancelada, 5= En proceso).';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."justificacion_resolucion" IS 'Justificacion en caso que la solicitud sea rechazada por parte del minsal';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."fecha_registro_minsal" IS 'Campo donde se almacena la fecha en que el ministerio de salud registro la solicitud.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."fecha_resolucion_minsal" IS 'Campo donde se almacena la fecha en que el ministerio de salud aprobo o denego la solicitud.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."estado_externo" IS 'Campo donde se guarda el estado que otras instituciones han dado a la solicitud; pueden ser: LiquidadoAprobado(LA) o LiquidadoDenegado(LD) y Espera de Respuesta (ER), Sin Estado(SE)';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."fecha_estado_externo" IS 'Campo donde se almacena la fecha en que se recibe un estado externo(BCR) de la solicitud';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."id_alim_solicitud_importacion_bcr" IS 'Contiene la llave primaria de la tabla alim_solicitud_importacion_bcr';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."id_ctl_pais" IS 'Este campo es la llave primaria de la tabla ctl_pais.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."nombre_tramitador" IS 'Guarda el nombre de la persona que realiza el tramite.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."tipo_documento_tramitador" IS 'Guarda el tipo de documento de la persona que realizo el tramite de importacion.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."numero_documento_tramitador" IS 'Guarda el numero de documento de la persona que realizo el tramite de importacion.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."id_alim_empresa_persona_aux" IS 'Contiene la llave primaria de la tabla alim_empresa_persona_aux';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."id_fos_user_user" IS 'Campo utilizado para almacenar el usuario que realizo la solicitud. Esto para solicitudes de importacion con registro.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."numero_solicitud_minsal" IS 'Este campo contiene el codigo de la solicitud de importación';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."id_usuario_autorizador" IS 'Campo utilizado para almacenar el usuario que realizo la aprobacion o rechazo de la solicitud.';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."id_ctl_departamento" IS 'Contiene la llave primaria de la tabla ctl_departamento';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."id_ctl_municipio" IS 'Contiene la llave primaria de la tabla ctl_municipio';
COMMENT ON COLUMN "public"."alim_solicitud_importacion_minsal"."direccion_importador" IS 'Este campo contiene la dirección del importador';
COMMENT ON TABLE "public"."alim_solicitud_importacion_minsal" IS 'Tabla donde se almacena la informacion especifica que concierne al minsal y que puede cambiar de las solicitudes de importacion.';
```

## Índices

```sql
CREATE UNIQUE INDEX alim_solicitud_importacion_minsal_numero_solicitud_minsal_key ON public.alim_solicitud_importacion_minsal USING btree (numero_solicitud_minsal);
```
