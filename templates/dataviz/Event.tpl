{literal}
<style>
  .eventoverview{
    background-color: #ddd;
    padding: 10px;
    border-radius: 5px;
    margin-top: 10px;
    margin-bottom: 20px;
    overflow: auto;
    position: relative;
  }
  .eventdetails{
    width: 400px;
    float: left;
  }
  .detailfield{
    font-size:14px; 
    color:steelblue; 
    display:inline;
    font-weight: 800;
    padding-right: 5px;
  }
  .detailvalue{
    font-size:14px; 
    display:inline;
    font-weight: 800;
  }
  .detail{ 
    clear:both;
  }
  #noofparticipants{
    float: left;
    left:400px;
    position: absolute;
    bottom: 0;
  }
</style>
{/literal}

{if !$id}
  <script type="text/javascript">
    location.replace('events');
  </script>
{/if}

<div class="eventoverview">
  <div class="eventdetails">
  </div>
  <div id="noofparticipants">    
  </div>
</div>
<div class="clear"></div>

<div id="participants">
</div>
<div id="gender"></div>
<div id="status"></div>
<div id="barFee"></div>
<script>
'use strict';

//console.log({$id});

var eventdetails = {crmSQL json="eventdetails" eventid=$id setTitle="title"};
var participantdetails = {crmSQL json="eventparticipants" eventid=$id};

console.log(eventdetails);

eventdetails = eventdetails.values[0];

console.log(participantdetails);

var i = {crmAPI entity="OptionValue" option_group_id="14"}; {*todo on 4.4, use the event-type as id *}
var s = {crmAPI entity='ParticipantStatusType' option_sort="is_counted desc"};

{literal}

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

cj('.eventdetails').html(
  "<div class='detail'><div class='detailfield'>Name:</div><div class='detailvalue'>"+eventdetails.title+"</div></div>"
  +"<div class='detail'><div class='detailfield'>Event Type:</div><div class='detailvalue'>"+typeLabel[eventdetails.event_type_id]+"</div></div>"
  +"<div class='detail'><div class='detailfield'>Start Date:</div><div class='detailvalue'>"+eventdetails.start_date+"</div></div>"
  +"<div class='detail'><div class='detailfield'>End Date:</div><div class='detailvalue'>"+eventdetails.end_date+"</div></div>"
  +"<div class='detail'><div class='detailfield'>Registration Start Date:</div><div class='detailvalue'>"+eventdetails.registration_start_date+"</div></div>"
  +"<div class='detail'><div class='detailfield'>Registration End Date:</div><div class='detailvalue'>"+eventdetails.registration_end_date+"</div></div>"
  );

var numberFormat = d3.format(".2f");
var birthdateFormat = d3.time.format("%Y-%m-%d");
var registerdateFormat = d3.time.format("%Y-%m-%d %H:%M:%S");
var currentDate = new Date();

//console.log(currentDate);

var genderLabel={};
genderLabel["1"]="Male";
genderLabel["2"]="Female";

participantdetails.values.forEach(function(d){
    d.bd = birthdateFormat.parse(d.birth_date);
    d.rd = registerdateFormat.parse(d.register_date);s
    d.status = statusLabel[d.status_id];
    if(d.gender_id!==""){
      d.gender_id=genderLabel[d.gender_id];
    }
    else
      d.gender_id="Not Specified";
    if(d.fee_amount==""){
      d.fee_amount="0";
    }
  });
  
var lineParticipants, pieGender, barFee, pieStatus, dataTable, numberParticipants;

cj(function($) {

  function print_filter(filter){var f=eval(filter);if(typeof(f.length)!="undefined"){}else{}if(typeof(f.top)!="undefined"){f=f.top(Infinity);}else{}if(typeof(f.dimension)!="undefined"){f=f.dimension(function(d){return "";}).top(Infinity);}else{}console.log(filter+"("+f.length+")="+JSON.stringify(f).replace("[", "[\n\t").replace(/}\,/g, "},\n\t").replace("]", "\n]"));}
  
  var ndx = crossfilter(participantdetails.values), all = ndx.groupAll();
  var grouped=ndx.groupAll().reduce(function(p,v){ ++p.count; return p; }, function(p,v){p.count-=1;return p;}, function(){return {count:0};});

  var min = d3.time.day.offset(d3.min(participantdetails.values, function(d) { return d.rd;} ),-1);
  var max = d3.time.day.offset(d3.max(participantdetails.values, function(d) { return d.rd;} ), 1);

  lineParticipants = dc.lineChart("#participants");
  pieGender = dc.pieChart("#gender").radius(100);
  pieStatus = dc.pieChart("#status").radius(100);
  barFee = dc.rowChart("#barFee");
  numberParticipants = dc.numberDisplay("#noofparticipants");

  var RByDay = ndx.dimension(function(d) { return d3.time.day(d.rd);});
  var RByDayGroup = RByDay.group().reduceCount();

  lineParticipants
    .margins({top: 10, right: 50, bottom: 20, left:40})
    .height(200)
    .dimension(RByDay)
    .group(RByDayGroup)
    .brushOn(false)
    .x(d3.time.scale().domain([min, max]))
    .round(d3.time.day.round)
    .elasticY(true)
    .xUnits(d3.time.days);

  var gender = ndx.dimension(function(d){return d.gender_id});
  var genderGroup = gender.group().reduceCount();

  pieGender
    .width(220)
    .height(220)
    .dimension(gender)
    .group(genderGroup);

  var status = ndx.dimension(function(d){return d.status});
  var statusGroup = status.group().reduceCount();

  pieStatus
    .width(220)
    .height(220)
    .dimension(status)
    .group(statusGroup);

  print_filter(participantdetails);

  var Fee = ndx.dimension(function(d){return d.fee_amount});
  var FeeGroup = Fee.group().reduceCount();

  barFee
    .height(220)
    .width(300)
    .dimension(Fee)
    .group(FeeGroup);

  numberParticipants
    .group(grouped)
    .html({some:'<span style="font-size:90px; line-height:102px; color:steelblue;">%number</span> Participants', one:'<span style="font-size:90px;  line-height:102px; color: steelblue;">%number</span> Participant'})
    .valueAccessor(function(d) {return d.count;});
    //.formatNumber(d3.format("d"));

  dc.renderAll();

});
{/literal}
</script>
<div class="clear"></div>
