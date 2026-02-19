```sql
-- Table Definition
CREATE TABLE "public"."expedient_base_entity_fields" (
    "id" uuid NOT NULL,
    "expedient_base_entity_id" uuid NOT NULL,
    "name" varchar(255) NOT NULL,
    "field_type" varchar(255) NOT NULL,
    "is_required" bool NOT NULL DEFAULT false,
    "default_value" text,
    "configuration" json,
    "order" int4 NOT NULL DEFAULT 0,
    "created_at" timestamp(0),
    "updated_at" timestamp(0),
    "deleted_at" timestamp(0),
    CONSTRAINT "expedient_base_entity_fields_expedient_base_entity_id_foreign" FOREIGN KEY ("expedient_base_entity_id") REFERENCES "public"."expedient_base_entities"("id") ON DELETE CASCADE,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."expedient_base_entity_fields"."expedient_base_entity_id" IS 'Reference to the parent expedient base entity';
COMMENT ON COLUMN "public"."expedient_base_entity_fields"."name" IS 'Name of the field';
COMMENT ON COLUMN "public"."expedient_base_entity_fields"."field_type" IS 'Type of field (TEXT, NUMBER, DATE, BOOLEAN, etc.)';
COMMENT ON COLUMN "public"."expedient_base_entity_fields"."is_required" IS 'Indicates if this field is required';
COMMENT ON COLUMN "public"."expedient_base_entity_fields"."default_value" IS 'Default value for this field';
COMMENT ON COLUMN "public"."expedient_base_entity_fields"."configuration" IS 'Additional configuration options for the field';
COMMENT ON COLUMN "public"."expedient_base_entity_fields"."order" IS 'Display order of the field within the base entity';


-- Indices
CREATE INDEX expedient_base_entity_fields_expedient_base_entity_id_index ON public.expedient_base_entity_fields USING btree (expedient_base_entity_id);
CREATE INDEX expedient_base_entity_fields_field_type_index ON public.expedient_base_entity_fields USING btree (field_type);
CREATE INDEX expedient_base_entity_fields_expedient_base_entity_id_order_ind ON public.expedient_base_entity_fields USING btree (expedient_base_entity_id, "order");
```
