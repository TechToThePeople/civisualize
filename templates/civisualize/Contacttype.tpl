{if !$embedded}
{php}CRM_Utils_System::setTitle('What type are your contacts?');{/php}
<div id="dataviz">
</div>
{/if}


<script>
(function (name,options) {ldelim}
var types = {crmAPI entity="contact" action="getstat" return="contact_type"};

  drawPie(types,options);

{literal}
function drawPie(types,options) {
  options = options || {};
  width = options.width || 300;
  height = options.height || width;
  }

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
      .style("left", (width+10)+"px")
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
        .attr("font-size", (width /10) +"px");

  if (name) {
    window[name]=this;
  }
{/literal}
}("{$name}",{$options|@json_encode}));
</script>

<style>
{literal}

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

