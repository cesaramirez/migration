# DDL: srs_sub_grupo_alimenticio (Migración Cross-Database)

Migración de `alim_sub_grupo_alimenticio` (BD origen) → `srs_sub_grupo_alimenticio` (BD destino) via CSV.

---

## Paso 1: Crear Tabla en BD Destino

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE srs_sub_grupo_alimenticio (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre                    VARCHAR(300) NOT NULL,
    clasificacion_alimenticia VARCHAR(200) NOT NULL,
    tipo_riesgo               VARCHAR(100),
    legacy_id                 VARCHAR(20) NOT NULL UNIQUE,
    created_at                TIMESTAMP DEFAULT NOW(),
    updated_at                TIMESTAMP DEFAULT NOW(),
    deleted_at                TIMESTAMP
);

CREATE INDEX idx_sub_grupo_legacy ON srs_sub_grupo_alimenticio(legacy_id);
CREATE INDEX idx_sub_grupo_nombre ON srs_sub_grupo_alimenticio(nombre);
CREATE INDEX idx_sub_grupo_clasificacion ON srs_sub_grupo_alimenticio(clasificacion_alimenticia);
```

---

## Paso 2: Exportar Datos (BD Origen → TablePlus)

```sql
SELECT
    sg.nombre,
    cg.nombre AS clasificacion_alimenticia,
    tr.nombre AS tipo_riesgo,
    CONCAT('SGR-', sg.id) AS legacy_id
FROM alim_sub_grupo_alimenticio sg
LEFT JOIN ctl_clasificacion_grupo_alimenticio cg ON sg.id_ctl_clasificacion_grupo_alimenticio = cg.id
LEFT JOIN ctl_tipo_riesgo tr ON sg.id_ctl_tipo_riesgo = tr.id;
```

Guardar como: `/Users/heycsar/tmp/sub_grupos.csv`

---

## Paso 3: Importar en BD Destino (Terminal)

```bash
psql -h HOST -U usuario -d base_datos_destino
```

```sql
\COPY srs_sub_grupo_alimenticio(nombre, clasificacion_alimenticia, tipo_riesgo, legacy_id) FROM '/Users/heycsar/tmp/sub_grupos.csv' WITH CSV HEADER;
```

---

## Paso 4: Registrar en data_center_tables

```sql
INSERT INTO data_center_tables (id, name, description, columns, deleted_at, created_at, updated_at)
VALUES (
    'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e',
    'srs_sub_grupo_alimenticio',
    'Sub grupos alimenticios para clasificación de productos',
    '[{"id": "c1d2e3f4-a5b6-4c7d-8e9f-0a1b2c3d4e5f", "name": "id", "type": "UUID"}, {"id": "c2d3e4f5-a6b7-4c8d-9e0f-1a2b3c4d5e6f", "name": "nombre", "type": "STRING"}, {"id": "c4d5e6f7-a8b9-4c0d-1e2f-3a4b5c6d7e8f", "name": "clasificacion_alimenticia", "type": "STRING"}, {"id": "c5d6e7f8-a9b0-4c1d-2e3f-4a5b6c7d8e9f", "name": "tipo_riesgo", "type": "STRING"}, {"id": "c9d0e1f2-a3b4-4c5d-6e7f-8a9b0c1d2e3f", "name": "legacy_id", "type": "STRING"}, {"id": "d0e1f2a3-b4c5-4d6e-7f8a-9b0c1d2e3f4a", "name": "created_at", "type": "TIMESTAMP"}, {"id": "d1e2f3a4-b5c6-4d7e-8f9a-0b1c2d3e4f5a", "name": "updated_at", "type": "TIMESTAMP"}, {"id": "d2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6a", "name": "deleted_at", "type": "TIMESTAMP"}]',
    NULL,
    NOW(),
    NOW()
);
```

---

## Paso 5: Validar

```sql
SELECT COUNT(*) FROM srs_sub_grupo_alimenticio;

SELECT clasificacion_alimenticia, COUNT(*)
FROM srs_sub_grupo_alimenticio
GROUP BY clasificacion_alimenticia
ORDER BY COUNT(*) DESC;
```

---

## Resumen de Columnas (8 total)

| Campo | Tipo | Origen |
|-------|------|--------|
| `id` | UUID | generado |
| `nombre` | STRING | nombre |
| `clasificacion_alimenticia` | STRING | ctl_clasificacion_grupo_alimenticio.nombre |
| `tipo_riesgo` | STRING | ctl_tipo_riesgo.nombre |
| `legacy_id` | STRING | SGR-{id} |
| `created_at` | TIMESTAMP | generado |
| `updated_at` | TIMESTAMP | generado |
| `deleted_at` | TIMESTAMP | soft delete |
