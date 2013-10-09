{*crmScript ext=eu.tttp.civisualize file=bar.js*}
<div id="dataviz"></div>
<script>
var data={crmAPI entity="tag" action="getstat"};
{literal}

var nesta =function (data) {
  var nest = d3.nest()
    .key(function(d) { 
console.log(d);
//      if (!d.parent_id) 
//        return 0;
      return d.parent_id; })
    .entries(data);
console.log(nest);
};

//nesta(data.values);



var drawTable = (function(data) {
/*d3.selectAll("#dataviz").append("ul").attr("id","data-list")
  .selectAll(".data-item")
  .data(data.values)
  .enter()
    .append("li")
    .attr("id",function(d){return "tag-"+d.id;})
    .html(function(d){return d.name});
*/

  var columns = d3.keys(data[0]);

var table = d3.selectAll("#dataviz").append("table").attr("id","data-list")
      ,thead = table.append("thead")
      ,tbody = table.append("tbody");

    // append the header row
 thead.append("tr")
   .selectAll("th")
   .data(columns)
   .enter()
   .append("th")
     .text(function(column) { return column; });

  
var tr= tbody.selectAll("tr")  
  .data(data)
  .enter()
    .append("tr")
    .attr("id",function(d){return "tag-"+d.id;})

tr.selectAll("td")
  .data(function(row) {
    return columns.map(function(column) { return row[column]})})
  .enter()
  .append("td")
    .text(function(d) {return d});

});
  
drawTable(data.values);

function drawBubble() {
var diameter = 960,
    format = d3.format(",d"),
    color = d3.scale.category20c();

var bubble = d3.layout.pack()
    .sort(null)
    .size([diameter, diameter])
    .padding(1.5);

var svg = d3.select("body").append("svg")
    .attr("width", diameter)
    .attr("height", diameter)
    .attr("class", "bubble");

  var node = svg.selectAll(".node")
      .data(bubble.nodes(data.values))
    .enter().append("g")
      .attr("class", "node")
      .attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });

  node.append("title")
      .text(function(d) { return d.name; });

  node.append("circle")
      .attr("r", function(d) { return d.r; })
      .style("fill", function(d) { return color(d.packageName); });

  node.append("text")
      .attr("dy", ".3em")
      .style("text-anchor", "middle")
      .text(function(d) { return d.name.substring(0, d.r / 3); });


};

{/literal}
</script>
