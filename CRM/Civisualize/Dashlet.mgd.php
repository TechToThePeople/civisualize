<?php

return array (
0=>array (
  'name'=>'dataviz_contact',
  'entity'=> 'Dashboard',
  'params'=> array (
    'version'=>'3',
    'name'=>'dataviz_contact',
    'label'=> 'Dataviz of contacts',
    'url' => CRM_Utils_System::url('civicrm/civisualize/contacts', 'snippet=4'),
  )
),

1=>array (
  'name'=>'dataviz_events',
  'entity'=> 'Dashboard',
  'params'=> array (
    'version'=>'3',
    'name'=>'dataviz_event',
    'label'=> 'Dataviz of events',
    'url' => CRM_Utils_System::url('civicrm/civisualize/events', 'snippet=4'),
  )
),

2=>array (
  'name'=>'dataviz_contribute',
  'entity'=> 'Dashboard',
  'params'=> array (
    'version'=>'3',
    'name'=>'dataviz_contribute',
    'label'=> 'Dataviz of contributions',
    'url' => CRM_Utils_System::url('civicrm/civisualize/contribute', 'snippet=4'),
  )
)

);
