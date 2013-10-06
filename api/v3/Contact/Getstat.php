<?

function civicrm_api3_contact_getstat ($params) {
 // mostly copy pasted from contact_get and the functions called by it
  $options = array();
  _civicrm_api3_contact_get_supportanomalies($params, $options);

  $contacts = _civicrm_api3_get_using_query_object('contact', $params, $options);
  $options = _civicrm_api3_get_options_from_params($params, TRUE);

  $inputParams = CRM_Utils_Array::value('input_params', $options, array());
  $returnProperties = CRM_Utils_Array::value('return', $options, array());

  if(!empty($params['check_permissions'])){
    // we will filter query object against getfields
    $fields = civicrm_api("contact", 'getfields', array('version' => 3, 'action' => 'get'));
    // we need to add this in as earlier in this function 'id' was unset in favour of $entity_id
    $fields['values'][$entity . '_id'] = array();
    $varsToFilter = array('returnProperties', 'inputParams');
    foreach ($varsToFilter as $varToFilter){
      if(!is_array($$varToFilter)){
        continue;
      }
      //I was going to throw an exception rather than silently filter out - but
      //would need to diff out of exceptions arr other keys like 'options', 'return', 'api. etcetc
      //so we are silently ignoring parts of their request
      //$exceptionsArr = array_diff(array_keys($$varToFilter), array_keys($fields['values']));
      $$varToFilter = array_intersect_key($$varToFilter, $fields['values']);
    }
  }
//  $options = array_merge($options,$additional_options);
  $sort             = CRM_Utils_Array::value('sort', $options, NULL);
  $offset             = CRM_Utils_Array::value('offset', $options, NULL);
  $limit             = CRM_Utils_Array::value('limit', $options, NULL);
  $smartGroupCache  = CRM_Utils_Array::value('smartGroupCache', $params);

  $newParams = CRM_Contact_BAO_Query::convertFormValues($inputParams);
  $skipPermissions = CRM_Utils_Array::value('check_permissions', $params)? 0 :1;

  $query = new CRM_Contact_BAO_Query(
    $params, $returnProperties,
    NULL, TRUE, FALSE, 1,
    $skipPermissions,
    TRUE, $smartGroupCache
  );

  //this should add a check for view deleted if permissions are enabled
  if ($skipPermissions){
    $query->_skipDeleteClause = TRUE;
  }
  $query->generatePermissionClause(FALSE, $count);
  list($select, $from, $where, $having) = $query->query($count);

  $options = $query->_options;
  if(!empty($query->_permissionWhereClause)){
    if (empty($where)) {
      $where = "WHERE $query->_permissionWhereClause";
    } else {
      $where = "$where AND $query->_permissionWhereClause";
    }
  }

  $sql = "$select $from $where $having";

  if (!empty($returnProperties)) {
    $extra = array();
    $sql = "SELECT count(*) AS total,". substr ($sql, 34,10000); //replace select contact_id, by select count(*)
    $sql .= " GROUP BY ". implode (",",array_keys($returnProperties)) ;
  } else {
    $sql = "SELECT count(*) AS total  $from $where $having";
    $extra = array ("tip"=>"if you need to group by a field, use the return param, eg return=contact_type,gender",
                    "warning"=> "use getcount, getstat without param might be blocked in the future"); 
  }
  $dao = CRM_Core_DAO::executeQuery($sql);
  $values = array();
  while ($dao->fetch()) {
    $values[] = $dao->toArray();
  }
  
  return civicrm_api3_create_success($values, $params, $entity = "contact", "getstat", $dao,$extra);
}
