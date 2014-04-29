<?php
function civicrm_api3_group_contact_getstat ($params) {
  $sql = "SELECT count(*) as total,civicrm_group.id, civicrm_group.name 
          FROM civicrm_group_contact, civicrm_group 
          WHERE civicrm_group_contact.group_id = civicrm_group.id
          GROUP BY civicrm_group.id";
  return _civicrm_api3_basic_getsql ($params,$sql);
}
