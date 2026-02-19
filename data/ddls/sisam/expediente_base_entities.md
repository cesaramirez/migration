```sql
-- Table Definition
CREATE TABLE "public"."expedient_base_entities" (
    "id" uuid NOT NULL,
    "name" varchar(255) NOT NULL,
    "description" text,
    "status" varchar(255) NOT NULL,
    "version" int4 NOT NULL DEFAULT 1,
    "is_current_version" bool NOT NULL DEFAULT true,
    "parent_version_id" uuid,
    "created_at" timestamp(0),
    "updated_at" timestamp(0),
    "deleted_at" timestamp(0),
    "created_by" uuid,
    "updated_by" uuid,
    CONSTRAINT "expedient_base_entities_parent_version_id_foreign" FOREIGN KEY ("parent_version_id") REFERENCES "public"."expedient_base_entities"("id") ON DELETE SET NULL,
    CONSTRAINT "expedient_base_entities_created_by_foreign" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE SET NULL,
    CONSTRAINT "expedient_base_entities_updated_by_foreign" FOREIGN KEY ("updated_by") REFERENCES "public"."users"("id") ON DELETE SET NULL,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."expedient_base_entities"."name" IS 'Unique name identifier for the base entity';
COMMENT ON COLUMN "public"."expedient_base_entities"."description" IS 'Detailed description of the base entity purpose and usage';
COMMENT ON COLUMN "public"."expedient_base_entities"."status" IS 'Current status of the base entity (draft, active, inactive)';
COMMENT ON COLUMN "public"."expedient_base_entities"."version" IS 'Version number of this base entity';
COMMENT ON COLUMN "public"."expedient_base_entities"."is_current_version" IS 'Indicates if this is the currently active version';
COMMENT ON COLUMN "public"."expedient_base_entities"."parent_version_id" IS 'Reference to the parent version of this base entity';


-- Indices
CREATE INDEX expedient_base_entities_status_index ON public.expedient_base_entities USING btree (status);
CREATE INDEX expedient_base_entities_is_current_version_index ON public.expedient_base_entities USING btree (is_current_version);
CREATE INDEX expedient_base_entities_name_is_current_version_index ON public.expedient_base_entities USING btree (name, is_current_version);
```
