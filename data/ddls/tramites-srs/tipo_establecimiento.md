```sql
-- Source Database: tramites-srs

create table tipo_establecimiento
(
    establet_id integer null, -- Assumed integer
    establet_tipo character varying null, -- Assumed varchar
    establet_descripcion character varying null, -- Assumed varchar
    form_id varchar null, -- Assumed varchar
    tramite_abreviado varchar null, -- Assumed varchar
    activo_cnr boolean null -- Assumed boolean or string
);
```
