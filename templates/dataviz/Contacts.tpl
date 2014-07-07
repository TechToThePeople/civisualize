{if !$embedded}
{php}CRM_Utils_System::setTitle('Your Contacts');{/php}
<div id="dataviz">
</div>
{/if}
<div id="datacount" style="margin-bottom:20px;">
    <h2><strong><span class="filter-count"></span></strong> contacts selected from a total of <strong><span id="total-count"></span></strong> records</h2>
</div>
<div class="clear"></div>
<div id="type">
    <strong>Type</strong>
    <a class="reset" href="javascript:typePie.filterAll();dc.redrawAll();" style="display: none;">reset</a>
    <div class="clearfix"></div>
</div>
<div id="gender">
    <strong>Gender</strong>
    <a class="reset" href="javascript:genderPie.filterAll();dc.redrawAll();" style="display: none;">reset</a>
    <div class="clearfix"></div>
</div>
<div id="source">
    <strong>Source of Contact</strong>
    <a class="reset" href="javascript:sourceChart.filterAll();dc.redrawAll();" style="display: none;">reset</a>
    <div class="clearfix"></div>
</div>
<div id="dayofweek">
    <strong>Day - Contact Created</strong>
    <a class="reset" href="javascript:weekChart.filterAll();dc.redrawAll();" style="display: none;">reset</a>
    <div class="clearfix"></div>
</div>
<div class="clear"></div>
<div id="contacts-by-month">
    <strong>Date - Contact Created</strong>
    <a class="reset" href="javascript:monthLineChart.filterAll();dc.redrawAll();" style="display: none;">reset</a>
    <div class="clearfix"></div>
</div>

{*crmStyle ext="eu.tttp.civisualize" file="js/dc/dc.css"}
{crmScript ext="eu.tttp.civisualize" file="js/dc/dc.js"}
{crmScript ext="eu.tttp.civisualize" file="js/dc/crossfilter.js"*}
<!--script scr="{crmResURL ext="eu.tttp.civisualize"}js/dc/dc.js"></script>
<script scr="{crmResURL ext="eu.tttp.civisualize"}js/dc/crossfilter.js"></script -->


<script>
'use strict';

var data = {crmSQL file="contacts"};
{literal}

data.values.forEach(function(d) {
	console.log(d);
});

var numberFormat = d3.format(".2f");
var genderPie=null, typePie=null, sourceChart=null, monthLineChart=null, weekChart=null;
var genderLabel = {};  

cj(function($) {
	// create a pie chart under #chart-container1 element using the default global chart group

	genderLabel[1]='Male';
	genderLabel[2]='Female';
	genderLabel[3]='None';

	var dateFormat = d3.time.format("%Y-%m-%d");

	var totalContacts = 0;
	
	data.values.forEach(function(d){ totalContacts+=d.count; d.dd = dateFormat.parse(d.modified_date); if(d.source=="") d.source='None';});
	var min = d3.time.day.offset(d3.min(data.values, function(d) { return d.dd;} ),-2);
	var max = d3.time.day.offset(d3.max(data.values, function(d) { return d.dd;} ), 2);

	typePie = dc.pieChart("#type").innerRadius(10).radius(90);
	genderPie = dc.pieChart('#gender').innerRadius(10).radius(90);
	sourceChart = dc.rowChart('#source');
	monthLineChart = dc.lineChart('#contacts-by-month');
	weekChart = dc.rowChart('#dayofweek');

	var ndx  = crossfilter(data.values), all = ndx.groupAll();

	var totalCount = dc.dataCount("#datacount")
        .dimension(ndx)
        .group(all);

    document.getElementById("total-count").innerHTML=totalContacts;

	var gender = ndx.dimension(function(d){if(d.gender!="") return d.gender; else return 3;});
	var genderGroup = gender.group().reduceSum(function(d){return d.count;});

	var source = ndx.dimension(function(d){ return d.source;});
	var sourceGroup = source.group().reduceSum(function(d){return d.count;});

	var dctype        = ndx.dimension(function(d) {return d.type;});
	var dctypeGroup   = dctype.group().reduceSum(function(d) { return d.count; });

	var byMonth = ndx.dimension(function(d) { return d.dd; });
	var byMonthCount = byMonth.group().reduceSum(function(d) { return d.count; });

	var dayOfWeek = ndx.dimension(function (d) { 
		var day = d.dd.getDay(); 
		var name=["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
		return day+"."+name[day]; 
	});
	var dayOfWeekGroup = dayOfWeek.group().reduceSum(function(d){return d.count;});

	var _group   = byMonth.group().reduceSum(function(d) {return d.count;});
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

	typePie
		.width(250)
		.height(200)
		.dimension(dctype)
		.colors(d3.scale.category10())
		.group(dctypeGroup)
		.label(function(d){
			if (typePie.hasFilter() && !typePie.hasFilter(d.key))
                return d.key + "(0%)";
			return d.key+"(" + Math.floor(d.value / all.reduceSum(function(d) {return d.count;}).value() * 100) + "%)";
		})
		.renderlet(function (chart) {			
		});

	genderPie
		.width(250)
		.height(200)
		.dimension(gender)
		.colors(d3.scale.category10())
		.group(genderGroup)
		.label(function(d) {
			if (genderPie.hasFilter() && !genderPie.hasFilter(d.key))
                return genderLabel[d.key] + "(0%)";
			return genderLabel[d.key]+"(" + Math.floor(d.value / all.reduceSum(function(d) {return d.count;}).value() * 100) + "%)";;
		})
		.renderlet(function (chart) {			
		});

	sourceChart
		.width(300)
		.height(200)
		.margins({top: 20, left: 10, right: 10, bottom: 20})
		.dimension(source)
		.colors(d3.scale.category10())
		.group(sourceGroup)
		.label(function(d){
			if (sourceChart.hasFilter() && !sourceChart.hasFilter(d.key))
                return d.key + "(0%)";
			return d.key+"(" + Math.floor(d.value / all.reduceSum(function(d) {return d.count;}).value() * 100) + "%)";
		})
		.elasticX(true);

	weekChart.width(300)
		.height(200)
		.margins({top: 0, left: 10, right: 10, bottom: 20})
		.group(dayOfWeekGroup)
		.dimension(dayOfWeek)
		.ordinalColors(["#d95f02","#1b9e77","#7570b3","#e7298a","#66a61e","#e6ab02","#a6761d"])
		.label(function (d) {
			return d.key.split(".")[1];
		})
		.title(function (d) {
			return d.value;
		})
		.elasticX(true)
		.xAxis().ticks(4);

	monthLineChart
		.width(800)
		.height(200)
		.dimension(byMonth)
		.group(group)
		.x(d3.time.scale().domain([min, max]))
		.round(d3.time.day.round)
		.elasticY(true)
		.xUnits(d3.time.days);
	
	dc.renderAll();

});
{/literal}
</script>
<div class="clear"></div>