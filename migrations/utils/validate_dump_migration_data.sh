#!/bin/bash
# =============================================================================
# Script: validate_dump_migration_data.sh
# Propósito: Validar si un dump SQL contiene datos de las tablas de migración
# Uso: ./validate_dump_migration_data.sh <archivo_dump.sql>
# =============================================================================

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Tablas a verificar
# =============================================================================
EXPEDIENT_TABLES=(
    "expedient_base_entities"
    "expedient_base_entity_fields"
    "expedient_base_registries"
    "expedient_base_registry_fields"
    "expedient_base_registry_relation"
)

CENTRO_DATOS_TABLES=(
    "srs_bodega"
    "srs_entidad"
    "srs_sub_grupo_alimenticio"
    "srs_certificado_libre_venta"
    "srs_material"
    "srs_unidad_medida"
    "paises"
    "data_center_tables"
)

MIGRATION_TEMP_TABLES=(
    "migration_alim_producto_temp"
    "migration_bodega_producto"
    "migration_bodega_mapping"
)

# =============================================================================
# Funciones
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

check_table() {
    local dump_file=$1
    local table_name=$2

    # Buscar COPY o INSERT para la tabla
    local copy_count=$(grep -c "COPY.*${table_name}" "$dump_file" 2>/dev/null || echo "0")
    local insert_count=$(grep -c "INSERT INTO.*${table_name}" "$dump_file" 2>/dev/null || echo "0")
    local create_count=$(grep -c "CREATE TABLE.*${table_name}" "$dump_file" 2>/dev/null || echo "0")

    # Estimar cantidad de registros (contar líneas después de COPY hasta \.)
    local data_lines=0
    if [ "$copy_count" -gt 0 ]; then
        # Extraer las líneas entre COPY y \.
        data_lines=$(awk "/COPY.*${table_name}/,/^\\\\\./" "$dump_file" 2>/dev/null | wc -l | tr -d ' ')
        # Restar 2 (línea de COPY y línea de \.)
        data_lines=$((data_lines - 2))
        [ $data_lines -lt 0 ] && data_lines=0
    fi

    echo "$copy_count|$insert_count|$create_count|$data_lines"
}

validate_dump() {
    local dump_file=$1

    if [ ! -f "$dump_file" ]; then
        echo -e "${RED}❌ Error: El archivo '$dump_file' no existe${NC}"
        exit 1
    fi

    local file_size=$(du -h "$dump_file" | cut -f1)
    echo -e "${BLUE}📄 Archivo: ${NC}$dump_file"
    echo -e "${BLUE}📦 Tamaño: ${NC}$file_size"
    echo ""

    # =============================================================================
    # Verificar tablas de Expediente
    # =============================================================================
    print_header "📋 TABLAS DE EXPEDIENTE (Core)"

    printf "%-45s %-8s %-8s %-8s %-12s\n" "Tabla" "COPY" "INSERT" "CREATE" "~Registros"
    echo "────────────────────────────────────────────────────────────────────────────────"

    local exp_total=0
    for table in "${EXPEDIENT_TABLES[@]}"; do
        result=$(check_table "$dump_file" "$table")
        IFS='|' read -r copy insert create data_lines <<< "$result"

        if [ "$copy" -gt 0 ] || [ "$insert" -gt 0 ]; then
            status="${GREEN}✅${NC}"
            exp_total=$((exp_total + data_lines))
        elif [ "$create" -gt 0 ]; then
            status="${YELLOW}⚠️ ${NC}"
        else
            status="${RED}❌${NC}"
        fi

        printf "%-45s %-8s %-8s %-8s %-12s %b\n" "$table" "$copy" "$insert" "$create" "$data_lines" "$status"
    done
    echo ""
    echo -e "${BLUE}Total estimado de registros en expediente: ${NC}$exp_total"

    # =============================================================================
    # Verificar tablas de Centro de Datos
    # =============================================================================
    print_header "🗄️  TABLAS DE CENTRO DE DATOS"

    printf "%-45s %-8s %-8s %-8s %-12s\n" "Tabla" "COPY" "INSERT" "CREATE" "~Registros"
    echo "────────────────────────────────────────────────────────────────────────────────"

    local cd_total=0
    for table in "${CENTRO_DATOS_TABLES[@]}"; do
        result=$(check_table "$dump_file" "$table")
        IFS='|' read -r copy insert create data_lines <<< "$result"

        if [ "$copy" -gt 0 ] || [ "$insert" -gt 0 ]; then
            status="${GREEN}✅${NC}"
            cd_total=$((cd_total + data_lines))
        elif [ "$create" -gt 0 ]; then
            status="${YELLOW}⚠️ ${NC}"
        else
            status="${RED}❌${NC}"
        fi

        printf "%-45s %-8s %-8s %-8s %-12s %b\n" "$table" "$copy" "$insert" "$create" "$data_lines" "$status"
    done
    echo ""
    echo -e "${BLUE}Total estimado de registros en centro de datos: ${NC}$cd_total"

    # =============================================================================
    # Verificar tablas temporales de migración
    # =============================================================================
    print_header "🔄 TABLAS TEMPORALES DE MIGRACIÓN"

    printf "%-45s %-8s %-8s %-8s %-12s\n" "Tabla" "COPY" "INSERT" "CREATE" "~Registros"
    echo "────────────────────────────────────────────────────────────────────────────────"

    for table in "${MIGRATION_TEMP_TABLES[@]}"; do
        result=$(check_table "$dump_file" "$table")
        IFS='|' read -r copy insert create data_lines <<< "$result"

        if [ "$copy" -gt 0 ] || [ "$insert" -gt 0 ]; then
            status="${GREEN}✅${NC}"
        elif [ "$create" -gt 0 ]; then
            status="${YELLOW}⚠️ ${NC}"
        else
            status="${RED}❌${NC}"
        fi

        printf "%-45s %-8s %-8s %-8s %-12s %b\n" "$table" "$copy" "$insert" "$create" "$data_lines" "$status"
    done

    # =============================================================================
    # Verificar legacy_id (trazabilidad)
    # =============================================================================
    print_header "🔗 VERIFICACIÓN DE LEGACY_ID (Trazabilidad)"

    local prd_count=$(grep -o "PRD-[0-9]*" "$dump_file" 2>/dev/null | wc -l | tr -d ' ')
    local bod_count=$(grep -o "BOD-[0-9]*" "$dump_file" 2>/dev/null | wc -l | tr -d ' ')
    local emp_count=$(grep -o "EMP-[0-9]*" "$dump_file" 2>/dev/null | wc -l | tr -d ' ')
    local per_count=$(grep -o "PER-[0-9]*" "$dump_file" 2>/dev/null | wc -l | tr -d ' ')
    local clv_count=$(grep -o "CLV-[0-9]*" "$dump_file" 2>/dev/null | wc -l | tr -d ' ')

    echo -e "PRD-* (Productos):     $prd_count referencias"
    echo -e "BOD-* (Bodegas):       $bod_count referencias"
    echo -e "EMP-* (Empresas):      $emp_count referencias"
    echo -e "PER-* (Personas):      $per_count referencias"
    echo -e "CLV-* (Certificados):  $clv_count referencias"

    # =============================================================================
    # Resumen
    # =============================================================================
    print_header "📊 RESUMEN"

    if [ "$exp_total" -gt 0 ] || [ "$cd_total" -gt 0 ]; then
        echo -e "${GREEN}✅ El dump CONTIENE datos de migración${NC}"
        echo ""
        echo "Detalles:"
        echo "  • Registros de expediente: ~$exp_total"
        echo "  • Registros de centro de datos: ~$cd_total"
        echo "  • Referencias legacy_id: ~$((prd_count + bod_count + emp_count + per_count + clv_count))"
    else
        echo -e "${YELLOW}⚠️  El dump podría NO contener datos de migración${NC}"
        echo ""
        echo "Verifica que:"
        echo "  1. El dump incluye las tablas correctas"
        echo "  2. El dump fue exportado CON datos (no solo esquema)"
        echo "  3. La migración fue ejecutada antes del dump"
    fi

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
}

# =============================================================================
# Verificación de tablas personalizadas (opcional)
# =============================================================================
validate_custom_tables() {
    local dump_file=$1
    shift
    local tables=("$@")

    print_header "🔍 TABLAS PERSONALIZADAS"

    printf "%-45s %-8s %-8s %-8s %-12s\n" "Tabla" "COPY" "INSERT" "CREATE" "~Registros"
    echo "────────────────────────────────────────────────────────────────────────────────"

    for table in "${tables[@]}"; do
        result=$(check_table "$dump_file" "$table")
        IFS='|' read -r copy insert create data_lines <<< "$result"

        if [ "$copy" -gt 0 ] || [ "$insert" -gt 0 ]; then
            status="${GREEN}✅${NC}"
        elif [ "$create" -gt 0 ]; then
            status="${YELLOW}⚠️ ${NC}"
        else
            status="${RED}❌${NC}"
        fi

        printf "%-45s %-8s %-8s %-8s %-12s %b\n" "$table" "$copy" "$insert" "$create" "$data_lines" "$status"
    done
}

# =============================================================================
# Main
# =============================================================================

show_help() {
    echo "Uso: $0 [opciones] <archivo_dump.sql>"
    echo ""
    echo "Opciones:"
    echo "  -h, --help          Muestra esta ayuda"
    echo "  -t, --tables TABLE  Valida tablas específicas (puede usarse múltiples veces)"
    echo "  -q, --quick         Modo rápido (solo conteo, sin estimación de registros)"
    echo ""
    echo "Ejemplos:"
    echo "  $0 backup_core.sql"
    echo "  $0 -t alim_producto -t alim_empresa dump.sql"
    echo "  $0 --quick large_dump.sql"
}

# Parse arguments
CUSTOM_TABLES=()
QUICK_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--tables)
            CUSTOM_TABLES+=("$2")
            shift 2
            ;;
        -q|--quick)
            QUICK_MODE=true
            shift
            ;;
        -*)
            echo -e "${RED}Error: Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
        *)
            DUMP_FILE="$1"
            shift
            ;;
    esac
done

if [ -z "$DUMP_FILE" ]; then
    echo -e "${RED}Error: Debe especificar un archivo de dump${NC}"
    show_help
    exit 1
fi

# Ejecutar validación
validate_dump "$DUMP_FILE"

# Validar tablas personalizadas si se especificaron
if [ ${#CUSTOM_TABLES[@]} -gt 0 ]; then
    validate_custom_tables "$DUMP_FILE" "${CUSTOM_TABLES[@]}"
fi

echo ""
echo -e "${BLUE}Validación completada: $(date)${NC}"
