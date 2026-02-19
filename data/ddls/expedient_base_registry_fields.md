```sql
-- Table Definition
CREATE TABLE "public"."expedient_base_registry_fields" (
    "id" uuid NOT NULL,
    "expedient_base_registry_id" uuid NOT NULL,
    "expedient_base_entity_field_id" uuid NOT NULL,
    "value" text,
    "created_at" timestamp(0),
    "updated_at" timestamp(0),
    "deleted_at" timestamp(0),
    "expiration_at" timestamp(0),
    "notification_at" timestamp(0),
    "expired_at" timestamp(0),
    "notified_at" timestamp(0),
    "replacement_value" varchar(255),
    "timer_config" jsonb,
    "selected_options" jsonb,
    CONSTRAINT "expedient_base_registry_fields_expedient_base_entity_field_id_f" FOREIGN KEY ("expedient_base_entity_field_id") REFERENCES "public"."expedient_base_entity_fields"("id") ON DELETE CASCADE,
    CONSTRAINT "expedient_base_registry_fields_expedient_base_registry_id_forei" FOREIGN KEY ("expedient_base_registry_id") REFERENCES "public"."expedient_base_registries"("id") ON DELETE CASCADE,
    PRIMARY KEY ("id")
);

-- Column Comment
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."id" IS 'Identificador único del registro de valor de campo';
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."expedient_base_registry_id" IS 'Clave foránea a la instancia de registro padre';
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."expedient_base_entity_field_id" IS 'Clave foránea a la definición de campo de la plantilla';
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."value" IS 'Valor real del campo almacenado como texto, validación de tipo basada en la definición de campo';
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."deleted_at" IS 'Marca de tiempo de eliminación suave para historial de valores de campo';
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."expiration_at" IS 'Planned expiration date of the value';
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."notification_at" IS 'Planned notification date before expiration';
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."expired_at" IS 'Timestamp when expiration job was executed';
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."notified_at" IS 'Timestamp when notification job was executed';
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."replacement_value" IS 'Replacement value applied when expiration occurs';
COMMENT ON COLUMN "public"."expedient_base_registry_fields"."timer_config" IS 'Timer configuration in JSON format';


-- Indices
CREATE INDEX expedient_base_registry_fields_expedient_base_registry_id_index ON public.expedient_base_registry_fields USING btree (expedient_base_registry_id);
CREATE INDEX expedient_base_registry_fields_expedient_base_entity_field_id_i ON public.expedient_base_registry_fields USING btree (expedient_base_entity_field_id);
CREATE INDEX ebrf_pending_notification_idx ON public.expedient_base_registry_fields USING btree (notification_at) WHERE ((notification_at IS NOT NULL) AND (notified_at IS NULL));
CREATE INDEX ebrf_pending_expiration_idx ON public.expedient_base_registry_fields USING btree (expiration_at) WHERE ((expiration_at IS NOT NULL) AND (expired_at IS NULL));
```
