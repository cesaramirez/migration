``` SQL
create table alim_persona
(
    id                                    serial
        constraint fk_persona
            primary key,
    nombre                                varchar(100) not null,
    apellido                              varchar(100) not null,
    dui                                   varchar(9),
    iva                                   varchar(7),
    nit                                   varchar(14),
    carne_residente                       varchar(15),
    estado_persona                        integer      not null,
    direccion                             varchar(300),
    correo_electronico                    varchar      not null,
    ruta_archivo_dui                      varchar(250),
    ruta_archivo_nit                      varchar(250),
    ruta_archivo_iva                      varchar(250),
    ruta_certificacion_planta_mag         varchar(250),
    ruta_archivo_carne_residente          varchar(250),
    id_ctl_pais                           integer      not null
        constraint ctl_pais_alim_persona_fk
            references ctl_pais
            on update cascade on delete cascade,
    id_ctl_municipio                      integer
        constraint ctl_municipio_alim_persona_fk
            references ctl_municipio
            on update cascade on delete cascade,
    importa_lac                           boolean,
    tipo_persona_tramitador               integer,
    ruta_archivo_declaracion_jurada       varchar(250),
    fecha_registro                        timestamp,
    fecha_emision_documento_identidad     date,
    fecha_vencimiento_documento_identidad date
);

comment on table alim_persona is 'Tabla en la que se almacena los datos generales de una persona, la cual puede ser: Persona Natural, Tramitador, Empleado.';

comment on column alim_persona.id is 'Llave primaria del la tabla alim_empresa.';

comment on column alim_persona.nombre is 'Campo en el cual se almacena el nombre de la persona.';

comment on column alim_persona.apellido is 'Campo donde se almacena el apellido de la persona.';

comment on column alim_persona.dui is 'Campo donde se almacena el numero de documento unico de identidad de la persona.';

comment on column alim_persona.iva is 'Se guarda el Numero de Registro Tributario (IVA) de la persona natural.';

comment on column alim_persona.nit is 'En este campo se almacena el Número de Identificación Tributaria de la Persona.';

comment on column alim_persona.carne_residente is 'Si es un representante extranjero debe poseer carne de residente.';

comment on column alim_persona.estado_persona is 'Campo que nos indica el estado una determinada persona: 1=Activa, 2: Inactiva';

comment on column alim_persona.direccion is 'Se guarda la direccion de residencia de la persona.';

comment on column alim_persona.correo_electronico is 'Campo donde se almacena el correo electronico de una persona.';

comment on column alim_persona.ruta_archivo_dui is 'ruta donde se almacena la copia del documento unico de identidad (DUI).';

comment on column alim_persona.ruta_archivo_nit is 'Campo donde se almacena la copia del documento del Número de Identificación Tributaria(NIT).';

comment on column alim_persona.ruta_archivo_iva is 'Se aguarda la ruta en la que se almacena la copia del ducumento del IVA.';

comment on column alim_persona.ruta_certificacion_planta_mag is 'Campo donde se almacena la certificacion o autorizacion de parte del ministerio de agricultura.';

comment on column alim_persona.ruta_archivo_carne_residente is 'Este campo almacena la ruta de acceso del archivo que contiene el carne de residente de un tramitador.';

comment on column alim_persona.id_ctl_pais is 'Este campo es la llave primaria de la tabla ctl_pais.';

comment on column alim_persona.id_ctl_municipio is 'Este campo es la llave primaria de la tabla ctl_municipio.';

comment on column alim_persona.importa_lac is 'Nos indica si una persona natural importa lácteos desde la union aduanera.';

comment on column alim_persona.tipo_persona_tramitador is 'Campo utilizado para identificar el tipo de persona con relacion a tramitadores: 1-Solo es persona natural, 2- Solo es tramitador, 3- Es persona natural y tramitador a la vez';

comment on column alim_persona.ruta_archivo_declaracion_jurada is 'Este campo almacena la ruta de acceso del archivo que contiene la declaración jurada';

comment on column alim_persona.fecha_registro is 'Fecha y hora de registro de la persona';

comment on column alim_persona.fecha_emision_documento_identidad is 'fecha de emisión del documento de identidad presentado (DUI, pasaporte)';

comment on column alim_persona.fecha_vencimiento_documento_identidad is 'Fecha de vencimiento de documento de identidad presentado (Dui, pasaporte)';
```