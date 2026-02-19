# DDL: srs_material (Migración Cross-Database)

Migración de `ctl_material` (SISAM) → `srs_material` (Centro de Datos)

---

## Paso 1: Crear Tabla en Centro de Datos

```sql
DROP TABLE IF EXISTS srs_material CASCADE;

CREATE TABLE srs_material (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre            TEXT NOT NULL,
    activo            BOOLEAN DEFAULT true,
    attributes        JSONB,
    legacy_id         VARCHAR(30) NOT NULL UNIQUE,
    sys_migrated_at   TIMESTAMP DEFAULT NOW(),
    created_at        TIMESTAMP DEFAULT NOW(),
    updated_at        TIMESTAMP DEFAULT NOW(),
    deleted_at        TIMESTAMP
);

CREATE INDEX idx_material_legacy ON srs_material(legacy_id);
CREATE INDEX idx_material_nombre ON srs_material(nombre);
```

---

## Paso 2: Exportar de SISAM

```sql
-- Ejecutar en SISAM
SELECT
    nombre,
    activo,
    CONCAT('MAT-', id) AS legacy_id
FROM ctl_material
WHERE activo = true
ORDER BY id;
```

➡️ Exportar a: `/Users/heycsar/tmp/materiales.csv`

---

## Paso 3: Importar en Centro de Datos

```sql
\COPY srs_material(nombre, activo, legacy_id)
FROM '/Users/heycsar/tmp/materiales.csv'
WITH CSV HEADER;
```

---

## Paso 4: Validar

```sql
SELECT COUNT(*) as total FROM srs_material;
SELECT * FROM srs_material ORDER BY legacy_id LIMIT 10;
```

---

## Resumen de Columnas

| Campo | Tipo | Origen |
|-------|------|--------|
| `id` | UUID | generado |
| `nombre` | TEXT | nombre |
| `legacy_id` | VARCHAR(30) | MAT-{id} |
| `activo` | BOOLEAN | default true |
| `attributes` | JSONB | - |
| `sys_migrated_at` | TIMESTAMP | NOW() |
| `created_at` | TIMESTAMP | NOW() |
| `updated_at` | TIMESTAMP | NOW() |
| `deleted_at` | TIMESTAMP | soft delete |
