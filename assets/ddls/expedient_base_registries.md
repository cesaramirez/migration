```sql
-- Table Definition
CREATE TABLE "public"."expedient_base_registries" (
    "id" uuid NOT NULL,
    "name" text,
    "metadata" json,
    "expedient_base_entity_id" uuid NOT NULL,
    "created_at" timestamp(0),
    "updated_at" timestamp(0),
    "deleted_at" timestamp(0),
    "unique_code" varchar(32) NOT NULL,
    CONSTRAINT "expedient_base_registries_expedient_base_entity_id_foreign" FOREIGN KEY ("expedient_base_entity_id") REFERENCES "public"."expedient_base_entities"("id") ON DELETE CASCADE,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."expedient_base_registries"."id" IS 'Identificador único de la instancia de registro';
COMMENT ON COLUMN "public"."expedient_base_registries"."metadata" IS 'Metadatos adicionales almacenados como pares clave-valor JSON';
COMMENT ON COLUMN "public"."expedient_base_registries"."expedient_base_entity_id" IS 'Clave foránea a la plantilla de entidad base que sigue este registro';
COMMENT ON COLUMN "public"."expedient_base_registries"."deleted_at" IS 'Marca de tiempo de eliminación suave para archivar registros';


-- Indices
CREATE INDEX expedient_base_registries_expedient_base_entity_id_index ON public.expedient_base_registries USING btree (expedient_base_entity_id);
CREATE UNIQUE INDEX expedient_base_registries_unique_code_unique ON public.expedient_base_registries USING btree (unique_code);
```
