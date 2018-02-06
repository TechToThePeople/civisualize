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
    $path = "doc/";
    if (CRM_Utils_Array::value(2, $request)) {
      $tplfile = _civicrm_api_get_camel_name($request[2]);
      $tplfile = explode('?', $tplfile);
      $file = $tplfile[0].'.md';
    }
    if (CRM_Utils_Array::value(3, $request)) {
      $r3 = _civicrm_api_get_camel_name($request[3]);
      if (!is_numeric($r3)) {
        $file = $r3 .'.md';
        $path = $path.$tplfile[0].'/';
      }
      $smarty->assign("id",$r3);
    }
    
    if (CIVISUALIZE_GITHUB_DOC) {
      $smarty->assign("github",CIVISUALIZE_GITHUB_DOC);
    } else {
      $smarty->assign("github","TechToThePeople/civisualize");
    }
    
//    $github = civicrm_api3('setting', 'getvalue', array('group' => 'Civisualize Preferences', 'name' => 'civisualize_github_doc'));
    $md = file_get_contents($path.$file, FILE_USE_INCLUDE_PATH);
    if (!$md) {
      $md= "$path$file not found"; 
      $smarty->assign("error","missing_file");
    }
    $smarty->assign("mdfile",$file);
    $smarty->assign("path",$path);
    $smarty->assign("md",$md);

    if (CRM_Utils_Array::value(4, $request)) {
      $r3 = CRM_Utils_String::munge($request[4]);
      $smarty->assign("id2",$r3);
    }
    if (!$tplfile) {
      $tpl = "CRM/Civisualize/Page/Doc.tpl";
    }

    parent::run();
  }

}
