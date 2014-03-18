<?php

function civicrm_api3_tag_getstat ($params) {
  $sql = "SELECT count(*) as total, civicrm_tag.id, civicrm_tag.name, civicrm_tag.parent_id, description
          FROM civicrm_tag, civicrm_entity_tag
          WHERE civicrm_tag.id = civicrm_entity_tag.tag_id AND entity_table = 'civicrm_contact'
          GROUP BY civicrm_tag.id";
  return _civicrm_api3_basic_getsql ($params,$sql);
}

