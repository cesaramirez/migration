---
description: Migración de srs_marca desde Data Center Dev a Centro de Datos con registro en data_center_tables
---

# Migración Cross-Database: srs_marca

Migración simple de tablas SRS entre bases de datos.

## Credenciales n8n
- **Data Center Dev** → Origen
- **Centro de Datos** → Destino
- **SDT** → Core (data_center_tables)

---

## Paso 1: Crear tabla en destino (Centro de Datos)

```sql
CREATE TABLE IF NOT EXISTS srs_marca (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre      TEXT NOT NULL,
    legacy_id   VARCHAR(20) NOT NULL UNIQUE,
    created_at  TIMESTAMP DEFAULT now(),
    updated_at  TIMESTAMP DEFAULT now(),
    deleted_at  TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_srs_marca_legacy ON srs_marca(legacy_id);
CREATE INDEX IF NOT EXISTS idx_srs_marca_nombre ON srs_marca(nombre);
```

---

## Paso 2: Migrar datos (Data Center Dev → Centro de Datos)

Ejecutar en **Data Center Dev** para exportar:
```sql
\COPY (SELECT id, nombre, legacy_id, created_at, updated_at, deleted_at FROM srs_marca ORDER BY id) TO '/tmp/srs_marca.csv' WITH CSV HEADER;
```

Ejecutar en **Centro de Datos** para importar:
```sql
\COPY srs_marca(id, nombre, legacy_id, created_at, updated_at, deleted_at) FROM '/tmp/srs_marca.csv' WITH CSV HEADER;
```

---

## Paso 3: Registrar en data_center_tables (SDT)

```sql
INSERT INTO data_center_tables (id, name, description, columns, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'srs_marca',
    'Catálogo de marcas comerciales de productos alimenticios',
    '[
        {"name": "id", "type": "UUID"},
        {"name": "nombre", "type": "TEXT"},
        {"name": "legacy_id", "type": "VARCHAR(20)"},
        {"name": "created_at", "type": "TIMESTAMP"},
        {"name": "updated_at", "type": "TIMESTAMP"},
        {"name": "deleted_at", "type": "TIMESTAMP"}
    ]'::jsonb,
    NOW(),
    NOW()
)
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    columns = EXCLUDED.columns,
    updated_at = NOW();
```

---

## Paso 4: Validar

```sql
-- En origen (Data Center Dev)
SELECT COUNT(*) as origen FROM srs_marca;

-- En destino (Centro de Datos)
SELECT COUNT(*) as destino FROM srs_marca;

-- En core (SDT)
SELECT name, description FROM data_center_tables WHERE name = 'srs_marca';
```

---

## Template para Otras Tablas

Para migrar otra tabla, copia este template y reemplaza:

```sql
-- ========================================
-- MIGRAR: [NOMBRE_TABLA]
-- ========================================

-- 1. CREAR EN DESTINO (Centro de Datos)
CREATE TABLE IF NOT EXISTS [NOMBRE_TABLA] (
    -- columnas aquí
);

-- 2. EXPORTAR (Data Center Dev)
\COPY (SELECT * FROM [NOMBRE_TABLA]) TO '/tmp/[NOMBRE_TABLA].csv' WITH CSV HEADER;

-- 3. IMPORTAR (Centro de Datos)
\COPY [NOMBRE_TABLA] FROM '/tmp/[NOMBRE_TABLA].csv' WITH CSV HEADER;

-- 4. REGISTRAR (SDT)
INSERT INTO data_center_tables (id, name, description, columns, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    '[NOMBRE_TABLA]',
    '[DESCRIPCIÓN]',
    '[COLUMNAS_JSON]'::jsonb,
    NOW(), NOW()
)
ON CONFLICT (name) DO UPDATE SET updated_at = NOW();
```
