SELECT COUNT(*) as count, contact_type as type, DATE(modified_date) as modified_date from civicrm_contact as contact where modified_date is not null group by DATE(modified_date), contact_type;
