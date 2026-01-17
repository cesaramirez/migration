```sql
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS ctl_unidad_medida_id_seq;

-- Table Definition
CREATE TABLE "public"."ctl_unidad_medida" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_unidad_medida_id_seq'::regclass),
    "nombre" varchar(30) NOT NULL,
    "simbolo" varchar(10) NOT NULL,
    "codigo_regional" varchar(4),
    "id_ctl_modulo" int4,
    "activo" bool NOT NULL DEFAULT false,
    CONSTRAINT "ctl_modulo_ctl_unidad_medida_fk" FOREIGN KEY ("id_ctl_modulo") REFERENCES "public"."ctl_modulo"("id_modulo") ON DELETE RESTRICT ON UPDATE RESTRICT,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."ctl_unidad_medida"."id" IS 'Este campo es la llave primaria de la tabla ctl_unidad_medida.';
COMMENT ON COLUMN "public"."ctl_unidad_medida"."nombre" IS 'Este campo posee el nombre de una unidad de medida.';
COMMENT ON COLUMN "public"."ctl_unidad_medida"."simbolo" IS 'Este campo almacena el simbolo de una unidad de medida.';
COMMENT ON COLUMN "public"."ctl_unidad_medida"."codigo_regional" IS 'Este campo almacena el codigo de la región';
COMMENT ON COLUMN "public"."ctl_unidad_medida"."id_ctl_modulo" IS 'Campo que nos indica a que módulo pertenece la unidad de medida';


-- Comments
COMMENT ON TABLE "public"."ctl_unidad_medida" IS 'Esta tabla es un catalogo de las diferentes unidades de medida que se utilizan en los materiales de la presentacion de un producto.';
```
