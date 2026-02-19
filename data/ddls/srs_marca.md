# DDL: srs_marca (Migración Cross-Database)

Migración de `ctl_marca` (BD origen SISAM) → `srs_marca` (BD destino Centro de Datos) via CSV.

---

## Paso 1: Crear Tabla en BD Destino

```sql
DROP TABLE IF EXISTS srs_marcas CASCADE;

CREATE TABLE srs_marcas (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre                    TEXT NOT NULL,
    legacy_id                 VARCHAR(20) NOT NULL UNIQUE,
    created_at                TIMESTAMP DEFAULT NOW(),
    updated_at                TIMESTAMP DEFAULT NOW(),
    deleted_at                TIMESTAMP
);

CREATE INDEX idx_marca_legacy ON srs_marca(legacy_id);
CREATE INDEX idx_marca_nombre ON srs_marca(nombre);
```

---

## Paso 2: Exportar Datos (BD Origen → TablePlus)

```sql
SELECT
    m.nombre,
    CONCAT('MARCA-', m.id) AS legacy_id
FROM ctl_marca m
ORDER BY m.id;
```

Guardar como: `/Users/heycsar/tmp/ctl_marca.csv`

---

## Paso 3: Importar en BD Destino (Terminal)

```bash
psql -h HOST -U usuario -d centro_de_datos
```

```sql
\COPY srs_marca(nombre, legacy_id) FROM '/Users/heycsar/tmp/ctl_marca.csv' WITH CSV HEADER;
```

---

## Paso 4: Registrar en data_center_tables

```sql
INSERT INTO data_center_tables (id, name, description, columns, deleted_at, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'srs_marca',
    'Catálogo de marcas comerciales de productos alimenticios',
    '[{"id": "uuid", "name": "id", "type": "UUID"}, {"id": "uuid", "name": "nombre", "type": "STRING"}, {"id": "uuid", "name": "legacy_id", "type": "STRING"}, {"id": "uuid", "name": "created_at", "type": "TIMESTAMP"}, {"id": "uuid", "name": "updated_at", "type": "TIMESTAMP"}, {"id": "uuid", "name": "deleted_at", "type": "TIMESTAMP"}]',
    NULL,
    NOW(),
    NOW()
);
```

---

## Paso 5: Validar

```sql
-- Conteo total
SELECT COUNT(*) FROM srs_marca;

-- Verificar marcas de 1-2 caracteres (son válidas según el cliente)
SELECT nombre, legacy_id
FROM srs_marca
WHERE LENGTH(nombre) <= 2
ORDER BY nombre;

-- Top 10 marcas más usadas (requiere join con relaciones)
SELECT * FROM srs_marca ORDER BY nombre LIMIT 20;
```

---

## Resumen de Columnas (6 total)

| Campo | Tipo | Origen |
|-------|------|--------|
| `id` | UUID | generado |
| `nombre` | STRING | nombre |
| `legacy_id` | STRING | MARCA-{id} |
| `created_at` | TIMESTAMP | generado |
| `updated_at` | TIMESTAMP | generado |
| `deleted_at` | TIMESTAMP | soft delete |

## Campos Removidos de ctl_marca

- `id_modulo` (no relevante para el destino)

## Notas Importantes

### Marcas con nombres cortos
Se detectaron marcas con nombres de 1-2 caracteres (ej: `A`, `C`, `M`, `Z`). Estas son **datos válidos** según confirmación del cliente - no son errores de importación.

### Conteo esperado
- **ctl_marca (origen)**: ~24,289 registros
- **srs_marca (destino)**: mismo conteo
