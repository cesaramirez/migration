#!/bin/bash
# =============================================================================
# Script para extraer DDLs de tablas PostgreSQL a archivos .md
# =============================================================================
# Uso: ./extract_ddls.sh <host> <user> <database> <tabla1> <tabla2> ...
# Ejemplo: ./extract_ddls.sh 127.0.0.1 postgres sisam alim_producto ctl_pais
# =============================================================================

# Configuración
HOST="${1:-127.0.0.1}"
USER="${2:-postgres}"
DATABASE="${3:-sisam}"

# Obtener directorio del script y calcular ruta absoluta
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/../assets/ddls"

# Validar argumentos
if [ $# -lt 4 ]; then
    echo "Uso: $0 <host> <user> <database> <tabla1> [tabla2] [tabla3] ..."
    echo "Ejemplo: $0 127.0.0.1 postgres sisam alim_producto ctl_pais"
    exit 1
fi

# Crear directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"

# Saltar los primeros 3 argumentos (host, user, database)
shift 3

# Procesar cada tabla
for TABLE in "$@"; do
    OUTPUT_FILE="$OUTPUT_DIR/${TABLE}.md"

    echo "Extrayendo DDL de: $TABLE -> $OUTPUT_FILE"

    # Crear archivo markdown con el DDL
    cat > "$OUTPUT_FILE" << EOF
# DDL: ${TABLE}

## Estructura

\`\`\`sql
$(psql -h "$HOST" -U "$USER" -d "$DATABASE" -q -t -A -c "
WITH cols AS (
    SELECT
        '    \"' || column_name || '\" ' ||
        CASE
            WHEN udt_name = 'int4' THEN 'int4'
            WHEN udt_name = 'int8' THEN 'int8'
            WHEN udt_name = 'int2' THEN 'int2'
            WHEN udt_name = 'float4' THEN 'float4'
            WHEN udt_name = 'float8' THEN 'float8'
            WHEN data_type = 'character' THEN 'bpchar'
            WHEN data_type = 'character varying' THEN 'varchar'
            ELSE data_type
        END ||
        CASE
            WHEN character_maximum_length IS NOT NULL THEN '(' || character_maximum_length || ')'
            ELSE ''
        END ||
        CASE WHEN is_nullable = 'NO' THEN ' NOT NULL' ELSE '' END ||
        CASE WHEN column_default IS NOT NULL THEN ' DEFAULT ' || column_default ELSE '' END as col_def,
        ordinal_position
    FROM information_schema.columns
    WHERE table_name = '$TABLE' AND table_schema = 'public'
),
pk AS (
    SELECT string_agg('\"' || kcu.column_name || '\"', ', ') as pk_cols
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = '$TABLE' AND tc.constraint_type = 'PRIMARY KEY'
    GROUP BY tc.constraint_name
),
seqs AS (
    SELECT 'CREATE SEQUENCE IF NOT EXISTS ' || SUBSTRING(column_default FROM 'nextval\(''([^'']+)''' ) || ';' as seq_def
    FROM information_schema.columns
    WHERE table_name = '$TABLE' AND column_default LIKE 'nextval%'
)
SELECT
    COALESCE((SELECT string_agg(seq_def, E'\n') FROM seqs) || E'\n\n', '') ||
    'CREATE TABLE \"public\".\"$TABLE\" (' || E'\n' ||
    (SELECT string_agg(col_def, ',' || E'\n' ORDER BY ordinal_position) FROM cols) ||
    COALESCE(',' || E'\n' || '    PRIMARY KEY (' || (SELECT pk_cols FROM pk) || ')', '') ||
    E'\n' || ');'
;")
\`\`\`

## Comentarios

\`\`\`sql
$(psql -h "$HOST" -U "$USER" -d "$DATABASE" -q -t -A -c "
SELECT 'COMMENT ON COLUMN \"public\".\"' || c.table_name || '\".\"' || c.column_name || '\" IS ''' ||
       pgd.description || ''';'
FROM information_schema.columns c
JOIN pg_catalog.pg_statio_all_tables st ON c.table_name = st.relname
JOIN pg_catalog.pg_description pgd ON pgd.objoid = st.relid
    AND pgd.objsubid = c.ordinal_position
WHERE c.table_name = '$TABLE' AND pgd.description IS NOT NULL
ORDER BY c.ordinal_position;
")
$(psql -h "$HOST" -U "$USER" -d "$DATABASE" -q -t -A -c "
SELECT 'COMMENT ON TABLE \"public\".\"' || relname || '\" IS ''' || obj_description(relid) || ''';'
FROM pg_statio_all_tables
WHERE relname = '$TABLE' AND obj_description(relid) IS NOT NULL;
")
\`\`\`

## Índices

\`\`\`sql
$(psql -h "$HOST" -U "$USER" -d "$DATABASE" -q -t -A -c "
SELECT pg_get_indexdef(indexrelid) || ';'
FROM pg_index
WHERE indrelid = '$TABLE'::regclass
AND NOT indisprimary;
")
\`\`\`
EOF

    echo "  ✓ Creado: $OUTPUT_FILE"
done
