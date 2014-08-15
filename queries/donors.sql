SELECT 
	contact_id, contact.display_name, SUM(total_amount) as total_amount, YEAR(receive_date) as year, birth_date, contact_type, gender_id
FROM 
	civicrm_contribution as contrib
	INNER JOIN civicrm_contact as contact
	ON
		contrib.contact_id = contact.id AND contact.is_deleted=0
WHERE
	total_amount>0
GROUP BY
	YEAR(receive_date), contact_id
ORDER BY
	YEAR(receive_date);