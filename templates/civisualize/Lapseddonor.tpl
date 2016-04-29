<div>
<h2>Look, a unicorn</h2>
<table>
<tr>
<th>Recovered</th>
<th>Prior</th>
</tr><tr>
<td id="recovered"></td>
<td id="prior"></td>
</tr></table>
<script>
'use strict';
//var data = {crmAPI entity="reportinstance"...};
{literal}

var data = {"is_error":0,"version":3,"count":2,"values":[{"from_date":"2010-01-01","to_date":"2011-07-01","recovered":780,"prior":"508"},{"from_date":"2011-07-01","to_date":"2012-12-30","recovered":"9999","prior":"845"}]};


dc.pieChart("#recovered")
  .width(300)
  .height(300)
  .innerRadius(50)
  .dimension({}).group({})
  .title(function(d) { return d.from_date + "\n->" + d.to_date; })
  .label(function(d) { return d.from_date })
  .keyAccessor(function(d) { return d.from_date + "\n->" + d.to_date; })
  .valueAccessor(function(d) { return d.recovered;})
  .data(function() { return data.values});

dc.pieChart("#prior")
  .width(300)
  .height(300)
  .innerRadius(50)
  .dimension({}).group({})
  .title(function(d) { return d.from_date + "\n->" + d.to_date; })
  .label(function(d) { return d.from_date })
  .keyAccessor(function(d) { return d.from_date + "\n->" + d.to_date; })
  .valueAccessor(function(d) { return d.prior;})
  .data(function() { return data.values});

dc.renderAll();

{/literal}
//http://wiki.civicrm.org/confluence/display/CRM/CiviEngage+Enhancements+for+fund-raising#CiviEngageEnhancementsforfund-raising-2.LapsedandRecoveredDonorsChart
</script>
<div style="clear:both;"></div>
</div>
