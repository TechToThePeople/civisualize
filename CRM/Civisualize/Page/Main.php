<?php

require_once 'CRM/Core/Page.php';

class CRM_Civisualize_Page_Main extends CRM_Core_Page {

  function getTemplateFileName () {
    $request = CRM_Utils_System::currentPath();
    if (false !== strpos($request, '..')) {
      die ("SECURITY FATAL: the url can't contain '..'. Please report the issue on the forum at civicrm.org");
    }

    $request = split ('/',$request);
    $tplfile = NULL;
    $smarty= CRM_Core_Smarty::singleton( );
    $smarty->assign("options",array());
    if (CRM_Utils_Array::value(2, $request)) {
      $tplfile = _civicrm_api_get_camel_name($request[2]);
      $tplfile = explode('?', $tplfile);
      $tpl = 'dataviz/'.$tplfile[0].'.tpl';
    }
    if (CRM_Utils_Array::value(3, $request)) {
      $r3 = _civicrm_api_get_camel_name($request[3]);
      $smarty->assign("id",$r3);
    }
    if (!$tplfile) {
      $tpl = "CRM/Civizualise/Page/Main.tpl";
    }
    if( !$smarty->template_exists($tpl) ){
      header("Status: 404 Not Found");
      die ("Can't find the requested template file templates/$tpl");
    }
    return $tpl;
  }

  function run() {
    $smarty= CRM_Core_Smarty::singleton( );

    $dummy = NULL;
    if (array_key_exists('id',$_GET)) {// special treatmenent, because it's often used
      $smarty->assign ('id',(int)$_GET['id']);// an id is always positive
    }
    $pos = strpos (implode (array_keys ($_GET)),'<') ;

    if ($pos !== false) {
      die ("SECURITY FATAL: one of the param names contains &lt;");
    }
    $param = array_map( 'htmlentities' , $_GET);
//TODO: sql escape the params too
    unset($param['q']);
    $smarty->assign_by_ref("request", $param);

   CRM_Core_Resources::singleton()
    ->addScriptFile('eu.tttp.civisualize', 'js/d3.v3.js', 110, 'html-header', FALSE)
    ->addScriptFile('eu.tttp.civisualize', 'js/dc/dc.js', 110, 'html-header', FALSE)
    ->addScriptFile('eu.tttp.civisualize', 'js/dc/crossfilter.js', 110, 'html-header', FALSE)
    ->addStyleFile('eu.tttp.civisualize', 'js/dc/dc.css')
    ->addStyleFile('eu.tttp.civisualize', 'css/style.css');

    require_once 'CRM/Core/Smarty/plugins/function.crmSQL.php';
    $smarty->register_function("crmSQL", "smarty_function_crmSQL");

    require_once 'CRM/Core/Smarty/plugins/function.crmRetrieve.php';
    $smarty->register_function("crmRetrieve", "smarty_function_crmRetrieve");

    require_once 'CRM/Core/Smarty/plugins/function.crmTitle.php';
    $smarty->register_function("crmTitle", "smarty_function_crmTitle");

    return parent::run();
  }
}
