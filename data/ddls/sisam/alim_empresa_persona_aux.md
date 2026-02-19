# DDL: alim_empresa_persona_aux

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_empresa_persona_aux_id_seq;

CREATE TABLE "public"."alim_empresa_persona_aux" (
    "id" int4 NOT NULL DEFAULT nextval('alim_empresa_persona_aux_id_seq'::regclass),
    "nombre" varchar(200) NOT NULL,
    "nit" varchar(14),
    "correo_electronico" varchar(50),
    "direccion" varchar(150),
    "es_empresa" boolean NOT NULL,
    "id_empresa_persona" int4,
    "id_ctl_pais" int4 NOT NULL,
    "migrado" int4,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_empresa_persona_aux"."id" IS 'Llave primaria de la tabla alim empresa persona aux';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux"."nombre" IS 'Campo que puede contener el nombre comercial de una empresa o nombres y apellidos de una persona natural';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux"."nit" IS 'Se almacena el nit de una empresa o persona natural.';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux"."correo_electronico" IS 'Contiene el email registrado para una determinada empresa o persona natural';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux"."direccion" IS 'Nos almacena la direccion registrada para una empresa o persona natural';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux"."es_empresa" IS 'Campo que nos indica si la tupla contenido es una empresa o persona natural:
TRUE= EMPRESA
FALSE= PERSONA';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux"."id_empresa_persona" IS 'Campo donde se almacena la llave primaria del elemento empresa o persona natural, no se agrega relacion solo campo';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux"."id_ctl_pais" IS 'Se almacena la llave primaria del pais al cual pertenece la empresa o persona natural, no se agrega relacion solo campo';
COMMENT ON COLUMN "public"."alim_empresa_persona_aux"."migrado" IS 'Este campo contiene información de si la empresa/persona ha sido una migración';
COMMENT ON TABLE "public"."alim_empresa_persona_aux" IS 'Tabla auxiliar  donde se guardaran todas las empresas y personas naturales ya sea con registro completo  o registrados al momento de realizar una solicitud de registro sanitario.';
```

## Índices

```sql
CREATE INDEX alim_empresa_persona_aux_idx ON public.alim_empresa_persona_aux USING btree (nit);
```
