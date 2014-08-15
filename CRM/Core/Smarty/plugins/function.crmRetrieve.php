<?php

function smarty_function_crmRetrieve($params, &$smarty) { 
	if (!array_key_exists('var', $params) || !array_key_exists('type', $params) || !array_key_exists('name', $params)) { 
		$smarty->trigger_error("crmRetrieve: missing car, name or type"); 
		return;
	}
	$value = CRM_Utils_Request::retrieve($params['name'], $params['type']);
	if($value===null){
		$smarty->trigger_error("crmRetrive: Cannot find a variable with matching name and type");
	}
	$smarty->assign($params['var'], $value);
}