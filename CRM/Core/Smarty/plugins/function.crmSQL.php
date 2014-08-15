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

    if(array_key_exists('set', $params)){
        if($values!=""){
            //echo "console.log('string')";
            $smarty->assign($params['set'], $values);
        }
    }

    return json_encode(array("is_error"=>$is_error, "error"=>$error, "values" => $values), JSON_NUMERIC_CHECK);
}
