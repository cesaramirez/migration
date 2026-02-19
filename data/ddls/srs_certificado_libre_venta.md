# DDL: srs_certificado_libre_venta (Migración Cross-Database)

Migración de `alim_certificado_libre_venta` (BD origen) → `srs_certificado_libre_venta` (BD destino) via CSV.

---

## Paso 1: Crear Tabla en BD Destino

```sql
DROP TABLE IF EXISTS srs_certificado_libre_venta CASCADE;

CREATE TABLE srs_certificado_libre_venta (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    codigo                    VARCHAR(100) NOT NULL,
    pais                      VARCHAR(100) NOT NULL,
    fecha_emision             VARCHAR(10) NOT NULL,
    autoridad_sanitaria       VARCHAR(250) NOT NULL,
    legacy_id                 VARCHAR(20) NOT NULL UNIQUE,
    created_at                TIMESTAMP DEFAULT NOW(),
    updated_at                TIMESTAMP DEFAULT NOW(),
    deleted_at                TIMESTAMP
);

CREATE INDEX idx_clv_legacy ON srs_certificado_libre_venta(legacy_id);
CREATE INDEX idx_clv_codigo ON srs_certificado_libre_venta(codigo);
CREATE INDEX idx_clv_pais ON srs_certificado_libre_venta(pais);
```

---

## Paso 2: Exportar Datos (BD Origen → TablePlus)

```sql
SELECT
    clv.cod_clv AS codigo,
    p.nombre AS pais,
    TO_CHAR(clv.fecha_emision, 'DD/MM/YYYY') AS fecha_emision,
    clv.autoridad_sanitaria_emite AS autoridad_sanitaria,
    CONCAT('CLV-', clv.id) AS legacy_id
FROM alim_certificado_libre_venta clv
LEFT JOIN ctl_pais p ON clv.id_ctl_pais = p.id;
```

Guardar como: `/Users/heycsar/tmp/certificados.csv`

---

## Paso 3: Importar en BD Destino (Terminal)

```bash
psql -h HOST -U usuario -d base_datos_destino
```

```sql
\COPY srs_certificado_libre_venta(codigo, pais, fecha_emision, autoridad_sanitaria, legacy_id) FROM '/Users/heycsar/tmp/certificados.csv' WITH CSV HEADER;
```

---

## Paso 4: Registrar en data_center_tables

```sql
INSERT INTO data_center_tables (id, name, description, columns, deleted_at, created_at, updated_at)
VALUES (
    'c3d4e5f6-a7b8-4c9d-0e1f-2a3b4c5d6e7f',
    'srs_certificado_libre_venta',
    'Certificados de libre venta emitidos a nivel nacional o registrados del extranjero',
    '[{"id": "d1e2f3a4-b5c6-4d7e-8f9a-0b1c2d3e4f5b", "name": "id", "type": "UUID"}, {"id": "d2e3f4a5-b6c7-4d8e-9f0a-1b2c3d4e5f6b", "name": "codigo", "type": "STRING"}, {"id": "d3e4f5a6-b7c8-4d9e-0f1a-2b3c4d5e6f7b", "name": "pais", "type": "STRING"}, {"id": "d4e5f6a7-b8c9-4d0e-1f2a-3b4c5d6e7f8b", "name": "fecha_emision", "type": "DATE"}, {"id": "d5e6f7a8-b9c0-4d1e-2f3a-4b5c6d7e8f9b", "name": "autoridad_sanitaria", "type": "STRING"}, {"id": "d6e7f8a9-b0c1-4d2e-3f4a-5b6c7d8e9f0b", "name": "legacy_id", "type": "STRING"}, {"id": "d7e8f9a0-b1c2-4d3e-4f5a-6b7c8d9e0f1b", "name": "created_at", "type": "TIMESTAMP"}, {"id": "d8e9f0a1-b2c3-4d4e-5f6a-7b8c9d0e1f2b", "name": "updated_at", "type": "TIMESTAMP"}, {"id": "d9e0f1a2-b3c4-4d5e-6f7a-8b9c0d1e2f3b", "name": "deleted_at", "type": "TIMESTAMP"}]',
    NULL,
    NOW(),
    NOW()
);
```

---

## Paso 5: Validar

```sql
SELECT COUNT(*) FROM srs_certificado_libre_venta;

SELECT pais, COUNT(*)
FROM srs_certificado_libre_venta
GROUP BY pais
ORDER BY COUNT(*) DESC;
```

---

## Resumen de Columnas (9 total)

| Campo | Tipo | Origen |
|-------|------|--------|
| `id` | UUID | generado |
| `codigo` | STRING | cod_clv |
| `pais` | STRING | ctl_pais.nombre |
| `fecha_emision` | DATE | fecha_emision |
| `autoridad_sanitaria` | STRING | autoridad_sanitaria_emite |
| `legacy_id` | STRING | CLV-{id} |
| `created_at` | TIMESTAMP | generado |
| `updated_at` | TIMESTAMP | generado |
| `deleted_at` | TIMESTAMP | soft delete |

## Campos Removidos

- `tipo_clv`
- `id_alim_empresa`, `id_alim_persona`
- `usuario`
- `id_ctl_pais_destino`
- `ruta_archivo_clv`
- `fecha_registro`
