<?php

function smarty_function_crmSQL($params, &$smarty) { 
  $is_error = 0;
  $error = "";
  $values = "";
  $sql="";

  if (!array_key_exists('sql', $params) && !array_key_exists('file', $params) && !array_key_exists('json', $params)) { 
    $smarty->trigger_error("assign: missing 'sql', 'json' OR 'file' parameter"); 
    $error = "crmAPI: missing 'sql', 'json' or 'file' parameter"; 
    $is_error = 1;
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

  else if(array_key_exists('sql', $params)){
    $sql = $params["sql"];
  } 
  else if(array_key_exists('file', $params)){
    $sql = file_get_contents('queries/'.$params["file"].".sql", true);
  }

  if(strpos(strtolower($sql), "delete ")!==false){
    $smarty->trigger_error("DELETE command not allowed");
    $error = "crmAPI: you can not delete using crmSQL";
    $is_error = 1;
  }

  else if(strpos(strtolower($sql), "drop ")!==false){
    $smarty->trigger_error("DROP command not allowed");
    $error = "crmAPI: you can not drop using crmSQL";
    $is_error = 1;
  }
  else if(strpos(strtolower($sql), "update ")!==false){
    $smarty->trigger_error("UPDATE command not allowed");
    $error = "crmAPI: you can not update using crmSQL";
    $is_error = 1;
  }
  else if(strpos(strtolower($sql), "grant ")!==false){
    $smarty->trigger_error("GRANT command not allowed");
    $error = "crmAPI: you can not grant privileges using crmSQL";
    $is_error = 1;
  }

  if (array_key_exists('debug', $params)) { 
    $smarty->trigger_error("sql:". $params["sql"]); 
  }

  //  CRM_Core_Error::setCallback(array('CRM_Utils_REST', 'fatal')); 

  try{
    if($is_error==0){
      $errorScope = CRM_Core_TemporaryErrorScope::useException();
      $dao = CRM_Core_DAO::executeQuery($sql,$parameters);
      $values = array();
      while ($dao->fetch()) {
        $values[] = $dao->toArray();
      }
    }
  }
  catch(Exception $e){
    $is_error=1;
    $error = "crmAPI: ".$e->getMessage();
    $values="";
  }

  return json_encode(array("is_error"=>$is_error, "error"=>$error, "values" => $values), JSON_NUMERIC_CHECK);
}
