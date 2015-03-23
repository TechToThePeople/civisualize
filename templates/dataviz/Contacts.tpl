{crmTitle string="Contacts Overview"}

<div class="dc_contacts" id="dataviz-contacts">
	<div id="datacount" style="margin-bottom:20px;">
	    <h2><strong><span class="filter-count"></span></strong> contacts selected from a total of <strong><span id="total-count"></span></strong> records</h2>
	</div>
	<div style="clear:both"></div>
	<div id="type" style="width:350px;">
	    <strong>Type</strong>
	    <a class="reset" href="javascript:typePie.filterAll();dc.redrawAll();" style="display: none;">reset</a>
	    <div class="clearfix"></div>
	</div>
		<div class="source">
	    <strong>Source of Contact</strong>
	    <a class="reset" href="javascript:sourceRow.filterAll();dc.redrawAll();" style="display: none;">reset</a>
	    <div class="clearfix"></div>
	</div>
	<div class="clear"></div>
	<div id="gender" style="width:350px;">
	    <strong>Gender</strong>
	    <a class="reset" href="javascript:genderPie.filterAll();dc.redrawAll();" style="display: none;">reset</a>
	    <div class="clearfix"></div>
	</div>
	<div id="dayofweek">
	    <strong>Day - Contact Created</strong>
	    <a class="reset" href="javascript:weekRow.filterAll();dc.redrawAll();" style="display: none;">reset</a>
	    <div class="clearfix"></div>
	</div>
	<div class="clear"></div>
	<div id="contacts-by-month">
	    <strong>Date - Contact Created</strong>
	    <a class="reset" href="javascript:monthLine.filterAll();dc.redrawAll();" style="display: none;">reset</a>
	    <div class="clearfix"></div>
	</div>
</div>

<script>
(function(guid){ldelim}
	'use strict';

	var data = {crmSQL file="contacts"};
	var gender = {crmAPI entity="contact" action="getoptions" field="gender_id"};

	{literal}

		if(!data.is_error){//Check for database error
			var numberFormat = d3.format(".2f");
			var genderLabel = {};

			gender.values.forEach(function(d){
				genderLabel[d.key]=d.value;
			});

			var dateFormat = d3.time.format("%Y-%m-%d");

			var genderPie=null, typePie=null, sourceRow=null, monthLine=null, weekRow=null;

			cj(function($) {
				var totalContacts = 0;

				data.values.forEach(function(d){ 
					totalContacts+=d.count;
					d.gender=genderLabel[d.gender_id];
					d.dd = dateFormat.parse(d.created_date);
					if(d.source=="")
						d.source='None';
					if(d.gender_id=="")
						d.gender='None';
				});

				// data.values.forEach(function(d) {
				// 	console.log(d);
				// });

				var min = d3.time.day.offset(d3.min(data.values, function(d) { return d.dd;} ),-2);
				var max = d3.time.day.offset(d3.max(data.values, function(d) { return d.dd;} ), 2);

				typePie 	= dc.pieChart("#type").innerRadius(10).radius(90);
				genderPie 	= dc.pieChart('#gender').innerRadius(10).radius(90);
				sourceRow 	= dc.rowChart(guid + '.source');
				monthLine 	= dc.lineChart('#contacts-by-month');
				weekRow 	= dc.rowChart('#dayofweek');

				var ndx  = crossfilter(data.values), all = ndx.groupAll();

				var totalCount = dc.dataCount("#datacount")
			        .dimension(ndx)
			        .group(all);

			    document.getElementById("total-count").innerHTML=totalContacts;

				var gender = ndx.dimension(function(d){if(d.gender!="") return d.gender; else return 3;});
				var genderGroup = gender.group().reduceSum(function(d){return d.count;});

				var source = ndx.dimension(function(d){ return d.source;});
				var sourceGroup = source.group().reduceSum(function(d){return d.count;});

				var type        = ndx.dimension(function(d) {return d.type;});
				var typeGroup   = type.group().reduceSum(function(d) { return d.count; });

				var creationMonth = ndx.dimension(function(d) { return d.dd; });
				var creationMonthGroup = creationMonth.group().reduceSum(function(d) { return d.count; });

				var creationWeek = ndx.dimension(function (d) { 
					var day = d.dd.getDay(); 
					var name=["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
					return day+"."+name[day]; 
				});

				var creationWeekGroup = creationWeek.group().reduceSum(function(d){return d.count;});
				
				var _group   = creationMonth.group().reduceSum(function(d) {return d.count;});
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
					.dimension(type)
					.colors(d3.scale.category10())
					.group(typeGroup)
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
			                return d.key + "(0%)";
						return d.key+"(" + Math.floor(d.value / all.reduceSum(function(d) {return d.count;}).value() * 100) + "%)";;
					})
					.renderlet(function (chart) {			
					});

				sourceRow
					.width(300)
					.height(200)
					.margins({top: 20, left: 10, right: 10, bottom: 20})
					.dimension(source)
					.cap(5)
          .ordering (function(d) {return d.count;})
					.colors(d3.scale.category10())
					.group(sourceGroup)
					.label(function(d){
						if (sourceRow.hasFilter() && !sourceRow.hasFilter(d.key))
			                return d.key + "(0%)";
						return d.key+"(" + Math.floor(d.value / all.reduceSum(function(d) {return d.count;}).value() * 100) + "%)";
					})
					.elasticX(true);

				weekRow
					.width(300)
					.height(200)
					.margins({top: 0, left: 10, right: 10, bottom: 20})
					.group(creationWeekGroup)
					.dimension(creationWeek)
					.ordinalColors(["#d95f02","#1b9e77","#7570b3","#e7298a","#66a61e","#e6ab02","#a6761d"])
					.label(function (d) {
						return d.key.split(".")[1];
					})
					.title(function (d) {
						return d.value;
					})
					.elasticX(true)
					.xAxis().ticks(4);

				monthLine
					.width(800)
					.height(200)
           .margins({top: 10, right: 50, bottom: 30, left: 50})
					.dimension(creationMonth)
					.group(group)
					.x(d3.time.scale().domain([min, max]))
					.round(d3.time.day.round)
					.elasticY(true)
					.xUnits(d3.time.days);
				
				dc.renderAll();

			});
		}
		else{
			cj('.dc_contacts').html('<div style="color:red; font-size:18px;">There is a database error. Please Contact the administrator as soon as possible.</div>');
		}
	{/literal}
{rdelim})("#dataviz-contacts ");
</script>
<div class="clear"></div>
