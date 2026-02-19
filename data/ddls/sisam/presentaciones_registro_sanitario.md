```sql
-- Table Definition
CREATE TABLE presentaciones_registro_sanitario (
    "id" uuid NOT NULL,
    "created_at" timestamp(0),
    "updated_at" timestamp(0),
    "id_media" varchar(255),
    "id_material" varchar(255),
    "id_unidad_medida" varchar(255),
    "unidad" varchar(255),
    PRIMARY KEY ("id")
);
```
