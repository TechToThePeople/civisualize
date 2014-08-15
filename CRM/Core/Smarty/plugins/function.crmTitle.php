<?php
function smarty_function_crmTitle($params, &$smarty) { 
	if (array_key_exists('string', $params)) {
		CRM_Utils_System::setTitle($params['string']);
		return;
	}
	if (array_key_exists('array', $params)&&array_key_exists('field', $params)) {
		CRM_Utils_System::setTitle($params['array'][0][$params['field']]);
		return;
	}
}