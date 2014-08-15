{crmTitle string="Events Overview"}

<div class="eventsoverview">
        <div style="font-size:20px; float:left; width:100%; text-align:center; height:90px;">
        <span id="pastevents"></span>, 
        <span id="currentevents"></span> and 
        <span id="upcomingevents"></span>
        with a total of <span id="nparticipants" style="color:steelblue; font-size:50px; line-height:80px"></span> Participants.
    </div>

    <div id="events" style="width:100%;">
        <strong>Events</strong>
        <a class="reset" href="javascript:barEvents.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>
    
    <div id="participants" style="width:100%;">
        <strong>Participants</strong>
        <a class="reset" href="javascript:lineParticipants.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>

    <div class="clear">

    <div id="type">
        <strong>Type</strong>
        <a class="reset" href="javascript:pieType.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>

    <div id="duration">
        <strong>Day of Week</strong>
        <a class="reset" href="javascript:dayofweekRow.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>

    <div id="ismonetory">
        <strong>Is Monetory</strong>
        <a class="reset" href="javascript:pieMonetory.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>

    <div class="clear"></div>
    <table id="dc-data-table">
        <thead>
            <tr class="header">
                <th>Event Name</th>
                <th>Start Date</th>
                <th>End Date</th>
                <th>Participants</th>
            </tr>
        </thead>
    </table>
    <div class="clear"></div>
</div>

<script>
    'use strict';

    var data = {crmSQL file="events"};
    var i = {crmAPI entity="OptionValue" option_group_id="14"}; {*todo on 4.4, use the event-type as id *}
    var s = {crmAPI entity='ParticipantStatusType' option_sort="is_counted desc"};

    {literal}
        if(!data.is_error){

            var statusLabel = {};
            s.values.forEach (function(d) {
                statusLabel[d.id] = d.label;
            });
            s=null;

            var typeLabel = {};
            i.values.forEach (function(d) {
                typeLabel[d.value] = d.label;
            });
            i=null;

            var numberFormat = d3.format(".2f");
            var datetimeFormat = d3.time.format("%Y-%m-%d %H:%M:%S");
            var dateFormat = d3.time.format("%Y-%m-%d");
            var currentDate = new Date();

            var Events={};

            data.values.forEach(function(d){
                d.rd = dateFormat.parse(d.rd);
                d.ed = datetimeFormat.parse(d.ed);
                d.sd = datetimeFormat.parse(d.sd);
                if(d.im==1)
                    d.im='Monetory';
                else
                    d.im='Free';
                if(d.tid!="")
                    d.tid = typeLabel[d.tid];  
                else
                    d.tid = "Unspecified";
                Events[d.id]={'title':d.title,'sd':d.sd,'ed':d.ed};
            });

            var barEvents, numberUpcomingEvents, numberPastEvents, lineParticipants, pieType, dayofweekRow, pieEventStatus, pdurationRow, pieMonetory, dataTable;

            cj(function($) {

                function print_filter(filter){var f=eval(filter);if(typeof(f.length)!="undefined"){}else{}if(typeof(f.top)!="undefined"){f=f.top(Infinity);}else{}if(typeof(f.dimension)!="undefined"){f=f.dimension(function(d){return "";}).top(Infinity);}else{}console.log(filter+"("+f.length+")="+JSON.stringify(f).replace("[", "[\n\t").replace(/}\,/g, "},\n\t").replace("]", "\n]"));}

                function eventReduceAdd(a,d){
                    if(!a.events[d.id]){
                        a.events[d.id]=d.count;
                        a.eventcount++;
                    }
                    else{
                        a.events[d.id]+=d.count;
                    }
                    a.participantcount+=d.count;
                    return a;
                }

                function eventReduceRemove(a, d) {
                    a.events[d.id]-=d.count;
                    if(a.events[d.id]==0){
                        a.eventcount--;
                    }
                    a.participantcount-=d.count;
                    return a;
                }

                function eventReduceInitial() {
                    var eventlist = {}
                    Object.keys(Events).forEach(function(a){
                        eventlist[a]=0;
                    });
                    return {events:eventlist, eventcount:0, participantcount:0};
                }

                var min = d3.time.month.offset(d3.min(data.values, function(d) { return d.rd;} ),-1);
                var max = d3.time.month.offset(d3.max(data.values, function(d) { return d.ed;} ), 1);


                var ndx                 = crossfilter(data.values),
                all = ndx.groupAll();

                barEvents = dc.barChart("#events");
                lineParticipants = dc.lineChart("#participants");
                pieType = dc.pieChart("#type").innerRadius(0).radius(90);
                dayofweekRow = dc.rowChart("#duration");
                dataTable = dc.dataTable("#dc-data-table");
                pieMonetory = dc.pieChart("#ismonetory").innerRadius(20).radius(70);

                var byMonth = ndx.dimension(function(d) { return d3.time.month(d.sd);});
                var eventsByMonth = byMonth.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);
                var RByMonth = ndx.dimension(function(d) { return d3.time.month(d.rd);});
                var RegistrationByMonth = RByMonth.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

                var typeE        = ndx.dimension(function(d) {return d.tid; });
                var typeEGroup   = typeE.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

                var dayOfWeek = ndx.dimension(function (d) {
                var day = d.sd.getDay();
                    switch (day) {
                        case 0:
                        return "Sunday";
                        case 1:
                        return "Monday";
                        case 2:
                        return "Tuesday";
                        case 3:
                        return "Wednesday";
                        case 4:
                        return "Thursday";
                        case 5:
                        return "Friday";
                        case 6:
                        return "Saturday";
                    }
                });
                var dayOfWeekGroup = dayOfWeek.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

                var monetory = ndx.dimension(function(d){ return d.im; });
                var monetoryGroup = monetory.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

                var list = ndx.dimension(function(d){return d.id});
                var listGroup = list.group().reduceSum(function(d){return d.count});

                var pseudoList = {
                    top: function (x) {
                    return listGroup.top(x)
                    .map(function (d) { return {"id":d.key, "count":d.value, "title":Events[d.key].title, "sd":Events[d.key].sd, "ed":Events[d.key].ed}; });
                    }
                };

                var event_status = ndx.dimension(function(d)
                {
                    if(d.sd>currentDate)
                        return "Upcoming Event";
                    if(d.ed>currentDate)
                        return "Ongoing Event";
                    return "Past Event";
                });

                var eventstatus_group = event_status.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

                function statusevent(status){
                    return {
                        value:function(){
                            var v = {'value':0};
                            eventstatus_group.all().forEach(function(d,i){
                                if (d.key == status) 
                                    {v.value=d.value.eventcount;}
                            });
                            return v;
                        }
                    };
                }

                var grouped=ndx.groupAll().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

                var eventsN = dc.numberDisplay("#nevents")
                    .group(grouped)
                    .formatNumber(d3.format("d"))
                    .valueAccessor(function(d) {return d.eventcount;});

                var participantsN = dc.numberDisplay("#nparticipants")
                    .group(grouped)
                    .valueAccessor(function(d) {return d.participantcount});

                var numberPastEvents = dc.numberDisplay('#pastevents')
                    .dimension(event_status)
                    .html({some:"<span style='color:steelblue; font-size:50px; line-height:80px'>%number</span> past events",one:"<span style=\"color:steelblue; font-size:50px; line-height:80px\">%number</span> past event", none:"no past events"})
                    .group(statusevent('Past Event'))
                    .formatNumber(d3.format("d"));

                var numberUpcomingEvents = dc.numberDisplay('#upcomingevents')
                    .dimension(event_status)
                    .html({some:"<span style=\"color:steelblue; font-size:50px; line-height:80px\">%number</span> upcoming events",one:"<span style=\"color:steelblue; font-size:50px; line-height:80px\">%number</span> upcoming event", none:"no upcoming events"})
                    .group(statusevent('Upcoming Event'))
                    .formatNumber(d3.format("d"));

                var numberOngoingEvents = dc.numberDisplay('#currentevents')
                    .dimension(event_status)
                    .html({some:"<div style=\"color:steelblue; font-size:50px; line-height:80px\">%number</div> ongoing events",one:"<span style=\"color:steelblue; font-size:50px; line-height:80px\">%number</span> ongoing event", none:"no ongoing events"})
                    .group(statusevent('Ongoing Event'))
                    .formatNumber(d3.format("d"));


                //Events
                barEvents
                    .height(200)
                    .margins({top: 0, right: 50, bottom: 20, left:40})
                    .dimension(byMonth)
                    .group(eventsByMonth)
                    .centerBar(true)
                    .gap(1)
                    .x(d3.time.scale().domain([min, max]))
                    .round(d3.time.month.round)
                    .valueAccessor(function (d) {
                    return d.value.eventcount;
                    })
                    .xUnits(d3.time.months);

                lineParticipants
                    .margins({top: 0, right: 50, bottom: 20, left:40})
                    .height(200)
                    .dimension(RByMonth)
                    .valueAccessor(function (d) {
                    return d.value.events['1'];
                    })
                    .brushOn(false)
                    .x(d3.time.scale().domain([min, max]))
                    .round(d3.time.month.round)
                    .elasticY(true)
                    .xUnits(d3.time.months);

                var flag=1;

                Object.keys(Events).forEach(function(a){
                    if(flag==1){
                        lineParticipants
                            .group(RegistrationByMonth);
                            flag=2;
                    }   
                    else{
                        lineParticipants
                            .stack(RegistrationByMonth,Events[a],function(d){return d.value.events[a];})
                            .title(Events[a], function(d) { 
                                return Events[a]+" "+d.value.events[a]; 
                            });
                    }
                });

                pieType
                    .width(200)
                    .height(200)
                    .dimension(typeE)
                    .group(typeEGroup)
                    .valueAccessor(function (d) {
                        return d.value.eventcount;
                    })
                    .legend(dc.legend().x(200).y(10).itemHeight(13).gap(5))
                    .renderlet(function(chart){});

                dayofweekRow
                    .width(300)
                    .height(200)
                    .dimension(dayOfWeek)
                    .group(dayOfWeekGroup)
                    .valueAccessor(function (d) {
                        return d.value.eventcount;
                    })
                    .xAxis().ticks(1);

                pieMonetory
                    .width(200)
                    .height(200)
                    .dimension(monetory)
                    .group(monetoryGroup)
                    .valueAccessor(function(d){
                        return d.value.eventcount;
                    })
                    .renderlet(function(chart){});

                dataTable
                    .dimension(pseudoList)
                    .group(function(d) {
                        return d.sd.getFullYear();
                    })
                    // dynamic columns creation using an array of closures
                    .columns([
                        function(d) {return "<a href='event/"+d.id+"'>"+d.title+"</a>"; },
                        function(d) {return d.sd.getDate()+"/"+(d.sd.getMonth()+1)+"/"+d.sd.getFullYear();},
                        function(d) {return d.ed.getDate()+"/"+(d.ed.getMonth()+1)+"/"+d.ed.getFullYear();},
                        function(d) {return d.count;}
                    ])
                    .sortBy(function (d) {
                    return d.sd;
                    });

                dc.renderAll();
            });
        }
        else{
            cj('.eventsoverview').html('<div style="color:red; font-size:18px;">Civisualize Error. Please contact Admin.'+data.error+'</div>')
        }
    {/literal}
</script>
<div class="clear"></div>
