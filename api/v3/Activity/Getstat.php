<?php
function civicrm_api3_activity_getstat ($params) {
  $sql="SELECT COUNT(id),DATE(register_date) as register from civicrm_participant group by DATE(register_date)";
  return _civicrm_api3_basic_getsql ($params,$sql);
}

