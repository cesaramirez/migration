# Guía de Migración: Presentaciones de Productos

**Proyecto**: Migración SISAM → Centro de Datos
**Fecha**: 2026-01-18
**Tabla Destino**: `presentaciones_registro_sanitario`

---

## 1. Resumen

Migrar las presentaciones de productos (combinación de envase + material + unidad de medida) desde SISAM hacia Centro de Datos.

### Tablas Origen (SISAM):
- `alim_presentacion_producto` - Presentaciones
- `alim_envase_producto` - Envases
- `alim_material_envase_producto` - Materiales del envase
- `ctl_unidad_medida` - Catálogo de unidades

### Tabla Destino (Centro de Datos):
- `presentaciones_registro_sanitario`

---

## 2. Modelo de Datos

```
alim_producto
    └── alim_presentacion_producto
            ├── cantidad (→ unidad)
            ├── id_ctl_unidad_medida (→ srs_unidad_medida.id)
            └── id_alim_envase_producto
                    └── alim_material_envase_producto
                            └── id_ctl_material (→ srs_material.id)
```

---

## 3. Prerrequisitos

Verificar que existan en Centro de Datos:

```sql
-- Materiales migrados
SELECT COUNT(*) FROM srs_material;

-- Unidades de medida migradas
SELECT COUNT(*) FROM srs_unidad_medida;
```

---

## 4. Paso 1: Exportar de SISAM

```sql
-- Ejecutar en SISAM
SELECT DISTINCT
    pp.id AS id_presentacion,
    pp.cantidad AS unidad,
    pp.id_ctl_unidad_medida,
    mep.id_ctl_material,
    pp.id_alim_producto
FROM alim_presentacion_producto pp
JOIN alim_envase_producto ep ON ep.id = pp.id_alim_envase_producto
JOIN alim_material_envase_producto mep ON mep.id_alim_envase_producto = ep.id
JOIN alim_producto p ON p.id = pp.id_alim_producto
WHERE p.estado_registro = 1
  AND p.fecha_emision_registro IS NOT NULL
  AND p.fecha_vigencia_registro IS NOT NULL
  AND p.num_registro_sanitario IS NOT NULL
ORDER BY pp.id_alim_producto, pp.id;
```

➡️ Exportar a: `/Users/heycsar/tmp/presentaciones.csv`

---

## 5. Paso 2: Exportar Mapeos de Centro de Datos

### Materiales:
```sql
SELECT id AS material_uuid, legacy_id FROM srs_material;
```
➡️ Exportar a: `/Users/heycsar/tmp/materiales_uuid.csv`

### Unidades de Medida:
```sql
SELECT id AS unidad_uuid, legacy_id FROM srs_unidad_medida;
```
➡️ Exportar a: `/Users/heycsar/tmp/unidades_uuid.csv`

---

## 6. Paso 3: Crear Tablas Temporales (Centro de Datos)

```sql
-- Tabla para presentaciones de SISAM
CREATE TABLE IF NOT EXISTS migration_presentaciones (
    id_presentacion INT,
    unidad VARCHAR(50),
    id_ctl_unidad_medida INT,
    id_ctl_material INT,
    id_alim_producto INT
);

-- Tabla para mapeo de materiales
CREATE TABLE IF NOT EXISTS migration_material_mapping (
    material_uuid UUID,
    legacy_id VARCHAR(20)
);

-- Tabla para mapeo de unidades
CREATE TABLE IF NOT EXISTS migration_unidad_mapping (
    unidad_uuid UUID,
    legacy_id VARCHAR(20)
);

-- Limpiar datos previos
TRUNCATE migration_presentaciones;
TRUNCATE migration_material_mapping;
TRUNCATE migration_unidad_mapping;
```

---

## 7. Paso 4: Importar CSVs

```sql
\COPY migration_presentaciones(id_presentacion, unidad, id_ctl_unidad_medida, id_ctl_material, id_alim_producto)
FROM '/Users/heycsar/tmp/presentaciones.csv'
WITH CSV HEADER;

\COPY migration_material_mapping(material_uuid, legacy_id)
FROM '/Users/heycsar/tmp/materiales_uuid.csv'
WITH CSV HEADER;

\COPY migration_unidad_mapping(unidad_uuid, legacy_id)
FROM '/Users/heycsar/tmp/unidades_uuid.csv'
WITH CSV HEADER;
```

---

## 8. Paso 5: Verificar Importación

```sql
SELECT 'Presentaciones SISAM' as fuente, COUNT(*) as registros FROM migration_presentaciones
UNION ALL
SELECT 'Mapeo Materiales', COUNT(*) FROM migration_material_mapping
UNION ALL
SELECT 'Mapeo Unidades', COUNT(*) FROM migration_unidad_mapping;
```

---

## 9. Paso 6: Insertar en Tabla Destino

```sql
INSERT INTO presentaciones_registro_sanitario (
    id,
    id_material,
    id_unidad_medida,
    unidad,
    created_at,
    updated_at
)
SELECT
    gen_random_uuid() AS id,
    mm.material_uuid::text AS id_material,
    um.unidad_uuid::text AS id_unidad_medida,
    mp.unidad,
    NOW() AS created_at,
    NOW() AS updated_at
FROM migration_presentaciones mp
JOIN migration_material_mapping mm
    ON mm.legacy_id = 'MAT-' || mp.id_ctl_material
JOIN migration_unidad_mapping um
    ON um.legacy_id = 'UM-' || mp.id_ctl_unidad_medida;
```

---

## 10. Paso 7: Validar

```sql
-- Conteo total
SELECT COUNT(*) as total_presentaciones FROM presentaciones_registro_sanitario;

-- Comparar con origen
SELECT
    (SELECT COUNT(*) FROM migration_presentaciones) as origen,
    (SELECT COUNT(*) FROM presentaciones_registro_sanitario) as destino;

-- Muestra de datos
SELECT * FROM presentaciones_registro_sanitario LIMIT 10;
```

---

## 11. Paso 8: Limpiar Tablas Temporales

```sql
DROP TABLE IF EXISTS migration_presentaciones;
DROP TABLE IF EXISTS migration_material_mapping;
DROP TABLE IF EXISTS migration_unidad_mapping;
```

---

## 12. Rollback

**IMPORTANTE**: Antes de ejecutar el INSERT, anota la fecha/hora actual para el rollback selectivo.

```sql
-- Ver la hora actual antes de migrar
SELECT NOW();
-- Ejemplo resultado: 2026-01-18 18:00:00

-- Rollback: Eliminar solo registros creados después de cierta fecha
DELETE FROM presentaciones_registro_sanitario
WHERE created_at >= '2026-01-18 18:00:00';  -- Ajustar a la hora anotada

-- Verificar eliminación
SELECT COUNT(*) FROM presentaciones_registro_sanitario;
```

---

## Notas

- El campo `id_media` se omite en esta primera versión.
- El `legacy_id` de unidades de medida asume formato `UM-{id}`. Verificar el formato real en `srs_unidad_medida`.
