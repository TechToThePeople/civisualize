<div id="dataviz">
</div>

<script>
(function () {ldelim}
var types = {crmAPI entity="contact" action="getstat" return="contact_type"};
var groups = {crmAPI entity="group_contact" action="getstat"};

{literal}
drawType(types);
drawGroup(groups.values);

function drawType(types) {
  var width = 300,
      height = 300,
      radius = Math.min(width, height) / 2;

  var color = d3.scale.ordinal()
      .range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"]);

  var arc = d3.svg.arc()
      .outerRadius(radius - 10)
      .innerRadius(radius - 60);

  var pie = d3.layout.pie()
      .sort(null)
      .value(function(d) { return d.total; });

  var svg = d3.select("#dataviz").append("svg")
      .attr("width", width*2)
      .attr("height", height);

  var g= svg.append("g")
      .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");

  var legend= d3.selectAll("#dataviz").append("ul")
      .attr("id","legend")
      .selectAll(".legendLine")
        .data(types.values)
        .enter()
        .append("li")
          .attr("class","legendLine")
          .style("background-color", function(d) { return color(d.contact_type); })
          .html(function(d) { return d.contact_type; });
    
    var a = g.selectAll(".arc")
        .data(pie(types.values))
      .enter()
        .append("path")
        .attr("d", arc)
        .attr("class", "arc")
        .style("fill", function(d) { return color(d.data.contact_type); })
  /*
        .append("text")
        .attr("transform", function(d) { return "translate(" + arc.centroid(d) + ")"; })
        .attr("dy", ".35em")
        .style("text-anchor", "middle")
        .text(function(d) { return d.data.contact_type; });
  */

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
}

function drawGroup (data) {
console.log(data);
  var valueLabelWidth = 40; // space reserved for value labels (right)
  var barHeight = 20; // height of one bar
  var barLabelWidth = 200; // space reserved for bar labels
  var barLabelPadding = 5; // padding between bar and bar labels (left)
  var gridLabelHeight = 18; // space reserved for gridline labels
  var gridChartOffset = 3; // space between start of grid and first bar
  var maxBarWidth = 420; // width of the bar with the max value
   
  var barLabel = function(d) { return d.name; };
  var barValue = function(d) { return parseFloat(d.total) };
  
// scales
  var yScale = d3.scale.ordinal().domain(d3.range(0, data.length)).rangeBands([0, data.length * barHeight]);
  var y = function(d, i) { return yScale(i); };
  var yText = function(d, i) { return y(d, i) + yScale.rangeBand() / 2; };
  var x = d3.scale.linear().domain([0, d3.max(data, barValue)]).range([0, maxBarWidth]);

  var chart = d3.select('#dataviz').append("svg")
    .attr('width', maxBarWidth + barLabelWidth + valueLabelWidth)
    .attr('height', gridLabelHeight + gridChartOffset + data.length * barHeight);
  // grid line labels
  var gridContainer = chart.append('g')
    .attr('transform', 'translate(' + barLabelWidth + ',' + gridLabelHeight + ')'); 
  gridContainer.selectAll("text").data(x.ticks(10)).enter().append("text")
    .attr("x", x)
    .attr("dy", -3)
    .attr("text-anchor", "middle")
    .text(String);
  // vertical grid lines
  gridContainer.selectAll("line").data(x.ticks(10)).enter().append("line")
    .attr("x1", x)
    .attr("x2", x)
    .attr("y1", 0)
    .attr("y2", yScale.rangeExtent()[1] + gridChartOffset)
    .style("stroke", "#ccc");
  // bar labels
  var labelsContainer = chart.append('g')
    .attr('transform', 'translate(' + (barLabelWidth - barLabelPadding) + ',' + (gridLabelHeight + gridChartOffset) + ')'); 
  labelsContainer.selectAll('text').data(data).enter().append('text')
    .attr('y', yText)
    .attr('stroke', 'none')
    .attr('fill', 'black')
    .attr("dy", ".35em") // vertical-align: middle
    .attr('text-anchor', 'end')
    .text(barLabel);
  // bars
  var barsContainer = chart.append('g')
    .attr('transform', 'translate(' + barLabelWidth + ',' + (gridLabelHeight + gridChartOffset) + ')'); 
  barsContainer.selectAll("rect").data(data).enter().append("rect")
    .attr('y', y)
    .attr('height', yScale.rangeBand())
    .attr('width', function(d) { return x(barValue(d)); })
    .attr('stroke', 'white')
    .attr('fill', 'steelblue');
  // bar value labels
  barsContainer.selectAll("text").data(data).enter().append("text")
    .attr("x", function(d) { return x(barValue(d)); })
    .attr("y", yText)
    .attr("dx", 3) // padding-left
    .attr("dy", ".35em") // vertical-align: middle
    .attr("text-anchor", "start") // text-align: right
    .attr("fill", "black")
    .attr("stroke", "none")
    .text(function(d) { return d3.round(barValue(d), 2); });
  // start line
  barsContainer.append("line")
    .attr("y1", -gridChartOffset)
    .attr("y2", yScale.rangeExtent()[1] + gridChartOffset)
    .style("stroke", "#000");
}

}());
</script>

<style>

#dataviz {position:relative;}
#legend {   
  position: absolute;           
  width: 120px;   
  left:300px;
  top:40px;                                
  padding: 2px;             
  font: 12px sans-serif;        
  background: #eee;   
  border: 0px;      
  border-radius: 5px;           
  pointer-events: none;         
  border: 1px solid rgba(0,0,0,.2);
  z-index: 10000;

  transition: opacity 500ms linear;
  -moz-transition: opacity 500ms linear;
  -webkit-transition: opacity 500ms linear;

  transition-delay: 500ms;
  -moz-transition-delay: 500ms;
  -webkit-transition-delay: 500ms;

  -moz-box-shadow: 0 5px 10px rgba(0,0,0,.2);
  -webkit-box-shadow: 0 5px 10px rgba(0,0,0,.2);
  box-shadow: 0 5px 10px rgba(0,0,0,.2);

  -webkit-touch-callout: none;
  -webkit-user-select: none;
  -khtml-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

#legend li {
margin:0 0 5px 0;
padding:10px 10px 10px 10px;
list-style:none;
color:white;
border-radius: 5px;           
  text-align: center;           
}

#legend ul {
  padding:5px 0 0 0;
  margin:0;
}

</style>
{/literal}

