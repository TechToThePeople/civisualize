{literal}
<style>
#donorBar{
	width: 100%;
}
</style>
{/literal}

{crmTitle string="Donor Trends"}
<div id="donorBar"></div>
<script>
var data={crmSQL file="donors"};
//console.log(data.values);


{literal}

var donorLine, donorRow, donorBar;

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
    var maxYear=d3.max(data.values, function(d){return d.year;});

	donorBar = dc.barChart("#donorBar");


	var byYear = ndx.dimension(function(d) {return d.year;});
	var byYearGroup = byYear.group().reduce(Add, Remove, Initial);
	var byYearGroupCount = byYear.group().reduceCount();

	var group = {
			all:function () {
				var g=[];
				var k={fresh:0, upgraded:0, downgraded:0, maintained:0};
				for(var i=minYear-1; i<=maxYear+1; i++){
					var flag=0;
					byYearGroup.all().forEach(function(d,m) {
						if(d.key==i){
							g.push({key:d.key,value:d.value});
							flag=1;
						}
					});
					if(flag==0){
						g.push({key:i, value:k});
					}
				}
				return g;
			}
		};

	print_filter(byYear);
	print_filter(byYearGroup);
//	print_filter(group);


	donorBar
		.height(200)
		.group(group,"New")
		.dimension(byYear)
		.valueAccessor(function(d) {
			return d.value.fresh;
		})
		.centerBar(true)
      	.gap(5)
      	.round(function(n) {return Math.floor(n)+0.5})
		.x(d3.scale.linear().domain([minYear-1, maxYear+1]))
		.legend(dc.legend().x(50).y(10).itemHeight(13).gap(5))
		.stack(group,"Upgraded", function(d){return d.value.upgraded;})
		.stack(group,"Downgraded", function(d){return d.value.downgraded;})
		.stack(group,"maintained", function(d){return d.value.maintained;});

	

     dc.renderAll();


});
{/literal}
</script>