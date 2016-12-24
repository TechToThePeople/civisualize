{crmTitle string="Mailing details"}

<a class="reset" href="javascript:sourceRow.filterAll();dc.redrawAll();" style="display: none;">reset</a>

<div class="row">
<div id="open" class="col-md-12"><h3>Date Open</h3><div class="graph"></div><div class="avg"></div></div>
</div>

<div class="row">
</div>

<script>
var data = {crmSQL json="mailing_open" mailing_id=$id};
var dateFormat = d3.time.format("%Y-%m-%d %H:%M");
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

function drawOpen (dom) {
  var dim = ndx.dimension(function(d){return d.date});
  //var group = dim.group().reduceSum(function(d){return 1;});
  var _group = dim.group().reduceSum(function(d){return d.count;});

  var group = {
    all:function () {
     var cumulate = 0;
     var g = [];
     _group.all().forEach(function(d,i) {
       cumulate += d.value;
       g.push({key:d.key,value:cumulate})
     });
     return g;
    }
  }; 
  var graph=dc.lineChart(dom)
   .margins({top: 10, right: 10, bottom: 20, left:50})
    .height(200)
    .dimension(dim)
    .renderArea(true)
    .group(group)
    .brushOn(false)
    .x(d3.time.scale().domain(d3.extent(dim.top(2000), function(d) { return d.date; })))
    //.round(d3.time.day.round)
    .elasticY(true)
    .xUnits(d3.time.days);

   graph.yAxis().ticks(5);
   graph.xAxis().ticks(12);
  return graph;
}


drawOpen("#open .graph");

dc.renderAll();

</script>

<style>
.clear {clear:both;}

</style>
{/literal}
