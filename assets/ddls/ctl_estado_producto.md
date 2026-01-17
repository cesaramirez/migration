```sql
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS ctl_estado_producto_id_seq;

-- Table Definition
CREATE TABLE "public"."ctl_estado_producto" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_estado_producto_id_seq'::regclass),
    "nombre" varchar(30) NOT NULL,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."ctl_estado_producto"."id" IS 'Este campo es la llave primaria de la tabla ctl_estado_producto.';
COMMENT ON COLUMN "public"."ctl_estado_producto"."nombre" IS 'Este campo contiene el nombre de los estados del registro sanitario de un producto:
1: vigente, 2: Bloqueado, 3: vencido';


-- Comments
COMMENT ON TABLE "public"."ctl_estado_producto" IS 'Esta tabla es un catalogo de los estados en que se encuentra un producto.';
```
