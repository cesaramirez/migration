# DDL: alim_movimiento_estado_solicitud

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_movimiento_estado_solicitud_id_seq;

CREATE TABLE "public"."alim_movimiento_estado_solicitud" (
    "id" int4 NOT NULL DEFAULT nextval('alim_movimiento_estado_solicitud_id_seq'::regclass),
    "fecha" timestamp without time zone NOT NULL,
    "observacion" varchar(5000),
    "id_ctl_estado_solicitud" int4 NOT NULL,
    "id_alim_solicitud" int4 NOT NULL,
    "id_alim_emp_empleado" int4,
    "id_alim_persona" int4,
    "nota_observacion" varchar(5000),
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_movimiento_estado_solicitud"."id" IS 'Esta tabla es la llave primaria de la tabla historial_estado_solicitud_reg_prod.';
COMMENT ON COLUMN "public"."alim_movimiento_estado_solicitud"."fecha" IS 'Este campo contiene la fecha en que cambio de estado una solicitud de registro de producto.';
COMMENT ON COLUMN "public"."alim_movimiento_estado_solicitud"."observacion" IS 'Este campo contiene una descripcion de las observaciones que se realizan a una solicitud de registro de producto por diverson motivos.';
COMMENT ON COLUMN "public"."alim_movimiento_estado_solicitud"."id_ctl_estado_solicitud" IS 'Este campo es la llave primaria de la tabla ctl_estado_solicitud.';
COMMENT ON COLUMN "public"."alim_movimiento_estado_solicitud"."id_alim_solicitud" IS 'Llave primaria de la tabla solicitud.';
COMMENT ON COLUMN "public"."alim_movimiento_estado_solicitud"."id_alim_emp_empleado" IS 'Llave primaria de la tabla emp_empleado.';
COMMENT ON COLUMN "public"."alim_movimiento_estado_solicitud"."id_alim_persona" IS 'Llave primaria del la tabla alim_empresa.';
COMMENT ON TABLE "public"."alim_movimiento_estado_solicitud" IS 'Esta tabla contiene el historial de una solicitud de registro de productos, indicando los diferentes estados por las cuales ha pasado y en que fecha han sucedido.';
```

## Índices

```sql

```
