# 📘 Guía: Migración por UUID de Expedient Base Entity

**Fecha**: 2026-01-22
**Versión**: 1.0
**Autor**: Data Expert Migration Team

---

## 📋 Índice

1. [Contexto](#1-contexto)
2. [Cuándo usar este tipo de migración](#2-cuándo-usar-este-tipo-de-migración)
3. [Prerrequisitos](#3-prerrequisitos)
4. [Flujo de ejecución](#4-flujo-de-ejecución)
5. [Scripts disponibles](#5-scripts-disponibles)
6. [Validaciones obligatorias](#6-validaciones-obligatorias)
7. [Mapeo de campos](#7-mapeo-de-campos)
8. [Troubleshooting](#8-troubleshooting)
9. [Rollback](#9-rollback)

---

## 1. Contexto

### ¿Qué es la migración por UUID?

Es un enfoque de migración que **referencia la entidad destino por su UUID** en lugar de buscarla por nombre. Esto permite trabajar con entidades que fueron creadas por **otro equipo** de desarrollo.

### Diferencia con la migración tradicional

| Aspecto | Migración tradicional | Migración por UUID |
|---------|----------------------|-------------------|
| Script | `02_migrate_from_temp.sql` | `03_migrate_by_entity_uuid.sql` |
| Referencia entidad | Por nombre (`WHERE name = '...'`) | Por UUID (`WHERE id = '...'::uuid`) |
| Crea entidad | ✅ Sí | ❌ No |
| Crea campos | ✅ Sí | ❌ No |
| Requiere coordinación | No | Sí (con el equipo que creó la entidad) |

---

## 2. Cuándo usar este tipo de migración

### ✅ Usar migración por UUID cuando:

- Otro equipo ya creó la entidad (`expedient_base_entities`) con sus campos
- Tienes el UUID de la entidad y está confirmado
- Los nombres de los campos en la entidad coinciden con los esperados

### ❌ Usar migración tradicional cuando:

- Estás creando una nueva entidad desde cero
- No tienes coordinación con otro equipo
- Tienes control total sobre la definición de campos

---

## 3. Prerrequisitos

### 3.1 Información requerida

| Dato | Valor para T81 |
|------|----------------|
| UUID de entidad | `af224c8b-ccdf-44ef-8e5d-58b8d7d70285` |
| Nombre de entidad | T81 - Registro Sanitario Alimentos |
| Status | ACTIVE |
| Versión | 1 |

### 3.2 Tablas requeridas en Core

- [ ] `expedient_base_entities` - Con la entidad creada
- [ ] `expedient_base_entity_fields` - Con los campos definidos
- [ ] `migration_alim_producto_temp` - Con datos a migrar
- [ ] `srs_sub_grupo_alimenticio` - Para relaciones (opcional)
- [ ] `srs_certificado_libre_venta` - Para relaciones (opcional)
- [ ] `paises` - Para relaciones (opcional)

### 3.3 Datos de origen

La tabla `migration_alim_producto_temp` debe existir con los datos extraídos de SISAM usando `00_export_from_sisam.sql`.

---

## 4. Flujo de ejecución

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                      FLUJO DE MIGRACIÓN POR UUID                             │
└─────────────────────────────────────────────────────────────────────────────┘

FASE 0: VALIDACIONES (antes del BEGIN)
═══════════════════════════════════════
  ┌──────────────────┐
  │ 0.1 Verificar    │ → ¿Existe la entidad con ese UUID?
  │     entidad      │
  └────────┬─────────┘
           │ ✅
           ▼
  ┌──────────────────┐
  │ 0.2 Listar       │ → ¿Cuántos campos tiene? ¿Nombres correctos?
  │     campos       │
  └────────┬─────────┘
           │ ✅
           ▼
  ┌──────────────────┐
  │ 0.3 Verificar    │ → ¿Campos requeridos existen?
  │     compatibilid │
  └────────┬─────────┘
           │ ✅
           ▼
  ┌──────────────────┐
  │ 0.4 Verificar    │ → ¿Hay datos en migration_alim_producto_temp?
  │     datos origen │
  └────────┬─────────┘
           │ ✅
           ▼

FASE 1: MIGRACIÓN (dentro de BEGIN...COMMIT)
═══════════════════════════════════════════
  ┌──────────────────┐
  │ PASO 1-2         │ → Funciones y estructura
  │ Preparación      │
  └────────┬─────────┘
           │
           ▼
  ┌──────────────────┐
  │ PASO 3           │ → INSERT INTO expedient_base_registries
  │ Crear registries │   usando UUID directo
  └────────┬─────────┘
           │
           ▼
  ┌──────────────────┐
  │ PASO 4-5         │ → INSERT INTO expedient_base_registry_fields
  │ Crear campos     │   47 campos por registro
  └────────┬─────────┘
           │
           ▼
  ┌──────────────────┐
  │ PASO 6           │ → Campos MULTISELECT vacíos
  │ Marcas/Bodegas   │   (relaciones van en otra tabla)
  └────────┬─────────┘
           │
           ▼
  ┌──────────────────┐
  │ PASO 7           │ → Conteos y muestreo
  │ Verificación     │
  └────────┬─────────┘
           │
           ▼
    ┌──────────────┐
    │   COMMIT     │ → Guardar cambios permanentemente
    └──────────────┘
```

---

## 5. Scripts disponibles

| Script | Propósito | Ejecutar en |
|--------|-----------|-------------|
| `03_migrate_by_entity_uuid.sql` | Migración principal | Core |
| `03_rollback_by_entity_uuid.sql` | Revertir migración | Core |

### Ubicación

```
/Users/heycsar/Developer/Elaniin/Migration/scripts/
├── 03_migrate_by_entity_uuid.sql
└── 03_rollback_by_entity_uuid.sql
```

---

## 6. Validaciones obligatorias

Ejecutar **ANTES** del `BEGIN`:

### 6.1 Verificar que la entidad existe

```sql
SELECT
    CASE WHEN COUNT(*) = 1 THEN '✅ Entidad encontrada'
         ELSE '❌ ERROR: Entidad no existe'
    END AS validacion,
    id, name, status
FROM expedient_base_entities
WHERE id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
GROUP BY id, name, status;
```

**Resultado esperado**: `✅ Entidad encontrada`

### 6.2 Listar campos disponibles

```sql
SELECT f.name, f.field_type, f."order"
FROM expedient_base_entity_fields f
WHERE f.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
ORDER BY f."order";
```

**Verificar**: Que existan los 47+ campos esperados

### 6.3 Verificar campos críticos

```sql
WITH campos_requeridos AS (
    SELECT unnest(ARRAY[
        'Nombre del producto',
        'Tipo de producto',
        'País de fabricación'
    ]) AS campo_esperado
),
campos_existentes AS (
    SELECT f.name
    FROM expedient_base_entity_fields f
    WHERE f.expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
)
SELECT
    cr.campo_esperado,
    CASE WHEN ce.name IS NOT NULL THEN '✅' ELSE '❌ FALTA' END AS status
FROM campos_requeridos cr
LEFT JOIN campos_existentes ce ON cr.campo_esperado = ce.name;
```

**Resultado esperado**: Todos con `✅`

### 6.4 Verificar datos origen

```sql
SELECT COUNT(*) as registros_a_migrar
FROM migration_alim_producto_temp;
```

**Esperado**: > 0 registros

---

## 7. Mapeo de campos

### Campos requeridos por la migración

| # | Campo en entidad | Campo en temp table | Tipo |
|---|------------------|---------------------|------|
| 1 | Nombre del producto | `nombre` | TEXT |
| 2 | Número de registro sanitario | `num_registro_sanitario` | TEXT |
| 3 | Tipo de producto | `tipo_producto` | TEXT |
| 4 | Número de partida arancelaria | `num_partida_arancelaria` | TEXT |
| 5 | Fecha de emisión del registro | `fecha_emision_registro` | DATE |
| 6 | Fecha de vigencia del registro | `fecha_vigencia_registro` | DATE |
| 7 | Estado | `estado_producto` | TEXT |
| 8 | Subgrupo alimenticio | `subgrupo_alimenticio` | TEXT |
| 9 | Clasificación alimenticia | `clasificacion_alimenticia` | TEXT |
| 10 | Riesgo | `riesgo` | TEXT |
| 11 | País de fabricación | `pais` | TEXT |
| 12 | Código de CLV | `codigo_clv` | TEXT |
| 13 | Nombre del producto según CLV | `nombre_producto_clv` | TEXT |
| 14 | País de procedencia según CLV | `pais_procedencia_clv` | TEXT |
| 15-20 | Propietario (*) | `propietario_*` | TEXT/EMAIL |
| 21-26 | Fabricante (*) | `fabricante_*` | TEXT/EMAIL |
| 27-32 | Distribuidor (*) | `distribuidor_*` | TEXT/EMAIL |
| 33-38 | Envasador (*) | `envasador_*` | TEXT/EMAIL |
| 39-44 | Importador (*) | `importador_*` | TEXT/EMAIL |
| 45 | id_sub_grupo_alimenticio | (JOIN con srs_sub_grupo) | TEXT |
| 46 | id_pais_fabricacion | (JOIN con paises) | TEXT |
| 47 | id_clv | (JOIN con srs_certificado) | TEXT |

### ⚠️ Si los nombres no coinciden

Si el equipo que creó la entidad usó **nombres diferentes** para los campos, debes:

1. Ejecutar la consulta 6.2 para ver los nombres reales
2. Modificar el script `03_migrate_by_entity_uuid.sql`
3. Cambiar los `f.name = 'Nombre esperado'` por los nombres reales

---

## 8. Troubleshooting

### Error: "No se insertaron registros"

**Causa probable**: La entidad no existe o el UUID es incorrecto.

```sql
-- Verificar
SELECT id, name FROM expedient_base_entities
WHERE id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;
```

### Error: "Campo no encontrado"

**Causa probable**: El nombre del campo en la entidad no coincide.

```sql
-- Ver nombres reales
SELECT name FROM expedient_base_entity_fields
WHERE expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid;
```

### Error: "Duplicate key value violates unique constraint"

**Causa probable**: Ya existen registros con el mismo `legacy_id`.

```sql
-- Verificar duplicados
SELECT legacy_id, COUNT(*)
FROM expedient_base_registries
WHERE legacy_id LIKE 'PRD-%'
GROUP BY legacy_id
HAVING COUNT(*) > 1;
```

**Solución**: Ejecutar rollback primero o usar `ON CONFLICT DO NOTHING`.

---

## 9. Rollback

### Cuándo hacer rollback

- Si la migración tuvo errores
- Si los datos migrados son incorrectos
- Si necesitas volver a ejecutar con cambios

### Cómo ejecutar el rollback

```sql
-- 1. Vista previa (ver qué se eliminará)
SELECT 'Registros a eliminar' as accion, COUNT(*)
FROM expedient_base_registries
WHERE expedient_base_entity_id = 'af224c8b-ccdf-44ef-8e5d-58b8d7d70285'::uuid
  AND legacy_id LIKE 'PRD-%';

-- 2. Ejecutar rollback
\i scripts/03_rollback_by_entity_uuid.sql
```

### Qué elimina el rollback

| Tabla | Criterio | ¿Elimina? |
|-------|----------|-----------|
| `expedient_base_entities` | UUID | ❌ NO |
| `expedient_base_entity_fields` | UUID | ❌ NO |
| `expedient_base_registries` | UUID + `PRD-%` | ✅ SÍ |
| `expedient_base_registry_fields` | Cascada | ✅ SÍ |
| `expedient_base_registry_relation` | Cascada | ✅ SÍ |

---

## 📎 Referencias

- [Reporte completo de migración](./data_engineer_migration_expedient_report.md)
- [Script de extracción SISAM](../scripts/00_export_from_sisam.sql)
- [Script de tabla temporal](../scripts/01_create_temp_table.sql)

---

*Documento generado: 2026-01-22*
*Última actualización: 2026-01-22*
*Versión: 1.0*
