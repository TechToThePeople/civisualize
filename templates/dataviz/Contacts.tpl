{if !$embedded}
{php}CRM_Utils_System::setTitle('Your Contacts');{/php}
<div id="dataviz">
</div>
{/if}

<div id="type">
    <strong>Type</strong>
    <a class="reset" href="javascript:pietype.filterAll();dc.redrawAll();" style="display: none;">reset</a>
    <div class="clearfix"></div>
</div>
<div id="gender">
    <strong>Gender</strong>
    <a class="reset" href="javascript:piegender.filterAll();dc.redrawAll();" style="display: none;">reset</a>
    <div class="clearfix"></div>
</div>
<div class="clear"></div>
<div id="contacts-by-month">
    <strong>Contacts By Month</strong>
    <a class="reset" href="javascript:contactlinechart.filterAll();dc.redrawAll();" style="display: none;">reset</a>
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
var piegender, pietype, contactlinechart;
var genderLabel = {};  

cj(function($) {
	// create a pie chart under #chart-container1 element using the default global chart group

	genderLabel[1]='Male';
	genderLabel[2]='Female';
	genderLabel[3]='None';

	var dateFormat = d3.time.format("%Y-%m-%d");
	data.values.forEach(function(d){d.dd = dateFormat.parse(d.modified_date)});
	var min = d3.time.day.offset(d3.min(data.values, function(d) { return d.dd;} ),-2);
	var max = d3.time.day.offset(d3.max(data.values, function(d) { return d.dd;} ), 2);

	pietype = dc.pieChart("#type").innerRadius(10).radius(110);
	piegender = dc.pieChart('#gender').innerRadius(10).radius(110);
	contactlinechart = dc.lineChart('#contacts-by-month');

	var ndx  = crossfilter(data.values), all = ndx.groupAll();

	var gender = ndx.dimension(function(d){if(d.gender!="") return d.gender; else return 3;});
	var genderGroup = gender.group().reduceSum(function(d){return d.count;});

	var dctype        = ndx.dimension(function(d) {return d.type;});
	var dctypeGroup   = dctype.group().reduceSum(function(d) { return d.count; });

	var byMonth = ndx.dimension(function(d) { return d.dd; });
	var byMonthCount = byMonth.group().reduceSum(function(d) { return d.count; });

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

	pietype
		.width(250)
		.height(250)
		.dimension(dctype)
		.colors(d3.scale.category10())
		.group(dctypeGroup)
		.renderlet(function (chart) {			
		});

	piegender
		.width(250)
		.height(250)
		.dimension(gender)
		.colors(d3.scale.category10())
		.group(genderGroup)
		.label(function(d) {
			return genderLabel[d.key];
		})
		.renderlet(function (chart) {			
		});

	contactlinechart
		.width(800)
		.height(200)
		.dimension(byMonth)
		.group(group)
		.x(d3.time.scale().domain([min, max]))
		.round(d3.time.day.round)
		.xUnits(d3.time.days);
	
	dc.renderAll();

});
{/literal}
</script>
<div class="clear"></div>