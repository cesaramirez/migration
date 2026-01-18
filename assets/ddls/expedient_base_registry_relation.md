```sql
-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS expedient_base_registry_relation_id_seq;

-- Table Definition
CREATE TABLE "public"."expedient_base_registry_relation" (
    "id" int8 NOT NULL DEFAULT nextval('expedient_base_registry_relation_id_seq'::regclass),
    "expedient_base_registry_id" uuid NOT NULL,
    "relation_id" uuid NOT NULL,
    "relation_type" varchar(255) NOT NULL,
    "created_at" timestamp(0),
    "updated_at" timestamp(0),
    "reference_name" varchar(255),
    "source" varchar(255),
    "expedient_base_entity_field_id" uuid,
    "display_value" varchar(255),
    CONSTRAINT "expedient_base_registry_relation_expedient_base_entity_field_id" FOREIGN KEY ("expedient_base_entity_field_id") REFERENCES "public"."expedient_base_entity_fields"("id") ON DELETE SET NULL,
    CONSTRAINT "expedient_base_registry_relation_expedient_base_registry_id_for" FOREIGN KEY ("expedient_base_registry_id") REFERENCES "public"."expedient_base_registries"("id"),
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."expedient_base_registry_relation"."expedient_base_registry_id" IS 'ID de relacion con el expediente base';
COMMENT ON COLUMN "public"."expedient_base_registry_relation"."relation_id" IS 'ID del registro con el cual hace relacion (ID del registro de centro de datos o el ID del registro de expediente)';
COMMENT ON COLUMN "public"."expedient_base_registry_relation"."relation_type" IS 'tipo de relacion (expedient_base_registry o data_center, o cualquier otro tipo que vaya surgiendo)';
COMMENT ON COLUMN "public"."expedient_base_registry_relation"."reference_name" IS 'Nombre de la columna de centro de datos (si es una relacion con el centro de datos)';


-- Indices
CREATE INDEX ebr_relation_field_idx ON public.expedient_base_registry_relation USING btree (expedient_base_registry_id, expedient_base_entity_field_id);
CREATE INDEX ebr_relation_table_source_idx ON public.expedient_base_registry_relation USING btree (reference_name, source);
```
