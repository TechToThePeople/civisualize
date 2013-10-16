<?php

require_once 'CRM/Core/Page.php';

class CRM_Civisualize_Page_Main extends CRM_Core_Page {
  function run() {
    $dummy = NULL;
print_r($_GET);
    $request = CRM_Utils_Request::retrieve( 'q', 'String',$dummy, true, NULL, 'GET');
    if (false !== strpos($request, '..')) {
      die ("SECURITY FATAL: the url can't contain '..'. Please report the issue on the forum at civicrm.org");
    }

    $request = split ('/',$request);
    $tplfile=_civicrm_api_get_camel_name($request[2]);

    $tpl = 'dataviz/'.$tplfile.'.tpl';
    $smarty= CRM_Core_Smarty::singleton( );
    $smarty->assign("options",array());
    if( !$smarty->template_exists($tpl) ){
      header("Status: 404 Not Found");
      die ("Can't find the requested template file templates/$tpl");
    }
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
    ->addStyleFile('eu.tttp.civisualize', 'js/dc/dc.css');

  require_once 'CRM/Core/Smarty/plugins/function.crmSQL.php';
   $smarty->register_function("crmSQL", "smarty_function_crmSQL");

    if  ( ! array_key_exists ( 'HTTP_X_REQUESTED_WITH', $_SERVER ) ||
      $_SERVER['HTTP_X_REQUESTED_WITH'] != "XMLHttpRequest"  )  {

        $smarty->assign( 'tplFile', $tpl );

        
        $config = CRM_Core_Config::singleton();
        $content = $smarty->fetch( 'CRM/common/'. strtolower($config->userFramework) .'.tpl' );

        if (!defined('CIVICRM_UF_HEAD') && $region = CRM_Core_Region::instance('html-header', FALSE)) {
          CRM_Utils_System::addHTMLHead($region->render(''));
        }
        CRM_Utils_System::appendTPLFile( $tpl, $content );

        return CRM_Utils_System::theme($content);

      } else {
        $content = "<!-- .tpl file embeded: $tpl -->\n";
        CRM_Utils_System::appendTPLFile( $tpl, $content );
        echo $content . $smarty->fetch ($tpl);
        CRM_Utils_System::civiExit( );
    }
  }
}
