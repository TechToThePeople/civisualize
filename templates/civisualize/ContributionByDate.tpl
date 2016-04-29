{crmScript ext="eu.tttp.civisualize" file="js/dc/dc.js"}
{crmScript ext="eu.tttp.civisualize" file="js/dc/crossfilter.js"}

<div id="your-chart">
    <!-- Title or anything you want to add above the chart -->
    <span>Days by Gain or Loss</span>

<span class="reset" style="display: none;">Current filter: <span class="filter"></span></span>
<!-- anchor div for data table -->
<div id="data-table">
    <!-- create a custom header -->
    <div class="header">
        <span>Date</span>
        <span>Open</span>
        <span>Close</span>
        <span>Change</span>
        <span>Volume</span>
    </div>
    <!-- data rows will filled in here -->
</div>



<script>

cj(function($) {ldelim}

var gainOrLossChart = dc.pieChart("#gain-loss-chart");
var fluctuationChart = dc.barChart("#fluctuation-chart");
var quarterChart = dc.pieChart("#quarter-chart");
var dayOfWeekChart = dc.rowChart("#day-of-week-chart");
var moveChart = dc.compositeChart("#monthly-move-chart");
var volumeChart = dc.barChart("#monthly-volume-chart");
var yearlyBubbleChart = dc.bubbleChart("#yearly-bubble-chart");


var data={crmSQL file="contribution_by_date"}.values;

{literal}
dateFormat = d3.time.format("%Y-%m-%d");
data.forEach(function(e) { e.dd = dateFormat.parse(e.receive_date); });

// feed it through crossfilter
var ndx = crossfilter(data);
 
// define group all for counting
var all = ndx.groupAll();
 
// define a dimension
var volumeByMonth = ndx.dimension(function(d) { return d3.time.month(d.dd); });
// map/reduce to group sum
var volumeByMonthGroup = volumeByMonth.group().reduceSum(function(d) { return d.count; });
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


var contactType = ndx.dimension(function(d) { return d.contact_type; });
var contactTypeGroup=contactType.group();

/* Create a pie chart and use the given css selector as anchor. You can also specify
 * an optional chart group for this chart to be scoped within. When a chart belongs
 * to a specific group then any interaction with such chart will only trigger redraw
 * on other charts within the same chart group. */
dc.pieChart("#contact-type-chart", "chartGroup")
    .width(200) // (optional) define chart width, :default = 200
    .height(200) // (optional) define chart height, :default = 200
    .transitionDuration(500) // (optional) define chart transition duration, :default = 350
    // (optional) define color array for slices
    .colors(['#3182bd', '#6baed6', '#9ecae1', '#c6dbef', '#dadaeb'])
    // (optional) define color domain to match your data domain if you want to bind data or color
    .colorDomain([-1750, 1644])
    // (optional) define color value accessor
    .colorAccessor(function(d, i){return d.value;})
    .radius(90) // define pie radius
    // (optional) if inner radius is used then a donut chart will
    // be generated instead of pie chart
    .innerRadius(40)
    .dimension(contactType) // set dimension
    .group(contactTypeGroup) // set group
    // (optional) by default pie chart will use group.key as it's label
    // but you can overwrite it with a closure
    .label(function(d) { return d.data.key + "(" + Math.floor(d.data.value / all.value() * 100) + "%)"; })
    // (optional) whether chart should render labels, :default = true
    .renderLabel(true)
    // (optional) by default pie chart will use group.key and group.value as its title
    // you can overwrite it with a closure
    .title(function(d) { return d.data.key + "(" + Math.floor(d.data.value / all.value() * 100) + "%)"; })
    // (optional) whether chart should render titles, :default = false
    .renderTitle(true);

return;

/* Create a bar chart and use the given css selector as anchor. You can also specify
 * an optional chart group for this chart to be scoped within. When a chart belongs
 * to a specific group then any interaction with such chart will only trigger redraw
 * on other charts within the same chart group. */
dc.barChart("#volume-month-chart")
    .width(990) // (optional) define chart width, :default = 200
    .height(250) // (optional) define chart height, :default = 200
    .transitionDuration(500) // (optional) define chart transition duration, :default = 500
    // (optional) define margins
    .margins({top: 10, right: 50, bottom: 30, left: 40})
    .dimension(volumeByMonth) // set dimension
    .group(volumeByMonthGroup) // set group
    // (optional) whether chart should rescale y axis to fit data, :default = false
    .elasticY(true)
    // (optional) when elasticY is on whether padding should be applied to y axis domain, :default=0
    .yAxisPadding(100)
    // (optional) whether chart should rescale x axis to fit data, :default = false
    .elasticX(true)
    // (optional) when elasticX is on whether padding should be applied to x axis domain, :default=0
    .xAxisPadding(500)
    // define x scale
    .x(d3.time.scale().domain([new Date(1985, 0, 1), new Date(2012, 11, 31)]))
    // (optional) set filter brush rounding
    .round(d3.time.month.round)
    // define x axis units
    .xUnits(d3.time.months)
    // (optional) whether bar should be center to its x value, :default=false
    .centerBar(true)
    // (optional) set gap between bars manually in px, :default=2
    .barGap(1)
    // (optional) render horizontal grid lines, :default=false
    .renderHorizontalGridLines(true)
    // (optional) render vertical grid lines, :default=false
    .renderVerticalGridLines(true)
    // (optional) add stacked group and custom value retriever
    .stack(monthlyMoveGroup, function(d){return d.value;})
    // (optional) you can add multiple stacked group with or without custom value retriever
    // if no custom retriever provided base chart's value retriever will be used
    .stack(monthlyMoveGroup)
    // (optional) whether this chart should generate user interactive brush to allow range
    // selection, :default=true.
    .brushOn(true)
    // (optional) whether svg title element(tooltip) should be generated for each bar using
    // the given function, :default=no
    .title(function(d) { return "Value: " + d.value; })
    // (optional) whether chart should render titles, :default = false
    .renderTitle(true);

/* Create a row chart and use the given css selector as anchor. You can also specify
 * an optional chart group for this chart to be scoped within. When a chart belongs
 * to a specific group then any interaction with such chart will only trigger redraw
 * on other charts within the same chart group. */
dc.rowChart("#days-of-week-chart", "chartGroup")
    .width(180) // (optional) define chart width, :default = 200
    .height(180) // (optional) define chart height, :default = 200
    .group(dayOfWeekGroup) // set group
    .dimension(dayOfWeek) // set dimension
    // (optional) define margins
    .margins({top: 20, left: 10, right: 10, bottom: 20})
    // (optional) define color array for slices
    .colors(['#3182bd', '#6baed6', '#9ecae1', '#c6dbef', '#dadaeb'])
    // (optional) set gap between rows, default is 5
    gap(7)
    // (optional) set x offset for labels, default is 10
    labelOffSetX(5)
    // (optional) set y offset for labels, default is 15
    labelOffSetY(10)
    // (optional) whether chart should render labels, :default = true
    .renderLabel(true)
    // (optional) by default pie chart will use group.key and group.value as its title
    // you can overwrite it with a closure
    .title(function(d) { return d.data.key + "(" + Math.floor(d.data.value / all.value() * 100) + "%)"; })
    // (optional) whether chart should render titles, :default = false
    .renderTitle(true);
    // (optional) specify the number of ticks for the X axis
//    .xAxis().ticks(4);



/* Create a line chart and use the given css selector as anchor. You can also specify
 * an optional chart group for this chart to be scoped within. When a chart belongs
 * to a specific group then any interaction with such chart will only trigger redraw
 * on other charts within the same chart group. */
dc.lineChart("#contribution-monthly-chart", "chartGroup")
    .width(990) // (optional) define chart width, :default = 200
    .height(200) // (optional) define chart height, :default = 200
    .transitionDuration(500) // (optional) define chart transition duration, :default = 500
    // (optional) define margins
    .margins({top: 10, right: 50, bottom: 30, left: 40})
    .dimension(monthly) // set dimension
    .group(monthlyGroup) // set group
    // (optional) whether chart should rescale y axis to fit data, :default = false
    .elasticY(true)
    // (optional) when elasticY is on whether padding should be applied to y axis domain, :default=0
    .yAxisPadding(100)
    // (optional) whether chart should rescale x axis to fit data, :default = false
    .elasticX(true)
    // (optional) when elasticX is on whether padding should be applied to x axis domain, :default=0
    .xAxisPadding(500)
    // define x scale
    .x(d3.time.scale().domain([new Date(1985, 0, 1), new Date(2013, 11, 31)]))
    // (optional) set filter brush rounding
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
    .stack(monthlyGroup, function(d){return d.total;})
    // (optional) you can add multiple stacked group with or without custom value retriever
    // if no custom retriever provided base chart's value retriever will be used
    .stack(monthlyGroup)
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

/* Create a composite chart and use the given css selector as anchor. You can also specify
     * an optional chart group for this chart to be scoped within. When a chart belongs
     * to a specific group then any interaction with such chart will only trigger redraw
     * on other charts within the same chart group. */
dc.compositeChart("#montly-move-chart", "chartGroup")
    .width(990) // (optional) define chart width, :default = 200
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
    .x(d3.time.scale().domain([new Date(1985, 0, 1), new Date(2012, 11, 31)]))
    // (optional) set filter brush rounding
    .round(d3.time.month.round)
    // define x axis units
    .xUnits(d3.time.months)
    // (optional) render horizontal grid lines, :default=false
    .renderHorizontalGridLines(true)
    // (optional) render vertical grid lines, :default=false
    .renderVerticalGridLines(true)
    // compose sub charts, currently composite chart only supports line chart & bar chart
    .compose([
        /* Pass the parent chart instance to sub-chart function instead of css selector.
         * Sub-charts can have it's own group and dimension however usually it should
         * share parent chart's dimension. If sub-chart's dimension or group is not
         * explicitly defined here then it will simply inherent from it's parent. */
        dc.barChart(volumeMoveChart).group(volumeByMonthGroup),
        // you can even include stacked bar chart or line chart in a composite chart
        dc.lineChart(volumeMoveChart).group(indexAvgByMonthGroup).valueAccessor(function(d){return d.value.avg;}).renderArea(true).stack(monthlyMoveGroup, function(d){return d.value;})
    ])
    // (optional) whether this chart should generate user interactive brush to allow range
    // selection, :default=true.
    .brushOn(true);


/* Create a data table widget and use the given css selector as anchor. You can also specify
 * an optional chart group for this chart to be scoped within. When a chart belongs
 * to a specific group then any interaction with such chart will only trigger redraw
 * on other charts within the same chart group. */
dc.dataTable("#data-table")
    // set dimension
    .dimension(dateDimension)
    // data table does not use crossfilter group but rather a closure
    // as a grouping function
    .group(function(d) {
        return d.dd.getFullYear() + "/" + (d.dd.getMonth() + 1);
    })
    // (optional) max number of records to be shown, :default = 25
    .size(10)
    // dynamic columns creation using an array of closures
    .columns([
        function(d) { return d.date; },
        function(d) { return d.open; },
        function(d) { return d.close; },
        function(d) { return Math.floor((d.close - d.open)/d.open*100) + "%"; },
        function(d) { return d.volume; }
    ])
    // (optional) sort using the given field, :default = function(d){return d;}
    .sortBy(function(d){ return d.dd; })
    // (optional) sort order, :default ascending
    .order(d3.ascending);
});
</script>
{/literal}

