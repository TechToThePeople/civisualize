{php}
CRM_Utils_System::setTitle('Overview of your CiviCRM');

$this->assign("options", array('width'=>200));

{/php}

<div id="dataviz">
</div>
{include file="dataviz/Contacttype.tpl" embedded=1 name="contactTypeGraph" options=$options}

{include file="dataviz/Groupbarchart.tpl" embedded=1 name="GroupBarChart"}

{literal}
<style>
#GroupBarChart {position:absolute;left:320px;}
</style>
{/literal}

