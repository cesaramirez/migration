# DDL: alim_producto

## Estructura

```sql
CREATE SEQUENCE IF NOT EXISTS alim_producto_id_seq;

CREATE TABLE "public"."alim_producto" (
    "id" int4 NOT NULL DEFAULT nextval('alim_producto_id_seq'::regclass),
    "nombre" varchar(600) NOT NULL,
    "tipo_producto" int4 NOT NULL,
    "num_partida_arancelaria" bpchar(14),
    "ruta_archivo_ingredientes" varchar(250),
    "fecha_emision_registro" date,
    "fecha_vigencia_registro" date,
    "num_autorizacion_reconocimiento" varchar,
    "num_registro_sanitario" varchar(15),
    "num_certificacion" varchar,
    "estado_registro" int4 NOT NULL,
    "id_ctl_estado_producto" int4,
    "id_ctl_pais" int4 NOT NULL,
    "id_sub_grupo_alimenticio" int4,
    "detalle_reconocimiento" json,
    "marca_temp" varchar,
    "id_rm" int4,
    "ruta_archivo_vineta_reconocimiento" varchar(300),
    "tipo_de_laboratorio" int4 NOT NULL DEFAULT 1,
    PRIMARY KEY ("id")
);
```

## Comentarios

```sql
COMMENT ON COLUMN "public"."alim_producto"."id" IS 'Este campo es la llave primaria de la tabla producto.';
COMMENT ON COLUMN "public"."alim_producto"."nombre" IS 'Este campo contiene el nombre de los productos tanto nacionales como importados.';
COMMENT ON COLUMN "public"."alim_producto"."tipo_producto" IS 'Este campo indica si el producto es nacional, importado de la union aduanera o imprtado de otros paises.
1: Nacional
2: Importado de Union Aduanera
3: Importado de otros paises';
COMMENT ON COLUMN "public"."alim_producto"."num_partida_arancelaria" IS 'Este campo almacena el numero de partida arancelaria de un producto importado.';
COMMENT ON COLUMN "public"."alim_producto"."ruta_archivo_ingredientes" IS 'Este campo almacena la ruta de acceso del archivo que contiene los ingredientes de un producto.';
COMMENT ON COLUMN "public"."alim_producto"."fecha_emision_registro" IS 'Este campo contiene la fecha de emision del registro del producto.';
COMMENT ON COLUMN "public"."alim_producto"."fecha_vigencia_registro" IS 'Este campo contiene la fecha de vigencia del registro del producto.';
COMMENT ON COLUMN "public"."alim_producto"."num_autorizacion_reconocimiento" IS 'Campo donde se almacena el numero de autorizacion del producto de  la union aduanera, luego de que se ha avalado el reconocimiento de este.';
COMMENT ON COLUMN "public"."alim_producto"."num_registro_sanitario" IS 'Este campo contiene el numero de registro sanitario';
COMMENT ON COLUMN "public"."alim_producto"."num_certificacion" IS 'Este campo contiene el numero de certificacion del producto.';
COMMENT ON COLUMN "public"."alim_producto"."estado_registro" IS 'Este campo indica el estado de un registro especifico de la tabla producto. 1=Existe en la base y 2= Borardo Logico de la base.';
COMMENT ON COLUMN "public"."alim_producto"."id_ctl_estado_producto" IS 'Este campo es la llave primaria de la tabla ctl_estado_producto.';
COMMENT ON COLUMN "public"."alim_producto"."id_ctl_pais" IS 'Este campo es la llave primaria de la tabla ctl_pais. Se guarda el pais donde se fabrico el producto.';
COMMENT ON COLUMN "public"."alim_producto"."id_sub_grupo_alimenticio" IS 'Campo que es la llave primaria de la tabla sub_grupo_alimenticio.';
COMMENT ON COLUMN "public"."alim_producto"."detalle_reconocimiento" IS 'Este campo almacena toda la información en un arreglo obtenida de un reconocimiento';
COMMENT ON COLUMN "public"."alim_producto"."ruta_archivo_vineta_reconocimiento" IS 'Este campo almacena la ruta de la viñeta del reconocimiento';
COMMENT ON TABLE "public"."alim_producto" IS 'Esta tabla contiene la informacion de un producto nacional o importado.';
```

## Índices

```sql

```
