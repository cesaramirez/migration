# Sistema de Migración ACH - Google Sheets → PostgreSQL

Sistema completo para migrar catálogos de ACH (Administración de Conjuntos Habitacionales) desde Google Sheets a PostgreSQL SDT.

## 🚀 Inicio Rápido

1. **Importar workflows a n8n**
   ```bash
   # En n8n (http://localhost:5678):
   # 1. Import from File → "Migrate All ACH Google Sheets (Master Orchestrator).json"
   # 2. Verificar que "Migrate ACH Table (Parametrized)" esté activo
   ```

2. **Configurar credenciales**
   - Ver sección "Paso 3" en `GUIA_CONFIGURACION_ACH_GOOGLE_SHEETS.md`

3. **Actualizar spreadsheet_ids**
   ```bash
   # Método automático (recomendado):
   python3 update_ach_spreadsheet_ids.py
   # Editar ach_spreadsheet_ids.csv con tus IDs
   # Ejecutar nuevamente el script
   # Reimportar el workflow a n8n

   # Método manual:
   # Editar cada nodo "Config: ..." en el Master Orchestrator
   ```

4. **Ejecutar migración**
   - Probar con un catálogo: Ejecutar "Migrate ACH Table (Parametrized)"
   - Migración completa: Ejecutar "Migrate All ACH Google Sheets"

## 📁 Archivos Importantes

| Archivo | Descripción |
|---------|-------------|
| `Migrate ACH Table (Parametrized).json` | Workflow base (ya en n8n: hvZzjopsdq38w4Ox) |
| `Migrate All ACH Google Sheets (Master Orchestrator).json` | Orquestador de 20 catálogos |
| `GUIA_CONFIGURACION_ACH_GOOGLE_SHEETS.md` | 📚 **Guía completa** (LEER PRIMERO) |
| `update_ach_spreadsheet_ids.py` | Script para actualizar IDs masivamente |

## 📊 Catálogos Incluidos (20)

1. Parcelaciones Tipo
2. Inmuebles Tipo
3. Propietarios Tipo
4. Servicios Tipo
5. Estados General
6. Estados Pago
7. Estados Mantenimiento
8. Áreas Comunes
9. Tipos Mantenimiento
10. Tipos Pago
11. Conceptos Cobro
12. Países
13. Departamentos
14. Municipios
15. Bancos
16. Tipos Documento
17. Roles Usuario
18. Permisos
19. Tipos Notificación
20. Prioridades

## ⚙️ Características

- ✅ Migración desde Google Sheets (múltiples archivos)
- ✅ Mapeo automático de valores (SI/NO → boolean)
- ✅ Generación de códigos (PAR_HAB, INM_001, etc.)
- ✅ Comentarios SQL con valores ENUM
- ✅ Columnas de auditoría (created_at, updated_at, deleted_at)
- ✅ Registro en data_center_tables
- ✅ UPSERT automático (actualiza registros existentes)
- ✅ Batch processing (500 registros por INSERT)
- ✅ Manejo de errores con logging
- ✅ Resumen ejecutivo de migración

## 🔧 Configuración Mínima

Para cada catálogo, necesitas:

```javascript
{
  spreadsheet_id: 'TU_SPREADSHEET_ID',  // Obtener de la URL de Google Sheets
  sheet_name: 'NombreHoja',              // Nombre de la pestaña
  header_row: 7,                         // Fila con encabezados
  data_start_row: 8,                     // Primera fila de datos
  field_mappings: {                      // Mapeo de columnas
    'Código': 'codigo',
    'Nombre': 'nombre'
  }
}
```

## 📖 Documentación Completa

Ver: **`GUIA_CONFIGURACION_ACH_GOOGLE_SHEETS.md`**

Incluye:
- Configuración paso a paso de Google Sheets OAuth2
- Ejemplos completos de configuración
- Solución de problemas
- Consultas SQL útiles
- Checklist de configuración

## 🧪 Pruebas

```bash
# 1. Probar un solo catálogo
# En n8n: Abrir "Migrate ACH Table (Parametrized)"
# Ejecutar con datos de prueba

# 2. Verificar en PostgreSQL
psql -h localhost -U postgres -d sdt_data_center
SELECT * FROM ach_parcelaciones_tipo LIMIT 10;

# 3. Ver auditoría
SELECT * FROM sys_migration_audit WHERE workflow_name LIKE '%ACH%';
```

## 🆘 Soporte

**Problemas comunes:**

1. **"No data received from Google Sheets"**
   → Verificar spreadsheet_id y credenciales

2. **"Missing required columns"**
   → Ajustar required_fields según encabezados reales

3. **"Duplicate key value"**
   → Normal en re-ejecuciones (UPSERT actualiza registros)

Ver más en la guía completa.

## 📦 Estructura de Base de Datos

Cada tabla creada tendrá:

```sql
CREATE TABLE ach_nombre_catalogo (
  id UUID PRIMARY KEY,
  code VARCHAR(50) UNIQUE,
  -- columnas del Excel --
  original_id VARCHAR(200) UNIQUE,
  attributes JSONB,
  sys_migrated_at TIMESTAMP,
  sys_batch_id VARCHAR(100),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP,
  deleted_at TIMESTAMP
);
```

## ✅ Checklist

- [ ] Workflows importados en n8n
- [ ] Credenciales de Google Sheets configuradas
- [ ] Spreadsheet IDs actualizados
- [ ] Prueba con 1 catálogo exitosa
- [ ] Migración completa ejecutada
- [ ] Datos verificados en PostgreSQL

---

**¿Preguntas?** Ver la guía completa o revisar logs en n8n.

¡Buena suerte con la migración! 🚀
