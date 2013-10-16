<div id="type"></div>
   <div id="day-of-week-chart">
        <strong>Day of Week</strong>
        <a class="reset" href="javascript:dayOfWeekChart.filterAll();dc.redrawAll();" style="display: none;">reset</a>

        <div class="clearfix"></div>
    </div>

<div class="row">
    <div id="monthly-move-chart">
        <strong>Amount by month</strong>
        <span class="reset" style="display: none;">range: <span class="filter"></span></span>
        <a class="reset" href="javascript:moveChart.filterAll();volumeChart.filterAll();dc.redrawAll();"
           style="display: none;">reset</a>

        <div class="clearfix"></div>
    </div>
</div>


<div id="monthly-volume-chart"></div>

{*crmStyle ext="eu.tttp.civisualize" file="js/dc/dc.css"}
{crmScript ext="eu.tttp.civisualize" file="js/dc/dc.js"}
{crmScript ext="eu.tttp.civisualize" file="js/dc/crossfilter.js"*}
<!--script scr="{crmResURL ext="eu.tttp.civisualize"}js/dc/dc.js"></script>
<script scr="{crmResURL ext="eu.tttp.civisualize"}js/dc/crossfilter.js"></script--!>

<script>
'use strict';

var data = {crmSQL file="contribution_by_date"};

{literal}

var numberFormat = d3.format(".2f");
var volumeChart =null,dayOfWeekChart=null,moveChart=null;  

cj(function($) {
// create a pie chart under #chart-container1 element using the default global chart group
var pietype = dc.pieChart("#type").innerRadius(20).radius(70);
volumeChart = dc.barChart("#monthly-volume-chart");
dayOfWeekChart = dc.rowChart("#day-of-week-chart");
//var moveChart = dc.seriesChart("#monthly-move-chart");
moveChart = dc.lineChart("#monthly-move-chart");
var dateFormat = d3.time.format("%Y-%m-%d");
//data.values.forEach(function(d){data.values[i].dd = new Date(d.receive_date)});
data.values.forEach(function(d){d.dd = dateFormat.parse(d.receive_date)});
var min = d3.min(data.values, function(d) { return d.dd;} );
var max = d3.max(data.values, function(d) { return d.dd;} );
console.log(min);
var ndx                 = crossfilter(data.values),
all = ndx.groupAll();

var type        = ndx.dimension(function(d) {return d.contact_type;});
var typeGroup   = type.group().reduceSum(function(d) { return d.count; });
 
var byMonth = ndx.dimension(function(d) { return d3.time.month(d.dd); });
var byDay = ndx.dimension(function(d) { return d.dd; });
var volumeByMonthGroup = byMonth.group().reduceSum(function(d) { return d.count; });
var totalByMonthGroup = byMonth.group().reduceSum(function(d) { return d.total; });
var totalByDayGroup = byDay.group().reduceSum(function(d) { return d.total; });

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
  .ordinalColors(['#3182bd', '#6baed6', '#9ecae1', '#c6dbef', '#dadaeb'])
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
  .renderlet(function (chart) {
  });

                    //.round(d3.time.month.round)
    //.interpolate('monotone')
            moveChart.width(800)
                    .height(200)
                    .transitionDuration(1000)
                    .margins({top: 30, right: 50, bottom: 25, left: 40})
                    .dimension(byDay)
                    .mouseZoomable(true)
                    .x(d3.time.scale().domain([min,max]))
                    .xUnits(d3.time.months)
                    .elasticY(true)
                    .renderHorizontalGridLines(true)
                    .legend(dc.legend().x(800).y(10).itemHeight(13).gap(5))
                    .brushOn(false)
                    .rangeChart(volumeChart)
  .group(totalByDayGroup)
                 .valueAccessor(function (d) { 
                        return d.value;
                    })
 
                 .title(function (d) {
                        var value = d.data.value;
                        if (isNaN(value)) value = 0;
                        return dateFormat(d.data.key) + "\n" + numberFormat(value);
                    });

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

