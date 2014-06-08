{if $id}
<!-- For Type of Events. Not used it yet -->
{/if}
{php}CRM_Utils_System::setTitle('Events');{/php}
<h1>Events Overview</h1>

<h3>Events</h3>
<div id="type"></div>
<div id="duration"></div>
<div id="eventstatus"></div>
<div class="clear"></div>
<h3>Participants</h3>
<div id="ptype"></div>
<div id="pduration"></div>
<div id="status"></div>
<div class="clear"></div>

<script>
'use strict';

console.log({$id});
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

data.values.forEach(function(d){
  console.log(d);
});

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

console.log(currentDate);

cj(function($) {

  function print_filter(filter) {
    var f = eval(filter);
    if (typeof (f.length) != "undefined") {} 
    else {}
    if (typeof (f.top) != "undefined") {
      f = f.top(Infinity);
    } 
    else {}
    if (typeof (f.dimension) != "undefined") {
      f = f.dimension(function (d) {
        return "";
      }).top(Infinity);
    }
    else {}
    console.log(filter + "(" + f.length + ") = " + JSON.stringify(f).replace("[", "[\n\t").replace(/}\,/g, "},\n\t").replace("]", "\n]"));
  }

  function eventReduceAdd(a,d){
    if(!a.id[d.id]){
      a.id[d.id] = 0;
      a.eventcount++;
    }
    a.id[d.id] ++;
    return a;
  }

  function eventReduceRemove(a, d) {
    a.id[d.id]--;
    if(a.id[d.id]==0){
      a.eventcount--;
    }
    return a;
  }

  function eventReduceInitial() { 
    return {id:{}, eventcount:0};
  }


  var pieType = dc.pieChart("#type").innerRadius(20).radius(70);
  var durationRow = dc.rowChart("#duration");
  var pieEventStatus = dc.pieChart("#eventstatus").innerRadius(50).radius(70);
  var piePType = dc.pieChart("#ptype").innerRadius(20).radius(70);
  var pdurationRow = dc.rowChart("#pduration");
  var pieStatus = dc.pieChart("#status").innerRadius(20).radius(70);

  data.values.forEach(function(d){
    d.rd = dateFormat.parse(d.register_date);
    d.ed = dateFormat.parse(d.end_date);
    d.sd = dateFormat.parse(d.start_date);
  });

  var min = d3.min(data.values, function(d) { return d.rd;} );
  var max = d3.max(data.values, function(d) { return d.ed;} );

  var ndx                 = crossfilter(data.values),
  all = ndx.groupAll();

  var typeE        = ndx.dimension(function(d) {return d.event_type_id; });
  var typeEGroup   = typeE.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);
  
  var typeP        = ndx.dimension(function(d) {return d.event_type_id; });
  var typePGroup   = typeP.group().reduceSum(function(d){ return d.count });

  print_filter("typeEGroup");

  var durationE = ndx.dimension(function(d){ return dhm(d.ed - d.sd)});
  var durationEGroup = durationE.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);

  var durationP = ndx.dimension(function(d){ return dhm(d.ed - d.sd)});
  var durationPGroup = durationP.group().reduceSum(function(d){ return d.count });

  var status = ndx.dimension(function(d){ return d.status_id});
  var statusgroup = status.group().reduceSum(function(d){ return d.count });

  var event_status = ndx.dimension(function(d)
    {
      if(d.sd>currentDate)
        return "Upcoming Event";
      if(d.ed<currentDate)
        return "Past Event";
      return "Ongoing Event"
  });

  var eventstatus_group = event_status.group().reduce(eventReduceAdd,eventReduceRemove,eventReduceInitial);


//Events
  pieType
    .width(200)
    .height(200)
    .dimension(typeE)
    .group(typeEGroup)
    .label(function(d){
      return typeLabel[d.key];
    })
    .valueAccessor(function (d) {
      return d.value.eventcount;
    })
    .renderlet(function(chart){});

  durationRow
    .width(300)
    .height(200)
    .dimension(durationE)
    .group(durationEGroup)
    .label(function(d){
      if(d.key==1)
        return d.key + " Day Event: " + d.value.eventcount;
      else
        return d.key + " Days Event: " + d.value.eventcount;
    })
    .valueAccessor(function (d) {
      return d.value.eventcount;
    })
    .xAxis().ticks(1);

  pieEventStatus
    .width(200)
    .height(200)
    .dimension(event_status)
    .group(eventstatus_group)
    .valueAccessor(function (d) {
      return d.value.eventcount;
    })
    .renderlet(function(chart){});

//Participants
  piePType
    .width(200)
    .height(200)
    .dimension(typeP)
    .group(typePGroup)
    .label(function(d){
      return typeLabel[d.key];
    })
    .renderlet(function(chart){});

  pdurationRow
    .width(300)
    .height(200)
    .dimension(durationP)
    .group(durationPGroup)
    .label(function(d){
      if(d.key==1)
        return d.key + " Day Event: " + d.value;
      else
        return d.key + " Days Event: " + d.value;
    })
    .xAxis().ticks(1);

  pieStatus
    .width(200)
    .height(200)
    .dimension(status)
    .group(statusgroup)
    .label(function(d){
      return statusLabel[d.key];
    })
    .renderlet(function(chart){});

  dc.renderAll();
});
{/literal}
</script>
<div class="clear"></div>