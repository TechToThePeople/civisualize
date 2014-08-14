{crmTitle string="Donor Trends"}
<div id="line"></div>
<script>
var data={crmSQL file="donors"};
//console.log(data.values);


{literal}

var lineChart;
cj(function($){

	function print_filter(filter){var f=eval(filter);if(typeof(f.length)!="undefined"){}else{}if(typeof(f.top)!="undefined"){f=f.top(Infinity);}else{}if(typeof(f.dimension)!="undefined"){f=f.dimension(function(d){return "";}).top(Infinity);}else{}console.log(filter+"("+f.length+")="+JSON.stringify(f).replace("[", "[\n\t").replace(/}\,/g, "},\n\t").replace("]", "\n]"));}

	function Add(a,d){
		var f=1, ug=0, dg=0, mtd=0; 
		data.values.forEach(function(m){
			if(m.year<d.year){
				if(m.contact_id==d.contact_id){
					if(m.year===d.year-1){
						f=0;
						if(m.total_amount==d.total_amount){
							mtd=1;
						}
						else if(m.total_amount>d.total_amount){
							dg=1;
						}
						else if((m.total_amount<d.total_amount)){
							ug=1;
						}
					}
				}
			}
		});
		a.fresh+=f;
		a.upgraded+=ug;
		a.downgraded+=dg;
		a.maintained+=mtd;
		return a;
	}

	function Remove(a, d) {
		var f=1, ug=0, dg=0, mtd=0; 
		data.values.forEach(function(m){
			if(m.year!=d.year){
				if(m.contact_id==d.contact_id){
					if(m.year<d.year){
						f=0;
					}
					if(m.year===d.year-1){
						if(m.total_amount==d.total_amount){
							mtd=1;
						}
						else if(m.total_amount>d.total_amount){
							dg=1;
						}
						else if(m.total_amount<d.total_amount){
							ug=1;
						}
					}
				}
			}
		});
		a.fresh-=f;
		a.upgraded-=ug;
		a.downgraded-=dg;
		a.maintained-=mtd;
		return a;
	}

	function Initial() {
		return { fresh:0, upgraded:0, downgraded:0, maintained:0};
	}


	var ndx                 = crossfilter(data.values),
    all = ndx.groupAll();

    var minYear=d3.min(data.values, function(d){return d.year;});
    var maxYear=d3.min(data.values, function(d){return d.year;});

	lineChart = dc.lineChart("#line");

	var byYear = ndx.dimension(function(d) {return d.year;});
	var byYearGroup = byYear.group().reduce(Add, Remove, Initial);

	print_filter(byYear);
	print_filter(byYearGroup);

	lineChart
		.margins({top: 0, right: 50, bottom: 20, left:40})
      	.height(200)
      	.width(800)
		.group(byYearGroup)
		.dimension(byYear)
		.valueAccessor(function(d) {return d.fresh;})
		.x(d3.scale.linear().domain([minYear, maxYear]))
      	.elasticY(true);


    dc.renderAll();


});
{/literal}
</script>