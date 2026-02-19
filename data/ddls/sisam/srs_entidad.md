# DDL: srs_entidad (Migración Cross-Database)

Migración de `alim_empresa` y `alim_persona` (BD origen) → `srs_entidad` (BD destino) via CSV.

---

## Paso 1: Crear Tabla en BD Destino

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE srs_entidad (
    id                                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre                                VARCHAR(300) NOT NULL,
    razon_social                          VARCHAR(100),
    direccion                             VARCHAR(300),
    correo_electronico                    VARCHAR(100),
    nit                                   VARCHAR(14),
    iva                                   VARCHAR(7),
    dui                                   VARCHAR(9),
    carne_residente                       VARCHAR(15),
    tamanio_empresa                       VARCHAR(100),
    giro_empresa                          VARCHAR(300),
    municipio                             VARCHAR(100),
    pais                                  VARCHAR(100) NOT NULL,
    activo                                BOOLEAN NOT NULL DEFAULT TRUE,
    legacy_id                             VARCHAR(20) NOT NULL UNIQUE,
    tipo_entidad                          VARCHAR(20) NOT NULL CHECK (tipo_entidad IN ('EMPRESA', 'PERSONA')),
    created_at                            TIMESTAMP DEFAULT NOW(),
    updated_at                            TIMESTAMP DEFAULT NOW(),
    deleted_at                            TIMESTAMP
);

CREATE INDEX idx_entidad_legacy ON srs_entidad(legacy_id);
CREATE INDEX idx_entidad_nombre ON srs_entidad(nombre);
CREATE INDEX idx_entidad_tipo ON srs_entidad(tipo_entidad);
CREATE INDEX idx_entidad_activo ON srs_entidad(activo);
```

---

## Paso 2: Exportar Empresas (BD Origen → TablePlus)

```sql
SELECT
    e.nombre_comercial AS nombre,
    e.razon_social,
    e.direccion,
    e.correo_electronico,
    e.nit,
    e.iva,
    NULL AS dui,
    NULL AS carne_residente,
    t.nombre AS tamanio_empresa,
    g.nombre AS giro_empresa,
    m.nombre AS municipio,
    p.nombre AS pais,
    CASE
        WHEN e.estado_empresa = '1' OR UPPER(e.estado_empresa) = 'ACTIVO' THEN TRUE
        ELSE FALSE
    END AS activo,
    CONCAT('EMP-', e.id) AS legacy_id,
    'EMPRESA' AS tipo_entidad
FROM alim_empresa e
LEFT JOIN ctl_tamanio_empresa t ON e.id_ctl_tamanio_empresa = t.id
LEFT JOIN ctl_giro_empresa g ON e.id_ctl_giro_empresa = g.id
LEFT JOIN ctl_municipio m ON e.id_ctl_municipio = m.id
LEFT JOIN ctl_pais p ON e.id_ctl_pais = p.id;
```

Guardar como: `/Users/heycsar/tmp/empresas.csv`

---

## Paso 3: Exportar Personas (BD Origen → TablePlus)

```sql
SELECT
    CONCAT(pe.nombre, ' ', pe.apellido) AS nombre,
    NULL AS razon_social,
    pe.direccion,
    pe.correo_electronico,
    pe.nit,
    pe.iva,
    pe.dui,
    pe.carne_residente,
    NULL AS tamanio_empresa,
    NULL AS giro_empresa,
    m.nombre AS municipio,
    p.nombre AS pais,
    CASE WHEN pe.estado_persona = 1 THEN TRUE ELSE FALSE END AS activo,
    CONCAT('PER-', pe.id) AS legacy_id,
    'PERSONA' AS tipo_entidad
FROM alim_persona pe
LEFT JOIN ctl_municipio m ON pe.id_ctl_municipio = m.id
LEFT JOIN ctl_pais p ON pe.id_ctl_pais = p.id;
```

Guardar como: `/Users/heycsar/tmp/personas.csv`

---

## Paso 4: Importar en BD Destino (Terminal)

```bash
psql -h HOST -U usuario -d base_datos_destino
```

```sql
\COPY srs_entidad(nombre, razon_social, direccion, correo_electronico, nit, iva, dui, carne_residente, tamanio_empresa, giro_empresa, municipio, pais, activo, legacy_id, tipo_entidad) FROM '/Users/heycsar/tmp/empresas.csv' WITH CSV HEADER;

\COPY srs_entidad(nombre, razon_social, direccion, correo_electronico, nit, iva, dui, carne_residente, tamanio_empresa, giro_empresa, municipio, pais, activo, legacy_id, tipo_entidad) FROM '/Users/heycsar/tmp/personas.csv' WITH CSV HEADER;
```

---

## Paso 5: Registrar en data_center_tables

```sql
INSERT INTO data_center_tables (id, name, description, columns, deleted_at, created_at, updated_at)
VALUES (
    'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
    'srs_entidad',
    'Tabla unificada de empresas y personas naturales para registros sanitarios',
    '[{"id": "f1a2b3c4-d5e6-4f7a-8b9c-0d1e2f3a4b5c", "name": "id", "type": "UUID"}, {"id": "f2a3b4c5-d6e7-4f8a-9b0c-1d2e3f4a5b6c", "name": "nombre", "type": "STRING"}, {"id": "f3a4b5c6-d7e8-4f9a-0b1c-2d3e4f5a6b7c", "name": "razon_social", "type": "STRING"}, {"id": "f4a5b6c7-d8e9-4f0a-1b2c-3d4e5f6a7b8c", "name": "direccion", "type": "STRING"}, {"id": "f5a6b7c8-d9e0-4f1a-2b3c-4d5e6f7a8b9c", "name": "correo_electronico", "type": "STRING"}, {"id": "f6a7b8c9-d0e1-4f2a-3b4c-5d6e7f8a9b0c", "name": "nit", "type": "STRING"}, {"id": "f7a8b9c0-d1e2-4f3a-4b5c-6d7e8f9a0b1c", "name": "iva", "type": "STRING"}, {"id": "f8a9b0c1-d2e3-4f4a-5b6c-7d8e9f0a1b2c", "name": "dui", "type": "STRING"}, {"id": "f9a0b1c2-d3e4-4f5a-6b7c-8d9e0f1a2b3c", "name": "carne_residente", "type": "STRING"}, {"id": "f0a1b2c3-d4e5-4f6a-7b8c-9d0e1f2a3b4c", "name": "tamanio_empresa", "type": "STRING"}, {"id": "f1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d", "name": "giro_empresa", "type": "STRING"}, {"id": "f2b3c4d5-e6f7-4a8b-9c0d-1e2f3a4b5c6d", "name": "municipio", "type": "STRING"}, {"id": "f3b4c5d6-e7f8-4a9b-0c1d-2e3f4a5b6c7d", "name": "pais", "type": "STRING"}, {"id": "f7b8c9d0-e1f2-4a3b-4c5d-6e7f8a9b0c1d", "name": "activo", "type": "BOOLEAN"}, {"id": "f8b9c0d1-e2f3-4a4b-5c6d-7e8f9a0b1c2d", "name": "legacy_id", "type": "STRING"}, {"id": "f9b0c1d2-e3f4-4a5b-6c7d-8e9f0a1b2c3d", "name": "tipo_entidad", "type": "STRING"}, {"id": "a0b1c2d3-e4f5-4a6b-7c8d-9e0f1a2b3c4d", "name": "created_at", "type": "TIMESTAMP"}, {"id": "a1b2c3d4-f5e6-4a7b-8c9d-0e1f2a3b4c5e", "name": "updated_at", "type": "TIMESTAMP"}, {"id": "a2b3c4d5-f6e7-4a8b-9c0d-1e2f3a4b5c6e", "name": "deleted_at", "type": "TIMESTAMP"}]',
    NULL,
    NOW(),
    NOW()
);
```

---

## Paso 6: Validar

```sql
SELECT tipo_entidad, activo, COUNT(*)
FROM srs_entidad
GROUP BY tipo_entidad, activo
ORDER BY tipo_entidad, activo DESC;
```

---

## Resumen de Columnas (19 total)

| Campo | Tipo | Empresa | Persona |
|-------|------|---------|---------|
| `id` | UUID | ✅ | ✅ |
| `nombre` | STRING | nombre_comercial | nombre + apellido |
| `razon_social` | STRING | ✅ | NULL |
| `direccion` | STRING | ✅ | ✅ |
| `correo_electronico` | STRING | ✅ | ✅ |
| `nit` | STRING | ✅ | ✅ |
| `iva` | STRING | ✅ | ✅ |
| `dui` | STRING | NULL | ✅ |
| `carne_residente` | STRING | NULL | ✅ |
| `tamanio_empresa` | STRING | ✅ | NULL |
| `giro_empresa` | STRING | ✅ | NULL |
| `municipio` | STRING | ✅ | ✅ |
| `pais` | STRING | ✅ | ✅ |
| `activo` | BOOLEAN | ✅ | ✅ |
| `legacy_id` | STRING | EMP-{id} | PER-{id} |
| `tipo_entidad` | STRING | EMPRESA | PERSONA |
| `created_at` | TIMESTAMP | ✅ | ✅ |
| `updated_at` | TIMESTAMP | ✅ | ✅ |
| `deleted_at` | TIMESTAMP | ✅ | ✅ |
