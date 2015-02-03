{if !$id}
    <script type="text/javascript">
        location.replace('events');
    </script>
{/if}

{literal}
    <style type="text/css">
        .eventoverview{
            background-color: #ddd;
            padding: 10px;
            border-radius: 5px;
            margin-top: 10px;
            margin-bottom: 20px;
            overflow: auto;
            position: relative;
        }

        .eventDetails{
            width: 400px;z
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
        #participants{
            width:100%;
        }
    </style>
{/literal}

<div id="eventoverview">
    <div class="eventoverview">
        <div class="eventDetails"></div>
        <div id="noofparticipants"></div>
    </div>

    <div class="clear"></div>
    <div id="participantsCount" style="font-size:14px; margin-bottom:10px;"></div>
    <div id="participants">
        <strong>Participants</strong>
        <a class="reset" href="javascript:participantsLine.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>
    <div id="gender">
        <strong>Gender</strong>
        <a class="reset" href="javascript:genderPie.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>
    <div id="status">
        <strong>Participant Status</strong>
        <a class="reset" href="javascript:statusPie.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>
    <div id="feeRow">
        <strong>Fee Paid</strong>
        <a class="reset" href="javascript:feeRow.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>
    <table id="participantTable">
        <thead>
            <tr class="header">
                <th>Name</th>
                <th>Gender</th>
                <th>Fee Paid</th>
                <th>Status</th>
            </tr>
        </thead>
    </table>
</div>

<script>

    'use strict';

    //console.log({$id});

    var eventDetails        = {crmSQL json="eventdetails" eventid=$id set="event"};
    
    var participantDetails  = {crmSQL json="eventparticipants" eventid=$id};

    {crmTitle array=$event field="title"}

    

    var i = {crmAPI entity="OptionValue" option_group_id="14"};
    var s = {crmAPI entity='ParticipantStatusType' option_sort="is_counted desc"};

    var gender = {crmAPI entity="contact" action="getoptions" field="gender_id"};

    {literal}

        if((!eventDetails.is_error)&&(!participantDetails.is_error)){

            var genderLabel = {};

            gender.values.forEach(function(d){
                genderLabel[d.key]=d.value;
            });

            eventDetails = eventDetails.values[0];

            {/literal}
                eventDetails['url'] = "{crmURL p='civicrm/event/info' q='id='}{$id}";
            {literal}

            var statusLabel = {};
            var typeLabel   = {};

            s.values.forEach (function(d) {
                statusLabel[d.id] = d.label;
            });
            s=null;
            i.values.forEach (function(d) {
                typeLabel[d.value] = d.label;
            });
            i=null;

            cj('.eventDetails').html(
                "<div class='detail'><div class='detailfield'>Name:</div><div class='detailvalue'><a href='"+eventDetails.url+"'>"+eventDetails.title+"</a></div></div>"
                +"<div class='detail'><div class='detailfield'>Event Type:</div><div class='detailvalue'>"+typeLabel[eventDetails.event_type_id]+"</div></div>"
                +"<div class='detail'><div class='detailfield'>Start Date:</div><div class='detailvalue'>"+eventDetails.start_date+"</div></div>"
                +"<div class='detail'><div class='detailfield'>End Date:</div><div class='detailvalue'>"+eventDetails.end_date+"</div></div>"
                +"<div class='detail'><div class='detailfield'>Registration Start Date:</div><div class='detailvalue'>"+eventDetails.registration_start_date+"</div></div>"
                +"<div class='detail'><div class='detailfield'>Registration End Date:</div><div class='detailvalue'>"+eventDetails.registration_end_date+"</div></div>"
            );

            var numberFormat        = d3.format("d");
            var birthdateFormat     = d3.time.format("%Y-%m-%d");
            var registerdateFormat  = d3.time.format("%Y-%m-%d %H:%M:%S");
            var currentDate         = new Date();


            participantDetails.values.forEach(function(d){
                d.bd = birthdateFormat.parse(d.birth_date);
                d.rd = registerdateFormat.parse(d.register_date);s
                d.status = statusLabel[d.status_id];
                if(d.gender_id!==""){
                    d.gender_id=genderLabel[d.gender_id];
                }
                else{
                    d.gender_id="Not Specified";
                }
                if(d.fee_amount==""){
                    d.fee_amount="0";
                }
            });

            var participantsLine, genderPie, feeRow, statusPie, dataTable, participantsNumber, participantsCount;

            cj(function($) {

                function print_filter(filter){var f=eval(filter);if(typeof(f.length)!="undefined"){}else{}if(typeof(f.top)!="undefined"){f=f.top(Infinity);}else{}if(typeof(f.dimension)!="undefined"){f=f.dimension(function(d){return "";}).top(Infinity);}else{}console.log(filter+"("+f.length+")="+JSON.stringify(f).replace("[", "[\n\t").replace(/}\,/g, "},\n\t").replace("]", "\n]"));}

                var ndx = crossfilter(participantDetails.values), all = ndx.groupAll();
                var grouped=ndx.groupAll().reduce(function(p,v){ ++p.count; return p; }, function(p,v){p.count-=1;return p;}, function(){return {count:0};});

                var min = d3.time.day.offset(d3.min(participantDetails.values, function(d) { return d.rd;} ),-1);
                var max = d3.time.day.offset(d3.max(participantDetails.values, function(d) { return d.rd;} ), 1);

                participantsLine    = dc.lineChart("#participants");
                genderPie           = dc.pieChart("#gender").radius(100);
                statusPie           = dc.pieChart("#status").radius(100);
                feeRow              = dc.rowChart("#feeRow");
                dataTable           = dc.dataTable("#participantTable");
                participantsNumber  = dc.numberDisplay("#noofparticipants");
                participantsCount   = dc.dataCount("#participantsCount");

                var RByDay      = ndx.dimension(function(d) { return d3.time.day(d.rd);});
                var RByDayGroup = RByDay.group().reduceCount();
                var group       = {
                    all:function () {
                        var cumulate = 0;
                        var g = [];
                        RByDayGroup.all().forEach(function(d,i) {
                        cumulate += d.value;
                        g.push({key:d.key,value:cumulate})
                    });
                    return g;
                    }
                };  

                var gender      = ndx.dimension(function(d){return d.gender_id});
                var genderGroup = gender.group().reduceCount();

                var status      = ndx.dimension(function(d){return d.status});
                var statusGroup = status.group().reduceCount();

                var Fee         = ndx.dimension(function(d){return d.fee_amount});
                var FeeGroup    = Fee.group().reduceCount();

                var date        = ndx.dimension(function(d){return d.rd;});

                participantsCount
                    .dimension(ndx)
                    .group(all)
                    .html({"all":"All Records Selected","some":"<strong>%filter-count</strong> selected from <strong>%total-count</strong>"});

                participantsLine
                    .margins({top: 10, right: 50, bottom: 20, left:40})
                    .height(200)
                    .dimension(RByDay)
                    .group(group)
                    .brushOn(true)
                    .x(d3.time.scale().domain([min, max]))
                    .round(d3.time.day.round)
                    .elasticY(true)
                    .xUnits(d3.time.days);

                genderPie
                    .width(220)
                    .height(220)
                    .dimension(gender)
                    .group(genderGroup);


                statusPie
                    .width(220)
                    .height(220)
                    .dimension(status)
                    .group(statusGroup);

                feeRow
                    .height(220)
                    .width(300)
                    .elasticX(true)
                    .dimension(Fee)
                    .group(FeeGroup);

                dataTable
                    .dimension(date)
                    .group(function(d){ return ""; })
                    .size(9999)
                    .columns(
                        [
                            function (d) {
                                return d.display_name;
                            },
                            function (d) {
                                return d.gender_id;
                            },
                            function (d) {
                                return d.fee_amount;
                            },
                            function (d) {
                                return statusLabel[d.status_id];
                            }
                        ]
                    );


                participantsNumber
                    .group(grouped)
                    .formatNumber(numberFormat)
                    .html({some:'<span style="font-size:90px; line-height:102px; color:steelblue;">%number</span> Participants', one:'<span style="font-size:90px;  line-height:102px; color: steelblue;">%number</span> Participant'})
                    .valueAccessor(function(d) {
                        return d.count;
                    });

                dc.renderAll();

            });
        }
        else{
            cj('#eventoverview').html('<div style="color:red; font-size:18px;">Civisualize Error. Please contact Admin.'+eventDetails.error+participantDetails.error+'</div>');
        }
    {/literal}
</script>
<div class="clear"></div>
