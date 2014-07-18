SELECT
	COUNT(*) as count,
	event.id, 
	event.title, 
	event.event_type_id as tid, 
	event.is_monetary as im,
	event.start_date as start_date, 
	event.end_date as end_date,
	DATE(participant.register_date) as register_date
FROM
	civicrm_event as event
	INNER JOIN 
	civicrm_participant as participant 
	ON event.id=participant.event_id
	JOIN 
	civicrm_contact as contact
	ON participant.contact_id = contact.id and contact.is_deleted=0
WHERE start_date IS NOT NULL AND end_date IS NOT NULL AND register_date IS NOT NULL
GROUP BY event.id, register_date;