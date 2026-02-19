# DDL: ctl_funcion_empresa_persona

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS ctl_funcion_empresa_persona_id_seq;

CREATE TABLE "public"."ctl_funcion_empresa_persona" (
    "id" int4 NOT NULL DEFAULT nextval('ctl_funcion_empresa_persona_id_seq'::regclass),
    "funcion" varchar(50) NOT NULL,
    "codigo" varchar(4),
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."ctl_funcion_empresa_persona"."id" IS 'Llave primaria de la tabla ctl_function_empresa_persona';
COMMENT ON COLUMN "public"."ctl_funcion_empresa_persona"."funcion" IS 'Funcion de la empresa o persona sobre un determinado producto:
1=Dueña, 2=fabricante,3=enavasador,4=distribuidor';
COMMENT ON COLUMN "public"."ctl_funcion_empresa_persona"."codigo" IS 'Este campo almacena el codigo de la funcion de la empresa';
COMMENT ON TABLE "public"."ctl_funcion_empresa_persona" IS 'Catalogo que nos almacena el tipo de Funcion(relacion) que una empresa o persona natural  tiene sobre un determinado producto: 1=Dueña, 2=fabricante,3=enavasador,4=distribuidor';
```

## Índices

```sql

```
