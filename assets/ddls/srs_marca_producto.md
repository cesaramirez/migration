# DDL: srs_marca_producto (Migración Cross-Database)

Migración de `alim_marca_producto` (BD origen SISAM) → `srs_marca_producto` (BD destino Centro de Datos) via CSV.

**Alternativa**: Las relaciones también pueden ir a `expedient_base_registry_relation` en Core.

---

## Paso 1: Crear Tabla en BD Destino

```sql
DROP TABLE IF EXISTS srs_marca_producto CASCADE;

CREATE TABLE srs_marca_producto (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_legacy_id        VARCHAR(20) NOT NULL,     -- PRD-{id}
    marca_legacy_id           VARCHAR(20) NOT NULL,     -- MARCA-{id}
    estado                    VARCHAR(20) DEFAULT 'ACTIVO',  -- ACTIVO | INACTIVO
    created_at                TIMESTAMP DEFAULT NOW(),
    updated_at                TIMESTAMP DEFAULT NOW(),
    deleted_at                TIMESTAMP,

    UNIQUE(producto_legacy_id, marca_legacy_id)
);

CREATE INDEX idx_marca_prod_producto ON srs_marca_producto(producto_legacy_id);
CREATE INDEX idx_marca_prod_marca ON srs_marca_producto(marca_legacy_id);
```

---

## Paso 2: Exportar Datos (BD Origen → TablePlus)

```sql
-- Export con deduplicación y filtro de productos válidos
SELECT DISTINCT
    CONCAT('PRD-', mp.id_alim_producto) AS producto_legacy_id,
    CONCAT('MARCA-', mp.id_ctl_marca) AS marca_legacy_id,
    CASE MAX(mp.estado_marca_producto)
        WHEN 1 THEN 'ACTIVO'
        WHEN 2 THEN 'INACTIVO'
        ELSE 'ACTIVO'
    END AS estado
FROM alim_marca_producto mp
JOIN alim_producto p ON p.id = mp.id_alim_producto
WHERE p.estado_registro = 1
  AND p.fecha_emision_registro IS NOT NULL
  AND p.fecha_vigencia_registro IS NOT NULL
  AND p.num_registro_sanitario IS NOT NULL
GROUP BY mp.id_alim_producto, mp.id_ctl_marca
ORDER BY mp.id_alim_producto, mp.id_ctl_marca;
```

Guardar como: `/Users/heycsar/tmp/alim_marca_producto.csv`

---

## Paso 3: Importar en BD Destino (Terminal)

```bash
psql -h HOST -U usuario -d centro_de_datos
```

```sql
\COPY srs_marca_producto(producto_legacy_id, marca_legacy_id, estado) FROM '/Users/heycsar/tmp/alim_marca_producto.csv' WITH CSV HEADER;
```

---

## Paso 4: Validar

```sql
-- Conteo total de relaciones
SELECT COUNT(*) FROM srs_marca_producto;

-- Productos con más marcas
SELECT producto_legacy_id, COUNT(*) as num_marcas
FROM srs_marca_producto
GROUP BY producto_legacy_id
ORDER BY num_marcas DESC
LIMIT 10;

-- Marcas más populares
SELECT marca_legacy_id, COUNT(*) as en_productos
FROM srs_marca_producto
GROUP BY marca_legacy_id
ORDER BY en_productos DESC
LIMIT 10;

-- Distribución de marcas por producto
SELECT
    CASE
        WHEN cnt = 1 THEN '1 marca'
        WHEN cnt BETWEEN 2 AND 5 THEN '2-5 marcas'
        WHEN cnt BETWEEN 6 AND 10 THEN '6-10 marcas'
        WHEN cnt > 10 THEN '10+ marcas'
    END as rango,
    COUNT(*) as productos
FROM (
    SELECT producto_legacy_id, COUNT(*) as cnt
    FROM srs_marca_producto
    GROUP BY producto_legacy_id
) sub
GROUP BY 1
ORDER BY 1;
```

---

## Resumen de Columnas (7 total)

| Campo | Tipo | Origen |
|-------|------|--------|
| `id` | UUID | generado |
| `producto_legacy_id` | STRING | PRD-{id_alim_producto} |
| `marca_legacy_id` | STRING | MARCA-{id_ctl_marca} |
| `estado` | STRING | estado_marca_producto (1→ACTIVO, 2→INACTIVO) |
| `created_at` | TIMESTAMP | generado |
| `updated_at` | TIMESTAMP | generado |
| `deleted_at` | TIMESTAMP | soft delete |

## Campos Removidos de alim_marca_producto

- `id` (llave primaria, reemplazada por UUID)

## Anomalías Documentadas

### Productos con muchas marcas
Se detectaron 3 productos con 66 marcas cada uno (son datos válidos del sistema origen):
- PRD-90793: 66 marcas
- PRD-88586: 66 marcas
- PRD-91461: 66 marcas

### Marcas de caracteres cortos
Las marcas con nombres de 1-2 caracteres (A, C, M, etc.) son **datos válidos** - confirmado por el cliente.

## Conteos Esperados

| Métrica | Valor |
|---------|-------|
| Total relaciones (con duplicados) | ~113,964 |
| Total relaciones únicas | ~113,000 (aproximado) |
| Productos con marca | ~107,145 |
| Marcas en uso | ~15,684 |
