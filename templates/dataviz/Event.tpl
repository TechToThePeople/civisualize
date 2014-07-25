
{if !$id}
  <script type="text/javascript">
    location.replace('events');
  </script>
{/if}

<div class="eventoverview">
  <div class="eventdetails">
  </div>
</div>

<script>
'use strict';

//console.log({$id});

var eventdetails = {crmSQL json="eventdetails" eventid=$id};
var participantdetails = {crmSQL json="eventparticipants" eventid=$id};

console.log(eventdetails);

eventdetails = eventdetails.values[0];

console.log(participantdetails.values);

{php}CRM_Utils_System::setTitle('Siddharth');{/php}

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
  "<strong><div style='font-size:14px; color:steelblue; display:inline;'>Name:</div><div style='display:inline;'>"+eventdetails.title
  +"</div><br /><div style='font-size:14px; color:steelblue; display:inline;'>Event Type: </div><div style='display:inline;'>"+typeLabel[eventdetails.event_type_id]
  +"</div><br /><div style='font-size:14px; color:steelblue; display:inline;'>Start Date: </div><div style='display:inline;'>"+eventdetails.start_date
  +"</div><br /><div style='font-size:14px; color:steelblue; display:inline;'>End Date: </div><div style='display:inline;'>"+eventdetails.end_date
  +"</div><br /><div style='font-size:14px; color:steelblue; display:inline;'>Registration Start Date: </div><div style='display:inline;'>"+eventdetails.registration_start_date
  +"</div><br /><div style='font-size:14px; color:steelblue; display:inline;'>Registration End Date: </div><div style='display:inline;'>"+eventdetails.registration_end_date
  +"</div></strong>"
  );

var numberFormat = d3.format(".2f");
var dateFormat = d3.time.format("%Y-%m-%d %H:%M:%S");
var currentDate = new Date();

//console.log(currentDate);
  
var lineParticipants, pieGender, pieMonetory, dataTable;

cj(function($) {

  function print_filter(filter){var f=eval(filter);if(typeof(f.length)!="undefined"){}else{}if(typeof(f.top)!="undefined"){f=f.top(Infinity);}else{}if(typeof(f.dimension)!="undefined"){f=f.dimension(function(d){return "";}).top(Infinity);}else{}console.log(filter+"("+f.length+")="+JSON.stringify(f).replace("[", "[\n\t").replace(/}\,/g, "},\n\t").replace("]", "\n]"));}

});
{/literal}
</script>
<div class="clear"></div>
