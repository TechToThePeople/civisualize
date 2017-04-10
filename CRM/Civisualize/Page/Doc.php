<?php

class CRM_Civisualize_Page_Doc extends CRM_Core_Page {

  public function run() {
   CRM_Core_Resources::singleton()
    ->addScriptFile('eu.tttp.civisualize', 'js/marked.min.js', 110, 'html-header', FALSE);

    $request = CRM_Utils_System::currentPath();
    if (false !== strpos($request, '..')) {
      die ("SECURITY FATAL: the url can't contain '..'. Please report the issue on the forum at civicrm.org");
    }

    $request = explode('/',$request);
//print_r($request);
    $tplfile = NULL;
    $smarty= CRM_Core_Smarty::singleton( );
    $smarty->assign("options",array());
    if (CRM_Utils_Array::value(2, $request)) {
      $tplfile = _civicrm_api_get_camel_name($request[2]);
      $tplfile = explode('?', $tplfile);
      $mdfile = 'doc/'.$tplfile[0].'.md';
      $md = file_get_contents($mdfile, FILE_USE_INCLUDE_PATH);
      if (!$md) $md= "$mdfile not found";
      $smarty->assign("mdfile",$md);
      $smarty->assign("md",$md);

      
    }
    if (CRM_Utils_Array::value(3, $request)) {
      $r3 = _civicrm_api_get_camel_name($request[3]);
      $smarty->assign("id",$r3);
    }
    if (CRM_Utils_Array::value(4, $request)) {
      $r3 = CRM_Utils_String::munge($request[4]);
      $smarty->assign("id2",$r3);
    }
    if (!$tplfile) {
      $tpl = "CRM/Civisualize/Page/Main.tpl";
    }
    // Example: Assign a variable for use in a template
    $this->assign('currentTime', date('Y-m-d H:i:s'));

    parent::run();
  }

}
