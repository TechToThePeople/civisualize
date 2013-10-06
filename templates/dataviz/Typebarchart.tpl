{*<script src="{$config->extensionsURL}/eu.tttp.datavisualization/js/barchart.js" />*}
<div id="dataviz">
</div>
<script>

var types = {crmAPI entity="contact" action="getstat" return="contact_type"};

{literal}
var width = 500,
    height = 500,
    radius = Math.min(width, height) / 2;

var color = d3.scale.ordinal()
    .range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"]);

var arc = d3.svg.arc()
    .outerRadius(radius - 10)
    .innerRadius(radius - 100);

var startpie = d3.layout.pie()
    .sort(null)
    .value(function(d) { return 100; });

var pie = d3.layout.pie()
    .sort(null)
    .value(function(d) { return d.total; });

var svg = d3.select("#dataviz").append("svg")
    .attr("width", width)
    .attr("height", height);

var g= d3.select("svg").append("g")
    .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");


  var a = g.selectAll(".arc")
      .data(pie(types.values))
    .enter().append("g")
      .attr("class", "arc");

  a.append("path")
      .attr("d", arc)
      .style("fill", function(d) { return color(d.data.contact_type); });

  a.append("text")
      .attr("transform", function(d) { return "translate(" + arc.centroid(d) + ")"; })
      .attr("dy", ".35em")
      .style("text-anchor", "middle")
      .text(function(d) { return d.data.contact_type; });

//    pie.value(function(d) { return d.total; }); 
//    g.transition().duration(750).attrTween("d", arcTween); 

  g.append("text")
    .attr("class","total")
    .style("text-anchor", "middle")
    .attr("font-size","10px")
    .text(function(d) { 
      var t=0; 
      types.values.forEach(function (e){ 
        t = t+parseFloat(e.total);});
        return t;
    })
    .transition()
    .duration(function (){return 2000;})
      .attr("font-size","40px");

{/literal}

</script>
