{*crmScript ext=eu.tttp.civisualize file=bar.js*}
<script>
var data={crmAPI entity="tag" action="getstat"};
{literal}
cj(function($) {

d3.selectAll("#dataviz").append("ul").attr("id","data-list")
  .selectAll(".data-item")
  .data(data.values)
  .enter()
    .append("li")
    .attr("id",function(d){return "tag-"+d.id;})
    .html(function(d){return d.name});

d3.selectAll("#dataviz").append("table").attr("id","data-list")
  .selectAll(".data-item")
  .data(data.values)
  .enter()
    .append("tr")
      .attr("id",function(d){return "tag-"+d.id;})
      .call(function(tr){
       console.log(tr.data());
        tr.data().forEach(function(td,i) {
console.log(i); 
console.log(td); 
          tr.append("td").text(td[i]);
        });
         
       });

 

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


});
{/literal}
</script>
<div id="dataviz"></div>
