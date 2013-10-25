<div id="type"></div>
   <div id="day-of-week-chart">
        <strong>Day of Week</strong>
        <a class="reset" href="javascript:dayOfWeekChart.filterAll();dc.redrawAll();" style="display: none;">reset</a>

        <div class="clearfix"></div>
    </div>
<div id="status">
</div>

<div class="row clear">
    <div id="monthly-move-chart">
        <strong>Registration</strong>
        <span class="reset" style="display: none;">range: <span class="filter"></span></span>
        <a class="reset" href="javascript:count.filterAll();count.filterAll();dc.redrawAll();"
           style="display: none;">reset</a>
<div id="count"></div>

        <div class="clearfix"></div>
    </div>
</div>


<div id="monthly-volume-chart"></div>


<script>
'use strict';

var data = {crmSQL file="participants"};

var i = {crmAPI entity="OptionValue" option_group_id="14"}; {*todo on 4.4, use the event-type as id *}
var s = {crmAPI entity='ParticipantStatusType' option_sort="is_counted desc"};

{literal}
var statusLabel = {};
s.values.forEach (function(d) {
  statusLabel[d.id] = d.label;
});
s=null;

var typeLabel = {};
i.values.forEach (function(d) {
  typeLabel[d.value] = d.label;
});
i=null;

var numberFormat = d3.format(".2f");
var count =null,dayOfWeekChart=null,volumeChart=null;  

cj(function($) {
// create a pie chart under #chart-container1 element using the default global chart group
var pietype = dc.pieChart("#type").innerRadius(20).radius(70);
var piestatus = dc.pieChart("#status").innerRadius(50).radius(70);
volumeChart = dc.barChart("#monthly-volume-chart");
dayOfWeekChart = dc.rowChart("#day-of-week-chart");
//var moveChart = dc.seriesChart("#monthly-move-chart");
//moveChart = dc.lineChart("#monthly-move-chart");
var count = dc.seriesChart("#count");


var dateFormat = d3.time.format("%Y-%m-%d");
var event = {};
data.values.forEach(function(d){
  d.dd = dateFormat.parse(d.register_date)
/*  if (event[d.event_id])
    event[d.event_id] = event[d.event_id]+parseFloat(d.count);
  else 
    event[d.event_id] = parseFloat(d.count);
*/
  if (!event[d.event_id])
    event[d.event_id]= +d.count;

  d.participants = event[d.event_id];
});

var min = d3.min(data.values, function(d) { return d.dd;} );
var max = d3.max(data.values, function(d) { return d.dd;} );
var ndx                 = crossfilter(data.values),
all = ndx.groupAll();

var status        = ndx.dimension(function(d) {return d.status_id;});
var statusGroup   = status.group().reduceSum(function(d) { return d.count; });

var type        = ndx.dimension(function(d) {return d.event_type_id;});
var typeGroup   = type.group().reduceSum(function(d) { return d.count; });

var byMonth = ndx.dimension(function(d) { return d3.time.month(d.dd); });
var byDay = ndx.dimension(function(d) { return d.dd; });
var volumeByMonthGroup = byMonth.group().reduceSum(function(d) { return d.count; });
var totalByDayGroup = byDay.group().reduceSum(function(d) { return d.participants; });

var events = ndx.dimension(function(d) {return [+d.event_id,d.dd];});
var eventGroup   = events.group().reduceSum(function(d) { 
return +d.participants });
  
var dayOfWeek = ndx.dimension(function (d) { 
      var day = d.dd.getDay(); 
      var name=["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
      return day+"."+name[day]; 
  }); 

var dayOfWeekGroup = dayOfWeek.group(); 
dayOfWeekChart.width(180)
  .height(180)
  .margins({top: 20, left: 10, right: 10, bottom: 20})
  .group(dayOfWeekGroup)
  .dimension(dayOfWeek)
  .ordinalColors(["#d95f02","#1b9e77","#7570b3","#e7298a","#66a61e","#e6ab02","#a6761d"])
  .label(function (d) {
      return d.key.split(".")[1];
  })
  .title(function (d) {
      return d.value;
  })
  .elasticX(true)
  .xAxis().ticks(4);


pietype
  .width(200)
  .height(200)
  .dimension(type)
  .group(typeGroup)
  .colors(d3.scale.category10())
  .title(function(d) {
   return typeLabel[d.key]+":"+d.value;
})
  .label(function(d) {
     return typeLabel[d.key];
})
  .renderlet(function (chart) {
  });

piestatus
  .width(200)
  .height(200)
  .dimension(status)
  .group(statusGroup)
  .title(function(d) {
   return statusLabel[d.key]+":"+d.value;
})
  .label(function(d) {
     return statusLabel[d.key];
})
  .renderlet(function (chart) {
  });


  count
    .width(768)
    .height(480)
    .chart(function(c) { return dc.lineChart(c).interpolate('step-before'); })
                    .x(d3.time.scale().domain([min,max]))
    .brushOn(false)
    .yAxisLabel("participants")
    .xAxisLabel("Date")
    .elasticY(true)
    .dimension(events)
    .group(eventGroup)
    .mouseZoomable(true)
    .seriesAccessor(function(d) {return "Event " + d.key[0];})
    .keyAccessor(function(d) {
   return +d.key[1];})
    .valueAccessor(function(d) {
return +d.value;})
    .rangeChart(volumeChart)
    .legend(dc.legend().x(700).y(300).itemHeight(13).gap(5));
  count.yAxis().tickFormat(function(d) {return d3.format(',d')(d);});
  count.margins().left += 40;


volumeChart.width(800)
  .height(100)
  .margins({top: 0, right: 50, bottom: 20, left: 40})
  .dimension(byMonth)
  .group(volumeByMonthGroup)
  .centerBar(true)
  .gap(1)
  .x(d3.time.scale().domain([min, max]))
  .round(d3.time.month.round)
  .xUnits(d3.time.months);

dc.dataCount(".dc-data-count")
  .dimension(ndx)
  .group(all);



dc.renderAll();
//  pietype.render();

});
{/literal}
</script>
<div class="clear"></div>
