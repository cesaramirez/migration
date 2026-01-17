``` sql
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS ctl_material_id_seq;

-- Table Definition
CREATE TABLE "public"."ctl_material" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_material_id_seq'::regclass),
    "nombre" varchar(30) NOT NULL,
    "activo" bool NOT NULL DEFAULT false,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."ctl_material"."id" IS 'Este campo es la llave primaria de la tabla ctl_material.';
COMMENT ON COLUMN "public"."ctl_material"."nombre" IS 'Este campo contiene el nombre de los diferentes materiales que se usa en una presentacion de un producto.';


-- Comments
COMMENT ON TABLE "public"."ctl_material" IS 'Esta tabla es un catalogo de que contiene los tipos de materiales de los que esta fabricado una presentacion de un producto.';
```
