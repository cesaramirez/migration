UPDATE expedient_base_registry_relation
SET relation_type = 'selected_option'
WHERE relation_type = 'selection_option'
  AND reference_name = 'srs_marca';
