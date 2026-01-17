```sql
-- Table Definition
CREATE TABLE "public"."paises" (
    "id" uuid NOT NULL,
    "created_at" timestamp(0),
    "updated_at" timestamp(0),
    "nombre" varchar(255),
    "iso_2_code" varchar(255),
    "iso_3_code" varchar(255),
    "iso_number" int4,
    "activo" bool,
    "reconocimiento_mutuo_centroamericano" bool,
    PRIMARY KEY ("id")
);
```
