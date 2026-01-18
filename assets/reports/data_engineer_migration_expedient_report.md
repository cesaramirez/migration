# 📊 Reporte Técnico para Data Engineer
## Migración del Sistema de Expedientes SISAM → SDT

**Proyecto**: Migración del Registro Sanitario de Alimentos
**Fecha**: 2026-01-18
**Versión**: 1.0
**Autor**: Data Expert Migration Team

---

## 📋 Índice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Arquitectura del Sistema Destino](#2-arquitectura-del-sistema-destino)
3. [Modelo de Datos del Expediente](#3-modelo-de-datos-del-expediente)
4. [Tablas Origen (SISAM)](#4-tablas-origen-sisam)
5. [Mapeo de Datos](#5-mapeo-de-datos)
6. [Estrategia de Migración](#6-estrategia-de-migración)
7. [Scripts y Workflows](#7-scripts-y-workflows)
8. [Validaciones y Golden Rules](#8-validaciones-y-golden-rules)
9. [Consideraciones Especiales](#9-consideraciones-especiales)
10. [Roadmap de Ejecución](#10-roadmap-de-ejecución)

---

## 1. Resumen Ejecutivo

### 🎯 Objetivo
Migrar los registros de productos alimenticios del sistema legacy SISAM hacia el nuevo sistema SDT, utilizando el modelo de **Expediente Dinámico (Expedient Base)**.

### 📊 Métricas Clave

| Métrica | Valor |
|---------|-------|
| **Entidad Principal** | T81 - Registro Sanitario Alimentos |
| **Productos a migrar** | ~50,000+ (productos activos) |
| **Relaciones producto-bodega** | ~42,795 |
| **Campos por producto** | 47 campos |
| **Tablas origen** | 14 tablas |
| **Bases de datos destino** | 2 (Core + Centro de Datos) |

### 🏗️ Arquitectura de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           SISTEMA LEGACY (SISAM)                         │
│                                                                          │
│  PostgreSQL - Base de datos transaccional del registro sanitario         │
│  ┌──────────────────────────────────────────────────────────────────┐    │
│  │ alim_producto │ alim_empresa │ alim_persona │ ctl_* (catálogos) │    │
│  └──────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ ETL (CSV + SQL Scripts)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           SISTEMA DESTINO (SDT)                          │
│                                                                          │
│  ┌─────────────────────────────┐    ┌─────────────────────────────────┐ │
│  │     CORE Database          │    │     CENTRO DE DATOS Database    │ │
│  │                            │    │                                 │ │
│  │  expedient_base_entities   │    │  srs_* (tablas migradas n8n)   │ │
│  │  expedient_base_registries │◄──►│  srs_entidad                    │ │
│  │  expedient_base_entity_    │    │  srs_bodega                     │ │
│  │    fields                  │    │  srs_sub_grupo_alimenticio      │ │
│  │  expedient_base_registry_  │    │  srs_certificado_libre_venta    │ │
│  │    fields                  │    │  paises                         │ │
│  │  expedient_base_registry_  │    │                                 │ │
│  │    relation                │    │                                 │ │
│  └─────────────────────────────┘    └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Arquitectura del Sistema Destino

### 2.1 Modelo EAV (Entity-Attribute-Value)

El sistema destino utiliza un **modelo EAV dinámico** que permite:
- ✅ Agregar campos sin modificar el esquema
- ✅ Diferentes entidades con diferentes estructuras
- ✅ Versionado de plantillas
- ✅ Flexibilidad para futuros tipos de expedientes

### 2.2 Diagrama Entidad-Relación

```
┌─────────────────────────────────┐
│   expedient_base_entities       │  ← Plantilla/Tipo de expediente
├─────────────────────────────────┤     (ej: "T81 - Registro Sanitario")
│ id: UUID (PK)                   │
│ name: VARCHAR(255)              │
│ description: TEXT               │
│ status: VARCHAR(255)            │  ← ACTIVE, DRAFT, INACTIVE
│ version: INT                    │
│ is_current_version: BOOL        │
│ parent_version_id: UUID (FK)    │
└──────────────┬──────────────────┘
               │ 1:N
               ▼
┌─────────────────────────────────┐
│   expedient_base_entity_fields  │  ← Definición de campos
├─────────────────────────────────┤     (47 campos para T81)
│ id: UUID (PK)                   │
│ expedient_base_entity_id: UUID  │
│ name: VARCHAR(255)              │  ← "Nombre del producto"
│ field_type: VARCHAR(255)        │  ← TEXT, DATE, EMAIL, BOOLEAN
│ is_required: BOOL               │
│ default_value: TEXT             │
│ configuration: JSON             │  ← placeholder, section, key, etc.
│ order: INT                      │
└──────────────┬──────────────────┘
               │
               │ (Define la estructura)
               ▼
┌─────────────────────────────────┐
│   expedient_base_registries     │  ← Instancia del expediente
├─────────────────────────────────┤     (1 registro = 1 producto)
│ id: UUID (PK)                   │
│ name: TEXT                      │  ← Nombre del producto
│ metadata: JSON                  │  ← {original_id, source, etc.}
│ expedient_base_entity_id: UUID  │
│ unique_code: VARCHAR(32)        │  ← Código único generado
│ legacy_id: VARCHAR(30)          │  ← PRD-{id_original} ⭐ CLAVE
│ created_at: TIMESTAMP           │
│ deleted_at: TIMESTAMP           │  ← Soft delete
└──────────────┬──────────────────┘
               │ 1:N
               ▼
┌─────────────────────────────────┐
│   expedient_base_registry_      │  ← Valores de los campos
│   fields                        │     (N registros por producto)
├─────────────────────────────────┤
│ id: UUID (PK)                   │
│ expedient_base_registry_id: UUID│
│ expedient_base_entity_field_id: │
│   UUID                          │
│ value: TEXT                     │  ← Valor del campo (JSON string)
│ expiration_at: TIMESTAMP        │
│ timer_config: JSONB             │
│ selected_options: JSONB         │
└─────────────────────────────────┘
               │
               │ (Relaciones)
               ▼
┌─────────────────────────────────┐
│   expedient_base_registry_      │  ← Relaciones con otros sistemas
│   relation                      │     (Producto → Bodega, etc.)
├─────────────────────────────────┤
│ id: BIGINT (PK)                 │
│ expedient_base_registry_id: UUID│  ← UUID del producto
│ relation_id: UUID               │  ← UUID de la entidad relacionada
│ relation_type: VARCHAR(255)     │  ← 'selection_option'
│ source: VARCHAR(255)            │  ← 'data_center'
│ reference_name: VARCHAR(255)    │  ← 'srs_bodega'
│ display_value: VARCHAR(255)     │
│ expedient_base_entity_field_id: │
│   UUID                          │  ← Campo específico (opcional)
└─────────────────────────────────┘
```

---

## 3. Modelo de Datos del Expediente

### 3.1 Entidad: T81 - Registro Sanitario Alimentos

#### Estructura de Campos (47 campos)

| Orden | Campo | Tipo | Requerido | Sección |
|-------|-------|------|-----------|---------|
| **Datos Generales del Producto** |||||
| 1 | Nombre del producto | TEXT | ✅ | Datos generales |
| 2 | Número de registro sanitario | TEXT | ❌ | Datos generales |
| 3 | Tipo de producto | TEXT | ✅ | Datos generales |
| 4 | Número de partida arancelaria | TEXT | ❌ | Datos generales |
| 5 | Fecha de emisión del registro | DATE | ❌ | Datos generales |
| 6 | Fecha de vigencia del registro | DATE | ❌ | Datos generales |
| 7 | Estado | TEXT | ❌ | Datos generales |
| 8 | Subgrupo alimenticio | TEXT | ❌ | Datos generales |
| 9 | Clasificación alimenticia | TEXT | ❌ | Datos generales |
| 10 | Riesgo | TEXT | ❌ | Datos generales |
| 11 | País de fabricación | TEXT | ✅ | Datos generales |
| **Certificado de Libre Venta** |||||
| 12 | Código de CLV | TEXT | ❌ | CLV |
| 13 | Nombre del producto según CLV | TEXT | ❌ | CLV |
| 14 | País de procedencia según CLV | TEXT | ❌ | CLV |
| **Datos del Propietario** |||||
| 15-20 | Propietario (nombre, NIT, correo, dirección, país, razón social) | TEXT/EMAIL/TEXTAREA | ❌ | Propietario |
| **Datos del Fabricante** |||||
| 21-26 | Fabricante (nombre, NIT, correo, dirección, país, razón social) | TEXT/EMAIL/TEXTAREA | ❌ | Fabricante |
| **Datos del Distribuidor** |||||
| 27-32 | Distribuidor (nombre, NIT, correo, dirección, país, razón social) | TEXT/EMAIL/TEXTAREA | ❌ | Distribuidor |
| **Datos del Envasador** |||||
| 33-38 | Envasador (nombre, NIT, correo, dirección, país, razón social) | TEXT/EMAIL/TEXTAREA | ❌ | Envasador |
| **Datos del Importador** |||||
| 39-44 | Importador (nombre, NIT, correo, dirección, país, razón social) | TEXT/EMAIL/TEXTAREA | ❌ | Importador |
| **Relaciones (IDs)** |||||
| 45 | id_sub_grupo_alimenticio | TEXT | ❌ | Relaciones |
| 46 | id_pais_fabricacion | TEXT | ❌ | Relaciones |
| 47 | id_clv | TEXT | ❌ | Relaciones |

#### Configuración JSON de Campo (Ejemplo)

```json
{
  "show_in_summary": true,
  "section": {
    "title": "Datos generales del producto",
    "order": 1
  },
  "key": "nombre_del_producto",
  "placeholder": "Nombre del producto",
  "maxLength": "1000",
  "buttonEnabled": false,
  "type": "text"
}
```

---

## 4. Tablas Origen (SISAM)

### 4.1 Diagrama de Tablas Fuente

```
                           ┌─────────────────────────┐
                           │     alim_producto       │ ← TABLA PRINCIPAL
                           ├─────────────────────────┤
                           │ id (PK)                 │
                           │ nombre                  │
                           │ tipo_producto           │ → 1=Nacional, 2=UA, 3=Otros
                           │ num_registro_sanitario  │
                           │ fecha_emision_registro  │
                           │ fecha_vigencia_registro │
                           │ estado_registro         │ → 1=Activo, 2=Inactivo
                           │ id_ctl_estado_producto  │───┐
                           │ id_ctl_pais             │───┼───┐
                           │ id_sub_grupo_alimenticio│───┼───┼───┐
                           └───────────┬─────────────┘   │   │   │
                                       │                 │   │   │
     ┌─────────────────────────────────┼─────────────────┘   │   │
     │ ┌───────────────────────────────┘                     │   │
     │ │ ┌───────────────────────────────────────────────────┘   │
     │ │ │ ┌─────────────────────────────────────────────────────┘
     │ │ │ │
     ▼ ▼ ▼ ▼
┌─────────────────┐ ┌────────────────┐ ┌────────────────────────────┐
│ctl_estado_prod. │ │   ctl_pais     │ │ alim_sub_grupo_alimenticio │
├─────────────────┤ ├────────────────┤ ├────────────────────────────┤
│ id (PK)         │ │ id (PK)        │ │ id (PK)                    │
│ nombre          │ │ nombre         │ │ nombre                     │
└─────────────────┘ │ isonumero      │ │ id_ctl_clasificacion_...   │───┐
                    └────────────────┘ └────────────────────────────┘   │
                                                                        ▼
                                       ┌─────────────────────────────────────┐
                                       │ ctl_clasificacion_grupo_alimenticio │
                                       ├─────────────────────────────────────┤
                                       │ id (PK)                             │
                                       │ nombre                              │
                                       │ id_ctl_tipo_riesgo                  │───┐
                                       └─────────────────────────────────────┘   │
                                                                                 ▼
                                                                  ┌──────────────────┐
                                                                  │ ctl_tipo_riesgo  │
                                                                  ├──────────────────┤
                                                                  │ id (PK)          │
                                                                  │ nombre           │
                                                                  └──────────────────┘

==== RELACIONES EMPRESA/PERSONA ====

┌─────────────────────────┐        ┌────────────────────────────────────────┐
│     alim_producto       │ 1:N    │ alim_empresa_persona_aux_funcion_prod  │
├─────────────────────────┤◄───────├────────────────────────────────────────┤
│ id (PK)                 │        │ id_alim_producto                       │
└─────────────────────────┘        │ id_alim_empresa_persona_aux            │
                                   │ id_ctl_funcion_empresa_persona         │ → 1-5
                                   └──────────────────┬─────────────────────┘
                                                      │
                                                      ▼
                              ┌─────────────────────────────────────────────┐
                              │         alim_empresa_persona_aux            │
                              ├─────────────────────────────────────────────┤
                              │ id (PK)                                     │
                              │ nombre                                      │
                              │ nit                                         │
                              │ correo_electronico                          │
                              │ direccion                                   │
                              │ es_empresa (BOOL)                           │
                              │ id_ctl_pais                                 │
                              └─────────────────────────────────────────────┘

==== FUNCIONES EMPRESA/PERSONA ====

┌─────────────────────────────────────┐
│ ctl_funcion_empresa_persona         │
├─────────────────────────────────────┤
│ 1 = FABRICANTE                      │
│ 2 = DISTRIBUIDOR                    │
│ 3 = ENVASADOR                       │
│ 4 = PROPIETARIO                     │
│ 5 = IMPORTADOR                      │
└─────────────────────────────────────┘

==== CERTIFICADO LIBRE VENTA ====

┌─────────────────────────┐        ┌────────────────────────────────────────┐
│     alim_producto       │ 1:N    │   alim_producto_certificado_libre_venta│
├─────────────────────────┤◄───────├────────────────────────────────────────┤
│ id (PK)                 │        │ id_alim_producto                       │
└─────────────────────────┘        │ id_alim_certificado_libre_venta        │
                                   │ nombre_prod_segun_clv                  │
                                   └──────────────────┬─────────────────────┘
                                                      │
                                                      ▼
                              ┌────────────────────────────────────────────┐
                              │     alim_certificado_libre_venta           │
                              ├────────────────────────────────────────────┤
                              │ id (PK)                                    │
                              │ cod_clv                                    │
                              │ fecha_emision                              │
                              │ id_ctl_pais_procedencia                    │
                              └────────────────────────────────────────────┘

==== BODEGAS ====

┌─────────────────────────┐        ┌────────────────────────────────────────┐
│     alim_producto       │ N:M    │         alim_bodega_producto           │
├─────────────────────────┤◄───────├────────────────────────────────────────┤
│ id (PK)                 │        │ id_alim_producto                       │
└─────────────────────────┘        │ id_alim_bodega                         │
                                   │ fecha_registro                         │
                                   └──────────────────┬─────────────────────┘
                                                      │
                                                      ▼
                              ┌────────────────────────────────────────────┐
                              │              alim_bodega                   │
                              ├────────────────────────────────────────────┤
                              │ id (PK)                                    │
                              │ codigo_bodega                              │
                              │ nombre_bodega                              │
                              │ direccion_bodega                           │
                              │ estado_bodega                              │
                              └────────────────────────────────────────────┘
```

### 4.2 Cardinalidades

| Relación | Tipo | Descripción |
|----------|------|-------------|
| Producto → Estado | N:1 | Un producto tiene un estado |
| Producto → País | N:1 | País de fabricación |
| Producto → Subgrupo | N:1 | Clasificación alimenticia |
| Producto → CLV | 1:N | Un producto puede tener múltiples CLVs |
| Producto → Empresa/Persona | N:M | Múltiples roles (5 funciones) |
| Producto → Bodega | N:M | Un producto en múltiples bodegas |

---

## 5. Mapeo de Datos

### 5.1 Transformaciones de Valores

#### Tipo de Producto
```sql
CASE tipo_producto
    WHEN 1 THEN 'Nacional'
    WHEN 2 THEN 'Importado de Union Aduanera'
    WHEN 3 THEN 'Importado de otros paises'
END
```

#### Estado de Registro
```sql
-- Solo se migran productos con estado_registro = 1 (activos)
WHERE estado_registro = 1
```

#### Estado de Producto
```sql
UPPER(ctl_estado_producto.nombre)
-- Ejemplos: 'VIGENTE', 'VENCIDO', 'CANCELADO'
```

### 5.2 Desnormalización

Los siguientes campos se desnormalizan para evitar JOINs en consultas frecuentes:

| Campo Origen | Tabla Origen | Campo Destino |
|--------------|--------------|---------------|
| `ctl_pais.nombre` | `ctl_pais` | `pais` (TEXT) |
| `sub_grupo.nombre` | `alim_sub_grupo_alimenticio` | `subgrupo_alimenticio` |
| `clasificacion.nombre` | `ctl_clasificacion_grupo_alimenticio` | `clasificacion_alimenticia` |
| `riesgo.nombre` | `ctl_tipo_riesgo` | `riesgo` |

### 5.3 Estrategia de Legacy ID

Para mantener trazabilidad y facilitar JOINs entre sistemas:

| Entidad | Formato Legacy ID | Ejemplo |
|---------|-------------------|---------|
| Producto | `PRD-{id_original}` | `PRD-12345` |
| Bodega | `BOD-{id_original}` | `BOD-456` |
| Empresa | `EMP-{id_original}` | `EMP-789` |
| Persona | `PER-{id_original}` | `PER-101` |
| CLV | `CLV-{id_original}` | `CLV-202` |
| Subgrupo | `SGR-{id_original}` | `SGR-50` |

---

## 6. Estrategia de Migración

### 6.1 Fases de Migración

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     FLUJO DE MIGRACIÓN COMPLETO                          │
└─────────────────────────────────────────────────────────────────────────┘

FASE 1: CATÁLOGOS (n8n)                 FASE 2: PRODUCTOS (SQL Scripts)
═══════════════════                     ═══════════════════════════════

┌─────────────────┐                     ┌─────────────────────────────────┐
│ SISAM           │                     │ SISAM                           │
│ ctl_* tables    │                     │ alim_producto + JOINs           │
└────────┬────────┘                     └────────────────┬────────────────┘
         │                                               │
         │ n8n Workflow                                  │ 00_export_from_sisam.sql
         ▼                                               ▼
┌─────────────────┐                     ┌─────────────────────────────────┐
│ CENTRO DE DATOS │                     │ CSV: productos_full.csv         │
│ srs_* tables    │                     │ 42+ columnas desnormalizadas    │
│                 │                     └────────────────┬────────────────┘
│ • srs_bodega    │                                      │
│ • srs_entidad   │                                      │ TablePlus Import
│ • srs_sub_grupo │                     ┌────────────────▼────────────────┐
│ • paises        │                     │ CORE: migration_alim_producto_  │
└─────────────────┘                     │        temp                     │
         │                              └────────────────┬────────────────┘
         │                                               │
         │                                               │ 02_migrate_from_temp.sql
         │                              ┌────────────────▼────────────────┐
         │                              │ CORE:                           │
         │                              │ • expedient_base_entities       │
         │                              │ • expedient_base_entity_fields  │
         │                              │ • expedient_base_registries     │
         │                              │ • expedient_base_registry_fields│
         │                              └────────────────┬────────────────┘
         │                                               │
         ▼                                               │
FASE 3: RELACIONES                                       │
═══════════════════                     ┌────────────────▼────────────────┐
                                        │ CORE:                           │
    Usa UUIDs de srs_bodega ──────────► │ expedient_base_registry_relation│
    para vincular productos             │                                 │
    con sus bodegas                     │ ~42,795 relaciones              │
                                        └─────────────────────────────────┘
```

### 6.2 Dependencias de Ejecución

```
┌─────────────────────────────────────────────────────────────────────┐
│                      ORDEN DE EJECUCIÓN                              │
└─────────────────────────────────────────────────────────────────────┘

1. CATÁLOGOS BASE (n8n - paralelo)
   ├── srs_pais             ← Sin dependencias
   ├── srs_material         ← Sin dependencias
   ├── srs_tipo_riesgo      ← Sin dependencias
   └── srs_marcas           ← Sin dependencias

2. CATÁLOGOS DEPENDIENTES (n8n - secuencial)
   ├── srs_clasificacion_grupo_alimenticio ← Depende de: tipo_riesgo
   └── srs_sub_grupo_alimenticio           ← Depende de: clasificacion

3. ENTIDADES (n8n)
   └── srs_entidad          ← Unifica empresas + personas

4. BODEGAS (n8n)
   └── srs_bodega           ← Sin dependencias de expediente

5. CLV (n8n)
   └── srs_certificado_libre_venta ← Sin dependencias de expediente

6. PRODUCTOS (SQL Scripts)
   ├── 00_export_from_sisam.sql      ← Genera CSV
   ├── 01_create_temp_table.sql      ← Prepara staging
   └── 02_migrate_from_temp.sql      ← Migra a expedient_base

7. RELACIONES (SQL Scripts)
   └── 05_migrate_bodega_relations.sql ← Vincula productos con bodegas
```

### 6.3 Estrategia de Deduplicación

| Escenario | Estrategia |
|-----------|------------|
| Múltiples CLVs por producto | `DISTINCT ON (p.id) ORDER BY clv.fecha_emision DESC` - Toma el más reciente |
| Múltiples empresas por función | `DISTINCT ON (p.id, función)` - Toma la primera registrada |
| Productos duplicados | Filtro `estado_registro = 1` + `DISTINCT ON` |

---

## 7. Scripts y Workflows

### 7.1 Scripts SQL Disponibles

| Script | Ubicación | Propósito | Ejecutar en |
|--------|-----------|-----------|-------------|
| `00_export_from_sisam.sql` | `scripts/` | Extrae productos con JOINs | SISAM |
| `00_setup_temp_catalogs.sql` | `scripts/` | Preparar catálogos temporales | Core |
| `01_create_temp_table.sql` | `scripts/` | Crea tabla de staging | Core |
| `02_migrate_from_temp.sql` | `scripts/` | Migra a expedient_base | Core |
| `05_migrate_bodega_relations.sql` | `scripts/` | Crea relaciones producto-bodega | Core |
| `99_rollback_migration.sql` | `scripts/` | Rollback completo | Core |

### 7.2 Workflows n8n

| Workflow | ID | Propósito |
|----------|----|-----------|
| `Migrate All SRS Tables (Master Orchestrator)` | - | Orquesta migración de catálogos |
| `Migrate SRS Table (Parametrized)` | `L5EXIfRXTrEXMkFz` | Ejecuta migración individual |

### 7.3 Ejemplo: Query de Extracción Principal

```sql
SELECT DISTINCT ON (p.id)
    -- Identificación
    p.id AS original_id,
    TRIM(p.nombre) AS nombre,
    NULLIF(TRIM(p.num_registro_sanitario), '') AS num_registro_sanitario,

    -- Clasificación
    CASE p.tipo_producto
        WHEN 1 THEN 'Nacional'
        WHEN 2 THEN 'Importado de Union Aduanera'
        WHEN 3 THEN 'Importado de otros paises'
    END AS tipo_producto,

    -- Catálogos desnormalizados
    UPPER(ep.nombre) AS estado_producto,
    pais_fab.nombre AS pais,
    sg.nombre AS subgrupo_alimenticio,
    cga.nombre AS clasificacion_alimenticia,
    tr.nombre AS riesgo,

    -- Fechas
    TO_CHAR(p.fecha_emision_registro, 'DD/MM/YYYY') AS fecha_emision_registro,
    TO_CHAR(p.fecha_vigencia_registro, 'DD/MM/YYYY') AS fecha_vigencia_registro,

    -- CLV
    clv.cod_clv AS codigo_clv,
    pclv.nombre_prod_segun_clv AS nombre_producto_clv,
    pais_clv.nombre AS pais_procedencia_clv,

    -- Propietario (función = 4)
    prop_aux.nombre AS propietario_nombre,
    prop_aux.nit AS propietario_nit,
    prop_aux.correo_electronico AS propietario_correo,
    -- ... más campos

    -- IDs para relaciones
    p.id_sub_grupo_alimenticio AS original_sub_id,
    pais_fab.isonumero AS original_pais_iso,
    clv.id AS original_clv_id

FROM alim_producto p
LEFT JOIN ctl_estado_producto ep ON ep.id = p.id_ctl_estado_producto
LEFT JOIN ctl_pais pais_fab ON pais_fab.id = p.id_ctl_pais
LEFT JOIN alim_sub_grupo_alimenticio sg ON sg.id = p.id_sub_grupo_alimenticio
-- ... más JOINs

WHERE p.estado_registro = 1
  AND p.fecha_emision_registro IS NOT NULL
  AND p.fecha_vigencia_registro IS NOT NULL

ORDER BY p.id, clv.fecha_emision DESC NULLS LAST;
```

---

## 8. Validaciones y Golden Rules

### 8.1 Validaciones Pre-Migración

```sql
-- 1. Conteo de productos a migrar
SELECT COUNT(DISTINCT p.id) AS total_productos
FROM alim_producto p
WHERE p.estado_registro = 1
  AND p.fecha_emision_registro IS NOT NULL
  AND p.fecha_vigencia_registro IS NOT NULL;

-- 2. Distribución por tipo
SELECT
    CASE tipo_producto
        WHEN 1 THEN 'Nacional'
        WHEN 2 THEN 'Importado UA'
        WHEN 3 THEN 'Importado Otros'
    END AS tipo,
    COUNT(*) AS cantidad
FROM alim_producto
WHERE estado_registro = 1
GROUP BY tipo_producto;

-- 3. Verificar integridad referencial
SELECT 'Productos sin país' AS check, COUNT(*) AS total
FROM alim_producto WHERE id_ctl_pais IS NULL AND estado_registro = 1
UNION ALL
SELECT 'Productos sin subgrupo', COUNT(*)
FROM alim_producto WHERE id_sub_grupo_alimenticio IS NULL AND estado_registro = 1;
```

### 8.2 Validaciones Post-Migración

```sql
-- 1. Comparar conteos
SELECT
    (SELECT COUNT(*) FROM migration_alim_producto_temp) AS origen,
    (SELECT COUNT(*) FROM expedient_base_registries
     WHERE legacy_id LIKE 'PRD-%') AS destino;

-- 2. Verificar campos migrados
SELECT f.name AS campo, COUNT(rf.id) AS registros_con_valor
FROM expedient_base_entity_fields f
JOIN expedient_base_entities e ON e.id = f.expedient_base_entity_id
LEFT JOIN expedient_base_registry_fields rf ON rf.expedient_base_entity_field_id = f.id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
GROUP BY f.name, f."order"
ORDER BY f."order";

-- 3. Muestreo aleatorio
SELECT r.unique_code, r.name, r.legacy_id
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
ORDER BY RANDOM()
LIMIT 10;
```

### 8.3 Golden Rules

| Regla | Validación | Threshold |
|-------|------------|-----------|
| Completitud | Registros destino ≥ 99% de origen | 99% |
| Campos requeridos | 100% tienen nombre + país | 100% |
| Relaciones | Bodegas migradas = origen | 100% |
| Integridad | Sin registros huérfanos | 0 |
| Duplicados | Sin legacy_id duplicados | 0 |

---

## 9. Consideraciones Especiales

### 9.1 Manejo de NULL

| Campo | Estrategia |
|-------|------------|
| Campos opcionales | Se insertan solo si `IS NOT NULL` |
| IDs de relación | Se insertan como `""` (string vacío) si no hay match |
| Fechas | Formato `DD/MM/YYYY` o NULL |

### 9.2 Archivos y Rutas

Los siguientes campos contienen rutas de archivos que **NO se migran en esta fase**:

- `ruta_archivo_ingredientes`
- `ruta_archivo_vineta_reconocimiento`
- `ruta_archivo_iva`
- `ruta_escritura_publica`
- `ruta_registro_comercio`

**Plan futuro**: Migración de archivos a storage blob + actualización de referencias.

### 9.3 Formato de Valores en Registry Fields

Los valores se almacenan como **JSON string**:

```sql
-- Correcto
value = '"Nombre del producto"'  -- Con comillas dobles dentro

-- Para fechas
value = '"17/01/2026"'

-- Para campos vacíos de relación
value = '""'
```

### 9.4 Manejo de Caracteres Especiales

```sql
-- Los valores se sanitizan automáticamente
-- Comillas internas se escapan
'\"Valor con \"comillas\" internas\"'
```

---

## 10. Roadmap de Ejecución

### 10.1 Checklist de Migración

#### Pre-Migración
- [ ] Verificar conectividad a SISAM, Core, Centro de Datos
- [ ] Ejecutar queries de validación pre-migración
- [ ] Revisar que catálogos estén migrados en Centro de Datos
- [ ] Tener backup de bases de datos

#### Fase 1: Catálogos (Si no están)
- [ ] Ejecutar n8n Master Orchestrator para SRS Tables
- [ ] Verificar `srs_bodega` tiene legacy_id
- [ ] Verificar `srs_entidad` tiene legacy_id
- [ ] Verificar `paises` tiene iso_number

#### Fase 2: Productos
- [ ] Ejecutar `00_export_from_sisam.sql` en SISAM
- [ ] Exportar resultado como CSV
- [ ] Crear tabla temporal en Core
- [ ] Importar CSV con TablePlus
- [ ] Ejecutar `02_migrate_from_temp.sql`
- [ ] Validar conteos post-migración

#### Fase 3: Relaciones
- [ ] Exportar relaciones producto-bodega de SISAM
- [ ] Exportar mapeo UUID bodegas de Centro de Datos
- [ ] Importar en Core
- [ ] Ejecutar INSERT de relaciones
- [ ] Validar conteo de relaciones

#### Post-Migración
- [ ] Ejecutar queries de validación post-migración
- [ ] Verificar muestra aleatoria en UI
- [ ] Documentar métricas finales
- [ ] Limpiar tablas temporales

### 10.2 Tiempos Estimados

| Fase | Duración Estimada |
|------|-------------------|
| Pre-Migración | 30 min |
| Catálogos (si faltan) | 1-2 horas |
| Extracción SISAM | 15 min |
| Importación CSV | 30 min |
| Migración a expedient_base | 1-2 horas |
| Relaciones bodega | 30 min |
| Validaciones | 30 min |
| **Total** | **4-6 horas** |

### 10.3 Contactos y Recursos

| Recurso | Ubicación |
|---------|-----------|
| DDLs documentados | `/assets/ddls/` |
| Scripts SQL | `/scripts/` |
| Guías de migración | `/assets/guides/` |
| Reportes | `/assets/reports/` |
| Workflows n8n | `/srs/` |

---

## 📚 Apéndices

### A. Estructura de Archivos del Proyecto

```
/Users/heycsar/Developer/Elaniin/Migration/
├── assets/
│   ├── ddls/                    # DDLs documentados (33 archivos)
│   │   ├── expedient_base_*.md  # Tablas de expediente
│   │   ├── alim_*.md            # Tablas origen SISAM
│   │   ├── srs_*.md             # Tablas Centro de Datos
│   │   └── ctl_*.md             # Catálogos
│   ├── guides/
│   │   └── migration_bodega_relations.md
│   └── reports/
│       ├── extraction_report_t81.md
│       └── data_engineer_migration_expedient_report.md  # Este documento
├── scripts/
│   ├── 00_export_from_sisam.sql
│   ├── 00_setup_temp_catalogs.sql
│   ├── 01_create_temp_table.sql
│   ├── 02_migrate_from_temp.sql
│   ├── 05_migrate_bodega_relations.sql
│   └── 99_rollback_migration.sql
├── srs/
│   ├── Migrate All SRS Tables (Master Orchestrator).json
│   ├── Migrate SRS Table (Parametrized).json
│   └── ...
└── README.md                    # Documentación general del proyecto
```

### B. Queries de Referencia Rápida

```sql
-- Ver estado actual de expedientes migrados
SELECT
    e.name AS entidad,
    COUNT(r.id) AS registros,
    MIN(r.created_at) AS primera_migracion,
    MAX(r.created_at) AS ultima_migracion
FROM expedient_base_entities e
LEFT JOIN expedient_base_registries r ON r.expedient_base_entity_id = e.id
GROUP BY e.id
ORDER BY e.name;

-- Ver relaciones de un producto específico
SELECT
    r.legacy_id,
    r.name AS producto,
    rel.relation_type,
    rel.reference_name,
    rel.display_value
FROM expedient_base_registries r
JOIN expedient_base_registry_relation rel ON rel.expedient_base_registry_id = r.id
WHERE r.legacy_id = 'PRD-12345';

-- Ver estructura de campos de T81
SELECT
    f.name,
    f.field_type,
    f.is_required,
    f."order",
    f.configuration->>'section'->>'title' AS seccion
FROM expedient_base_entity_fields f
JOIN expedient_base_entities e ON e.id = f.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
ORDER BY f."order";
```

---

*Documento generado: 2026-01-18*
*Última actualización: 2026-01-18*
*Versión: 1.0*

---

## 📊 Sección Data Expert

> Esta sección fue generada aplicando el skill [`data-expert`](./.agent/skills/data-expert/SKILL.md) siguiendo las mejores prácticas de un Senior Data Engineer.

### DE.1 Queries de Diagnóstico Pre-Migración

Ejecutar estos queries **ANTES** de iniciar la migración para validar supuestos:

```sql
-- =============================================================================
-- DIAGNÓSTICO 1: Volumen total y filtros aplicados
-- =============================================================================
SELECT
    'Total productos en tabla' as metrica,
    COUNT(*) as valor
FROM alim_producto
UNION ALL
SELECT
    'Productos con estado_registro = 1 (activos)',
    COUNT(*)
FROM alim_producto WHERE estado_registro = 1
UNION ALL
SELECT
    'Productos activos CON fechas válidas',
    COUNT(*)
FROM alim_producto
WHERE estado_registro = 1
  AND fecha_emision_registro IS NOT NULL
  AND fecha_vigencia_registro IS NOT NULL
UNION ALL
SELECT
    'Diferencia (productos excluidos)',
    (SELECT COUNT(*) FROM alim_producto WHERE estado_registro = 1) -
    (SELECT COUNT(*) FROM alim_producto
     WHERE estado_registro = 1
       AND fecha_emision_registro IS NOT NULL
       AND fecha_vigencia_registro IS NOT NULL);

-- =============================================================================
-- DIAGNÓSTICO 2: Cardinalidades (⚠️ CRÍTICO - Revisar antes de JOINs)
-- =============================================================================

-- 2.1 Productos con múltiples CLVs (anomalía conocida)
SELECT
    'Productos con 1 CLV' as cardinalidad,
    COUNT(*) as cantidad
FROM (
    SELECT p.id, COUNT(pclv.id) as clvs
    FROM alim_producto p
    LEFT JOIN alim_producto_certificado_libre_venta pclv ON pclv.id_alim_producto = p.id
    WHERE p.estado_registro = 1
    GROUP BY p.id
    HAVING COUNT(pclv.id) = 1
) t
UNION ALL
SELECT 'Productos con 2+ CLVs', COUNT(*)
FROM (
    SELECT p.id, COUNT(pclv.id) as clvs
    FROM alim_producto p
    JOIN alim_producto_certificado_libre_venta pclv ON pclv.id_alim_producto = p.id
    WHERE p.estado_registro = 1
    GROUP BY p.id
    HAVING COUNT(pclv.id) > 1
) t
UNION ALL
SELECT 'Productos SIN CLV', COUNT(*)
FROM alim_producto p
LEFT JOIN alim_producto_certificado_libre_venta pclv ON pclv.id_alim_producto = p.id
WHERE p.estado_registro = 1 AND pclv.id IS NULL;

-- 2.2 Productos con múltiples empresas por función
SELECT
    ctl.nombre as funcion,
    COUNT(DISTINCT fp.id_alim_producto) as productos_con_multiple
FROM alim_empresa_persona_aux_funcion_producto fp
JOIN ctl_funcion_empresa_persona ctl ON ctl.id = fp.id_ctl_funcion_empresa_persona
JOIN alim_producto p ON p.id = fp.id_alim_producto
WHERE p.estado_registro = 1
GROUP BY ctl.nombre, fp.id_alim_producto, fp.id_ctl_funcion_empresa_persona
HAVING COUNT(*) > 1
ORDER BY funcion;

-- 2.3 Bodegas por producto (N:M esperado)
SELECT
    CASE
        WHEN cnt = 0 THEN '0 bodegas'
        WHEN cnt = 1 THEN '1 bodega'
        WHEN cnt BETWEEN 2 AND 5 THEN '2-5 bodegas'
        ELSE '6+ bodegas'
    END as rango,
    COUNT(*) as productos
FROM (
    SELECT p.id, COUNT(bp.id_alim_bodega) as cnt
    FROM alim_producto p
    LEFT JOIN alim_bodega_producto bp ON bp.id_alim_producto = p.id
    WHERE p.estado_registro = 1
    GROUP BY p.id
) t
GROUP BY rango
ORDER BY rango;

-- =============================================================================
-- DIAGNÓSTICO 3: Integridad Referencial (detectar huérfanos)
-- =============================================================================
SELECT 'Productos sin país (id_ctl_pais NULL)' as check_name, COUNT(*) as count
FROM alim_producto WHERE estado_registro = 1 AND id_ctl_pais IS NULL
UNION ALL
SELECT 'Productos sin subgrupo alimenticio', COUNT(*)
FROM alim_producto WHERE estado_registro = 1 AND id_sub_grupo_alimenticio IS NULL
UNION ALL
SELECT 'Productos sin estado_producto', COUNT(*)
FROM alim_producto WHERE estado_registro = 1 AND id_ctl_estado_producto IS NULL
UNION ALL
SELECT 'CLVs referenciando país inexistente', COUNT(*)
FROM alim_certificado_libre_venta clv
LEFT JOIN ctl_pais p ON p.id = clv.id_ctl_pais
WHERE p.id IS NULL AND clv.id_ctl_pais IS NOT NULL;

-- =============================================================================
-- DIAGNÓSTICO 4: Calidad de datos (NULLs y vacíos)
-- =============================================================================
SELECT
    'nombre vacío o NULL' as campo,
    COUNT(*) as afectados
FROM alim_producto WHERE estado_registro = 1 AND (nombre IS NULL OR TRIM(nombre) = '')
UNION ALL
SELECT 'num_registro_sanitario vacío', COUNT(*)
FROM alim_producto WHERE estado_registro = 1 AND (num_registro_sanitario IS NULL OR TRIM(num_registro_sanitario) = '')
UNION ALL
SELECT 'correo_electronico inválido en empresas', COUNT(*)
FROM alim_empresa_persona_aux WHERE correo_electronico NOT LIKE '%@%.%' AND correo_electronico IS NOT NULL;
```

---

### DE.2 Anomalías Detectadas y Documentadas

| # | Anomalía | Afectados | Impacto | Decisión | Documento |
|---|----------|-----------|---------|----------|-----------|
| 1 | Productos con múltiples CLVs | 21 activos | Medio | Migrar solo el CLV más reciente | [`anomaly_multiple_clv.md`](./anomaly_multiple_clv.md) |
| 2 | Productos sin fechas de registro | ~200 | Bajo | Excluir de migración (filtro aplicado) | N/A |
| 3 | Productos sin propietario asignado | Variable | Bajo | Campos de propietario quedan NULL | N/A |
| 4 | Múltiples empresas por función | Raro | Bajo | `DISTINCT ON` toma la primera | N/A |

#### Detalle: Anomalía #1 - Múltiples CLVs

- **Cantidad**: 49 productos totales (21 activos, 28 inactivos)
- **Causa raíz**: Renovaciones anuales del certificado (no error de datos)
- **Solución**: `DISTINCT ON (p.id) ORDER BY clv.fecha_emision DESC`
- **CLVs no migrados**: ~60 registros (2do y 3er CLV de cada producto)

---

### DE.3 Recomendaciones de Optimización

#### Índices Recomendados (Post-Migración)

```sql
-- =============================================================================
-- ÍNDICES PARA expedient_base_registries
-- =============================================================================

-- Búsqueda por legacy_id (JOIN con sistemas legacy)
CREATE INDEX IF NOT EXISTS idx_ebr_legacy_id
ON expedient_base_registries(legacy_id);

-- Búsqueda por entidad + estado (filtros comunes)
CREATE INDEX IF NOT EXISTS idx_ebr_entity_deleted
ON expedient_base_registries(expedient_base_entity_id)
WHERE deleted_at IS NULL;

-- Búsqueda por metadata (consultas JSONB)
CREATE INDEX IF NOT EXISTS idx_ebr_metadata_original_id
ON expedient_base_registries USING GIN ((metadata->'original_id'));

-- =============================================================================
-- ÍNDICES PARA expedient_base_registry_fields
-- =============================================================================

-- Consultas por registro + campo
CREATE INDEX IF NOT EXISTS idx_ebrf_registry_field
ON expedient_base_registry_fields(expedient_base_registry_id, expedient_base_entity_field_id);

-- Búsqueda por valor (para búsquedas textuales)
CREATE INDEX IF NOT EXISTS idx_ebrf_value_trgm
ON expedient_base_registry_fields USING GIN (value gin_trgm_ops);
-- Nota: Requiere extensión pg_trgm: CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- =============================================================================
-- ÍNDICES PARA expedient_base_registry_relation
-- =============================================================================

-- Búsqueda de relaciones por producto
CREATE INDEX IF NOT EXISTS idx_ebrr_registry_type
ON expedient_base_registry_relation(expedient_base_registry_id, relation_type);

-- Búsqueda inversa (encontrar productos relacionados a una bodega)
CREATE INDEX IF NOT EXISTS idx_ebrr_relation_reference
ON expedient_base_registry_relation(relation_id, reference_name);
```

#### Configuración de VACUUM/ANALYZE

```sql
-- Después de migración masiva, actualizar estadísticas
ANALYZE expedient_base_registries;
ANALYZE expedient_base_registry_fields;
ANALYZE expedient_base_registry_relation;

-- Configurar autovacuum agresivo para tablas grandes
ALTER TABLE expedient_base_registry_fields
SET (autovacuum_vacuum_scale_factor = 0.1,
     autovacuum_analyze_scale_factor = 0.05);
```

---

### DE.4 Queries de Validación Post-Migración

```sql
-- =============================================================================
-- GOLDEN RULE: Completitud >= 99%
-- =============================================================================
SELECT
    'Origen (temp table)' as fuente,
    COUNT(*) as registros
FROM migration_alim_producto_temp
UNION ALL
SELECT
    'Destino (expedient_base_registries)',
    COUNT(*)
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
WHERE e.name = 'T81 - Registro Sanitario Alimentos';

-- Calcular porcentaje de completitud
SELECT
    ROUND(
        (SELECT COUNT(*)::numeric FROM expedient_base_registries r
         JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
         WHERE e.name = 'T81 - Registro Sanitario Alimentos') /
        (SELECT COUNT(*)::numeric FROM migration_alim_producto_temp) * 100,
        2
    ) as porcentaje_completitud;
-- Esperado: >= 99.00%

-- =============================================================================
-- Validación de campos requeridos
-- =============================================================================
SELECT
    f.name as campo,
    COUNT(rf.id) as registros_con_valor,
    ROUND(COUNT(rf.id)::numeric /
        (SELECT COUNT(*) FROM expedient_base_registries r2
         JOIN expedient_base_entities e2 ON e2.id = r2.expedient_base_entity_id
         WHERE e2.name = 'T81 - Registro Sanitario Alimentos') * 100, 2
    ) as porcentaje
FROM expedient_base_entity_fields f
JOIN expedient_base_entities e ON e.id = f.expedient_base_entity_id
LEFT JOIN expedient_base_registry_fields rf ON rf.expedient_base_entity_field_id = f.id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
  AND f.is_required = true
GROUP BY f.name
ORDER BY porcentaje;
-- Esperado: 100% para campos requeridos

-- =============================================================================
-- Validación de relaciones bodega
-- =============================================================================
SELECT
    'Relaciones en origen (SISAM)' as metrica,
    (SELECT COUNT(*) FROM migration_bodega_producto) as valor
UNION ALL
SELECT
    'Relaciones en destino',
    COUNT(*)
FROM expedient_base_registry_relation
WHERE reference_name = 'srs_bodega';

-- =============================================================================
-- Muestreo aleatorio para verificación manual
-- =============================================================================
SELECT
    r.legacy_id,
    r.name as producto,
    rf_tipo.value as tipo_producto,
    rf_pais.value as pais
FROM expedient_base_registries r
JOIN expedient_base_entities e ON e.id = r.expedient_base_entity_id
LEFT JOIN expedient_base_entity_fields f_tipo ON f_tipo.name = 'Tipo de producto' AND f_tipo.expedient_base_entity_id = e.id
LEFT JOIN expedient_base_registry_fields rf_tipo ON rf_tipo.expedient_base_registry_id = r.id AND rf_tipo.expedient_base_entity_field_id = f_tipo.id
LEFT JOIN expedient_base_entity_fields f_pais ON f_pais.name = 'País de fabricación' AND f_pais.expedient_base_entity_id = e.id
LEFT JOIN expedient_base_registry_fields rf_pais ON rf_pais.expedient_base_registry_id = r.id AND rf_pais.expedient_base_entity_field_id = f_pais.id
WHERE e.name = 'T81 - Registro Sanitario Alimentos'
ORDER BY RANDOM()
LIMIT 10;
```

---

### DE.5 Checklist de Calidad (Data Expert)

| Criterio | Validación | Status |
|----------|------------|--------|
| ✅ Idempotencia | Scripts usan `ON CONFLICT DO NOTHING` | Implementado |
| ✅ Cardinalidad validada | Anomalía de múltiples CLVs documentada | Documentado |
| ✅ Integridad referencial | LEFT JOINs para evitar pérdida de datos | Implementado |
| ✅ Trazabilidad | `legacy_id` en todos los registros | Implementado |
| ✅ Validación pre/post | Queries de conteo incluidos | Incluido |
| ✅ Documentación de anomalías | Reporte `anomaly_multiple_clv.md` | Creado |
| ⬜ Rollback probado | Pendiente de ejecutar `99_rollback_migration.sql` | Pendiente |
| ⬜ Performance validado | EXPLAIN ANALYZE en queries de consulta | Pendiente |

---

*Documento generado: 2026-01-18*
*Última actualización: 2026-01-18*
*Versión: 1.1 - Actualizado con sección Data Expert*
*Skill aplicado: [`data-expert`](./.agent/skills/data-expert/SKILL.md)*
