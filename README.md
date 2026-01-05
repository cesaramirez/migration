# Elaniin Migration System

Sistema completo de migración ETL basado en n8n para migrar datos desde múltiples fuentes (PostgreSQL SRS y Google Sheets ACH) hacia el Data Center de PostgreSQL SDT.

---

## 📋 Tabla de Contenidos

- [Visión General](#-visión-general)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Sistemas de Migración](#-sistemas-de-migración)
  - [1. Migración SRS (PostgreSQL → PostgreSQL)](#1-migración-srs-postgresql--postgresql)
  - [2. Migración ACH (Google Sheets → PostgreSQL)](#2-migración-ach-google-sheets--postgresql)
- [Conceptos Clave](#-conceptos-clave)
- [Inicio Rápido](#-inicio-rápido)
- [Configuración Detallada](#-configuración-detallada)
- [Monitoreo y Debugging](#-monitoreo-y-debugging)
- [Solución de Problemas](#-solución-de-problemas)

---

## 🎯 Visión General

Este repositorio contiene workflows de n8n que automatizan la migración de datos desde diferentes fuentes hacia un esquema unificado en PostgreSQL. El sistema soporta:

- ✅ **Migración desde PostgreSQL** (tablas `alim_*` → `srs_*`)
- ✅ **Migración desde Google Sheets** (catálogos ACH → `ach_*`)
- ✅ Generación automática de códigos únicos
- ✅ Mapeo de valores y transformaciones
- ✅ Gestión de relaciones entre tablas
- ✅ UPSERT automático (actualización de registros existentes)
- ✅ Auditoría completa de migraciones
- ✅ Batch processing para grandes volúmenes
- ✅ Comentarios SQL con valores ENUM

---

## 📁 Estructura del Proyecto

```
/Users/heycsar/Developer/Elaniin/Migration/
├── srs/
│   ├── Migrate All SRS Tables (Master Orchestrator).json
│   ├── Migrate SRS Table (Parametrized).json
│   ├── Migrate All ACH Google Sheets (Master Orchestrator).json
│   └── Migrate Google Sheets Table (Parametrized).json
├── scripts/
│   └── update_ach_file_ids.py
├── GUIA_CONFIGURACION_ACH_GOOGLE_SHEETS.md
└── README.md (este archivo)
```

---

## 🔄 Sistemas de Migración

### 1. Migración SRS (PostgreSQL → PostgreSQL)

Migra datos desde el esquema legacy (`alim_*`) hacia el nuevo esquema (`srs_*`).

#### **Workflows:**
- **Master Orchestrator:** `Migrate All SRS Tables (Master Orchestrator).json`
- **Workflow Parametrizado:** `Migrate SRS Table (Parametrized).json` (ID: `L5EXIfRXTrEXMkFz`)

#### **Tablas Gestionadas:**

| Categoría | Tablas | Descripción |
|-----------|--------|-------------|
| **Gestión de Bodegas** | `srs_bodega`, `srs_empresa_persona_bodega`, `srs_bodega_producto` | Administración de bodegas y asignaciones |
| **Productos** | `srs_producto`, `srs_marca_producto`, `srs_material_envase_producto` | Catálogo de productos y marcas |
| **Certificados** | `srs_certificado_libre_venta`, `srs_producto_certificado_libre_venta` | Certificados de libre venta |
| **Catálogos Base** | `srs_estado_producto`, `srs_pais`, `srs_departamento`, `srs_municipio`, etc. | Tablas de referencia |
| **Entidades** | `srs_entidad_experiment` | Unificación de empresas y personas |

#### **Características Especiales:**
- **Mapeo de valores:** Conversión de ENUMs (ej: `1 → 'ACTIVO'`, `2 → 'INACTIVO'`)
- **Relaciones:** Gestión automática de foreign keys
- **Campos especiales:** Manejo de `VARCHAR(250)`, `BOOLEAN DEFAULT false`, etc.
- **Prefijos de código:** Generación automática según tabla (ej: `BOD_001`)

#### **Ejemplo de Configuración (SRS):**

```javascript
return {
  source_identifier: 'alim_bodega',
  table_destination: 'srs_bodega',
  code_prefix: 'BOD',
  use_db_prefix: true,

  required_fields: ['codigo_bodega', 'nombre_bodega'],
  promoted_fields: ['codigo_bodega', 'nombre_bodega', 'estado_bodega'],

  field_types: {
    'estado_bodega': 'VARCHAR(50)'
  },

  value_mappings: {
    'estado_bodega': {
      1: 'ACTIVO',
      2: 'INACTIVO'
    }
  },

  field_mappings: {
    'codigo_bodega': 'codigo_bodega',
    'nombre_bodega': 'nombre_bodega',
    'estado_bodega': 'estado_bodega'
  },

  relationships: {},
  batch_size: 500
};
```

---

### 2. Migración ACH (Google Sheets → PostgreSQL)

Migra catálogos del sistema ACH (Administración de Conjuntos Habitacionales) desde Google Sheets hacia PostgreSQL.

#### **Workflows:**
- **Master Orchestrator:** `Migrate All ACH Google Sheets (Master Orchestrator).json`
- **Workflow Parametrizado:** `Migrate Google Sheets Table (Parametrized).json` (ID: `hvZzjopsdq38w4Ox`)

#### **Catálogos Incluidos (20):**

| # | Tabla | Prefijo | Descripción |
|---|-------|---------|-------------|
| 1 | `ach_parcelaciones_tipo` | PAR | Tipos de parcelaciones |
| 2 | `ach_inmuebles_tipo` | INM | Tipos de inmuebles |
| 3 | `ach_propietarios_tipo` | PRO | Tipos de propietarios |
| 4 | `ach_servicios_tipo` | SRV | Tipos de servicios |
| 5 | `ach_estados_general` | EST | Estados generales |
| 6 | `ach_estados_pago` | EPG | Estados de pagos |
| 7 | `ach_estados_mantenimiento` | EMT | Estados de mantenimiento |
| 8 | `ach_areas_comunes` | ARE | Áreas comunes |
| 9 | `ach_tipos_mantenimiento` | MAN | Tipos de mantenimiento |
| 10 | `ach_tipos_pago` | TPG | Formas de pago |
| 11 | `ach_conceptos_cobro` | COB | Conceptos de cobro |
| 12 | `ach_paises` | PAI | Catálogo de países |
| 13 | `ach_departamentos` | DEP | Departamentos |
| 14 | `ach_municipios` | MUN | Municipios |
| 15 | `ach_bancos` | BAN | Entidades bancarias |
| 16 | `ach_tipos_documento` | DOC | Tipos de documentos |
| 17 | `ach_roles_usuario` | ROL | Roles de usuarios |
| 18 | `ach_permisos` | PER | Permisos del sistema |
| 19 | `ach_tipos_notificacion` | NOT | Tipos de notificaciones |
| 20 | `ach_prioridades` | PRI | Niveles de prioridad |

#### **Características Especiales:**
- **Lectura desde Google Sheets:** Integración OAuth2
- **Filas configurables:** `header_row` y `data_start_row` ajustables
- **Mapeo de valores:** Conversión de `SI/NO → true/false`
- **Validación de campos:** `required_fields` obligatorios

#### **Ejemplo de Configuración (ACH):**

```javascript
return {
  source_identifier: 'ACH Excel: parcelaciones_tipo',

  // Configuración de Google Sheets
  spreadsheet_id: '1ABC...XYZ123',  // ⚠️ ACTUALIZAR
  sheet_name: 'Parcelaciones_Tipo',
  header_row: 7,
  data_start_row: 8,

  // Configuración de destino
  table_destination: 'ach_parcelaciones_tipo',
  code_prefix: 'PAR',
  use_db_prefix: false,

  required_fields: ['Código', 'Nombre'],
  promoted_fields: ['Código', 'Nombre', '¿Activo?'],

  field_types: {
    '¿Activo?': 'BOOLEAN DEFAULT true'
  },

  value_mappings: {
    '¿Activo?': {'SI': true, 'NO': false}
  },

  field_mappings: {
    'Código': 'codigo',
    'Nombre': 'nombre',
    '¿Activo?': 'activo'
  },

  relationships: {},
  batch_size: 500,
  register_in_data_center: true,
  table_description: 'Tipos de parcelaciones'
};
```

---

## 🔑 Conceptos Clave

### **Config Nodes**
Nodos de tipo `n8n-nodes-base.code` que contienen un bloque `jsCode` con la configuración de migración:
- Tabla origen y destino
- Mapeo de campos
- Transformaciones de valores
- Relaciones entre tablas
- Tamaño de batch

### **Migrate Nodes**
Nodos de tipo `n8n-nodes-base.executeWorkflow` que invocan el workflow parametrizado para ejecutar la migración usando la configuración del Config node anterior.

### **Master Orchestrator**
Workflow principal que ejecuta secuencialmente todos los Config y Migrate nodes, generando un `batch_id` maestro para auditoría.

### **Parametrized Workflow**
Workflow reutilizable que recibe configuración como parámetros y ejecuta la lógica de migración:
1. Lee datos de la fuente
2. Valida campos requeridos
3. Transforma valores según `value_mappings`
4. Crea/actualiza tabla destino
5. Inserta datos en batches
6. Registra auditoría

### **Objeto `attributes` (JSONB)**

Cada registro migrado incluye una columna `attributes` de tipo JSONB que consolida toda la metadata de migración y auditoría:

#### **Estructura para SRS Tables (6 campos):**
```json
{
  "original_record": { ... },          // Registro completo del sistema origen
  "original_id": "alim_empresa:123",   // Formato: tabla_origen:id_original
  "sys_batch_id": "BATCH_20260105...", // ID del lote de migración
  "extracted_at": "2026-01-05T12:30:00.000Z",
  "source_table": "alim_empresa",
  "source_database": "SISAM"
}
```

#### **Estructura para Google Sheets (5 campos):**
```json
{
  "original_record": { ... },          // Registro completo del archivo origen
  "sys_batch_id": "BATCH_20260105...", // ID del lote de migración
  "extracted_at": "2026-01-05T12:30:00.000Z",
  "source_table": "Hoja1",
  "source_database": "Google Drive XLSX"
}
```

#### **Consultas SQL con `attributes`:**

```sql
-- 1. Consultar metadata de migración
SELECT
  code,
  attributes->>'original_id' as original_id,
  attributes->>'sys_batch_id' as batch_id,
  attributes->>'source_table' as tabla_origen
FROM srs_material
LIMIT 5;

-- 2. Filtrar por batch específico
SELECT code, nombre
FROM srs_material
WHERE attributes->>'sys_batch_id' = 'BATCH_20260105_122900';

-- 3. Auditoría: Ver todos los batches
SELECT
  attributes->>'sys_batch_id' as batch_id,
  COUNT(*) as total_registros,
  MIN(attributes->>'extracted_at') as primera_extraccion
FROM srs_material
GROUP BY attributes->>'sys_batch_id'
ORDER BY primera_extraccion DESC;

-- 4. Acceder a campos no promovidos del registro original
SELECT
  code,
  nombre,
  attributes->'original_record'->>'campo_no_promovido' as campo_extra
FROM srs_material
WHERE attributes->'original_record'->>'campo_no_promovido' IS NOT NULL;
```

**Beneficios:**
- ✅ Consolidación de metadata en un solo lugar
- ✅ Redundancia intencional (campos también existen como columnas para performance)
- ✅ Trazabilidad completa del origen y proceso de migración
- ✅ Acceso a campos no promovidos del registro original
- ✅ Consultas flexibles usando operadores JSONB (`->>` y `->`)

---

## 🚀 Inicio Rápido

### **Prerequisitos:**
- n8n instalado y corriendo (Docker o local)
- Acceso a PostgreSQL (fuente y destino)
- Para ACH: Credenciales de Google Sheets OAuth2

### **Pasos Generales:**

1. **Importar workflows a n8n:**
   ```bash
   # Abrir n8n: http://localhost:5678
   # Import from File → seleccionar JSON correspondiente
   ```

2. **Activar workflows parametrizados:**
   - `Migrate SRS Table (Parametrized)` → Toggle "Active"
   - `Migrate Google Sheets Table (Parametrized)` → Toggle "Active"

3. **Configurar credenciales:**
   - PostgreSQL (fuente y destino)
   - Google Sheets OAuth2 (solo para ACH)

4. **Ejecutar migración:**
   - Abrir Master Orchestrator correspondiente
   - Click en "Execute Workflow"
   - Monitorear ejecución

---

## ⚙️ Configuración Detallada

### **Configuración SRS (PostgreSQL)**

1. **Verificar conexiones de base de datos:**
   - Settings → Credentials → PostgreSQL
   - Configurar credenciales para DB fuente y destino

2. **Ajustar configuraciones de tablas:**
   - Abrir `Migrate All SRS Tables (Master Orchestrator).json`
   - Editar nodos `Config: nombre_tabla`
   - Actualizar `field_mappings`, `value_mappings`, `relationships`

3. **Ejecutar migración:**
   - Ejecutar Master Orchestrator completo
   - O ejecutar tabla individual con workflow parametrizado

### **Configuración ACH (Google Sheets)**

#### **Paso 1: Configurar OAuth2 de Google Sheets**

1. Ir a [Google Cloud Console](https://console.cloud.google.com)
2. Crear/seleccionar proyecto
3. Habilitar "Google Sheets API"
4. Crear credenciales OAuth 2.0:
   - Tipo: Web application
   - Redirect URI: `http://localhost:5678/rest/oauth2-credential/callback`
5. En n8n:
   - Settings → Credentials → Create New
   - Buscar "Google Sheets OAuth2 API"
   - Ingresar Client ID y Client Secret
   - Sign in with Google
   - Autorizar acceso

#### **Paso 2: Obtener IDs de Google Sheets**

Para cada catálogo, obtener el `spreadsheet_id` de la URL:

```
https://docs.google.com/spreadsheets/d/1ABC...XYZ123/edit
                                      ↑
                                spreadsheet_id
```

#### **Paso 3: Actualizar Configuraciones**

**Método Automático (Recomendado):**
```bash
cd /Users/heycsar/Developer/Elaniin/Migration/scripts
python3 update_ach_file_ids.py
# Editar ach_spreadsheet_ids.csv con tus IDs
# Ejecutar nuevamente el script
# Reimportar workflow a n8n
```

**Método Manual:**
- Editar cada nodo `Config: nombre_catalogo`
- Actualizar `spreadsheet_id`, `sheet_name`, `header_row`, `data_start_row`

#### **Paso 4: Ejecutar Migración ACH**

```bash
# Prueba individual:
# En n8n → "Migrate Google Sheets Table (Parametrized)"
# Execute Workflow con datos de prueba

# Migración completa:
# En n8n → "Migrate All ACH Google Sheets (Master Orchestrator)"
# Execute Workflow
```

---

## 📊 Monitoreo y Debugging

### **Ver Ejecuciones en n8n:**
1. Panel izquierdo → "Executions"
2. Filtrar por workflow
3. Click en ejecución para ver detalles y logs

### **Consultas SQL Útiles:**

```sql
-- Ver todas las tablas migradas
SELECT tablename
FROM pg_tables
WHERE tablename LIKE 'srs_%' OR tablename LIKE 'ach_%'
ORDER BY tablename;

-- Ver auditoría de migraciones
SELECT
  table_name,
  total_records,
  successful_records,
  error_count,
  status,
  created_at
FROM sys_migration_audit
WHERE workflow_name LIKE '%SRS%' OR workflow_name LIKE '%ACH%'
ORDER BY created_at DESC;

-- Ver registros de una tabla específica
SELECT * FROM srs_bodega LIMIT 100;
SELECT * FROM ach_parcelaciones_tipo LIMIT 100;

-- Ver comentarios de columnas (ENUMs)
SELECT
  cols.column_name,
  pg_catalog.col_description(c.oid, cols.ordinal_position::int) as comment
FROM information_schema.columns cols
JOIN pg_catalog.pg_class c ON c.relname = cols.table_name
WHERE cols.table_name = 'srs_bodega'
  AND pg_catalog.col_description(c.oid, cols.ordinal_position::int) IS NOT NULL;

-- Verificar registros activos (no eliminados)
SELECT COUNT(*) as total_activos
FROM srs_bodega
WHERE deleted_at IS NULL;

-- Ver tablas registradas en data center
SELECT * FROM data_center_tables
WHERE table_name LIKE 'srs_%' OR table_name LIKE 'ach_%';
```

---

## 🔧 Solución de Problemas

### **Error: "No data received from Google Sheets"**
**Causa:** spreadsheet_id incorrecto o sin permisos

**Solución:**
1. Verificar spreadsheet_id en la URL
2. Compartir Google Sheet con cuenta de servicio
3. Verificar credenciales OAuth2

### **Error: "Missing required columns"**
**Causa:** Nombres de columnas en `required_fields` no coinciden

**Solución:**
1. Verificar `header_row` apunta a fila correcta
2. Revisar nombres exactos (case-sensitive)
3. Ajustar `required_fields` según encabezados reales

### **Error: "Duplicate key value"**
**Causa:** Código o original_id duplicado

**Solución:**
1. Verificar códigos únicos en fuente
2. Re-ejecución actualiza registros (UPSERT)
3. Revisar columna `code` en PostgreSQL

### **Error: JSON syntax errors**
**Causa:** Comas mal colocadas en configuración

**Solución:**
1. Verificar cada objeto separado por una coma
2. No dejar comas después del último elemento
3. Validar JSON con herramienta online

### **Workflow queda en "Running" indefinidamente**
**Causa:** Timeout o error en API

**Solución:**
1. Cancelar ejecución
2. Revisar logs en n8n
3. Verificar rate limits de Google Sheets API
4. Reducir `batch_size` si hay muchos registros

---

## 📚 Agregar/Modificar Tablas

### **Agregar Nueva Tabla SRS:**

1. **Crear Config node:**
   ```javascript
   return {
     source_identifier: 'alim_nueva_tabla',
     table_destination: 'srs_nueva_tabla',
     code_prefix: 'NUE',
     use_db_prefix: true,
     required_fields: ['campo1', 'campo2'],
     promoted_fields: ['campo1', 'campo2', 'campo3'],
     field_types: {},
     value_mappings: {},
     field_mappings: {
       'campo1': 'campo1',
       'campo2': 'campo2'
     },
     relationships: {},
     batch_size: 500
   };
   ```

2. **Crear Migrate node:**
   - Type: `executeWorkflow`
   - Workflow ID: `L5EXIfRXTrEXMkFz`

3. **Conectar nodos:**
   - Config → Migrate → siguiente nodo

4. **Actualizar connections en JSON**

### **Agregar Nuevo Catálogo ACH:**

1. Duplicar último nodo `Config: ...`
2. Renombrar a `Config: nuevo_catalogo`
3. Duplicar nodo `Migrate: ...`
4. Renombrar a `Migrate: nuevo_catalogo`
5. Actualizar configuración con spreadsheet_id
6. Conectar: Config → Migrate → siguiente

---

## 📖 Documentación Adicional

- **Guía ACH Detallada:** `GUIA_CONFIGURACION_ACH_GOOGLE_SHEETS.md`
- **Scripts de Utilidad:** `scripts/update_ach_file_ids.py`
- [Google Sheets API](https://developers.google.com/sheets/api)
- [n8n Documentation](https://docs.n8n.io)
- [PostgreSQL COMMENT](https://www.postgresql.org/docs/current/sql-comment.html)

---

## ✅ Checklist de Configuración

### **SRS (PostgreSQL):**
- [ ] Workflows importados en n8n
- [ ] Credenciales PostgreSQL configuradas
- [ ] Configuraciones de tablas revisadas
- [ ] Prueba con tabla individual exitosa
- [ ] Migración completa ejecutada
- [ ] Datos verificados en PostgreSQL

### **ACH (Google Sheets):**
- [ ] Workflows importados en n8n
- [ ] Credenciales Google Sheets OAuth2 configuradas
- [ ] Spreadsheet IDs obtenidos
- [ ] Configuraciones de nodos Config actualizadas
- [ ] `header_row` y `data_start_row` ajustados
- [ ] `field_mappings` actualizados
- [ ] Prueba con catálogo individual exitosa
- [ ] Migración completa ejecutada
- [ ] Auditoría revisada

---

## 📞 Soporte

Si encuentras problemas:
1. Revisar logs de ejecución en n8n
2. Consultar esta guía y `GUIA_CONFIGURACION_ACH_GOOGLE_SHEETS.md`
3. Verificar estructura de datos vs. configuración
4. Revisar errores en PostgreSQL
5. Consultar tabla `sys_migration_audit`

---

## 📄 Licencia

Este proyecto es interno del equipo Elaniin. Para extender la migración o corregir bugs, seguir el workflow estándar de Git (branch, commit, PR) y ejecutar migración completa localmente antes de merge.

---

*Última actualización: 2026-01-05 - Agregado objeto `attributes` con metadata de migración*
*Generado por Antigravity AI Assistant*
