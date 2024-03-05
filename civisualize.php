<?php
use CRM_Civisualize_ExtensionUtil as E;
//todo: move that to core
function _civicrm_api3_basic_getsql ($params,$sql) {
  $returnSQL        = CRM_Utils_Array::value('sql', $params, CRM_Utils_Array::value('options_sql', $params));
  if ($returnSQL) {
    return array("is_error"=>1,"sql"=>$sql);
  }
  $dao = CRM_Core_DAO::executeQuery($sql);
  $values = array();
  while ($dao->fetch()) {
    $values[] = $dao->toArray();
  }
  return civicrm_api3_create_success($values, $params, NULL, NULL, $dao);
}

require_once 'civisualize.civix.php';

function civisualize_civicrm_dashboard( $contactID, &$contentPlacement ) {
  CRM_Civisualize_VisualBundle::register();
  /*
   CRM_Core_Resources::singleton()
    ->addScriptFile('eu.tttp.civisualize', 'js/d3.min.v5.7.0.js', 110, 'html-header', FALSE)
    ->addScriptFile('eu.tttp.civisualize', 'js/dc/dc.min.js', 110, 'html-header', FALSE)
    ->addScriptFile('eu.tttp.civisualize', 'js/dc/crossfilter.min.js', 110, 'html-header', FALSE)
    ->addStyleFile('eu.tttp.civisualize', 'js/dc/dc.min.css')
    ->addStyleFile('eu.tttp.civisualize', 'css/style.css');
   */
}

/**
 * Implementation of hook_civicrm_config
 */
function civisualize_civicrm_config(&$config) {
  _civisualize_civix_civicrm_config($config);
}
/**
 * Implements hook_civicrm_container
 *
 * We register 2 hooks to copy CiviCRM tags to Mailchimp.
 *
 * @param \Symfony\Component\DependencyInjection\ContainerBuilder $container
 */
function civisualize_civicrm_container($container) {
  $container->findDefinition('dispatcher')
            ->addMethodCall('addListener', [ 'hook_civicrm_buildAsset', ['\CRM_Civisualize_VisualBundle', 'buildAssetJs']])
            ->addMethodCall('addListener', [ 'hook_civicrm_buildAsset', ['\CRM_Civisualize_VisualBundle', 'buildAssetCss']]);
}

/**
 * Implementation of hook_civicrm_install
 */
function civisualize_civicrm_install() {
  return _civisualize_civix_civicrm_install();
}

/**
 * Implementation of hook_civicrm_enable
 */
function civisualize_civicrm_enable() {
  return _civisualize_civix_civicrm_enable();
}

/**
 * Adds a navigation menu item under report.
 *
 * @param array $params
 */
function civisualize_civicrm_navigationMenu( &$params ) {
  $path = "Reports";
  $item = array(
    'label' => 'Civisualize',
    'name' => 'Civisualize',
    'url' => 'civicrm/dataviz',
    'permission' => 'access CiviReport',
    'operator' => '',
    'separator' => TRUE,
    'active' => 1,
  );

  _civisualize_civix_insert_navigation_menu($params, $path, $item);
}
