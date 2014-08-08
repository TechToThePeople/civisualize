<?php
function smarty_function_crmTitle($params, &$smarty) { 
  if (array_key_exists('string', $params)) {
    CRM_Utils_System::setTitle($params['string']);
    return;
  }
}