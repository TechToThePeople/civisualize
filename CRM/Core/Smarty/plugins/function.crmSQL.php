<?php

function smarty_function_crmSQL($params, &$smarty) { 
  
  if (!array_key_exists('sql', $params) && !array_key_exists('file', $params) && !array_key_exists('json', $params)) { 
    $smarty->trigger_error("assign: missing 'sql', 'json' OR 'file' parameter"); 
    return "crmAPI: missing 'sql', 'json' or 'file' parameter"; 
  } 
  
  $parameters = array();

  if(array_key_exists('json', $params)){
    $json=json_decode(file_get_contents('queries/'.$params["json"].".json", true));//file_get_contents('queries/'.$params["json"].".json", true)
    $sql=$json->{"query"};
    foreach ($json->{"params"} as $key => $value) {
      $var=intval($key);
      $name=$value->{"name"};
      $type=$value->{"type"};
      if(array_key_exists($name, $params)){
        $parameters[$var] = array($params[$name],$type);
      }
    }
  }

  else if (array_key_exists('sql', $params)){
    $sql = $params["sql"];
  } 
  else {
    $sql=file_get_contents ('queries/'.$params["file"].".sql", true);
  }

  if(strpos(strtolower($sql), "delete ")!==false){
    $smarty->trigger_error("DELETE command not allowed");
    return "crmAPI: you can not delete using crmSQL";
  }
  else if(strpos(strtolower($sql), "drop ")!==false){
    $smarty->trigger_error("DROP command not allowed");
    return "crmAPI: you can not drop using crmSQL";
  }
  else if(strpos(strtolower($sql), "update ")!==false){
    $smarty->trigger_error("UPDATE command not allowed");
    return "crmAPI: you can not update using crmSQL";
  }
  else if(strpos(strtolower($sql), "grant ")!==false){
    $smarty->trigger_error("GRANT command not allowed");
    return "crmAPI: you can not grant privileges using crmSQL";
  }

  if (array_key_exists('debug', $params)) { 
    $smarty->trigger_error("sql:". $params["sql"]); 
  }

  //  CRM_Core_Error::setCallback(array('CRM_Utils_REST', 'fatal')); 
  $dao = CRM_Core_DAO::executeQuery($sql,$parameters);
  $values = array();
  while ($dao->fetch()) {
    $values[] = $dao->toArray();
  }       

  return json_encode(array("is_error"=>0, "values" => $values), JSON_NUMERIC_CHECK);
}
