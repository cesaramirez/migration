``` SQL
create table alim_empresa
(
    id                             serial
        constraint pk_alim_empresa
            primary key,
    nombre_comercial               varchar(156) not null,
    razon_social                   varchar(100) not null,
    direccion                      varchar(150),
    correo_electronico             varchar(50),
    nit                            varchar(14),
    iva                            varchar(7),
    estado_empresa                 varchar      not null,
    ruta_archivo_iva               varchar(250),
    ruta_escritura_publica         varchar(250),
    ruta_registro_comercio         varchar(250),
    ruta_certificacion_planta_mag  varchar(250),
    ruta_archivo_nit               varchar(250),
    id_ctl_tamanio_empresa         integer      not null
        constraint ctl_tamanio_empresa_alim_empresa_fk
            references ctl_tamanio_empresa
            on update cascade on delete cascade,
    id_ctl_giro_empresa            integer      not null
        constraint ctl_giro_empresa_alim_empresa_fk
            references ctl_giro_empresa
            on update cascade on delete cascade,
    id_ctl_municipio               integer
        constraint ctl_municipio_alim_empresa_fk
            references ctl_municipio
            on update cascade on delete cascade,
    id_ctl_pais                    integer      not null
        constraint ctl_pais_alim_empresa_fk
            references ctl_pais
            on update cascade on delete cascade,
    sin_nit                        boolean default false,
    importa_lac                    boolean default false,
    fecha_registro                 timestamp,
    ruta_archivo_permiso_ambiental varchar(250),
    codigo_validacion              varchar
);

comment on table alim_empresa is 'Tabla que almacena las empresas que estan involucradas con el registro sanitario de productos de alimentos en el país';

comment on column alim_empresa.id is 'Este campo es la llave primaria de la tabla empresa.';

comment on column alim_empresa.nombre_comercial is 'Campo donde se almacena el nombre comercial con el cuale esta registrada la empresa.
Ejemplo: Super Selectos es el nombre comercial de Grupo calleja s.a de c.v.';

comment on column alim_empresa.razon_social is 'Campo donde se guarda la razon social que posee una determinada empresa.
Ejemplo: Grupo Calleja S.A de C.V';

comment on column alim_empresa.direccion is 'Campo donde se almacena la direccion de una empresa o persona natural.';

comment on column alim_empresa.correo_electronico is 'Campo donde se almacena el correo electronico de una empresa.';

comment on column alim_empresa.nit is 'Numero de Identifiacion Tributaria que emite el Ministerio de Hacienda.';

comment on column alim_empresa.iva is 'Numero de Registro de Contribuyente que emite el Ministerio de Hacienda, comunmente conocido como IVA. Este numero es diferente al numero de registro de comercio.';

comment on column alim_empresa.estado_empresa is 'Campo que nos indica el estado una determinada empresa: 1=Activa, 2: Inactiva';

comment on column alim_empresa.ruta_archivo_iva is 'Campo donde se almacena la ruta donde se almacena la copia del documento de iva.';

comment on column alim_empresa.ruta_escritura_publica is 'En este campo se almacena la ruta de acceso hacia el archivo escaneado que contiene la escritura publica de constitucion de una empresa.';

comment on column alim_empresa.ruta_registro_comercio is 'Este campo almacena la ruta de acceso del archivo que contiene el registro de comercio de una empresa.';

comment on column alim_empresa.ruta_certificacion_planta_mag is 'Campo donde se almacena la certificacion o autorizacion de parte del ministerio de agricultura.';

comment on column alim_empresa.ruta_archivo_nit is 'Ruta donde se guarda  la copia notariada del NIT.';

comment on column alim_empresa.id_ctl_tamanio_empresa is 'Campo que es la llave primaria de la tabla ctl_tamanio_empresa.';

comment on column alim_empresa.id_ctl_giro_empresa is 'Campo donde que representa la llave primaria de la tabla ctl_giro_empresa.';

comment on column alim_empresa.id_ctl_municipio is 'Este campo es la llave primaria de la tabla ctl_municipio.';

comment on column alim_empresa.id_ctl_pais is 'Este campo es la llave primaria de la tabla ctl_pais.';

comment on column alim_empresa.sin_nit is 'Campo que indica si el NIT de la empresa es real o es generado, si tiene false, indicia que el NIT es real, caso contrario es generado por el sistema';

comment on column alim_empresa.importa_lac is 'Campo que nos  indica si la empresa importa productos lacteos';

comment on column alim_empresa.fecha_registro is 'Fecha y hora de registro de la empresa';

comment on column alim_empresa.codigo_validacion is 'codigo de validacion por correo';
```