-- =============================================================================
-- PASO 1: EXPORTAR DE SISAM (ejecutar en conexión SISAM Local)
-- =============================================================================
-- Después de ejecutar, exportar el resultado como SQL/JSON desde TablePlus

SELECT
    p.id as original_id,
    TRIM(p.nombre) as nombre,
    CASE p.tipo_producto
        WHEN 1 THEN 'Nacional'
        WHEN 2 THEN 'Importado Unión Aduanera'
        WHEN 3 THEN 'Importado Otros Países'
        ELSE 'Desconocido'
    END as tipo_producto,
    NULLIF(TRIM(p.num_partida_arancelaria), '') as num_partida_arancelaria,
    TO_CHAR(p.fecha_emision_registro, 'DD/MM/YYYY') as fecha_emision_registro,
    TO_CHAR(p.fecha_vigencia_registro, 'DD/MM/YYYY') as fecha_vigencia_registro,
    NULLIF(TRIM(p.num_registro_sanitario), '') as num_registro_sanitario,
    UPPER(ep.nombre) as estado_producto,
    pais.nombre as pais,
    sg.nombre as subgrupo_alimenticio,
    cga.nombre as clasificacion_alimenticia,
    tr.nombre as riesgo,
    -- Campos de Certificado de Libre Venta
    clv.cod_clv as codigo_clv,
    pclv.nombre_prod_segun_clv as nombre_producto_clv,
    pais_clv.nombre as pais_procedencia_clv,
    -- Campos de Propietario del Registro Sanitario
    prop_aux.nombre as propietario_nombre,
    prop_aux.nit as propietario_nit,
    prop_aux.correo_electronico as propietario_correo,
    prop_aux.direccion as propietario_direccion,
    pais_prop.nombre as propietario_pais,
    CASE
        WHEN prop_aux.es_empresa = true THEN prop_aux.nombre
        ELSE NULL
    END as propietario_razon_social
FROM alim_producto p
LEFT JOIN ctl_estado_producto ep ON ep.id = p.id_ctl_estado_producto
LEFT JOIN ctl_pais pais ON pais.id = p.id_ctl_pais
LEFT JOIN alim_sub_grupo_alimenticio sg ON sg.id = p.id_sub_grupo_alimenticio
LEFT JOIN ctl_clasificacion_grupo_alimenticio cga ON cga.id = sg.id_ctl_clasificacion_grupo_alimenticio
LEFT JOIN ctl_tipo_riesgo tr ON tr.id = sg.id_ctl_tipo_riesgo
-- JOINs para CLV
LEFT JOIN alim_producto_certificado_libre_venta pclv ON pclv.id_alim_producto = p.id
LEFT JOIN alim_certificado_libre_venta clv ON clv.id = pclv.id_alim_certificado_libre_venta
LEFT JOIN ctl_pais pais_clv ON pais_clv.id = clv.id_ctl_pais
-- JOINs para Propietario (id_ctl_funcion_empresa_persona = 4 = Propietario de registro sanitario)
LEFT JOIN alim_empresa_persona_aux_funcion_producto prop_fp ON prop_fp.id_alim_producto = p.id AND prop_fp.id_ctl_funcion_empresa_persona = 4
LEFT JOIN alim_empresa_persona_aux prop_aux ON prop_aux.id = prop_fp.id_alim_empresa_persona_aux
LEFT JOIN ctl_pais pais_prop ON pais_prop.id = prop_aux.id_ctl_pais
WHERE p.estado_registro = 1
  AND p.fecha_emision_registro IS NOT NULL
  AND p.fecha_vigencia_registro IS NOT NULL
  AND sg.nombre IS NOT NULL AND TRIM(sg.nombre) != '' AND sg.nombre NOT LIKE '%MIGRADO%'
  AND cga.nombre IS NOT NULL AND TRIM(cga.nombre) != ''
  AND tr.nombre IS NOT NULL AND TRIM(tr.nombre) != ''
ORDER BY p.id
LIMIT 25000;

-- =============================================================================
-- NOTA: Los campos de archivos (ruta_archivo_*) se manejarán en una fase posterior
-- =============================================================================
-- INSTRUCCIONES:
-- 1. Ejecutar este query en SISAM Local
-- 2. En TablePlus: Click derecho en el resultado → Export → SQL (Insert)
-- 3. Guardar como: migration_source_data.sql
-- 4. Editar el archivo: Cambiar el nombre de tabla a "migration_alim_producto_temp"
-- 5. Ir a la conexión SDT DEV
-- 6. Ejecutar 01_create_temp_table.sql
-- 7. Ejecutar el archivo exportado (migration_source_data.sql)
-- 8. Ejecutar 02_migrate_from_temp.sql
-- =============================================================================
