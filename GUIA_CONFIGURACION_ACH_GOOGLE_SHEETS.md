# Guía de Configuración: Migración ACH desde Google Sheets

## 📋 Resumen del Sistema

Se han creado dos workflows para migrar catálogos de ACH desde Google Sheets a PostgreSQL SDT:

1. **Migrate ACH Table (Parametrized)** - Workflow base que migra una tabla individual
2. **Migrate All ACH Google Sheets (Master Orchestrator)** - Orquestador que migra 20 catálogos

---

## 📊 Estructura Creada

### Workflows en n8n

| Workflow | ID | Estado | Nodos | Descripción |
|----------|-----|---------|-------|-------------|
| Migrate ACH Table (Parametrized) | `hvZzjopsdq38w4Ox` | ✅ Actualizado | 22 | Workflow base parametrizado |
| Migrate All ACH Google Sheets (Master Orchestrator) | *Por importar* | ⏳ Pendiente | 43 | Orquestador principal |

### Catálogos Configurados (20 ejemplos)

| # | Tabla | Prefijo | Descripción |
|---|-------|---------|-------------|
| 1 | ach_parcelaciones_tipo | PAR | Tipos de parcelaciones |
| 2 | ach_inmuebles_tipo | INM | Tipos de inmuebles |
| 3 | ach_propietarios_tipo | PRO | Tipos de propietarios |
| 4 | ach_servicios_tipo | SRV | Tipos de servicios |
| 5 | ach_estados_general | EST | Estados generales del sistema |
| 6 | ach_estados_pago | EPG | Estados de pagos |
| 7 | ach_estados_mantenimiento | EMT | Estados de mantenimiento |
| 8 | ach_areas_comunes | ARE | Áreas comunes del conjunto |
| 9 | ach_tipos_mantenimiento | MAN | Tipos de mantenimiento |
| 10 | ach_tipos_pago | TPG | Formas de pago |
| 11 | ach_conceptos_cobro | COB | Conceptos de cobro |
| 12 | ach_paises | PAI | Catálogo de países |
| 13 | ach_departamentos | DEP | Departamentos |
| 14 | ach_municipios | MUN | Municipios |
| 15 | ach_bancos | BAN | Entidades bancarias |
| 16 | ach_tipos_documento | DOC | Tipos de documentos de identidad |
| 17 | ach_roles_usuario | ROL | Roles de usuarios |
| 18 | ach_permisos | PER | Permisos del sistema |
| 19 | ach_tipos_notificacion | NOT | Tipos de notificaciones |
| 20 | ach_prioridades | PRI | Niveles de prioridad |

---

## 🚀 Pasos de Configuración

### Paso 1: Importar el Master Orchestrator

1. Abrir n8n: http://localhost:5678
2. Click en "+" (nuevo workflow)
3. Click en menú "..." → "Import from File"
4. Seleccionar: `Migrate All ACH Google Sheets (Master Orchestrator).json`
5. Guardar el workflow

### Paso 2: Activar el Workflow Parametrizado

1. En n8n, buscar: "Migrate ACH Table (Parametrized)"
2. Abrir el workflow
3. Click en toggle "Active" (arriba a la derecha)
4. Verificar que dice "✓ Active"

### Paso 3: Configurar Credenciales de Google Sheets

#### Obtener credenciales OAuth2:

1. Ir a [Google Cloud Console](https://console.cloud.google.com)
2. Crear o seleccionar un proyecto
3. Habilitar "Google Sheets API"
4. Crear credenciales OAuth 2.0:
   - Tipo: Web application
   - Redirect URI: `http://localhost:5678/rest/oauth2-credential/callback`
5. Copiar Client ID y Client Secret

#### Configurar en n8n:

1. En n8n: Settings → Credentials → Create New
2. Buscar "Google Sheets OAuth2 API"
3. Ingresar:
   - **Client ID**: (de Google Cloud Console)
   - **Client Secret**: (de Google Cloud Console)
   - **Scopes**: `https://www.googleapis.com/auth/spreadsheets.readonly`
4. Click "Sign in with Google"
5. Autorizar acceso
6. Guardar credencial

### Paso 4: Obtener IDs de Google Sheets

Para cada catálogo, necesitas el **spreadsheet_id** de Google Sheets:

**Método 1: Desde la URL**
```
https://docs.google.com/spreadsheets/d/1ABC...XYZ123/edit
                                      ↑
                                spreadsheet_id
```

**Método 2: Script de ayuda**
```bash
# Crear lista de tus Google Sheets
# Formato: nombre_catalogo,spreadsheet_id,sheet_name

cat > /tmp/ach_sheets_ids.csv << 'EOF'
parcelaciones_tipo,REEMPLAZAR_CON_ID_REAL,Parcelaciones_Tipo
inmuebles_tipo,REEMPLAZAR_CON_ID_REAL,Inmuebles_Tipo
propietarios_tipo,REEMPLAZAR_CON_ID_REAL,Propietarios_Tipo
# ... agregar todos los catálogos
EOF
```

### Paso 5: Configurar Cada Catálogo

En el Master Orchestrator, cada catálogo tiene un nodo "Config: nombre_catalogo".

**Para cada nodo Config, actualizar:**

```javascript
return {
  source_identifier: 'ACH Excel: parcelaciones_tipo',

  // 🔑 ACTUALIZAR ESTOS VALORES:
  spreadsheet_id: 'TU_SPREADSHEET_ID_AQUI',  // ⚠️ REEMPLAZAR
  sheet_name: 'Parcelaciones_Tipo',           // Nombre de la hoja/pestaña
  header_row: 7,                              // Fila con encabezados
  data_start_row: 8,                          // Primera fila de datos

  // ✅ Verificar tabla destino:
  table_destination: 'ach_parcelaciones_tipo',
  code_prefix: 'PAR',

  // 📊 Actualizar según tu Excel:
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
  }
};
```

**Campos importantes a ajustar:**

| Campo | Descripción | Ejemplo |
|-------|-------------|---------|
| `spreadsheet_id` | ID del Google Sheet | `1ABC...XYZ123` |
| `sheet_name` | Nombre de la pestaña | `Parcelaciones_Tipo` |
| `header_row` | Fila con encabezados | `7` (basado en tu Excel) |
| `data_start_row` | Primera fila de datos | `8` |
| `promoted_fields` | Columnas a migrar | `['Código', 'Nombre', '¿Activo?']` |
| `field_mappings` | Mapeo de nombres | `{'Código': 'codigo'}` |

### Paso 6: Agregar/Quitar Catálogos (Opcional)

**Para agregar un nuevo catálogo:**

1. Duplicar el último nodo "Config: ..."
2. Renombrar a "Config: nuevo_catalogo"
3. Duplicar el nodo "Migrate: ..."
4. Renombrar a "Migrate: nuevo_catalogo"
5. Conectar: Config → Migrate → siguiente nodo
6. Actualizar configuración

**Para quitar un catálogo:**

1. Eliminar nodos "Config: ..." y "Migrate: ..."
2. Reconectar flujo (nodo anterior → nodo siguiente)

---

## 🔍 Ejemplo de Configuración Completa

### Catálogo: Parcelaciones_Tipo

**Estructura del Excel:**
```
Fila 1-6: Metadata
Fila 7: Encabezados → [Código *, Nombre *, Relación, ¿Activo? *]
Fila 8+: Datos      → [PAR_HAB, habitacional, N/A, SI]
```

**Configuración en nodo Config:**
```javascript
return {
  source_identifier: 'ACH Excel: parcelaciones_tipo',

  spreadsheet_id: '1ABC...XYZ',
  sheet_name: 'Parcelaciones_Tipo',
  header_row: 7,
  data_start_row: 8,

  table_destination: 'ach_parcelaciones_tipo',
  code_prefix: 'PAR',
  use_db_prefix: false,

  required_fields: ['Código', 'Nombre'],
  promoted_fields: ['Código', 'Nombre', 'Relación', '¿Activo?'],

  field_types: {
    '¿Activo?': 'BOOLEAN DEFAULT true'
  },

  value_mappings: {
    '¿Activo?': {'SI': true, 'NO': false},
    'Relación': {'N/A': null}
  },

  field_mappings: {
    'Código': 'codigo',
    'Nombre': 'nombre',
    'Relación': 'relacion',
    '¿Activo?': 'activo'
  },

  relationships: {},

  batch_size: 500,
  register_in_data_center: true,
  table_description: 'Tipos de parcelaciones'
};
```

**Resultado en PostgreSQL:**
```sql
CREATE TABLE ach_parcelaciones_tipo (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(50) UNIQUE,
  codigo TEXT,
  nombre TEXT,
  relacion TEXT,
  activo BOOLEAN DEFAULT true,
  original_id VARCHAR(200) UNIQUE,
  attributes JSONB,
  sys_migrated_at TIMESTAMP DEFAULT NOW(),
  sys_batch_id VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);

COMMENT ON COLUMN ach_parcelaciones_tipo.activo
  IS 'Valores posibles: SI → true, NO → false';
```

**Datos insertados:**
```sql
INSERT INTO ach_parcelaciones_tipo
  (code, codigo, nombre, relacion, activo, ...)
VALUES
  ('PAR_HAB', 'PAR_HAB', 'habitacional', NULL, true, ...);
```

---

## 🧪 Pruebas

### Probar un Solo Catálogo

1. En n8n, abrir "Migrate ACH Table (Parametrized)"
2. Click en "Execute Workflow" (botón play)
3. En el panel "Workflow Input", ingresar:

```json
{
  "source_identifier": "ACH Excel: TEST",
  "spreadsheet_id": "TU_SPREADSHEET_ID",
  "sheet_name": "NombreHoja",
  "header_row": 7,
  "data_start_row": 8,
  "table_destination": "ach_test",
  "code_prefix": "TST",
  "use_db_prefix": false,
  "required_fields": ["Código", "Nombre"],
  "promoted_fields": ["Código", "Nombre", "¿Activo?"],
  "field_types": {"¿Activo?": "BOOLEAN DEFAULT true"},
  "value_mappings": {"¿Activo?": {"SI": true, "NO": false}},
  "field_mappings": {"Código": "codigo", "Nombre": "nombre", "¿Activo?": "activo"},
  "relationships": {},
  "batch_size": 500,
  "register_in_data_center": true,
  "table_description": "Tabla de prueba"
}
```

4. Verificar resultados en PostgreSQL:
```sql
SELECT * FROM ach_test LIMIT 10;
SELECT * FROM sys_migration_audit WHERE table_name = 'ach_test';
```

### Ejecutar el Master Orchestrator Completo

1. Abrir "Migrate All ACH Google Sheets (Master Orchestrator)"
2. Click en "Execute Workflow"
3. Esperar a que termine (puede tomar varios minutos)
4. Revisar el nodo "Master Summary Report" para ver el resumen

---

## 📊 Monitoreo

### Ver Ejecuciones en n8n

1. En n8n, ir a "Executions" (panel izquierdo)
2. Filtrar por workflow: "Migrate All ACH Google Sheets"
3. Click en una ejecución para ver detalles

### Consultas SQL Útiles

```sql
-- Ver todas las tablas ACH creadas
SELECT tablename
FROM pg_tables
WHERE tablename LIKE 'ach_%'
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
WHERE workflow_name LIKE '%ACH%'
ORDER BY created_at DESC;

-- Ver registros de un catálogo
SELECT * FROM ach_parcelaciones_tipo LIMIT 100;

-- Ver comentarios de columnas (ENUMs)
SELECT
  cols.column_name,
  pg_catalog.col_description(c.oid, cols.ordinal_position::int)
FROM information_schema.columns cols
JOIN pg_catalog.pg_class c ON c.relname = cols.table_name
WHERE cols.table_name = 'ach_parcelaciones_tipo'
  AND pg_catalog.col_description(c.oid, cols.ordinal_position::int) IS NOT NULL;

-- Verificar registros activos (no eliminados)
SELECT COUNT(*) as total_activos
FROM ach_parcelaciones_tipo
WHERE deleted_at IS NULL;
```

---

## 🔧 Solución de Problemas

### Error: "No data received from Google Sheets"

**Causa:** spreadsheet_id incorrecto o sin permisos

**Solución:**
1. Verificar que el spreadsheet_id sea correcto
2. Verificar que las credenciales de Google Sheets tengan acceso al archivo
3. Compartir el Google Sheet con la cuenta de servicio

### Error: "Missing required columns"

**Causa:** Los nombres de columnas en `required_fields` no coinciden con el Excel

**Solución:**
1. Verificar que `header_row` apunte a la fila correcta
2. Revisar que los nombres en `required_fields` sean exactos (case-sensitive)
3. Ajustar `required_fields` según los encabezados reales

### Error: "Duplicate key value"

**Causa:** Código o original_id duplicado

**Solución:**
1. Verificar que los códigos en Excel sean únicos
2. Si re-ejecutas la migración, los registros se actualizarán (UPSERT)
3. Revisar la columna `code` en PostgreSQL

### Workflow queda en "Running" indefinidamente

**Causa:** Timeout o error en Google Sheets API

**Solución:**
1. Cancelar ejecución
2. Revisar logs en n8n
3. Verificar rate limits de Google Sheets API
4. Reducir `batch_size` si hay muchos registros

---

## 📚 Recursos Adicionales

### Archivos Importantes

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| Master Orchestrator | `Migrate All ACH Google Sheets (Master Orchestrator).json` | Workflow principal |
| Workflow Parametrizado | `Migrate ACH Table (Parametrized).json` | Workflow base |
| Lista de Catálogos | `/tmp/ach_catalogs.json` | Lista de 20 catálogos ejemplo |

### Documentación

- [Google Sheets API](https://developers.google.com/sheets/api)
- [n8n Documentation](https://docs.n8n.io)
- [PostgreSQL COMMENT](https://www.postgresql.org/docs/current/sql-comment.html)

---

## ✅ Checklist de Configuración

- [ ] Master Orchestrator importado en n8n
- [ ] Workflow "Migrate ACH Table (Parametrized)" activado
- [ ] Credenciales de Google Sheets configuradas
- [ ] IDs de Google Sheets obtenidos para cada catálogo
- [ ] Configuraciones de nodos Config actualizadas
- [ ] `header_row` y `data_start_row` ajustados por catálogo
- [ ] `field_mappings` actualizados según estructura de cada Excel
- [ ] Prueba con un catálogo individual ejecutada exitosamente
- [ ] Verificación de datos en PostgreSQL realizada
- [ ] Master Orchestrator ejecutado completamente
- [ ] Auditoría revisada en `sys_migration_audit`

---

## 📞 Soporte

Si encuentras problemas durante la configuración:

1. Revisar logs de ejecución en n8n
2. Consultar esta guía
3. Verificar la estructura del Excel vs. configuración
4. Revisar errores en PostgreSQL

¡Buena suerte con la migración! 🚀
