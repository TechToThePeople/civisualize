{if $id}
<!-- For Type of Events. Not used it yet -->
{/if}
{php}CRM_Utils_System::setTitle('Events');{/php}

<div style="font-size:20px; float:left; width:100%; text-align:center; height:90px;">
<span id="pastevents" style="color:steelblue; font-size:50px; line-height:80px"></span> <span id="isPast"></span><span id="isboth"></span><span id="upcomingevents" style="color:steelblue; font-size:50px; line-height:80px"></span> <span id="isUpcoming"></span> with a total of <span id="nparticipants" style="color:steelblue; font-size:50px; line-height:80px"></span> Participants.
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
  <strong>Duration of Event</strong>
  <a class="reset" href="javascript:durationRow.filterAll();dc.redrawAll();" style="display: none;">reset</a>
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
<!-- <h1>The graph below are still in development</h1>





<div id="eventstatus">
  <strong>Event Status</strong>
  <a class="reset" href="javascript:pieEventStatus.filterAll();dc.redrawAll();" style="display: none;">reset</a>
  <div class="clearfix"></div>  
</div>
<div class="clear"></div>
<h3>Participants</h3>

<div id="ptype">
  <strong>Participants by Type</strong>
  <a class="reset" href="javascript:piePType.filterAll();dc.redrawAll();" style="display: none;">reset</a>
  <div class="clearfix"></div>  
</div>
<div id="pduration">
  <strong>Participants by Duration</strong>
  <a class="reset" href="javascript:pdurationRow.filterAll();dc.redrawAll();" style="display: none;">reset</a>
  <div class="clearfix"></div>  
</div>
<div id="status">
  <strong>Participants Status</strong>
  <a class="reset" href="javascript:pieStatus.filterAll();dc.redrawAll();" style="display: none;">reset</a>
  <div class="clearfix"></div>  
</div>
<div class="clear"></div>
 -->
<script>
'use strict';

//console.log({$id});
var data = {crmSQL file="events"};
var i = {crmAPI entity="OptionValue" option_group_id="14"}; {*todo on 4.4, use the event-type as id *}
var s = {crmAPI entity='ParticipantStatusType' option_sort="is_counted desc"};
{literal}

function dhm(t){
  var cd = 24 * 60 * 60 * 1000,
      ch = 60 * 60 * 1000,
      d = Math.floor(t / cd),
      h = '0' + Math.floor( (t - d * cd) / ch),
      m = '0' + Math.round( (t - d * cd - h * ch) / 60000);
  return d+1;
}

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
var dateFormat = d3.time.format("%Y-%m-%d %H:%M:%S");
var currentDate = new Date();

//console.log(currentDate);

var barEvents, numberUpcomingEvents, numberPastEvents, lineParticipants, pieType, durationRow, pieEventStatus, pdurationRow, pieStatus, dataTable;

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

  var Events={};

  data.values.forEach(function(d){
    d.rd = dateFormat.parse(d.register_date);
    d.ed = dateFormat.parse(d.end_date);
    d.sd = dateFormat.parse(d.start_date);
    d.typeLabel = typeLabel[d.event_type_id];
    d.statusLabel = statusLabel[d.status_id];
    Events[d.id]={'title':d.title,'sd':d.sd,'ed':d.ed}; 
  });

  var min = d3.time.month.offset(d3.min(data.values, function(d) { return d.rd;} ),-1);
  var max = d3.time.month.offset(d3.max(data.values, function(d) { return d.ed;} ), 1);

  var ndx                 = crossfilter(data.values),
  all = ndx.groupAll();

  barEvents = dc.barChart("#events");
  lineParticipants = dc.lineChart("#participants");
  pieType = dc.pieChart("#type").innerRadius(0).radius(90);
  durationRow = dc.rowChart("#duration");
  dataTable = dc.dataTable("#dc-data-table");

  // pieEventStatus = dc.pieChart("#eventstatus").innerRadius(50).radius(70);
  // pdurationRow = dc.rowChart("#pduration");
  // pieStatus = dc.pieChart("#status").innerRadius(20).radius(70);

  var byMonth = ndx.dimension(function(d) { return d3.time.month(d.sd);});
  var eventsByMonth = byMonth.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);
  var RByMonth = ndx.dimension(function(d) { return d3.time.month(d.rd);});
  var RegistrationByMonth = RByMonth.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

  var typeE        = ndx.dimension(function(d) {return d.typeLabel; });
  var typeEGroup   = typeE.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);
  
  var durationE = ndx.dimension(function(d){
    var days = dhm(d.ed - d.sd);
    var weeks = Math.ceil(days/7);
    var months = Math.ceil(weeks/4);
    if(months>12)
      return "More than 1 Year";
    if(months>6)
      return "6-12 Months";
    if(months>3)
      return "3-6 Months";
    if(months==2)
      return "2 Months";
    if(weeks>4)
      return "1-2 Months";
    if(weeks>2)
      return "2-4 Weeks";
    if(days>5)
      return "5 Days to Week"; 
    if(days>1)
      return "2-4 Days";
    return "1 Day"

  });
  var durationEGroup = durationE.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

  // var durationP = ndx.dimension(function(d){ return dhm(d.ed - d.sd)});
  // var durationPGroup = durationP.group().reduceSum(function(d){ return d.count });

  var list = ndx.dimension(function(d){return d.id});
  var listGroup = list.group().reduceSum(function(d){return d.count});

  var pseudoList = {
  top: function (x) {
    return listGroup.top(x)
      .map(function (d) { return {"id":d.key, "count":d.value, "title":Events[d.key].title, "sd":Events[d.key].sd, "ed":Events[d.key].ed}; });
    }
  };

  var status = ndx.dimension(function(d){ return d.status_id});
  var statusgroup = status.group().reduceSum(function(d){ return d.count });

  var event_status = ndx.dimension(function(d)
    {
      if(d.sd>currentDate)
        return "Upcoming Event";
      return "Past Event";
  });
  var eventstatus_group = event_status.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);
  var upcoming_event =  {
    all:function () {
      var g = [];
      eventstatus_group.all().forEach(function(d,i){
        if (d.key == 'Upcoming Event') {g.push(d);}
      });
      return g;
    },
    top:function () {
      var g = [];
      eventstatus_group.all().forEach(function(d,i){
        if (d.key == 'Upcoming Event') {g.push(d);}
      });
      return g;
    }
  };
  var past_event =  {
    all:function () {
      var g = [];
      eventstatus_group.all().forEach(function(d,i){
        if (d.key == 'Past Event') {g.push(d);}
      });
      return g;
    },
    top:function () {
      var g = [];
      eventstatus_group.all().forEach(function(d,i){
        if (d.key == 'Past Event') {g.push(d);}
      });
      return g;
    }
  };

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
    .group(past_event)
    .valueAccessor(function(d){
        return d.value.eventcount;
    })
    .formatNumber(d3.format("d"));

  var numberUpcomingEvents = dc.numberDisplay('#upcomingevents')
    .dimension(event_status)
    .group(upcoming_event)
    .valueAccessor(function(d){
        return d.value.eventcount;
    })
    .formatNumber(d3.format("d"));

  if(numberUpcomingEvents.value()>0){
    document.getElementById("isUpcoming").innerHTML=" Upcoming Events ";
  }

  if(numberPastEvents.value()>0){
      if(numberUpcomingEvents.value()>0){
        document.getElementById("isboth").innerHTML=" and ";
      }
    document.getElementById("isPast").innerHTML=" Past Events ";
  }

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
        .title(Events[a], function(d) { return Events[a]+" "+d.value.events[a]; });
    }
  });

  pieType
    .width(200)
    .height(200)
    .dimension(typeE)
    .group(typeEGroup)
    // .label(function(d){
    //   return typeLabel[d.key];
    // })
    .valueAccessor(function (d) {
      return d.value.eventcount;
    })
    .legend(dc.legend().x(200).y(10).itemHeight(13).gap(5))
    .renderlet(function(chart){});

  durationRow
    .width(300)
    .height(200)
    .dimension(durationE)
    .group(durationEGroup)
    .valueAccessor(function (d) {
      return d.value.eventcount;
    })
    .xAxis().ticks(1);

  dataTable
    .dimension(pseudoList)
    .group(function(d) {return d.sd.getFullYear();})
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

  // pieEventStatus
  //   .width(200)
  //   .height(200)
  //   .dimension(event_status)
  //   .group(eventstatus_group)
  //   .valueAccessor(function (d) {
  //     return d.value.eventcount;
  //   })
  //   .renderlet(function(chart){});

  // pdurationRow
  //   .width(300)
  //   .height(200)
  //   .dimension(durationP)
  //   .group(durationPGroup)
  //   .label(function(d){
  //     if(d.key==1)
  //       return d.key + " Day Event: " + d.value;
  //     else
  //       return d.key + " Days Event: " + d.value;
  //   })
  //   .xAxis().ticks(1);

  // pieStatus
  //   .width(200)
  //   .height(200)
  //   .dimension(status)
  //   .group(statusgroup)
  //   .label(function(d){
  //     return statusLabel[d.key];
  //   })
  //   .renderlet(function(chart){});

  dc.renderAll();
});
{/literal}
</script>
<div class="clear"></div>
