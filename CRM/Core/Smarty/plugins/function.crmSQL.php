<?

function smarty_function_crmSQL($params, &$smarty) { 
  
  if (!array_key_exists('sql', $params)) { 
    $smarty->trigger_error("assign: missing 'sql' parameter"); 
    return "crmAPI: missing 'sql' parameter"; 
  } 
  $sql = $params["sql"]; // TODO: remove "DELETE "

  if (array_key_exists('debug', $params)) { 
    $smarty->trigger_error("sql:". $params["sql"]); 
    return "crmAPI: missing 'sql' parameter"; 
  }

//  CRM_Core_Error::setCallback(array('CRM_Utils_REST', 'fatal')); 
  $dao = CRM_Core_DAO::executeQuery($sql);
  $values = array();
  while ($dao->fetch()) {
    $values[] = $dao->toArray();
  }

//TODO run the sql
//  CRM_Core_Error::setCallback(); 

  return json_encode (array("is_error"=>0, "values" => $values));

  if (!array_key_exists('var', $params)) { 
    return json_encode($result); 
  } 
  $smarty->assign($params["var"], $result);
}
