

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