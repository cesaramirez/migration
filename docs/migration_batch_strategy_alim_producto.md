# Estrategia de Migración por Batches - alim_producto

## Resumen Ejecutivo

Este documento define la estrategia de segmentación y periodicidad del ETL para la migración de expedientes de `alim_producto` desde SISAM hacia el sistema CORE. La migración se realizará en múltiples batches, priorizando los expedientes aprobados y estableciendo un proceso recurrente para capturar nuevas aprobaciones.

---

## 1. Clasificación de Estados

### 1.1 Estados para Migración Inmediata (Batch 1)

Expedientes con estado **APROBADO** que serán migrados en el primer batch:

| ID | Estado | Código | Acción |
|----|--------|--------|--------|
| 8 | Aprobada | `APRO` | ✅ **Migrar en Batch 1** |

### 1.2 Estados Pendientes de Migración (Batches Subsecuentes)

Expedientes en proceso que **NO** han sido rechazados ni cancelados. Estos quedarán en cola para migración futura cuando alcancen el estado `APRO`:

| ID | Estado | Código | Descripción |
|----|--------|--------|-------------|
| 1 | Ingresada | `INGR` | Solicitud recién creada |
| 2 | Solicitud Ingresada | `RECP` | Solicitud recepcionada |
| 3 | En revisión técnica y analítica | `EVAL` | En proceso de evaluación |
| 4 | En espera de Autorización | `AUTH` | Pendiente de firma/autorización |
| 6 | Muestra enviada a Laboratorio | `LAB` | En análisis de laboratorio |
| 10 | Pendiente de Pago | `PEND` | Esperando confirmación de pago |
| 12 | En Observaciones | `OBS` | Con observaciones pendientes |
| 13 | En espera de clasificación alimenticia | `ECAL` | Pendiente de clasificación |
| 14 | Pendiente de recepción de expediente y pendiente de registro de resultados de análisis | `ERAN` | En espera de documentación |
| 15 | Análisis registrados y pendiente de aval técnico | `EAVT` | Pendiente aval técnico |
| 16 | En revisión de resultados análisis | `ERRA` | Revisando resultados |
| 17 | Revisión analítica | `REVA` | En revisión analítica |
| 18 | En espera de revisión de determinaciones analíticas | `ERDA` | Pendiente revisión analítica |
| 19 | Observación Técnica | `OBST` | Con observación técnica |
| 20 | Pendiente de recepción de expediente físico | `PREF` | Esperando expediente físico |
| 21 | Aceptada y pendiente de registro de resultados de análisis | `APRR` | Aceptada, pendiente análisis |

### 1.3 Estados Excluidos de Migración

Expedientes que **NO** serán migrados por estar en estado terminal negativo:

| ID | Estado | Código | Motivo de Exclusión |
|----|--------|--------|---------------------|
| 5 | Rechazada | `RECH` | ❌ Solicitud rechazada |
| 7 | Cancelada | `CANC` | ❌ Solicitud cancelada por usuario |
| 9 | Rechazada | `CREC` | ❌ Rechazo por criterios técnicos |
| 11 | Rechazo definitivo | `SREC` | ❌ Rechazo sin posibilidad de apelación |
| 22 | Deshabilitada | `DESH` | ❌ Expediente deshabilitado |

---

## 2. Query de Filtrado por Batch

### 2.1 Batch 1 - Expedientes Aprobados

```sql
-- Filtro para primer batch: Solo expedientes aprobados
SELECT p.*
FROM alim_producto p
INNER JOIN ctl_estado e ON p.id_ctl_estado = e.id
WHERE e.codigo = 'APRO'
  AND p.id_ctl_estado = 8;
```

### 2.2 Consulta de Expedientes Pendientes (En Proceso)

```sql
-- Expedientes en proceso que eventualmente podrían ser aprobados
SELECT
    p.id,
    p.nombre_comercial,
    e.nombre AS estado,
    e.codigo AS codigo_estado,
    p.fecha_registro
FROM alim_producto p
INNER JOIN ctl_estado e ON p.id_ctl_estado = e.id
WHERE e.codigo IN (
    'INGR', 'RECP', 'EVAL', 'AUTH', 'LAB', 'PEND',
    'OBS', 'ECAL', 'ERAN', 'EAVT', 'ERRA', 'REVA',
    'ERDA', 'OBST', 'PREF', 'APRR'
)
ORDER BY p.fecha_registro ASC;
```

### 2.3 Consulta de Expedientes Excluidos

```sql
-- Expedientes que NO serán migrados (estados terminales negativos)
SELECT
    p.id,
    p.nombre_comercial,
    e.nombre AS estado,
    e.codigo AS codigo_estado
FROM alim_producto p
INNER JOIN ctl_estado e ON p.id_ctl_estado = e.id
WHERE e.codigo IN ('RECH', 'CANC', 'CREC', 'SREC', 'DESH');
```

---

## 3. Estrategia de Periodicidad del ETL

### 3.1 Cronograma de Ejecución

```
┌─────────────────────────────────────────────────────────────────┐
│                    TIMELINE DE MIGRACIÓN                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Batch 1 (Inicial)       Batch 2      Batch 3      Batch 4     │
│  ────────────────       ─────────    ─────────    ─────────    │
│  │                      │            │            │            │
│  ▼                      ▼            ▼            ▼            │
│  [APRO actuales]        [Nuevos]     [Nuevos]     [Nuevos]     │
│                                                                 │
│  T0                     T0+1 día     T0+2 días    T0+3 días    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Frecuencia Recomendada

| Fase | Frecuencia | Descripción |
|------|------------|-------------|
| **Batch 1** | Única vez | Migración inicial de todos los expedientes `APRO` existentes |
| **Batches Subsecuentes** | **Diaria** | Captura de nuevas aprobaciones cada 24 horas |
| **Período de Transición** | 3-6 meses | Hasta que SISAM deje de recibir nuevas solicitudes |
| **Batch Final** | Única vez | Migración de últimos expedientes en proceso una vez cerrado SISAM |

> ⏰ **Horario sugerido de ejecución**: Entre 2:00 AM - 5:00 AM para minimizar impacto en operaciones.

### 3.3 Lógica del ETL Incremental

```sql
-- ETL Incremental: Detectar nuevas aprobaciones desde última ejecución
SELECT p.*
FROM alim_producto p
INNER JOIN ctl_estado e ON p.id_ctl_estado = e.id
WHERE e.codigo = 'APRO'
  AND p.fecha_aprobacion > :last_etl_run_date  -- Parámetro: fecha última ejecución
  AND NOT EXISTS (
      -- Verificar que no haya sido migrado previamente
      SELECT 1
      FROM core.expedient_base_registries r
      WHERE r.legacy_id = CAST(p.id AS VARCHAR)
  );
```

---

## 4. Diagrama de Flujo del Proceso

```
                                    ┌─────────────────┐
                                    │   alim_producto │
                                    │     (SISAM)     │
                                    └────────┬────────┘
                                             │
                                             ▼
                               ┌─────────────────────────┐
                               │   Clasificar por Estado │
                               └─────────────────────────┘
                                             │
                    ┌────────────────────────┼────────────────────────┐
                    │                        │                        │
                    ▼                        ▼                        ▼
           ┌───────────────┐        ┌───────────────┐        ┌───────────────┐
           │   APROBADO    │        │  EN PROCESO   │        │   EXCLUIDO    │
           │    (APRO)     │        │ (16 estados)  │        │  (5 estados)  │
           └───────┬───────┘        └───────┬───────┘        └───────┬───────┘
                   │                        │                        │
                   ▼                        ▼                        ▼
           ┌───────────────┐        ┌───────────────┐        ┌───────────────┐
           │   MIGRAR      │        │   MONITOREAR  │        │   NO MIGRAR   │
           │   A CORE      │        │   SEMANALMENTE│        │   (Fin)       │
           └───────────────┘        └───────┬───────┘        └───────────────┘
                                            │
                                            ▼
                                   ┌─────────────────┐
                                   │ ¿Cambió a APRO? │
                                   └────────┬────────┘
                                            │
                              ┌─────────────┴─────────────┐
                              │                           │
                              ▼                           ▼
                        ┌─────────┐                 ┌───────────┐
                        │   SÍ    │                 │    NO     │
                        └────┬────┘                 └─────┬─────┘
                             │                            │
                             ▼                            ▼
                      ┌────────────┐              ┌──────────────┐
                      │  MIGRAR    │              │  Continuar   │
                      │  EN BATCH  │              │  Monitoreando│
                      └────────────┘              └──────────────┘
```

---

## 5. Métricas y Monitoreo

### 5.1 KPIs del Proceso

| Métrica | Descripción | Query |
|---------|-------------|-------|
| **Total Aprobados** | Expedientes listos para Batch 1 | `SELECT COUNT(*) FROM alim_producto WHERE id_ctl_estado = 8` |
| **Total En Proceso** | Expedientes pendientes de aprobación | `SELECT COUNT(*) WHERE codigo IN ('INGR',...,'APRR')` |
| **Total Excluidos** | Expedientes que no migrarán | `SELECT COUNT(*) WHERE codigo IN ('RECH','CANC','CREC','SREC','DESH')` |
| **Tasa de Conversión** | % de pendientes que pasan a APRO por semana | Comparar snapshots semanales |

### 5.2 Alertas Recomendadas

- ⚠️ **Expedientes estancados**: Alertar si un expediente lleva >30 días en estado de proceso
- 📊 **Reporte diario**: Enviar resumen de expedientes migrados cada día
- ⚠️ **Volumen alto de pendientes**: Alertar si hay >1000 expedientes en cola
- ✅ **Batch exitoso**: Notificar cantidad migrada después de cada ejecución

---

## 6. Consideraciones Finales

### 6.1 Ventajas de esta Estrategia

1. **Priorización clara**: Los expedientes aprobados (productivos) se migran primero
2. **Actualización diaria**: Nuevas aprobaciones se reflejan en CORE en máximo 24 horas
3. **Sin pérdida de datos**: Los expedientes en proceso no se pierden, solo se retrasan
4. **Flexibilidad**: La periodicidad diaria puede ajustarse según volumen
5. **Trazabilidad**: Uso de `legacy_id` permite auditoría completa

### 6.2 Riesgos y Mitigaciones

| Riesgo | Mitigación |
|--------|------------|
| Expedientes que nunca se aprueban | Definir fecha límite para migración forzada o exclusión |
| Duplicados en batches | Validar `legacy_id` antes de cada inserción |
| Cambios de estado durante migración | Usar transacciones y snapshots de datos |

---

## 7. Historial de Versiones

| Versión | Fecha | Autor | Cambios |
|---------|-------|-------|---------|
| 1.0 | 2026-01-30 | Data Team | Documento inicial |
