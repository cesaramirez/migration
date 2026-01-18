# Guía de Migración: Relaciones Producto → Marca

**Proyecto**: Migración SISAM → SDT
**Fecha**: 2026-01-18
**Patrón**: Igual que bodega → `expedient_base_registry_relation`

---

## Resumen

| Recurso | Ubicación | Estado |
|---------|-----------|--------|
| Marcas | `srs_marcas` en Centro de Datos | ✅ Migrado |
| Productos | `expedient_base_registries` en Core | ✅ Migrado |
| **Relaciones** | `expedient_base_registry_relation` en Core | ❌ Pendiente |

---

## Paso 1: Exportar relaciones de SISAM

**Base de datos**: sisam (local)

```sql
SELECT DISTINCT
    mp.id_alim_producto,
    mp.id_ctl_marca
FROM alim_marca_producto mp
JOIN alim_producto p ON p.id = mp.id_alim_producto
WHERE p.estado_registro = 1
  AND p.fecha_emision_registro IS NOT NULL
  AND p.fecha_vigencia_registro IS NOT NULL
  AND p.num_registro_sanitario IS NOT NULL
ORDER BY mp.id_alim_producto, mp.id_ctl_marca;
```

➡️ Exportar a: `/Users/heycsar/tmp/marca_producto.csv`

---

## Paso 2: Exportar mapeo de marcas de Centro de Datos

**Base de datos**: Centro de Datos

```sql
SELECT
    id AS marca_uuid,
    legacy_id
FROM srs_marcas;
```

➡️ Exportar a: `/Users/heycsar/tmp/marcas_uuid.csv`

---

## Paso 3: Crear tablas temporales en Core

**Base de datos**: Core

```sql
-- Tabla para relaciones de SISAM
CREATE TABLE IF NOT EXISTS migration_marca_producto (
    id_alim_producto INT,
    id_ctl_marca INT
);

-- Tabla para mapeo de UUIDs
CREATE TABLE IF NOT EXISTS migration_marca_mapping (
    marca_uuid UUID,
    legacy_id VARCHAR(50)
);

-- Limpiar datos previos
TRUNCATE migration_marca_producto;
TRUNCATE migration_marca_mapping;
```

---

## Paso 4: Importar CSVs en Core

**Base de datos**: Core

```sql
\COPY migration_marca_producto(id_alim_producto, id_ctl_marca)
FROM '/Users/heycsar/tmp/marca_producto.csv'
WITH CSV HEADER;

\COPY migration_marca_mapping(marca_uuid, legacy_id)
FROM '/Users/heycsar/tmp/marcas_uuid.csv'
WITH CSV HEADER;
```

---

## Paso 5: Verificar importación

```sql
SELECT 'Relaciones SISAM' as fuente, COUNT(*) as registros
FROM migration_marca_producto
UNION ALL
SELECT 'Mapeo Marcas', COUNT(*)
FROM migration_marca_mapping;
```

---

## Paso 6: Insertar relaciones

```sql
INSERT INTO expedient_base_registry_relation (
    expedient_base_registry_id,
    relation_id,
    relation_type,
    source,
    reference_name,
    created_at,
    updated_at
)
SELECT
    r.id AS expedient_base_registry_id,
    mm.marca_uuid AS relation_id,
    'selected_option' AS relation_type,
    'data_center' AS source,
    'srs_marcas' AS reference_name,
    NOW() AS created_at,
    NOW() AS updated_at
FROM migration_marca_producto mmp
JOIN expedient_base_registries r
    ON r.legacy_id = 'PRD-' || mmp.id_alim_producto
JOIN migration_marca_mapping mm
    ON mm.legacy_id = 'MARCA-' || mmp.id_ctl_marca;
```

---

## Paso 7: Validar

```sql
-- Conteo de relaciones creadas
SELECT COUNT(*) as total_relaciones
FROM expedient_base_registry_relation
WHERE reference_name = 'srs_marcas';

-- Top productos con más marcas
SELECT
    r.legacy_id,
    COUNT(*) as marcas
FROM expedient_base_registries r
JOIN expedient_base_registry_relation rel
    ON rel.expedient_base_registry_id = r.id
WHERE rel.reference_name = 'srs_marcas'
GROUP BY r.id
ORDER BY marcas DESC
LIMIT 10;
```

---

## Paso 8: Limpiar tablas temporales

```sql
DROP TABLE IF EXISTS migration_marca_producto;
DROP TABLE IF EXISTS migration_marca_mapping;
```

---

## Rollback (si necesario)

```sql
DELETE FROM expedient_base_registry_relation
WHERE source = 'data_center'
  AND reference_name = 'srs_marcas';
```
