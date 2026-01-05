#!/usr/bin/env python3
"""
Script para actualizar masivamente los file_id en el Master Orchestrator ACH

Uso:
1. Crear archivo CSV con tus file_id de Google Drive:

   catalog_name,file_id,sheet_name
   parcelaciones_tipo,1ABC...XYZ,Parcelaciones_Tipo
   inmuebles_tipo,2DEF...ABC,Inmuebles_Tipo
   ...

   ¿Cómo obtener file_id?
   - Abrir archivo XLSX en Google Drive
   - URL: https://drive.google.com/file/d/[ESTE_ES_EL_FILE_ID]/view
   - Copiar el ID que está entre /d/ y /view

2. Ejecutar: python3 update_ach_file_ids.py

3. Reimportar el workflow actualizado a n8n
"""

import json
import csv
import sys

# Archivo del Master Orchestrator
WORKFLOW_FILE = 'Migrate All ACH XLSX from Google Drive (Master Orchestrator).json'

# Archivo CSV con los IDs (crear este archivo)
CSV_FILE = 'ach_file_ids.csv'

def update_workflow():
    """Actualiza los spreadsheet_id en el workflow"""

    # Leer CSV con los IDs
    try:
        with open(CSV_FILE, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            catalog_ids = {row['catalog_name']: row for row in reader}
    except FileNotFoundError:
        print(f"❌ Error: No se encontró el archivo {CSV_FILE}")
        print(f"\n📝 Crear archivo CSV con formato:")
        print("catalog_name,file_id,sheet_name")
        print("parcelaciones_tipo,1ABC...XYZ,Parcelaciones_Tipo")
        print("\nObtener file_id desde Google Drive:")
        print("  URL: https://drive.google.com/file/d/[FILE_ID]/view")
        sys.exit(1)

    # Leer workflow
    with open(WORKFLOW_FILE, 'r', encoding='utf-8') as f:
        workflow = json.load(f)

    updated_count = 0

    # Actualizar nodos Config
    for node in workflow['nodes']:
        if node['name'].startswith('Config: '):
            # Extraer nombre del catálogo
            catalog_name = node['name'].replace('Config: ', '')

            if catalog_name in catalog_ids:
                # Actualizar el código JavaScript
                code = node['parameters']['jsCode']
                catalog_data = catalog_ids[catalog_name]

                # Reemplazar file_id
                old_line = "file_id: 'YOUR_FILE_ID_HERE'"
                new_line = f"file_id: '{catalog_data['file_id']}'"
                code = code.replace(old_line, new_line)

                # Reemplazar sheet_name si está en el CSV
                if 'sheet_name' in catalog_data and catalog_data['sheet_name']:
                    old_sheet = f"sheet_name: '{catalog_name}'"
                    new_sheet = f"sheet_name: '{catalog_data['sheet_name']}'"
                    code = code.replace(old_sheet, new_sheet)

                node['parameters']['jsCode'] = code
                updated_count += 1
                print(f"✓ Actualizado: {catalog_name}")
                print(f"  - file_id: {catalog_data['file_id']}")
                print(f"  - sheet_name: {catalog_data.get('sheet_name', catalog_name)}")

    # Guardar workflow actualizado
    with open(WORKFLOW_FILE, 'w', encoding='utf-8') as f:
        json.dump(workflow, f, indent=2, ensure_ascii=False)

    print(f"\n✅ Actualizado {updated_count} catálogos en {WORKFLOW_FILE}")
    print(f"\n📝 Próximos pasos:")
    print(f"1. Revisar el archivo actualizado")
    print(f"2. Reimportar a n8n (Import from File)")
    print(f"3. Ejecutar el Master Orchestrator")

if __name__ == '__main__':
    print("="*60)
    print("Actualizador de File IDs - Master Orchestrator ACH (XLSX)")
    print("="*60)
    print()

    # Crear archivo CSV de ejemplo si no existe
    try:
        with open(CSV_FILE, 'r') as f:
            pass
    except FileNotFoundError:
        print(f"📝 Creando archivo de ejemplo: {CSV_FILE}")
        with open(CSV_FILE, 'w', encoding='utf-8') as f:
            f.write("catalog_name,file_id,sheet_name\n")
            f.write("# Reemplazar con tus File IDs reales de Google Drive\n")
            f.write("# Obtener file_id desde URL: https://drive.google.com/file/d/[FILE_ID]/view\n")
            f.write("parcelaciones_tipo,YOUR_FILE_ID_HERE,Parcelaciones_Tipo\n")
            f.write("inmuebles_tipo,YOUR_FILE_ID_HERE,Inmuebles_Tipo\n")
            f.write("propietarios_tipo,YOUR_FILE_ID_HERE,Propietarios_Tipo\n")
            f.write("servicios_tipo,YOUR_FILE_ID_HERE,Servicios_Tipo\n")
            f.write("estados_general,YOUR_FILE_ID_HERE,Estados_General\n")
            f.write("estados_pago,YOUR_FILE_ID_HERE,Estados_Pago\n")
            f.write("estados_mantenimiento,YOUR_FILE_ID_HERE,Estados_Mantenimiento\n")
            f.write("areas_comunes,YOUR_FILE_ID_HERE,Areas_Comunes\n")
            f.write("tipos_mantenimiento,YOUR_FILE_ID_HERE,Tipos_Mantenimiento\n")
            f.write("tipos_pago,YOUR_FILE_ID_HERE,Tipos_Pago\n")
            f.write("conceptos_cobro,YOUR_FILE_ID_HERE,Conceptos_Cobro\n")
            f.write("paises,YOUR_FILE_ID_HERE,Paises\n")
            f.write("departamentos,YOUR_FILE_ID_HERE,Departamentos\n")
            f.write("municipios,YOUR_FILE_ID_HERE,Municipios\n")
            f.write("bancos,YOUR_FILE_ID_HERE,Bancos\n")
            f.write("tipos_documento,YOUR_FILE_ID_HERE,Tipos_Documento\n")
            f.write("roles_usuario,YOUR_FILE_ID_HERE,Roles_Usuario\n")
            f.write("permisos,YOUR_FILE_ID_HERE,Permisos\n")
            f.write("tipos_notificacion,YOUR_FILE_ID_HERE,Tipos_Notificacion\n")
            f.write("prioridades,YOUR_FILE_ID_HERE,Prioridades\n")

        print(f"✓ Archivo creado: {CSV_FILE}")
        print(f"\n⚠️  Editar {CSV_FILE} y reemplazar 'YOUR_FILE_ID_HERE'")
        print(f"   con los File IDs reales de tus archivos XLSX en Google Drive")
        print(f"\n💡 Obtener file_id:")
        print(f"   1. Abrir archivo XLSX en Google Drive")
        print(f"   2. URL: https://drive.google.com/file/d/[ESTE_ES_EL_FILE_ID]/view")
        print(f"   3. Copiar el ID que está entre /d/ y /view\n")
        print(f"Luego ejecutar de nuevo este script.\n")
        sys.exit(0)

    update_workflow()
