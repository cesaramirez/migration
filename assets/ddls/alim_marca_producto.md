```sql
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS alim_marca_producto_id_seq;

-- Table Definition
CREATE TABLE "public"."alim_marca_producto" (
    "id" int4 NOT NULL DEFAULT nextval('alim_marca_producto_id_seq'::regclass),
    "estado_marca_producto" int4,
    "id_ctl_marca" int4 NOT NULL,
    "id_alim_producto" int4 NOT NULL,
    CONSTRAINT "alim_producto_alim_marca_producto_fk" FOREIGN KEY ("id_alim_producto") REFERENCES "public"."alim_producto"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "ctl_marca_empresa_producto_ctl_marca_fk" FOREIGN KEY ("id_ctl_marca") REFERENCES "public"."ctl_marca"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."alim_marca_producto"."id" IS 'Campo que es la llave primaria de la tabla ctl_marca_producto.';
COMMENT ON COLUMN "public"."alim_marca_producto"."estado_marca_producto" IS 'Campo donde se especifica el estado de una determinada marca dentro del catalogo; puede ser: 1=activo o 2=inactivo.';
COMMENT ON COLUMN "public"."alim_marca_producto"."id_ctl_marca" IS 'Este campo es la llave primaria de la tabla ctl_marca.';
COMMENT ON COLUMN "public"."alim_marca_producto"."id_alim_producto" IS 'Este campo es la llave primaria de la tabla producto.';


-- Comments
COMMENT ON TABLE "public"."alim_marca_producto" IS 'Esta tabla relaciona las diferentes marcas que puede poseer un producto en especifico,';


-- Indices
CREATE UNIQUE INDEX pk_alim_marca_producto ON public.alim_marca_producto USING btree (id);
```
