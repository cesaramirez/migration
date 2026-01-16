```sql
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS alim_certificado_libre_venta_id_seq;

-- Table Definition
CREATE TABLE "public"."alim_certificado_libre_venta" (
    "id" int4 NOT NULL DEFAULT nextval('alim_certificado_libre_venta_id_seq'::regclass),
    "cod_clv" varchar NOT NULL,
    "tipo_clv" int4 NOT NULL,
    "id_ctl_pais" int4 NOT NULL,
    "fecha_emision" date NOT NULL,
    "ruta_archivo_clv" varchar(250),
    "autoridad_sanitaria_emite" varchar(250) NOT NULL,
    "id_alim_empresa" int4,
    "id_alim_persona" int4,
    "usuario" varchar,
    "fecha_registro" date,
    "id_ctl_pais_destino" int4,
    CONSTRAINT "id_alim_persona" FOREIGN KEY ("id_alim_persona") REFERENCES "public"."alim_persona"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT "id_alim_empresa_fk" FOREIGN KEY ("id_alim_empresa") REFERENCES "public"."alim_empresa"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT "ctl_pais_destino_alim_certificado_libre_venta_fk" FOREIGN KEY ("id_ctl_pais_destino") REFERENCES "public"."ctl_pais"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT "ctl_pais_alim_certificado_libre_venta_fk" FOREIGN KEY ("id_ctl_pais") REFERENCES "public"."ctl_pais"("id") ON DELETE RESTRICT ON UPDATE RESTRICT,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."id" IS 'Esta campo es la llave primaria de la tabla certificado_libre_venta.';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."cod_clv" IS 'Este campo contiene el codigo del certificado de libre venta emitido.';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."tipo_clv" IS 'Este campo indica si el certificado es nacional o del exterior.';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."id_ctl_pais" IS 'Este campo es la llave primaria de la tabla ctl_pais. Se guarda el pais de procedencia del clv que es lo  mismo al pais de precedencia del producto.';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."fecha_emision" IS 'Esta campo contiene la fecha en que fue emitido el certificado de libre venta nacional, esta fecha es por cada clv.';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."ruta_archivo_clv" IS 'Este campo almacena la ruta de acceso del archivo que contiene el clv de un producto importado';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."autoridad_sanitaria_emite" IS 'Campo para almacenar la autoridad sanitaria que ha emitido el clv de un producto que ha sido importado.';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."id_alim_empresa" IS 'Relacion con la empresa que registro el certificado de libre venta';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."id_alim_persona" IS 'Campo para almacenar el id de la persona natural que registro el certificado de libre venta';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."usuario" IS 'Usuario que registro el certificado de libre venta';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."fecha_registro" IS 'Este campo contiene la fecha en la cual se registró el clv';
COMMENT ON COLUMN "public"."alim_certificado_libre_venta"."id_ctl_pais_destino" IS 'Campo donde se almacenará el id del país al cual se enviará el certificado.';


-- Comments
COMMENT ON TABLE "public"."alim_certificado_libre_venta" IS 'Esta tabla contiene la informacion de los certificados de libre venta que se emiten a nivel nacional, por parte de la Direccion de Salud Ambiental y los que se registran provenientes del extranjero.';
```
