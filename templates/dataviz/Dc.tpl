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

{crmStyle ext="eu.tttp.civisualize" file="js/dc/dc.css"}
{crmScript ext="eu.tttp.civisualize" file="js/dc/dc.js"}
{crmScript ext="eu.tttp.civisualize" file="js/dc/crossfilter.js"}
<script>
'use strict';

var data = {crmSQL file="contribution_by_date"};

{literal}
cj(function($) {
// create a pie chart under #chart-container1 element using the default global chart group
var pietype = dc.pieChart("#type").innerRadius(20).radius(70);
var volumeChart = dc.barChart("#monthly-volume-chart");
var dayOfWeekChart = dc.rowChart("#day-of-week-chart");
//var moveChart = dc.compositeChart("#monthly-move-chart");


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
var volumeByMonthGroup = byMonth.group().reduceSum(function(d) { return d.count; });

var totalByMonthGroup = byMonth.group().reduceSum(function(d) { return d.total; });

  var dayOfWeek = ndx.dimension(function (d) { 
      var day = d.dd.getDay(); 
      switch (day) { 
          case 0: 
              return "0.Sun"; 
          case 1: 
              return "1.Mon"; 
          case 2: 
              return "2.Tue"; 
          case 3: 
              return "3.Wed"; 
          case 4: 
              return "4.Thu"; 
          case 5: 
              return "5.Fri"; 
          case 6: 
              return "6.Sat"; 
      } 
  }); 

var dayOfWeekGroup = dayOfWeek.group(); 
dayOfWeekChart.width(180)
  .height(180)
  .margins({top: 20, left: 10, right: 10, bottom: 20})
  .group(dayOfWeekGroup)
  .dimension(dayOfWeek)
  .colors(['#3182bd', '#6baed6', '#9ecae1', '#c6dbef', '#dadaeb'])
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
  });;
/*
        dc.lineChart("#monthly-move-chart", "chartGroup")
            .width(800) // (optional) define chart width, :default = 200
            .height(200) // (optional) define chart height, :default = 200
            .transitionDuration(500) // (optional) define chart transition duration, :default = 500
            // (optional) define margins
            .margins({top: 10, right: 50, bottom: 30, left: 40})
            .dimension(monthlyMove) // set dimension
            .group(monthlyMoveGroup) // set group
            // (optional) whether chart should rescale y axis to fit data, :default = false
            .elasticY(true)
            // (optional) when elasticY is on whether padding should be applied to y axis domain, :default=0
            .yAxisPadding(100)
            // (optional) whether chart should rescale x axis to fit data, :default = false
            .elasticX(true)
            // (optional) when elasticX is on whether padding should be applied to x axis domain, :default=0
            .xAxisPadding(500)
            // define x scale
            .x(d3.time.scale().domain([min,max]))
            .round(d3.time.month.round)
            // define x axis units
            .xUnits(d3.time.months)
            // (optional) render horizontal grid lines, :default=false
            .renderHorizontalGridLines(true)
            // (optional) render vertical grid lines, :default=false
            .renderVerticalGridLines(true)
            // (optional) render as area chart, :default = false
            .renderArea(true)
            // (optional) add stacked group and custom value retriever
            .stack(monthlyMoveGroup, function(d){return d.value;})
            // (optional) you can add multiple stacked group with or without custom value retriever
            // if no custom retriever provided base chart's value retriever will be used
            .stack(monthlyMoveGroup)
            // (optional) whether this chart should generate user interactive brush to allow range
            // selection, :default=true.
            .brushOn(true)
            // (optional) whether dot and title should be generated on the line using
            // the given function, :default=no
            .title(function(d) { return "Value: " + d.value; })
            // (optional) whether chart should render titles, :default = false
            .renderTitle(true)
            // (optional) radius used to generate title dot, :default = 5
            .dotRadius(10);

*/
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

