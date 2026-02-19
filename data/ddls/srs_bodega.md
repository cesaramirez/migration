# DDL: srs_bodega (Migración Cross-Database)

Migración de `alim_bodega` (BD origen) → `srs_bodega` (BD destino) via CSV.

---

## Paso 1: Crear Tabla en BD Destino

```sql
DROP TABLE IF EXISTS srs_bodega CASCADE;

CREATE TABLE srs_bodega (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo_bodega             VARCHAR(15) NOT NULL UNIQUE,
    nombre                    VARCHAR(100) NOT NULL,
    estado_bodega             VARCHAR(20) NOT NULL,  -- 'Activo' o 'Inactivo' (desnormalizado)
    direccion                 VARCHAR(300) NOT NULL,
    municipio                 VARCHAR(100) NOT NULL, -- Desnormalizado desde ctl_municipio
    departamento              VARCHAR(100),          -- Desnormalizado desde ctl_departamento
    tipo_bodega               VARCHAR(100),          -- Desnormalizado desde ctl_tipo_bodega

    tipo_establecimiento      VARCHAR(20) NOT NULL,  -- 'Bodega', 'Fábrica', 'Tienda Comercial'
    legacy_id                 VARCHAR(20) NOT NULL UNIQUE,
    created_at                TIMESTAMP DEFAULT NOW(),
    updated_at                TIMESTAMP DEFAULT NOW(),
    deleted_at                TIMESTAMP
);

CREATE INDEX idx_bodega_legacy ON srs_bodega(legacy_id);
CREATE INDEX idx_bodega_codigo ON srs_bodega(codigo_bodega);
CREATE INDEX idx_bodega_municipio ON srs_bodega(municipio);
```

---

## Paso 2: Exportar Datos (BD Origen → CSV)

```sql
SELECT
    b.codigo_bodega,
    b.nombre,
    CASE b.estado_bodega
        WHEN 1 THEN 'Activo'
        WHEN 2 THEN 'Inactivo'
        ELSE 'Desconocido'
    END AS estado_bodega,
    b.direccion,
    m.nombre AS municipio,
    d.nombre AS departamento,
    tb.nombre AS tipo_bodega,
    CASE b.tipo_establecimiento
        WHEN 'B' THEN 'Bodega'
        WHEN 'F' THEN 'Fábrica'
        WHEN 'T' THEN 'Tienda Comercial'
        ELSE b.tipo_establecimiento
    END AS tipo_establecimiento,
    CONCAT('BOD-', b.id) AS legacy_id
FROM alim_bodega b
LEFT JOIN ctl_municipio m ON b.id_ctl_municipio = m.id
LEFT JOIN ctl_departamento d ON m.id_ctl_departamento = d.id
LEFT JOIN ctl_tipo_bodega tb ON b.id_ctl_tipo_bodega = tb.id
ORDER BY b.id;
```

Guardar como: `/Users/heycsar/tmp/bodegas.csv`

---

## Paso 3: Importar en BD Destino (Terminal)

```bash
psql -h HOST -U usuario -d base_datos_destino
```

```sql
\COPY srs_bodega(codigo_bodega, nombre, estado_bodega, direccion, municipio, departamento, tipo_bodega, tipo_establecimiento, legacy_id) FROM '/Users/heycsar/tmp/bodegas.csv' WITH CSV HEADER;
```

---

## Paso 4: Registrar en data_center_tables

```sql
INSERT INTO data_center_tables (id, name, description, columns, deleted_at, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'srs_bodega',
    'Bodegas, fábricas y tiendas comerciales de empresas alimenticias',
    '[{"id": "uuid", "name": "id", "type": "UUID"}, {"id": "uuid", "name": "codigo_bodega", "type": "STRING"}, {"id": "uuid", "name": "nombre", "type": "STRING"}, {"id": "uuid", "name": "estado_bodega", "type": "STRING"}, {"id": "uuid", "name": "direccion", "type": "STRING"}, {"id": "uuid", "name": "municipio", "type": "STRING"}, {"id": "uuid", "name": "departamento", "type": "STRING"}, {"id": "uuid", "name": "tipo_bodega", "type": "STRING"}, {"id": "uuid", "name": "tipo_establecimiento", "type": "STRING"}, {"id": "uuid", "name": "legacy_id", "type": "STRING"}]',
    NULL,
    NOW(),
    NOW()
);
```

---

## Paso 5: Validar

```sql
SELECT COUNT(*) FROM srs_bodega;

SELECT municipio, COUNT(*)
FROM srs_bodega
GROUP BY municipio
ORDER BY COUNT(*) DESC
LIMIT 10;

SELECT tipo_bodega, COUNT(*)
FROM srs_bodega
GROUP BY tipo_bodega;
```

---

## Resumen de Columnas (13 total)

| Campo | Tipo | Origen |
|-------|------|--------|
| `id` | UUID | generado |
| `codigo_bodega` | STRING | codigo_bodega |
| `nombre` | STRING | nombre |
| `estado_bodega` | STRING | estado_bodega (1→Activo, 2→Inactivo) |
| `direccion` | STRING | direccion |
| `municipio` | STRING | ctl_municipio.nombre |
| `departamento` | STRING | ctl_departamento.nombre |
| `tipo_bodega` | STRING | ctl_tipo_bodega.nombre |

| `tipo_establecimiento` | STRING | tipo_establecimiento (B→Bodega, F→Fábrica, T→Tienda) |
| `legacy_id` | STRING | BOD-{id} |
| `created_at` | TIMESTAMP | generado |
| `updated_at` | TIMESTAMP | generado |
| `deleted_at` | TIMESTAMP | soft delete |

## Campos Desnormalizados

- `municipio` ← antes era `id_ctl_municipio`
- `departamento` ← derivado de municipio
- `tipo_bodega` ← antes era `id_ctl_tipo_bodega`

- `estado_bodega` ← convertido de int a texto descriptivo
- `tipo_establecimiento` ← convertido de char a texto descriptivo
