{crmTitle string="Contributions"}
<h1><span id="nbcontrib"></span> Contributions for a total of <span id="amount"></span></h1>
<div id="type" style="width:250px;">
    <strong>Contributor</strong>
    <a class="reset" href="javascript:pietype.filterAll();dc.redrawAll();" style="display: none;">reset</a>
    <div class="clearfix"></div>
</div>

<div id="instrument" style="width:250px;">
    <strong>Payment instrument</strong>
    <a class="reset" href="javascript:pieinstrument.filterAll();dc.redrawAll();" style="display: none;">reset</a>
    <div class="clearfix"></div>
</div>

<div id="day-of-week-chart">
    <strong>Day of Week</strong>
    <a class="reset" href="javascript:dayOfWeekChart.filterAll();dc.redrawAll();" style="display: none;">reset</a>
    <div class="clearfix"></div>
</div>

<div class="row clear">
    <div id="monthly-move-chart">
        <strong>Amount by month</strong>
        <span class="reset" style="display: none;">range: <span class="filter"></span></span>
        <a class="reset" href="javascript:moveChart.filterAll();volumeChart.filterAll();dc.redrawAll();"
style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>
</div>

<div id="monthly-volume-chart"></div>

<div class="clear"></div>

<script>
    'use strict';

    var data = {crmSQL file="contribution_by_date"};
    var i = {crmAPI entity="OptionValue" option_group_id="10"}; {*todo on 4.4, use the payment_instrument as id *}

    {literal}
        if(!data.is_error){
            var instrumentLabel = {};
            i.values.forEach (function(d) {
                instrumentLabel[d.value] = d.label;
            });

            var numberFormat = d3.format(".2f");
            var volumeChart=null,dayOfWeekChart=null,moveChart=null,pieinstrument,pietype;  


            cj(function($) {
                // create a pie chart under #chart-container1 element using the default global chart group
                pietype = dc.pieChart("#type").innerRadius(20).radius(90);
                pieinstrument = dc.pieChart("#instrument").innerRadius(50).radius(90);
                volumeChart = dc.barChart("#monthly-volume-chart");
                dayOfWeekChart = dc.rowChart("#day-of-week-chart");
                //var moveChart = dc.seriesChart("#monthly-move-chart");
                moveChart = dc.lineChart("#monthly-move-chart");
                var dateFormat = d3.time.format("%Y-%m-%d");
                //data.values.forEach(function(d){data.values[i].dd = new Date(d.receive_date)});

                data.values.forEach(function(d){d.dd = dateFormat.parse(d.receive_date)});
                var min = d3.min(data.values, function(d) { return d.dd;} );
                var max = d3.max(data.values, function(d) { return d.dd;} );
                var ndx                 = crossfilter(data.values),
                all = ndx.groupAll();

                var type        = ndx.dimension(function(d) {return d.contact_type;});
                var typeGroup   = type.group().reduceSum(function(d) { return d.count; });

                var instrument        = ndx.dimension(function(d) {return d.instrument;});
                var instrumentGroup   = instrument.group().reduceSum(function(d) { return d.count; });

                var byMonth     = ndx.dimension(function(d) { return d3.time.month(d.dd); });
                var byDay       = ndx.dimension(function(d) { return d.dd; });
                var volumeByMonthGroup  = byMonth.group().reduceSum(function(d) { return d.count; });
                var totalByDayGroup     = byDay.group().reduceSum(function(d) { return d.total; });

                var dayOfWeek = ndx.dimension(function (d) { 
                    var day = d.dd.getDay(); 
                    var name=["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
                    return day+"."+name[day]; 
                }); 


                var group=ndx.groupAll().reduce(
                    function(a, d) { 
                        a.total += d.total; 
                        a.count += d.count; 
                        return a;
                    },
                    function(a, d) { 
                        a.total -= d.total; 
                        a.count -= d.count; 
                        return a; 
                    },
                    function() { 
                        return {total:0, count:0};
                    }
                );

                var contribND   = dc.numberDisplay("#nbcontrib")
                    .group(group)
                    .valueAccessor(function (d) {
                    return d.count;})
                    .formatNumber(d3.format("3.3s"));

                var amountND    = dc.numberDisplay("#amount")
                    .group(group)
                    .valueAccessor(function(d) {return d.total});



                var dayOfWeekGroup = dayOfWeek.group(); 
                
                dayOfWeekChart.width(300)
                    .height(220)
                    .margins({top: 20, left: 10, right: 10, bottom: 20})
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


                pieinstrument
                    .width(200)
                    .height(200)
                    .dimension(instrument)
                    .group(instrumentGroup)
                    .title(function(d) {
                        return instrumentLabel[d.key]+":"+d.value;
                    })
                    .label(function(d) {
                        return instrumentLabel[d.key];
                    })
                    .renderlet(function (chart) {
                    });

                pietype
                    .width(200)
                    .height(200)
                    .dimension(type)
                    .colors(d3.scale.category10())
                    .group(typeGroup)
                    .renderlet(function (chart) {
                    });

                //.round(d3.time.month.round)
                //.interpolate('monotone')
                moveChart.width(850)
                    .height(200)
                    .transitionDuration(1000)
                    .margins({top: 30, right: 50, bottom: 25, left: 40})
                    .dimension(byDay)
                    .mouseZoomable(true)
                    .x(d3.time.scale().domain([min,max]))
                    .xUnits(d3.time.months)
                    .elasticY(true)
                    .renderHorizontalGridLines(true)
                    .legend(dc.legend().x(800).y(10).itemHeight(13).gap(5))
                    .brushOn(false)
                    .rangeChart(volumeChart)
                    .group(totalByDayGroup)
                    .valueAccessor(function (d) { 
                        return d.value;
                    })
                    .title(function (d) {
                        var value = d.value;
                        if (isNaN(value)) value = 0;
                        return dateFormat(d.key) + "\n" + numberFormat(value);
                    });

                volumeChart.width(850)
                    .height(200)
                    .margins({top: 0, right: 50, bottom: 20, left:40})
                    .dimension(byMonth)
                    .group(volumeByMonthGroup)
                    .centerBar(true)
                    .gap(1)
                    .x(d3.time.scale().domain([min, max]))
                    .round(d3.time.month.round)
                    .xUnits(d3.time.months);

                dc.renderAll();
                //  pietype.render();
            });//end cj
        }
        else{
            cj('.eventsoverview').html('<div style="color:red; font-size:18px;">Civisualize Error. Please contact Admin.'+data.error+'</div>');
        }
    {/literal}
</script>
<div class="clear"></div>
