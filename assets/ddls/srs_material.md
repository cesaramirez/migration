# DDL: srs_material (Migración Cross-Database)

Migración de `ctl_material` (BD origen) → `srs_material` (BD destino) via CSV.

---

## Paso 1: Crear Tabla en BD Destino

```sql
DROP TABLE IF EXISTS srs_material CASCADE;

CREATE TABLE srs_material (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre                    VARCHAR(100) NOT NULL,
    legacy_id                 VARCHAR(20) NOT NULL UNIQUE,
    created_at                TIMESTAMP DEFAULT NOW(),
    updated_at                TIMESTAMP DEFAULT NOW(),
    deleted_at                TIMESTAMP
);

CREATE INDEX idx_material_legacy ON srs_material(legacy_id);
CREATE INDEX idx_material_nombre ON srs_material(nombre);
```

---

## Paso 2: Exportar Datos (BD Origen → TablePlus)

```sql
SELECT
    m.nombre,
    CONCAT('MAT-', m.id) AS legacy_id
FROM ctl_material m
WHERE m.activo = TRUE;
```

Guardar como: `/Users/heycsar/tmp/materiales.csv`

---

## Paso 3: Importar en BD Destino (Terminal)

```bash
psql -h HOST -U usuario -d base_datos_destino
```

```sql
\COPY srs_material(nombre, legacy_id) FROM '/Users/heycsar/tmp/materiales.csv' WITH CSV HEADER;
```

---

## Paso 4: Registrar en data_center_tables

```sql
INSERT INTO data_center_tables (id, name, description, columns, deleted_at, created_at, updated_at)
VALUES (
    'e4f5a6b7-c8d9-4e0f-1a2b-3c4d5e6f7a8b',
    'srs_material',
    'Catálogo de materiales para envases de productos',
    '[{"id": "e1f2a3b4-c5d6-4e7f-8a9b-0c1d2e3f4a5b", "name": "id", "type": "UUID"}, {"id": "e2f3a4b5-c6d7-4e8f-9a0b-1c2d3e4f5a6b", "name": "nombre", "type": "STRING"}, {"id": "e3f4a5b6-c7d8-4e9f-0a1b-2c3d4e5f6a7b", "name": "legacy_id", "type": "STRING"}, {"id": "e4f5a6b7-c8d9-4e0f-1a2b-3c4d5e6f7a8c", "name": "created_at", "type": "TIMESTAMP"}, {"id": "e5f6a7b8-c9d0-4e1f-2a3b-4c5d6e7f8a9c", "name": "updated_at", "type": "TIMESTAMP"}, {"id": "e6f7a8b9-c0d1-4e2f-3a4b-5c6d7e8f9a0c", "name": "deleted_at", "type": "TIMESTAMP"}]',
    NULL,
    NOW(),
    NOW()
);
```

---

## Paso 5: Validar

```sql
SELECT COUNT(*) FROM srs_material;
SELECT * FROM srs_material ORDER BY nombre;
```

---

## Resumen de Columnas (6 total)

| Campo | Tipo | Origen |
|-------|------|--------|
| `id` | UUID | generado |
| `nombre` | STRING | nombre |
| `legacy_id` | STRING | MAT-{id} |
| `created_at` | TIMESTAMP | generado |
| `updated_at` | TIMESTAMP | generado |
| `deleted_at` | TIMESTAMP | soft delete |

## Campos Removidos

- `activo` (usado solo como filtro, todos los migrados son activos)
