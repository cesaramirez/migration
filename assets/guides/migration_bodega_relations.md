# Guía de Migración: Relaciones Producto → Bodega

**Proyecto**: Migración SISAM → SDT
**Fecha**: 2026-01-17
**Autor**: Data Expert Migration Team

---

## 1. Resumen Ejecutivo

### Objetivo
Crear las relaciones entre productos (T81) y sus bodegas en el sistema destino.

### Alcance

| Métrica | Valor |
|---------|-------|
| Productos con bodega | 37,147 |
| Relaciones a crear | **42,795** |
| Bodegas únicas | 3,942 |

### Arquitectura

```
┌──────────────────────────────────────────────────────────────────────┐
│                         SISTEMA DESTINO                               │
│                                                                       │
│  ┌─────────────────────┐         ┌─────────────────────────────────┐ │
│  │  CORE Database      │         │  CENTRO DE DATOS Database       │ │
│  ├─────────────────────┤         ├─────────────────────────────────┤ │
│  │                     │         │                                 │ │
│  │ expedient_base_     │ ──────► │ srs_bodega                      │ │
│  │ registries          │         │ ┌─────────────────────────────┐ │ │
│  │ ┌─────────────────┐ │         │ │ id: UUID-BBB                │ │ │
│  │ │ id: UUID-AAA    │ │         │ │ legacy_id: 'BOD-456'        │ │ │
│  │ │ legacy_id:      │ │         │ │ nombre: 'Bodega Central'    │ │ │
│  │ │ 'PRD-123'       │ │         │ └─────────────────────────────┘ │ │
│  │ └─────────────────┘ │         │                                 │ │
│  │                     │         │ 3,942 registros                 │ │
│  │ expedient_base_     │         │                                 │ │
│  │ registry_relation   │         └─────────────────────────────────┘ │
│  │ ┌─────────────────┐ │                                             │
│  │ │ expedient_base_ │ │                                             │
│  │ │ registry_id:    │◄┼─── UUID del producto en Core                │
│  │ │ UUID-AAA        │ │                                             │
│  │ │                 │ │                                             │
│  │ │ relation_id:    │◄┼─── UUID de la bodega en Centro de Datos     │
│  │ │ UUID-BBB        │ │                                             │
│  │ │                 │ │                                             │
│  │ │ relation_type:  │ │                                             │
│  │ │ 'data_center'   │ │                                             │
│  │ │                 │ │                                             │
│  │ │ reference_name: │ │                                             │
│  │ │ 'srs_bodega'    │ │                                             │
│  │ └─────────────────┘ │                                             │
│  │                     │                                             │
│  │ ~42,795 relaciones  │                                             │
│  └─────────────────────┘                                             │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                         SISTEMA ORIGEN (SISAM)                        │
│                                                                       │
│  alim_bodega_producto                                                 │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │ id_alim_producto: 123  ←── Se convierte en 'PRD-123'            │ │
│  │ id_alim_bodega: 456    ←── Se convierte en 'BOD-456'            │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  42,795 relaciones                                                    │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 2. Prerrequisitos

Antes de iniciar, verificar:

- [ ] **Core**: Productos migrados en `expedient_base_registries` con `legacy_id = 'PRD-{id}'`
- [ ] **Centro de Datos**: Bodegas en `srs_bodega` con `legacy_id = 'BOD-{id}'`
- [ ] **Acceso**: Conexión a las 3 bases de datos (SISAM, Core, Centro de Datos)

### Queries de Verificación

```sql
-- En Core: Verificar productos migrados
SELECT COUNT(*) FROM expedient_base_registries WHERE legacy_id LIKE 'PRD-%';

-- En Centro de Datos: Verificar bodegas
SELECT COUNT(*) FROM srs_bodega WHERE legacy_id LIKE 'BOD-%';
```

---

## 3. Estrategia de Migración

### El Desafío

Los IDs en SISAM son **integers** (123, 456), pero en el destino son **UUIDs**.
Además, productos y bodegas están en **bases de datos diferentes**.

### La Solución

Usamos `legacy_id` como **puente** entre sistemas:

```
SISAM                           DESTINO
─────                           ───────
id_producto: 123  ──────────►   legacy_id: 'PRD-123' ──► UUID-AAA
id_bodega: 456    ──────────►   legacy_id: 'BOD-456' ──► UUID-BBB
```

### Flujo de Datos

```
Paso 1                 Paso 2                 Paso 3
───────                ───────                ───────
SISAM                  Centro de Datos        Core
│                      │                      │
│ Exportar             │ Exportar             │ Importar
│ relaciones           │ UUIDs bodegas        │ + JOIN
│                      │                      │ + INSERT
▼                      ▼                      ▼
bodega_producto.csv    bodegas_uuid.csv       expedient_base_
(42,795 filas)         (3,942 filas)          registry_relation
                                              (42,795 registros)
```

---

## 4. Pasos Detallados

### Paso 1: Exportar Relaciones de SISAM

**Base de datos**: SISAM
**Herramienta**: TablePlus o psql

```sql
-- Ejecutar este query en SISAM
SELECT
    bp.id_alim_producto,
    bp.id_alim_bodega,
    bp.fecha_registro,
    bp.fecha_traslado
FROM alim_bodega_producto bp
JOIN alim_producto p ON p.id = bp.id_alim_producto
WHERE p.estado_registro = 1
  AND p.fecha_emision_registro IS NOT NULL
  AND p.fecha_vigencia_registro IS NOT NULL
  AND p.num_registro_sanitario IS NOT NULL
ORDER BY bp.id_alim_producto, bp.id_alim_bodega;
```

**Acción**: Exportar resultado como CSV
**Archivo**: `/Users/heycsar/tmp/bodega_producto.csv`
**Registros esperados**: ~42,795

---

### Paso 2: Exportar Mapeo de Bodegas

**Base de datos**: Centro de Datos
**Herramienta**: TablePlus o psql

```sql
-- Ejecutar este query en Centro de Datos
SELECT
    id AS bodega_uuid,
    legacy_id
FROM srs_bodega;
```

**Acción**: Exportar resultado como CSV
**Archivo**: `/Users/heycsar/tmp/bodegas_uuid.csv`
**Registros esperados**: 3,942

---

### Paso 3: Preparar Core Database

**Base de datos**: Core
**Herramienta**: psql o TablePlus

```sql
-- Crear tabla para relaciones de SISAM (visible en TablePlus)
CREATE TABLE IF NOT EXISTS migration_bodega_producto (
    id_alim_producto INT,
    id_alim_bodega INT,
    fecha_registro DATE,
    fecha_traslado DATE
);

-- Crear tabla para mapeo de UUIDs
CREATE TABLE IF NOT EXISTS migration_bodega_mapping (
    bodega_uuid UUID,
    legacy_id VARCHAR(20)
);

-- Limpiar datos previos si existen
TRUNCATE migration_bodega_producto;
TRUNCATE migration_bodega_mapping;
```

---

### Paso 4: Importar CSVs en Core

**Base de datos**: Core
**Herramienta**: psql (requiere acceso al filesystem)

```sql
-- Importar relaciones de SISAM
\COPY migration_bodega_producto(id_alim_producto, id_alim_bodega, fecha_registro, fecha_traslado)
FROM '/Users/heycsar/tmp/bodega_producto.csv'
WITH CSV HEADER;

-- Importar mapeo de bodegas
\COPY migration_bodega_mapping(bodega_uuid, legacy_id)
FROM '/Users/heycsar/tmp/bodegas_uuid.csv'
WITH CSV HEADER;
```

---

### Paso 5: Verificar Importación

```sql
-- Verificar datos importados
SELECT 'Relaciones SISAM' as fuente, COUNT(*) as registros
FROM migration_bodega_producto
UNION ALL
SELECT 'Mapeo Bodegas', COUNT(*)
FROM migration_bodega_mapping;

-- Verificar integridad: ¿Todas las bodegas referenciadas existen?
SELECT COUNT(DISTINCT id_alim_bodega) as bodegas_en_relaciones,
       (SELECT COUNT(*) FROM migration_bodega_mapping) as bodegas_disponibles
FROM migration_bodega_producto;
```

---

### Paso 6: Insertar Relaciones

```sql
-- INSERT final en expedient_base_registry_relation
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
    r.id AS expedient_base_registry_id,      -- UUID del producto
    bm.bodega_uuid AS relation_id,            -- UUID de la bodega
    'selected_option' AS relation_type,      -- Tipo para data center
    'data_center' AS source,                  -- Origen de la relación
    'srs_bodega' AS reference_name,
    COALESCE(mbp.fecha_registro::timestamp, NOW()) AS created_at,
    NOW() AS updated_at
FROM migration_bodega_producto mbp
-- Buscar UUID del producto por legacy_id
JOIN expedient_base_registries r
    ON r.legacy_id = 'PRD-' || mbp.id_alim_producto
-- Buscar UUID de la bodega por legacy_id
JOIN migration_bodega_mapping bm
    ON bm.legacy_id = 'BOD-' || mbp.id_alim_bodega;
```

---

### Paso 7: Validar Migración

```sql
-- Conteo total de relaciones creadas
SELECT COUNT(*) as total_relaciones
FROM expedient_base_registry_relation
WHERE relation_type = 'selected_option'
  AND source = 'data_center'
  AND reference_name = 'srs_bodega';
-- Esperado: ~42,795

-- Comparar con origen
SELECT
    (SELECT COUNT(*) FROM migration_bodega_producto) as origen,
    (SELECT COUNT(*) FROM expedient_base_registry_relation
     WHERE reference_name = 'srs_bodega') as destino;

-- Top 10 productos con más bodegas
SELECT
    r.legacy_id,
    LEFT(r.name, 50) as producto,
    COUNT(rel.id) as bodegas
FROM expedient_base_registries r
JOIN expedient_base_registry_relation rel
    ON rel.expedient_base_registry_id = r.id
WHERE rel.reference_name = 'srs_bodega'
GROUP BY r.id
ORDER BY bodegas DESC
LIMIT 10;
```

---

### Paso 8: Limpiar Tablas de Migración

```sql
DROP TABLE IF EXISTS migration_bodega_producto;
DROP TABLE IF EXISTS migration_bodega_mapping;
```

---

## 5. Troubleshooting

### Problema: Relaciones faltantes

Si el conteo destino es menor que origen:

```sql
-- Encontrar productos sin match
SELECT tbp.id_alim_producto
FROM temp_bodega_producto tbp
LEFT JOIN expedient_base_registries r
    ON r.legacy_id = 'PRD-' || tbp.id_alim_producto
WHERE r.id IS NULL
LIMIT 20;

-- Encontrar bodegas sin match
SELECT DISTINCT tbp.id_alim_bodega
FROM temp_bodega_producto tbp
LEFT JOIN temp_bodega_mapping bm
    ON bm.legacy_id = 'BOD-' || tbp.id_alim_bodega
WHERE bm.bodega_uuid IS NULL
LIMIT 20;
```

### Problema: Duplicados

```sql
-- Verificar duplicados
SELECT expedient_base_registry_id, relation_id, COUNT(*)
FROM expedient_base_registry_relation
WHERE reference_name = 'srs_bodega'
GROUP BY expedient_base_registry_id, relation_id
HAVING COUNT(*) > 1;
```

---

## 6. Checklist Final

- [ ] Paso 1: CSV de relaciones exportado (~42,795 filas)
- [ ] Paso 2: CSV de mapeo bodegas exportado (3,942 filas)
- [ ] Paso 3: Tablas temporales creadas en Core
- [ ] Paso 4: CSVs importados correctamente
- [ ] Paso 5: Verificación de integridad OK
- [ ] Paso 6: INSERT ejecutado
---

## 8. Rollback

En caso de necesitar revertir la migración de relaciones:

### Rollback Completo

```sql
-- EJECUTAR EN CORE
-- ⚠️ PRECAUCIÓN: Esto eliminará TODAS las relaciones producto-bodega

BEGIN;

-- Contar registros a eliminar (verificar antes)
SELECT COUNT(*) as registros_a_eliminar
FROM expedient_base_registry_relation
WHERE relation_type = 'selected_option'
  AND reference_name = 'srs_bodega';

-- Eliminar relaciones
DELETE FROM expedient_base_registry_relation
WHERE relation_type = 'selected_option'
  AND reference_name = 'srs_bodega';

-- Verificar eliminación
SELECT COUNT(*) as registros_restantes
FROM expedient_base_registry_relation
WHERE reference_name = 'srs_bodega';
-- Debe ser 0

COMMIT;
-- O ROLLBACK; si algo está mal
```

### Rollback Parcial (por producto específico)

```sql
-- Eliminar relaciones de un producto específico
DELETE FROM expedient_base_registry_relation
WHERE expedient_base_registry_id = (
    SELECT id FROM expedient_base_registries
    WHERE legacy_id = 'PRD-12345'  -- Cambiar por el ID deseado
)
AND reference_name = 'srs_bodega';
```

### Rollback por Fecha

```sql
-- Eliminar relaciones creadas después de cierta fecha
DELETE FROM expedient_base_registry_relation
WHERE relation_type = 'selected_option'
  AND reference_name = 'srs_bodega'
  AND created_at >= '2026-01-17 22:00:00';
```

### Script de Rollback Idempotente

```sql
-- Script seguro que puede ejecutarse múltiples veces
DO $$
DECLARE
    v_count INT;
BEGIN
    -- Contar antes
    SELECT COUNT(*) INTO v_count
    FROM expedient_base_registry_relation
    WHERE relation_type = 'selected_option'
      AND reference_name = 'srs_bodega';

    RAISE NOTICE 'Relaciones bodega a eliminar: %', v_count;

    IF v_count > 0 THEN
        DELETE FROM expedient_base_registry_relation
        WHERE relation_type = 'selected_option'
          AND reference_name = 'srs_bodega';

        RAISE NOTICE 'Rollback completado: % relaciones eliminadas', v_count;
    ELSE
        RAISE NOTICE 'No hay relaciones bodega para eliminar';
    END IF;
END $$;
```

---

## 9. Resumen de Archivos

| Archivo | Ubicación | Propósito |
|---------|-----------|-----------|
| `bodega_producto.csv` | `/Users/heycsar/tmp/` | Relaciones de SISAM |
| `bodegas_uuid.csv` | `/Users/heycsar/tmp/` | Mapeo legacy_id → UUID |
| `05_migrate_bodega_relations.sql` | `scripts/` | Script consolidado |

---

*Documento generado como guía técnica para migración de relaciones producto-bodega.*
