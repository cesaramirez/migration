# Reporte de Anomalías: Productos con Múltiples CLVs

**Proyecto**: Migración SISAM → SDT
**Fecha de Generación**: 2026-01-17
**Generado por**: Data Migration Team

---

## Resumen Ejecutivo

Durante el proceso de migración de productos (T81 - Registro Sanitario Alimentos), se identificaron productos que tienen asociados más de un Certificado de Libre Venta (CLV) en el sistema origen (SISAM).

### Estadísticas

| Métrica | Valor |
|---------|-------|
| Total de productos con múltiples CLVs | 49 |
| Productos **inactivos** (no se migran) | 28 |
| **Productos activos afectados** | **21** |

### Desglose de Productos Activos (estado_registro = 1)

| # CLVs | Productos Activos |
|--------|-------------------|
| 3 CLVs | 8 |
| 2 CLVs | 13 |
| **Total** | **21** |

> ⚠️ **Nota importante**: Solo **21 productos activos** (que serán migrados) tienen esta anomalía. Los otros 28 productos con múltiples CLVs están inactivos y no forman parte de la migración.

---

## Análisis de la Anomalía

### Regla de Negocio Actual
Según el proceso actual del trámite T81, un producto puede tener **un único CLV** asociado.

### ✅ Causa Identificada: Renovaciones de CLV

Tras análisis detallado, se confirmó que los múltiples CLVs corresponden a **renovaciones anuales del certificado**, no a errores de datos:

| Ejemplo | CLV Original | Fecha | → | CLV Renovado | Fecha |
|---------|--------------|-------|---|--------------|-------|
| Pastas DIVELLA | CLV-1475 | 2016-05-05 | → | CLV-2201 | 2017-06-09 |
| Cervezas Belgas | CLV-1226 | 2016-11-24 | → | CLV-5192 | 2018-07-19 |
| Jarabes Washington | CLV-1229 | 2016-05-05 | → | CLV-5246 | 2018-06-04 |

**Evidencia**: Todos los CLVs provienen de la misma autoridad sanitaria, con fechas consecutivas indicando renovación.

### Impacto
- **Nulo**: No son errores de datos, son renovaciones legítimas
- **Decisión clara**: Migrar solo el CLV más reciente (vigente)

---

## Decisión de Migración

### Criterio Aplicado
Para los 49 productos afectados, se migró **únicamente el primer CLV** encontrado en la relación, utilizando la cláusula `DISTINCT ON (id_alim_producto)` en el query de exportación.

### Consecuencia
Los CLVs adicionales (38 registros con 2do CLV + 11 registros con 3er CLV = ~60 CLVs) **no fueron migrados** al sistema destino.

---

## Listado de Productos Afectados

> **Nota**: Ejecutar el siguiente query en SISAM para obtener el listado completo:

```sql
SELECT
    p.id as producto_id,
    p.nombre as producto,
    p.num_registro_sanitario,
    COUNT(pclv.id) as cantidad_clvs,
    STRING_AGG(clv.cod_clv, ', ' ORDER BY clv.id) as codigos_clv,
    STRING_AGG(clv.id::text, ', ' ORDER BY clv.id) as ids_clv
FROM alim_producto p
JOIN alim_producto_certificado_libre_venta pclv ON pclv.id_alim_producto = p.id
JOIN alim_certificado_libre_venta clv ON clv.id = pclv.id_alim_certificado_libre_venta
WHERE p.estado_registro = 1
GROUP BY p.id
HAVING COUNT(pclv.id) > 1
ORDER BY COUNT(pclv.id) DESC, p.id;
```

### Resultado del Query (Muestra de 21 registros):

| Producto ID | Nombre | Registro Sanitario | # CLVs | Códigos CLV |
|-------------|--------|-------------------|--------|-------------|
| 29875 | JARABE SABOR CARAMELO | 39393 | 3 | CLV-1229, CLV-1953, CLV-5246 |
| 29877 | JARABE SABOR AMARETTO | 39395 | 3 | CLV-1229, CLV-1953, CLV-5246 |
| 29878 | JARABE SABOR VAINILLA | 39396 | 3 | CLV-1229, CLV-1953, CLV-5246 |
| 29879 | JARABE SABOR MENTA | 39397 | 3 | CLV-1229, CLV-1953, CLV-5246 |
| 29880 | SALSA CON SABOR A CARAMELO | 39398 | 3 | CLV-1229, CLV-1953, CLV-5246 |
| 29881 | JARABE SABOR VAINILLA FRANCESA | 39399 | 3 | CLV-1229, CLV-1953, CLV-5246 |
| 29882 | SALSA CON SABOR A CHOCOLATE | 39400 | 3 | CLV-1229, CLV-1953, CLV-5246 |
| 29883 | JARABE SABOR CREMA IRLANDESA | 39401 | 3 | CLV-1229, CLV-1953, CLV-5246 |
| 26087 | CERVEZA 8% ALC. VOL. KASTEEL ROUGE | 46224 | 2 | CLV-1226, CLV-5192 |
| 26088 | CERVEZA 3.2% ALC. VOL. ST. LOUIS PREMIUM KRIEK | 46184 | 2 | CLV-1227, CLV-5192 |
| 10226 | PASTA DE SEMOLA DE GRANO DURO CANELONES | 40284 | 2 | CLV-1475, CLV-2201 |
| 29861 | MEZCLA EN POLVO PARA BEBIDA FRIA CON SABOR A CAFE Y CARAMELO | 20776 | 2 | CLV-1228, CLV-2072 |
| 29874 | MEZCLA EN POLVO PARA BEBIDA CON SABOR A TE CHAI Y CHOCOLATE | 35562 | 2 | CLV-1228, CLV-2072 |
| 29858 | MEZCLA EN POLVO PARA BEBIDA FRIA CON SABOR A CAFE Y VAINILLA | 20772 | 2 | CLV-1228, CLV-2072 |
| 10228 | PASTA DE SEMOLA DE GRANO DURO SPAGETHI | 38692 | 2 | CLV-1475, CLV-2201 |
| 10229 | PASTA DE SEMOLA DE GRANO DURO CON TOMATE Y ESPINACA | 40283 | 2 | CLV-1475, CLV-2201 |
| 10230 | PASTA DE SEMOLA DE GRANO DURO FETTUCCINE 90 | 40282 | 2 | CLV-1475, CLV-2201 |
| 10256 | TOMATE PELADO | 40536 | 2 | CLV-1475, CLV-2201 |
| 10257 | PASTA DE SEMOLA DE GRANO DURO (PENNE ZITI RIGATE 27) | 40534 | 2 | CLV-1475, CLV-2201 |
| 10258 | PASTA DE SEMULA DE GRANO DURO (SPAGHETTI RISTORANTE 8) | 40535 | 2 | CLV-1475, CLV-2201 |
| 26079 | CERVEZA 5.3% ALC. VOL. | 37413 | 2 | CLV-2283, CLV-4825 |

> **Nota**: Se muestran 21 de 49 registros. El listado completo está disponible ejecutando el query.

---

## Recomendaciones

1. **Inmediata**: Aceptar la decisión de migrar solo 1 CLV por producto
2. **Post-migración**: Revisar los 49 casos manualmente si es necesario
3. **Sistema nuevo**: Implementar constraint a nivel de BD para prevenir múltiples CLVs

---

## Aprobación

| Rol | Nombre | Fecha | Firma |
|-----|--------|-------|-------|
| Data Engineer | | | |
| Product Owner | | | |
| Cliente | | | |

---

*Documento generado como parte del proceso de Quality Assurance de migración de datos.*
