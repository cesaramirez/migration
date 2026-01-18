# Reporte de Extracción de Datos - SISAM T81

**Proyecto**: Migración SISAM → SDT
**Fecha**: 2026-01-17
**Entidad**: T81 - Registro Sanitario Alimentos
**Script**: `scripts/00_export_from_sisam.sql`

---

## Resumen de Extracción

| Métrica | Valor |
|---------|-------|
| Tabla principal | `alim_producto` |
| Filtros aplicados | `estado_registro = 1` (activos) |
| Deduplicación | `DISTINCT ON (p.id)` |
| Criterio CLV | CLV más reciente por `fecha_emision` |

---

## Campos Extraídos (42 columnas)

### 🔑 Identificación del Producto

| # | Campo | Origen | Transformación |
|---|-------|--------|----------------|
| 1 | `original_id` | `p.id` | ID original para trazabilidad |
| 2 | `nombre` | `p.nombre` | TRIM |
| 3 | `num_registro_sanitario` | `p.num_registro_sanitario` | NULLIF vacíos |

### 📋 Clasificación del Producto

| # | Campo | Origen | Transformación |
|---|-------|--------|----------------|
| 4 | `tipo_producto` | `p.tipo_producto` | CASE: 1→Nacional, 2→Importado UA, 3→Importado Otros |
| 5 | `num_partida_arancelaria` | `p.num_partida_arancelaria` | NULLIF vacíos |
| 6 | `estado_producto` | `ctl_estado_producto.nombre` | UPPER |
| 7 | `pais` | `ctl_pais.nombre` | Denormalizado |
| 8 | `subgrupo_alimenticio` | `alim_sub_grupo_alimenticio.nombre` | Denormalizado |
| 9 | `clasificacion_alimenticia` | `ctl_clasificacion_grupo_alimenticio.nombre` | Denormalizado |
| 10 | `riesgo` | `ctl_tipo_riesgo.nombre` | Denormalizado |

### 📅 Fechas

| # | Campo | Origen | Transformación |
|---|-------|--------|----------------|
| 11 | `fecha_emision_registro` | `p.fecha_emision_registro` | TO_CHAR DD/MM/YYYY |
| 12 | `fecha_vigencia_registro` | `p.fecha_vigencia_registro` | TO_CHAR DD/MM/YYYY |

### 📜 Certificado de Libre Venta (CLV)

| # | Campo | Origen | Transformación |
|---|-------|--------|----------------|
| 13 | `codigo_clv` | `alim_certificado_libre_venta.cod_clv` | CLV más reciente |
| 14 | `nombre_producto_clv` | `alim_producto_certificado_libre_venta.nombre_prod_segun_clv` | — |
| 15 | `pais_procedencia_clv` | `ctl_pais.nombre` (via CLV) | Denormalizado |

### 👤 Propietario del Registro (función = 4)

| # | Campo | Origen | Transformación |
|---|-------|--------|----------------|
| 16 | `propietario_nombre` | `alim_empresa_persona_aux.nombre` | — |
| 17 | `propietario_nit` | `alim_empresa_persona_aux.nit` | — |
| 18 | `propietario_correo` | `alim_empresa_persona_aux.correo_electronico` | — |
| 19 | `propietario_direccion` | `alim_empresa_persona_aux.direccion` | — |
| 20 | `propietario_pais` | `ctl_pais.nombre` | Denormalizado |
| 21 | `propietario_razon_social` | `alim_empresa_persona_aux.nombre` | Solo si es_empresa = true |

### 🏭 Fabricante (función = 1)

| # | Campo | Origen | Transformación |
|---|-------|--------|----------------|
| 22 | `fabricante_nombre` | `alim_empresa_persona_aux.nombre` | — |
| 23 | `fabricante_nit` | `alim_empresa_persona_aux.nit` | — |
| 24 | `fabricante_correo` | `alim_empresa_persona_aux.correo_electronico` | — |
| 25 | `fabricante_direccion` | `alim_empresa_persona_aux.direccion` | — |
| 26 | `fabricante_pais` | `ctl_pais.nombre` | Denormalizado |
| 27 | `fabricante_razon_social` | `alim_empresa_persona_aux.nombre` | Solo si es_empresa = true |

### 📦 Distribuidor (función = 2)

| # | Campo | Origen | Transformación |
|---|-------|--------|----------------|
| 28 | `distribuidor_nombre` | `alim_empresa_persona_aux.nombre` | — |
| 29 | `distribuidor_nit` | `alim_empresa_persona_aux.nit` | — |
| 30 | `distribuidor_correo` | `alim_empresa_persona_aux.correo_electronico` | — |
| 31 | `distribuidor_direccion` | `alim_empresa_persona_aux.direccion` | — |
| 32 | `distribuidor_pais` | `ctl_pais.nombre` | Denormalizado |
| 33 | `distribuidor_razon_social` | `alim_empresa_persona_aux.nombre` | Solo si es_empresa = true |

### 📦 Envasador (función = 3)

| # | Campo | Origen | Transformación |
|---|-------|--------|----------------|
| 34 | `envasador_nombre` | `alim_empresa_persona_aux.nombre` | — |
| 35 | `envasador_nit` | `alim_empresa_persona_aux.nit` | — |
| 36 | `envasador_correo` | `alim_empresa_persona_aux.correo_electronico` | — |
| 37 | `envasador_direccion` | `alim_empresa_persona_aux.direccion` | — |
| 38 | `envasador_pais` | `ctl_pais.nombre` | Denormalizado |
| 39 | `envasador_razon_social` | `alim_empresa_persona_aux.nombre` | Solo si es_empresa = true |

### 🚢 Importador (función = 5)

| # | Campo | Origen | Transformación |
|---|-------|--------|----------------|
| 40 | `importador_nombre` | `alim_empresa_persona_aux.nombre` | — |
| 41 | `importador_nit` | `alim_empresa_persona_aux.nit` | — |
| 42 | `importador_correo` | `alim_empresa_persona_aux.correo_electronico` | — |
| 43 | `importador_direccion` | `alim_empresa_persona_aux.direccion` | — |
| 44 | `importador_pais` | `ctl_pais.nombre` | Denormalizado |
| 45 | `importador_razon_social` | `alim_empresa_persona_aux.nombre` | Solo si es_empresa = true |

### 🔗 IDs de Relación (para JOINs en destino)

| # | Campo | Origen | Uso |
|---|-------|--------|-----|
| 46 | `original_sub_id` | `p.id_sub_grupo_alimenticio` | JOIN con `srs_sub_grupo_alimenticio` |
| 47 | `original_pais_iso` | `ctl_pais.isonumero` | JOIN con `paises` |
| 48 | `original_clv_id` | `alim_certificado_libre_venta.id` | JOIN con `srs_certificado_libre_venta` |

---

## Tablas Origen Involucradas (14 tablas)

| Tabla | Rol |
|-------|-----|
| `alim_producto` | Tabla principal |
| `ctl_estado_producto` | Catálogo estados |
| `ctl_pais` | Catálogo países (usado 6 veces) |
| `alim_sub_grupo_alimenticio` | Catálogo subgrupos |
| `ctl_clasificacion_grupo_alimenticio` | Catálogo clasificación |
| `ctl_tipo_riesgo` | Catálogo riesgos |
| `alim_producto_certificado_libre_venta` | Relación producto-CLV |
| `alim_certificado_libre_venta` | CLV |
| `alim_empresa_persona_aux_funcion_producto` | Relación producto-empresa (5 funciones) |
| `alim_empresa_persona_aux` | Empresas/personas |

---

## Filtros Aplicados

```sql
WHERE p.estado_registro = 1              -- Solo productos activos
  AND p.fecha_emision_registro IS NOT NULL
  AND p.fecha_vigencia_registro IS NOT NULL
```

---

## Decisiones de Diseño

| Decisión | Justificación |
|----------|---------------|
| `DISTINCT ON (p.id)` | Evita duplicados por múltiples CLVs/empresas |
| `ORDER BY clv.fecha_emision DESC` | Toma el CLV más reciente (vigente) |
| Denormalización de países | Evita JOINs en destino |
| LEFT JOINs | Incluye productos sin CLV o sin empresas |

---

## Datos Excluidos

| Campo/Tabla | Razón |
|-------------|-------|
| `ruta_archivo_*` | Fase posterior (archivos) |
| Productos inactivos | `estado_registro != 1` |
| CLVs antiguos | Solo se migra el más reciente |
| Múltiples empresas por función | `DISTINCT ON` toma la primera |

---

## Queries de Validación Pre-Exportación

```sql
-- Total de productos a exportar
SELECT COUNT(DISTINCT p.id)
FROM alim_producto p
WHERE p.estado_registro = 1
  AND p.fecha_emision_registro IS NOT NULL
  AND p.fecha_vigencia_registro IS NOT NULL;

-- Distribución por tipo de producto
SELECT
    CASE tipo_producto
        WHEN 1 THEN 'Nacional'
        WHEN 2 THEN 'Importado UA'
        WHEN 3 THEN 'Importado Otros'
    END as tipo,
    COUNT(*)
FROM alim_producto
WHERE estado_registro = 1
GROUP BY tipo_producto;

-- Productos sin CLV
SELECT COUNT(*)
FROM alim_producto p
LEFT JOIN alim_producto_certificado_libre_venta pclv ON pclv.id_alim_producto = p.id
WHERE p.estado_registro = 1
  AND pclv.id IS NULL;
```

---

*Reporte generado como documentación técnica del proceso de migración.*
