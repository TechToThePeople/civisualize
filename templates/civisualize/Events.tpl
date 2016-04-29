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
        <a class="reset" href="javascript:eventsBar.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>
    
    <div id="participants" style="width:100%;">
        <strong>Participants</strong>
        <a class="reset" href="javascript:participantsLine.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>

    <div class="clear">

    <div id="type">
        <strong>Type</strong>
        <a class="reset" href="javascript:typePie.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>

    <div id="duration">
        <strong>Day of Week</strong>
        <a class="reset" href="javascript:startdayRow.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>

    <div id="ismonetory">
        <strong>Is Monetory</strong>
        <a class="reset" href="javascript:monetoryPie.filterAll();dc.redrawAll();" style="display: none;">reset</a>
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
    var URL = "{crmURL p='civicrm/dataviz/event/xx'}";
    console.log(URL);

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

            console.log(data.values);

            var eventsBar, upcomingNumber, pastNumber, participantsLine, typePie, startdayRow, eventStatusPie, monetoryPie, dataTable;

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

                var firstEvent = d3.min(data.values, function(d) {return d.id});


                var ndx                 = crossfilter(data.values),
                all = ndx.groupAll();

                eventsBar = dc.barChart("#events");
                participantsLine = dc.lineChart("#participants");
                typePie = dc.pieChart("#type").innerRadius(0).radius(90);
                startdayRow = dc.rowChart("#duration");
                dataTable = dc.dataTable("#dc-data-table");
                monetoryPie = dc.pieChart("#ismonetory").innerRadius(20).radius(70);

                var startMonth = ndx.dimension(function(d) { return d3.time.month(d.sd);});
                var startMonthGroup = startMonth.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);
                
                var registrationMonth = ndx.dimension(function(d) { return d3.time.month(d.rd);});
                var registrationMonthGroup = registrationMonth.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);



                var type        = ndx.dimension(function(d) {return d.tid; });
                var typeGroup   = type.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

                var startDay = ndx.dimension(function (d) {
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
                var startDayGroup = startDay.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

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

                var eventStatus = ndx.dimension(function(d)
                {
                    if(d.sd>currentDate)
                        return "Upcoming Event";
                    if(d.ed>currentDate)
                        return "Ongoing Event";
                    return "Past Event";
                });

                var eventStatusGroup = eventStatus.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

                function statusevent(status){
                    return {
                        value:function(){
                            var v = {'value':0};
                            eventStatusGroup.all().forEach(function(d,i){
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

                var pastNumber = dc.numberDisplay('#pastevents')
                    .dimension(eventStatus)
                    .html({some:"<span style='color:steelblue; font-size:50px; line-height:80px'>%number</span> past events",one:"<span style=\"color:steelblue; font-size:50px; line-height:80px\">%number</span> past event", none:"no past events"})
                    .group(statusevent('Past Event'))
                    .formatNumber(d3.format("d"));

                var upcomingNumber = dc.numberDisplay('#upcomingevents')
                    .dimension(eventStatus)
                    .html({some:"<span style=\"color:steelblue; font-size:50px; line-height:80px\">%number</span> upcoming events",one:"<span style=\"color:steelblue; font-size:50px; line-height:80px\">%number</span> upcoming event", none:"no upcoming events"})
                    .group(statusevent('Upcoming Event'))
                    .formatNumber(d3.format("d"));

                var ongoingNumber = dc.numberDisplay('#currentevents')
                    .dimension(eventStatus)
                    .html({some:"<div style=\"color:steelblue; font-size:50px; line-height:80px\">%number</div> ongoing events",one:"<span style=\"color:steelblue; font-size:50px; line-height:80px\">%number</span> ongoing event", none:"no ongoing events"})
                    .group(statusevent('Ongoing Event'))
                    .formatNumber(d3.format("d"));


                //Events
                eventsBar
                    .height(200)
                    .margins({top: 0, right: 50, bottom: 20, left:40})
                    .dimension(startMonth)
                    .group(startMonthGroup)
                    .centerBar(true)
                    .gap(1)
                    .x(d3.time.scale().domain([min, max]))
                    .round(d3.time.month.round)
                    .valueAccessor(function (d) {
                        return d.value.eventcount;
                    })
                    .xUnits(d3.time.months);

                participantsLine
                    .margins({top: 0, right: 50, bottom: 20, left:40})
                    .height(200)
                    .dimension(registrationMonth)
                    .valueAccessor(function (d) {
                        return d.value.events[firstEvent];
                    })
                    .brushOn(false)
                    .x(d3.time.scale().domain([min, max]))
                    .round(d3.time.month.round)
                    .elasticY(true)
                    .elasticX(true)
                    .xUnits(d3.time.months);

                var flag=1;

                Object.keys(Events).forEach(function(a){
                    if(flag==1){
                        participantsLine
                            .group(registrationMonthGroup);
                            flag=2;
                    }   
                    else{
                        if(a!=firstEvent){
                            participantsLine
                                .stack(registrationMonthGroup,Events[a],function(d){return d.value.events[a];})
                                .title(Events[a], function(d) { 
                                    return Events[a]+" "+d.value.events[a]; 
                                });
                        }
                    }
                });

                typePie
                    .width(200)
                    .height(200)
                    .dimension(type)
                    .group(typeGroup)
                    .valueAccessor(function (d) {
                        return d.value.eventcount;
                    })
                    .legend(dc.legend().x(200).y(10).itemHeight(13).gap(5))
                    .renderlet(function(chart){});

                startdayRow
                    .width(300)
                    .height(200)
                    .dimension(startDay)
                    .group(startDayGroup)
                    .valueAccessor(function (d) {
                        return d.value.eventcount;
                    })
                    .xAxis().ticks(1);

                monetoryPie
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
                    .size(9999)
                    .order(d3.descending)
                    .columns([
                        function(d) {return "<a href='"+URL.replace('xx',d.id)+"'>"+d.title+"</a>"; },
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
