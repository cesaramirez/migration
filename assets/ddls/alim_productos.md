# alim_producto - Estrategia de Migración

## Contexto de Negocio (Trámite 81)

| Aspecto | Detalle |
|---------|---------|
| **Objetivo** | Registro sanitario de alimentos y bebidas |
| **Alcance** | Solicitudes de registro ingresadas por regulados |
| **Regulador** | Superintendencia de Regulación Sanitaria (SRS) |
| **Unidad** | Unidad de Alimentos y Bebidas |

> Esta tabla almacena los productos que solicitan registro sanitario ante la SRS.

---

## Destino
- **Entidad**: `expedient_base_entities` → "Producto Alimenticio"
- **Campos**: `expedient_base_entity_fields`
- **Registros**: `expedient_base_registries`
- **Valores**: `expedient_base_registry_fields`

## Decisiones Generales
| Aspecto | Decisión |
|---------|----------|
| **unique_code** | Generar con `UPPER(encode(gen_random_bytes(6), 'hex'))` (12 chars hex) |
| **Catálogos** | Desnormalizar como TEXT |
| **Archivos** | Campo tipo FILE → insertar en tabla `media` (polimórfica) |
| **Relaciones** | No aplica para esta primera prueba |
| **Volumen** | ~90,000 registros → usar batch de 5,000 |
| **Herramienta** | Scripts SQL directos |

## Catálogos a Desnormalizar

### `ctl_estado_producto`
| ID | Valor |
|----|-------|
| 1 | Vigente |
| 2 | Bloqueado |
| 3 | Vencido |

### `ctl_pais`
- Catálogo de países del mundo (~200 registros)
- Campos: `nombre`, `dominio2`, `dominio3`, `isonumero`
- Flag: `union_aduanera` (para reconocimiento de CLV)

### `alim_sub_grupo_alimenticio`
- Sub-grupos alimenticios con clasificación
- Campo a usar: `nombre`

## Estrategia de Archivos (tabla `media`)

Los campos de archivo se mapean a `expedient_base_entity_fields` con `field_type: 'FILE'`.
Al migrar, se crea un registro en `media` con:

| Campo | Valor |
|-------|-------|
| `model_type` | `expedient_base_registry_fields` |
| `model_id` | UUID del field que contiene el archivo |
| `collection_name` | `migration` |
| `file_name` | Extraer del path original |
| `disk` | `gcs` |

---

## Mapeo de Campos

| # | Campo Origen | ¿Migrar? | Destino / Notas |
|---|--------------|----------|-----------------|
| 1 | `id` | ⚙️ | Guardar en `metadata.original_id` |
| 2 | `nombre` | ✅ | Campo: "Nombre del Producto" (TEXT) |
| 3 | `tipo_producto` | ✅ | Campo: "Tipo de Producto" (TEXT) - Desnormalizar enum |
| 4 | `num_partida_arancelaria` | ✅ | Campo: "Partida Arancelaria" (TEXT) |
| 5 | `ruta_archivo_ingredientes` | ✅ | Campo: "Archivo Ingredientes" (FILE) → `media` |
| 6 | `fecha_emision_registro` | ✅ | Campo: "Fecha de Emisión del Registro" (TEXT) |
| 7 | `fecha_vigencia_registro` | ✅ | Campo: "Fecha de Vigencia del Registro" (TEXT) |
| 8 | `num_autorizacion_reconocimiento` | ✅ | Campo: "Autorización de Reconocimiento" (TEXT) |
| 9 | `num_registro_sanitario` | ✅ | Campo: "Registro Sanitario" (TEXT) |
| 10 | `num_certificacion` | ❌ | Omitir |
| 11 | `estado_registro` | ❌ | Omitir |
| 12 | `id_ctl_estado_producto` | ✅ | Campo: "Estado del Producto" (TEXT) - Desnormalizar nombre de `ctl_estado_producto` |
| 13 | `id_ctl_pais` | ✅ | Campo: "País" (TEXT) - Desnormalizar nombre de `ctl_pais` |
| 14 | `id_sub_grupo_alimenticio` | ✅ | Campo: "Sub Grupo Alimenticio" (TEXT) - Desnormalizar nombre de `alim_sub_grupo_alimenticio` |
| 15 | `detalle_reconocimiento` | ❌ | Omitir |
| 16 | `marca_temp` | ❌ | Omitir |
| 17 | `id_rm` | ❌ | Omitir |
| 18 | `ruta_archivo_vineta_reconocimiento` | ✅ | Campo: "Viñeta Reconocimiento" (FILE) → `media` |
| 19 | `tipo_de_laboratorio` | ❌ | Omitir |
| 20 | `registro_centroamericano` | ❌ | Omitir |
| 21 | `pais_centroamericano_de_registro` | ❌ | Omitir |
| 22 | `fecha_vigencia_registro_segun_resolucion` | ❌ | Omitir |
| 23 | `ruta_resolucion_registro_centroamericano` | ✅ | Campo: "Resolución Registro CA" (FILE) → `media` |
| 24 | `ruta_declaracion_jurada` | ✅ | Campo: "Declaración Jurada" (FILE) → `media` |

---

## Estrategia de Migración (SQL)

### Paso 1: Crear Entidad Base

```sql
INSERT INTO expedient_base_entities (name, description, status, version, is_current_version)
VALUES ('Producto Alimenticio', 'Productos alimenticios migrados del sistema SRS', 'active', 1, true)
RETURNING id;
-- Guardar este ID como :entity_id
```

### Paso 2: Crear Campos de la Entidad

```sql
INSERT INTO expedient_base_entity_fields (expedient_base_entity_id, name, field_type, is_required, "order") VALUES
(:entity_id, 'Nombre del Producto', 'TEXT', true, 1),
(:entity_id, 'Tipo de Producto', 'TEXT', true, 2),
(:entity_id, 'Partida Arancelaria', 'TEXT', false, 3),
(:entity_id, 'Fecha de Emisión del Registro', 'DATE', false, 4),
(:entity_id, 'Fecha de Vigencia del Registro', 'DATE', false, 5),
(:entity_id, 'Autorización de Reconocimiento', 'TEXT', false, 6),
(:entity_id, 'Registro Sanitario', 'TEXT', false, 7),
(:entity_id, 'Estado del Producto', 'TEXT', false, 8),
(:entity_id, 'País', 'TEXT', true, 9),
(:entity_id, 'Sub Grupo Alimenticio', 'TEXT', false, 10),
(:entity_id, 'Archivo Ingredientes', 'FILE', false, 11),
(:entity_id, 'Viñeta Reconocimiento', 'FILE', false, 12),
(:entity_id, 'Resolución Registro CA', 'FILE', false, 13),
(:entity_id, 'Declaración Jurada', 'FILE', false, 14);
```

### Paso 3: Función para Generar unique_code

```sql
-- Equivalente a PHP: strtoupper(bin2hex(random_bytes(6)))
CREATE OR REPLACE FUNCTION generate_unique_code()
RETURNS VARCHAR(12) AS $$
BEGIN
    RETURN UPPER(encode(gen_random_bytes(6), 'hex'));
END;
$$ LANGUAGE plpgsql;
```

### Paso 4: Migrar Registros (Productos)

```sql
INSERT INTO expedient_base_registries (name, metadata, expedient_base_entity_id, unique_code)
SELECT
    p.nombre,
    jsonb_build_object('original_id', p.id, 'source', 'alim_producto'),
    :entity_id,
    generate_unique_code()
FROM alim_producto p
WHERE p.estado_registro = 1;
```

### Paso 5: Migrar Valores de Campos

```sql
-- Para cada campo TEXT (ejemplo: Nombre del Producto)
INSERT INTO expedient_base_registry_fields (expedient_base_registry_id, expedient_base_entity_field_id, value)
SELECT
    r.id,
    (SELECT id FROM expedient_base_entity_fields WHERE name = 'Nombre del Producto' AND expedient_base_entity_id = :entity_id),
    p.nombre
FROM alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
WHERE r.expedient_base_entity_id = :entity_id;

-- Para campos desnormalizados (ejemplo: País)
INSERT INTO expedient_base_registry_fields (expedient_base_registry_id, expedient_base_entity_field_id, value)
SELECT
    r.id,
    (SELECT id FROM expedient_base_entity_fields WHERE name = 'País' AND expedient_base_entity_id = :entity_id),
    pais.nombre
FROM alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN ctl_pais pais ON pais.id = p.id_ctl_pais
WHERE r.expedient_base_entity_id = :entity_id;

-- Para campos de tipo_producto (desnormalizar enum)
INSERT INTO expedient_base_registry_fields (expedient_base_registry_id, expedient_base_entity_field_id, value)
SELECT
    r.id,
    (SELECT id FROM expedient_base_entity_fields WHERE name = 'Tipo de Producto' AND expedient_base_entity_id = :entity_id),
    CASE p.tipo_producto
        WHEN 1 THEN 'Nacional'
        WHEN 2 THEN 'Importado Unión Aduanera'
        WHEN 3 THEN 'Importado Otros Países'
    END
FROM alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
WHERE r.expedient_base_entity_id = :entity_id;
```

### Paso 6: Migrar Archivos a `media`

```sql
-- Para cada campo FILE (ejemplo: Archivo Ingredientes)
INSERT INTO media (uuid, model_type, model_id, collection_name, name, file_name, disk, size)
SELECT
    gen_random_uuid(),
    'expedient_base_registry_fields',
    rf.id,
    'migration',
    'archivo-ingredientes',
    SUBSTRING(p.ruta_archivo_ingredientes FROM '[^/]+$'),  -- Extraer nombre del archivo
    'gcs',
    0
FROM alim_producto p
JOIN expedient_base_registries r ON (r.metadata->>'original_id')::int = p.id
JOIN expedient_base_registry_fields rf ON rf.expedient_base_registry_id = r.id
    AND rf.expedient_base_entity_field_id = (
        SELECT id FROM expedient_base_entity_fields
        WHERE name = 'Archivo Ingredientes' AND expedient_base_entity_id = :entity_id
    )
WHERE p.ruta_archivo_ingredientes IS NOT NULL;
```

---

## DDL Original


```SQL
create table alim_producto
(
    id                                       serial
        constraint pk_alim_producto
            primary key,
    nombre                                   varchar(600)           not null,
    tipo_producto                            integer                not null,
    num_partida_arancelaria                  char(14),
    ruta_archivo_ingredientes                varchar(250),
    fecha_emision_registro                   date,
    fecha_vigencia_registro                  date,
    num_autorizacion_reconocimiento          varchar,
    num_registro_sanitario                   varchar(15),
    num_certificacion                        varchar,
    estado_registro                          integer                not null,
    id_ctl_estado_producto                   integer
        constraint ctl_estado_producto_producto_fk
            references ctl_estado_producto
            on update cascade on delete cascade,
    id_ctl_pais                              integer                not null
        constraint ctl_pais_alim_producto_fk
            references ctl_pais
            on update cascade on delete cascade,
    id_sub_grupo_alimenticio                 integer
        constraint sub_grupo_alimenticio_producto_fk
            references alim_sub_grupo_alimenticio
            on update cascade on delete cascade,
    detalle_reconocimiento                   json,
    marca_temp                               varchar,
    id_rm                                    integer,
    ruta_archivo_vineta_reconocimiento       varchar(300),
    tipo_de_laboratorio                      integer      default 1 not null,
    registro_centroamericano                 varchar(20)  default NULL::character varying,
    pais_centroamericano_de_registro         integer,
    fecha_vigencia_registro_segun_resolucion date,
    ruta_resolucion_registro_centroamericano varchar(255) default NULL::character varying,
    ruta_declaracion_jurada                  varchar(255) default NULL::character varying
);

comment on table alim_producto is 'Esta tabla contiene la informacion de un producto nacional o importado.';

comment on column alim_producto.id is 'Este campo es la llave primaria de la tabla producto.';

comment on column alim_producto.nombre is 'Este campo contiene el nombre de los productos tanto nacionales como importados.';

comment on column alim_producto.tipo_producto is 'Este campo indica si el producto es nacional, importado de la union aduanera o imprtado de otros paises.
1: Nacional
2: Importado de Union Aduanera
3: Importado de otros paises';

comment on column alim_producto.num_partida_arancelaria is 'Este campo almacena el numero de partida arancelaria de un producto importado.';

comment on column alim_producto.ruta_archivo_ingredientes is 'Este campo almacena la ruta de acceso del archivo que contiene los ingredientes de un producto.';

comment on column alim_producto.fecha_emision_registro is 'Este campo contiene la fecha de emision del registro del producto.';

comment on column alim_producto.fecha_vigencia_registro is 'Este campo contiene la fecha de vigencia del registro del producto.';

comment on column alim_producto.num_autorizacion_reconocimiento is 'Campo donde se almacena el numero de autorizacion del producto de  la union aduanera, luego de que se ha avalado el reconocimiento de este.';

comment on column alim_producto.num_registro_sanitario is 'Este campo contiene el numero de registro sanitario';

comment on column alim_producto.num_certificacion is 'Este campo contiene el numero de certificacion del producto.';

comment on column alim_producto.estado_registro is 'Este campo indica el estado de un registro especifico de la tabla producto. 1=Existe en la base y 2= Borardo Logico de la base.';

comment on column alim_producto.id_ctl_estado_producto is 'Este campo es la llave primaria de la tabla ctl_estado_producto.';

comment on column alim_producto.id_ctl_pais is 'Este campo es la llave primaria de la tabla ctl_pais. Se guarda el pais donde se fabrico el producto.';

comment on column alim_producto.id_sub_grupo_alimenticio is 'Campo que es la llave primaria de la tabla sub_grupo_alimenticio.';

comment on column alim_producto.detalle_reconocimiento is 'Este campo almacena toda la información en un arreglo obtenida de un reconocimiento';

comment on column alim_producto.ruta_archivo_vineta_reconocimiento is 'Este campo almacena la ruta de la viñeta del reconocimiento';
```
