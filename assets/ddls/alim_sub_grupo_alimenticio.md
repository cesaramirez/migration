``` SQL
create table alim_sub_grupo_alimenticio
(
    id                                     serial
        constraint pk_alim_sub_grupo_alimenticio
            primary key,
    nombre                                 varchar(300) not null,
    id_ctl_clasificacion_grupo_alimenticio integer      not null
        constraint ctl_clasificacion_grupo_alimenticio_sub_grupo_alimenticio_fk
            references ctl_clasificacion_grupo_alimenticio
            on update cascade on delete cascade,
    id_ctl_tipo_riesgo                     integer
        constraint ctl_tipo_riesgo_alim_sub_grupo_alimenticio_fk
            references ctl_tipo_riesgo
            on update cascade on delete cascade,
    nombre_completo                        varchar,
    precio_analisis                        real,
    precio_registro                        real,
    estado                                 boolean
);

comment on table alim_sub_grupo_alimenticio is 'Tabla que almacena los sub grupos alimenticios para un determinado grupo.';

comment on column alim_sub_grupo_alimenticio.id is 'Llave primaria de la tabla sub_grupo_alimenticio.';

comment on column alim_sub_grupo_alimenticio.nombre is 'CAmpo donde se almacena el nombre de los distintos sub_grupos alimenticios que puede tener un producto.';

comment on column alim_sub_grupo_alimenticio.id_ctl_clasificacion_grupo_alimenticio is 'Este campo es la llave primaria de la tabla ctl_clasificacion_grupo_alimenticio.';

comment on column alim_sub_grupo_alimenticio.id_ctl_tipo_riesgo is 'Este campo es la llave primaria de la tabla ctl_tipo_riesgo.';

comment on column alim_sub_grupo_alimenticio.nombre_completo is 'Es el nombre coimpleto, o descripcion del sub grupo. Agregada en consultoria';

comment on column alim_sub_grupo_alimenticio.precio_analisis is 'Se almacena el precio de los analisis para el sub grupo. Agregado en consultoria.';

comment on column alim_sub_grupo_alimenticio.precio_registro is 'Precio que tiene el registro en la unidad de alimentos y bebidas. Agregado en consultoria.';

comment on column alim_sub_grupo_alimenticio.estado is 'Este campo almacena el estado del sub_grupo_alimenticio';
```
