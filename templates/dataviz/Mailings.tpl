{crmTitle string="<span class='data_count'><span class='filter-count'></span> Mailings out of <span class='total-count'></span></span>"}

<a class="reset" href="javascript:sourceRow.filterAll();dc.redrawAll();" style="display: none;">reset</a>

<div class="row">
<div id="campaign" class="col-md-2"><h3>Campaign</h3><div class="graph"></div></div>
<div id="sender" class="col-md-2"><h3>Crew</h3><div class="graph"></div></div>
<div id="open" class="col-md-2"><h3>% Open</h3><div class="graph"></div><div class="avg"></div></div>
<div id="click" class="col-md-2"><h3>% Click</h3><div class="graph"></div><div class="avg"></div></div>
<div id="date" class="col-md-4"><h3>Date sent</h3><div class="graph"></div></div>
</div>

<div class="row">
<table class="table table-striped" id="table">

<thead><tr>
<th>Date</th>
<th>Name</th>
<th>Campaign</th>
<th>Creator</th>
<th>Recipients</th>
<th>Open</th>
<th>Clicks</th>
</tr></thead>
</table>
</div>

<div class="row">
</div>

<script>
var data = {crmSQL json="mailings"};
var dateFormat = d3.time.format("%Y-%m-%d %H:%M:%S");
var currentDate = new Date();


{literal}

var prettyDate = function (dateString){
  var date = new Date(dateString);
  var d = date.getDate();
  var m = ('0' + (date.getMonth()+1)).slice(-2);
  var y = date.getFullYear();
  var min = ('0' + date.getMinutes()).slice(-2);
  return d+'/'+m+'/'+y +' ' +date.getHours() + ':'+min;
}


function lookupTable(data,key,value) {
  var t= {}
  data.forEach(function(d){t[d[key]]=d[value]});
  return t;
}

data.values.forEach(function(d){
  d.date = dateFormat.parse(d.date);
});



var ndx  = crossfilter(data.values)
  , all = ndx.groupAll();

var totalCount = dc.dataCount("h1 .data_count")
      .dimension(ndx)
      .group(all);

function drawCampaign (dom) {
  var dim = ndx.dimension(function(d){return d.campaign});
  var group = dim.group().reduceSum(function(d){return 1;});
  var graph  = dc.pieChart(dom)
    .innerRadius(10).radius(50)
    .width(100)
    .height(100)
    .dimension(dim)
    .colors(d3.scale.category20())
    .group(group);

  return graph;
}

function drawSender (dom) {
  var dim = ndx.dimension(function(d){return d.owner});
  var group = dim.group().reduceSum(function(d){return 1;});
  var graph  = dc.pieChart(dom)
    .innerRadius(10).radius(50)
    .width(100)
    .height(100)
    .dimension(dim)
    .colors(d3.scale.category10())
    .group(group);

  return graph;
}
function drawType (dom) {
  var dim = ndx.dimension(function(d){return activityType[d.activity_type_id]});
  var group = dim.group().reduceSum(function(d){return 1;});
  var graph  = dc.pieChart(dom)
    .innerRadius(10).radius(90)
    .width(250)
    .height(200)
    .dimension(dim)
    .colors(d3.scale.category20b())
    .group(group);

  return graph;
}

function drawDate (dom) {
  var dim = ndx.dimension(function(d){return d3.time.day(d.date)});
  //var group = dim.group().reduceSum(function(d){return 1;});
  var group = dim.group().reduceSum(function(d){return d.recipients;});
  var graph=dc.lineChart(dom)
   .margins({top: 10, right: 10, bottom: 20, left:50})
    .height(100)
    .dimension(dim)
    .renderArea(true)
    .group(group)
    .brushOn(true)
    .x(d3.time.scale().domain(d3.extent(dim.top(2000), function(d) { return d.date; })))
    .round(d3.time.day.round)
    .elasticY(true)
    .xUnits(d3.time.days);

   graph.yAxis().ticks(3);
   graph.xAxis().ticks(5);
  return graph;
}


function drawPercent (dom,attr,name) {
  //var dim = ndx.dimension(function(d){return 10 * Math.floor((accessor(d)/d.recipients* 10)) });
  var dim = ndx.dimension(function(d){return 10 * Math.floor((attr(d)/d.recipients* 10)) });
  var group = dim.group().reduceSum(function(d){return 1;});
  //var group = dim.group().reduceSum(function(d){return d.recipients;});


  var graph = dc.barChart(dom+ " .graph")
    .height(100)
    .width(150)
    .gap(0)
    .margins({top: 10, right: 0, bottom: 20, left: 20})
    .colorCalculator(function(d, i) {
        return "#f85631";
        })
    .x(d3.scale.ordinal())
    .xUnits(dc.units.ordinal)
    .brushOn(false)
    .elasticY(true)
    .yAxisLabel(name)
    .dimension(dim)
    .group(group)
    .renderlet(function(chart) {
	    var d = chart.dimension().top(Number.POSITIVE_INFINITY);
	    var total = nb = recipients = 0;
	    d.forEach(function(a) {
		++nb;
                recipients += a.recipients;
                if (a.recipients)
	  	  total += attr(a);
	    });
	    if (nb) {
		//var avg = 100 * total / nb;
		var avg = 100 * total / recipients;
		jQuery(dom + " .avg").text(Math.round(avg) + "%");
	    } else {
		jQuery(dom +" .avg").text("");
	    }
      }
    );


   graph.yAxis().ticks(3);
   graph.xAxis().ticks(4);
   return graph;
}


function drawTable(dom) {
  var dim = ndx.dimension (function(d) {return d.id});
  var graph = dc.dataTable(dom)
    .dimension(dim)
    .size(2000)
    .group(function(d){ return ""; })
    .sortBy(function(d){ return d.date; })
    .order(d3.descending)
    .columns(
	[
	    function (d) {
		return prettyDate(d.date);
	    },
	    function (d) {
             return "<a title='"+d.subject+"' href='/civicrm/mailing/report?mid="+d.id+"' target='_blank'>"+d.name+"</a> <small><a title='Date Open graph' href='/civicrm/dataviz/mailing/"+d.id+"' >(details)</a></small>";
	    },
	    function (d) {
		return "<a href='/civicrm/campaign/add?reset=1&action=update&id="+d.campaign_id+"' target='_blank'>"+d.campaign+"</a>";
	    },
	    function (d) {
              return d.owner;
	    },
	    function (d) {
              return d.recipients;
	    },
	    function (d) {
              return "<span title='"+d.open+" contacts' >"+Math.round (100*d.open/d.recipients)+"%</span>";
	    },
	    function (d) {
              return "<span title='"+d.click+" contacts' >"+Math.round (100*d.click/d.recipients)+"%</span>";
	    },
	]
    );

  return graph;
}

 
drawPercent("#open", function(d){return d.open});
drawPercent("#click", function(d){return d.click});
drawTable("#table");
//drawType("#type .graph");
drawDate("#date .graph");
//drawStatus("#status .graph");
drawSender("#sender .graph");
drawCampaign("#campaign .graph");

dc.renderAll();

</script>

<style>
.clear {clear:both;}

</style>
{/literal}
