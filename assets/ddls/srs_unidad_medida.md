# DDL: srs_unidad_medida (Migración Cross-Database)

Migración de `ctl_unidad_medida` (SISAM) → `srs_unidad_medida` (Centro de Datos)

---

## Paso 1: Crear Tabla en Centro de Datos

```sql
DROP TABLE IF EXISTS srs_unidad_medida CASCADE;

CREATE TABLE srs_unidad_medida (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre            TEXT NOT NULL,
    simbolo           TEXT,
    legacy_id         VARCHAR(30) NOT NULL UNIQUE,
    activo            BOOLEAN DEFAULT true,
    attributes        JSONB,
    sys_migrated_at   TIMESTAMP DEFAULT NOW(),
    created_at        TIMESTAMP DEFAULT NOW(),
    updated_at        TIMESTAMP DEFAULT NOW(),
    deleted_at        TIMESTAMP
);

CREATE INDEX idx_unidad_medida_legacy ON srs_unidad_medida(legacy_id);
CREATE INDEX idx_unidad_medida_nombre ON srs_unidad_medida(nombre);
```

---

## Paso 2: Exportar de SISAM

```sql
-- Ejecutar en SISAM
SELECT
    nombre,
    simbolo,
    activo,
    CONCAT('UM-', id) AS legacy_id
FROM ctl_unidad_medida
WHERE activo = true
ORDER BY id;
```

➡️ Exportar a: `/Users/heycsar/tmp/unidades_medida.csv`

---

## Paso 3: Importar en Centro de Datos

```sql
\COPY srs_unidad_medida(nombre, simbolo, activo, legacy_id)
FROM '/Users/heycsar/tmp/unidades_medida.csv'
WITH CSV HEADER;
```

---

## Paso 4: Validar

```sql
SELECT COUNT(*) as total FROM srs_unidad_medida;
SELECT * FROM srs_unidad_medida ORDER BY legacy_id LIMIT 10;
```

---

## Resumen de Columnas

| Campo | Tipo | Origen |
|-------|------|--------|
| `id` | UUID | generado |
| `nombre` | TEXT | nombre |
| `simbolo` | TEXT | simbolo |
| `legacy_id` | VARCHAR(30) | UM-{id} |
| `activo` | BOOLEAN | default true |
| `attributes` | JSONB | - |
| `sys_migrated_at` | TIMESTAMP | NOW() |
| `created_at` | TIMESTAMP | NOW() |
| `updated_at` | TIMESTAMP | NOW() |
| `deleted_at` | TIMESTAMP | soft delete |
