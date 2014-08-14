SELECT 
	contact_id, SUM(total_amount) as total_amount, YEAR(receive_date) as year
FROM 
	civicrm_contribution
GROUP BY
	YEAR(receive_date), contact_id
ORDER BY
	YEAR(receive_date);