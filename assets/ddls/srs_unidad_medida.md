# DDL: srs_unidad_medida (Migración Cross-Database)

Migración de `ctl_unidad_medida` (BD origen) → `srs_unidad_medida` (BD destino) via CSV.

---

## Paso 1: Crear Tabla en BD Destino

```sql
DROP TABLE IF EXISTS srs_unidad_medida CASCADE;

CREATE TABLE srs_unidad_medida (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre                    VARCHAR(100) NOT NULL,
    simbolo                   VARCHAR(20) NOT NULL,
    legacy_id                 VARCHAR(20) NOT NULL UNIQUE,
    created_at                TIMESTAMP DEFAULT NOW(),
    updated_at                TIMESTAMP DEFAULT NOW(),
    deleted_at                TIMESTAMP
);

CREATE INDEX idx_unidad_legacy ON srs_unidad_medida(legacy_id);
CREATE INDEX idx_unidad_nombre ON srs_unidad_medida(nombre);
CREATE INDEX idx_unidad_simbolo ON srs_unidad_medida(simbolo);
```

---

## Paso 2: Exportar Datos (BD Origen → TablePlus)

```sql
SELECT
    um.nombre,
    um.simbolo,
    CONCAT('UM-', um.id) AS legacy_id
FROM ctl_unidad_medida um
WHERE um.activo = TRUE;
```

Guardar como: `/Users/heycsar/tmp/unidades_medida.csv`

---

## Paso 3: Importar en BD Destino (Terminal)

```bash
psql -h HOST -U usuario -d base_datos_destino
```

```sql
\COPY srs_unidad_medida(nombre, simbolo, legacy_id) FROM '/Users/heycsar/tmp/unidades_medida.csv' WITH CSV HEADER;
```

---

## Paso 4: Registrar en data_center_tables

```sql
INSERT INTO data_center_tables (id, name, description, columns, deleted_at, created_at, updated_at)
VALUES (
    'f5a6b7c8-d9e0-4f1a-2b3c-4d5e6f7a8b9c',
    'srs_unidad_medida',
    'Catálogo de unidades de medida para presentaciones de productos',
    '[{"id": "f1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c", "name": "id", "type": "UUID"}, {"id": "f2a3b4c5-d6e7-4f8a-9b0c-1d2e3f4a5b6c", "name": "nombre", "type": "STRING"}, {"id": "f3a4b5c6-d7e8-4f9a-0b1c-2d3e4f5a6b7c", "name": "simbolo", "type": "STRING"}, {"id": "f4a5b6c7-d8e9-4f0a-1b2c-3d4e5f6a7b8c", "name": "legacy_id", "type": "STRING"}, {"id": "f5a6b7c8-d9e0-4f1a-2b3c-4d5e6f7a8b9d", "name": "created_at", "type": "TIMESTAMP"}, {"id": "f6a7b8c9-d0e1-4f2a-3b4c-5d6e7f8a9b0d", "name": "updated_at", "type": "TIMESTAMP"}, {"id": "f7a8b9c0-d1e2-4f3a-4b5c-6d7e8f9a0b1d", "name": "deleted_at", "type": "TIMESTAMP"}]',
    NULL,
    NOW(),
    NOW()
);
```

---

## Paso 5: Validar

```sql
SELECT COUNT(*) FROM srs_unidad_medida;
SELECT * FROM srs_unidad_medida ORDER BY nombre;
```

---

## Resumen de Columnas (7 total)

| Campo | Tipo | Origen |
|-------|------|--------|
| `id` | UUID | generado |
| `nombre` | STRING | nombre |
| `simbolo` | STRING | simbolo |
| `legacy_id` | STRING | UM-{id} |
| `created_at` | TIMESTAMP | generado |
| `updated_at` | TIMESTAMP | generado |
| `deleted_at` | TIMESTAMP | soft delete |

## Campos Removidos

- `codigo_regional`
- `id_ctl_modulo`
- `activo` (usado solo como filtro)
