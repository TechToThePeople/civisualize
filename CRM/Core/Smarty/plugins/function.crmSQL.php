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

    try{
	    if(array_key_exists('json', $params)){

		$json=json_decode(str_replace(array("\r\n","\r","\n")," ",file_get_contents('queries/'.$params["json"].".json", true)));
		$sql=$json->query;
                if (!$sql){
                   $smarty->trigger_error("assign: missing 'query' in the json file"); 
                   $error = "crmAPI: missing 'query' in the json"; 
                }
		foreach ($json->params as $key => $value) {
		    $var=intval($key);
		    $name=$value->name;
		    $type=$value->type;
		    if(array_key_exists($name, $params)){
			$parameters[$var] = array($params[$name],$type);
		    }
		}
	    }

	    elseif(array_key_exists('sql', $params)){
		$sql = $params["sql"];
	    }

	    elseif(array_key_exists('file', $params)){
		$filename =  'queries/'.$params["file"].".sql";
		$sql = file_get_contents($filename, true);
		if (!$sql)  throw new Exception ("missing filename or empty ".$filename);

	    }

	    $forbidden=array("delete ", "drop ","update ","grant ");
	    foreach ($forbidden as $check) {
		if(strpos(strtolower($sql), $check)!==false){
		    $smarty->trigger_error($check."command not allowed");
		    $error = "crmAPI: you can not ".$check."using crmSQL";
		    $is_error = 1;
		    break;
		}
	    }

      if (array_key_exists('debug', $params)) { 
          $smarty->trigger_error("sql:". $params["sql"]); 
      }

        if($is_error==0){
            $errorScope = CRM_Core_TemporaryErrorScope::useException();
            CRM_Core_DAO::executeQuery("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;");
            $dao = CRM_Core_DAO::executeQuery($sql,$parameters);
            $values = array();
            $keys= null;
            if (array_key_exists('sequential', $params)) { 
              while ($dao->fetch()) {
                if (!$keys) $keys= array_keys($dao->toArray());
                $values[] = array_values($dao->toArray());
              }
            } else {
              while ($dao->fetch()) {
                $values[] = $dao->toArray();
              }
              $keys= array_keys($values[0]);
            }
          }
    }
    catch(Exception $e){
        $is_error=1;
        $error = "crmAPI: ".$e->getMessage();
        $values="";
    }

    if(array_key_exists('set', $params)){
        if($values!=""){
            //echo "console.log('string')";
            $smarty->assign($params['set'], $values);
        }
    }

    if (array_key_exists('debug', $params)) {
      return json_encode(array("is_error"=>$is_error, "keys"=> $keys, "error"=>$error, "values" => $values,"sql" => trim(preg_replace('/\s+/', ' ', $sql))), JSON_NUMERIC_CHECK);
    }
    return json_encode(array("is_error"=>$is_error, "keys"=> $keys, "error"=>$error, "values" => $values), JSON_NUMERIC_CHECK);
}
