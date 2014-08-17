{crmTitle string="Donor Trends"}

{literal}
    <style>
        #donorBar{
            width: 100%;
        }
        #genderPie{
            width:50%;
        }
    </style>
{/literal}

<div id="donortrends">
    <div id="donorsCount" style="font-size:14px; margin-bottom:5px;"><span id="contactNumber"></span> selected from a total of <span id="contactTotal" style="font-weight:800;"></span>.</div>
    <div id="donorBar">
        <strong>Donor Trends</strong>
        <a class="reset" href="javascript:donorBar.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>
    <div id="genderPie">
        <strong>Gender</strong>
        <a class="reset" href="javascript:genderPie.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>
    <div id="ageRow">
        <strong>Age</strong>
        <a class="reset" href="javascript:ageRow.filterAll();dc.redrawAll();" style="display: none;">reset</a>
        <div class="clearfix"></div>
    </div>
    <div class="clear"></div>
    <table id="dc-data-table">
        <thead>
            <tr class="header">
                <th>Participant Name</th>
                <th>Gender</th>
                <th>Age</th>
                <th>Total Amount</th>
            </tr>
        </thead>
    </table>
</div>
<div class="clear"></div>


<script>

    'use strict';

    var data        = {crmSQL file="donors"};
    var dateFormat  = d3.time.format("%Y-%m-%d");
    var currentDate = new Date();

    {literal}

        if(!data.is_error){

            var contactNumber, contactTotal, donorBar, genderPie, ageRow, dataTable;

            cj(function($){

                var genderLabel = {1:"Male",2:"Female"};

                var contactList = {};
                contactTotal    = 0;

                data.values.forEach(function(d){
                    if(!contactList[d.contact_id]){
                        contactTotal+=1;
                        contactList[d.contact_id]=1;
                    }
                    if(!d.gender_id){
                        d.gender_id = "Unspecified";
                    }
                    else{
                        d.gender_id = genderLabel[d.gender_id];
                    }
                    d.birth_date = dateFormat.parse(d.birth_date);
                    d.age=d3.time.years(d.birth_date, currentDate).length-1;
                });

                cj("#contactTotal").text(contactTotal);

                function print_filter(filter){var f=eval(filter);if(typeof(f.length)!="undefined"){}else{}if(typeof(f.top)!="undefined"){f=f.top(Infinity);}else{}if(typeof(f.dimension)!="undefined"){f=f.dimension(function(d){return "";}).top(Infinity);}else{}console.log(filter+"("+f.length+")="+JSON.stringify(f).replace("[", "[\n\t").replace(/}\,/g, "},\n\t").replace("]", "\n]"));}

                /* Functions */

                function Add(a,d){
                    var f=1, ug=0, dg=0, mtd=0; 
                    data.values.forEach(function(m){
                        if(m.year<d.year){
                            if(m.contact_id==d.contact_id){
                                if(m.year===d.year-1){
                                    f=0;
                                    if(m.total_amount==d.total_amount){
                                        mtd=1;
                                    }
                                    else if(m.total_amount>d.total_amount){
                                        dg=1;
                                    }
                                    else if((m.total_amount<d.total_amount)){
                                        ug=1;
                                    }
                                }
                            }
                        }
                    });
                    a.fresh+=f;
                    a.upgraded+=ug;
                    a.downgraded+=dg;
                    a.maintained+=mtd;
                    return a;
                }

                function Remove(a, d) {
                    var f=1, ug=0, dg=0, mtd=0; 
                    data.values.forEach(function(m){
                        if(m.year!=d.year){
                            if(m.contact_id==d.contact_id){
                                if(m.year<d.year){
                                    f=0;
                                }
                                if(m.year===d.year-1){
                                    if(m.total_amount==d.total_amount){
                                        mtd=1;
                                    }
                                    else if(m.total_amount>d.total_amount){
                                        dg=1;
                                    }
                                    else if(m.total_amount<d.total_amount){
                                        ug=1;
                                    }
                                }
                            }
                        }
                    });
                    a.fresh-=f;
                    a.upgraded-=ug;
                    a.downgraded-=dg;
                    a.maintained-=mtd;
                    return a;
                }

                function Initial() {
                    return { fresh:0, upgraded:0, downgraded:0, maintained:0, lapsed:0};
                }

                function countAdd(a,d){
                    if(a.contacts[d.contact_id]==0)
                    {
                        a.contacts[d.contact_id]++;
                        a.count++;
                    }
                    else{
                        a.contacts[d.contact_id]++;
                    }
                    return a;
                }

                function removeCount(a,d){
                    if(a.contacts[d.contact_id]>0){
                        a.contacts[d.contact_id]--;
                        if(a.contacts[d.contact_id]==0){
                            a.count--;
                        }
                    }
                    return a;
                }

                function initialCount(){
                    var c={};
                    data.values.forEach(function(d){
                        c[d.contact_id]=0;
                    });
                    return {count:0, contacts:c};
                }

                var ndx         = crossfilter(data.values),
                all             = ndx.groupAll();
                var minYear     = d3.min(data.values, function(d){return d.year;});
                var maxYear     = d3.max(data.values, function(d){return d.year;});

                donorBar        = dc.barChart("#donorBar");
                genderPie       = dc.pieChart("#genderPie").radius(80);
                ageRow          = dc.rowChart("#ageRow");
                dataTable       = dc.dataTable("#dc-data-table");
                contactNumber   = dc.numberDisplay("#contactNumber");

                var byYear      = ndx.dimension(function(d) {return d.year;});
                var byYearGroup = byYear.group().reduce(Add, Remove, Initial);
                var group = {
                    all:function () {
                            var g=[];
                            for(var i=minYear-1; i<=maxYear; i++){
                                var k={fresh:0, upgraded:0, downgraded:0, maintained:0, lapsed:0};
                                var flag=0;
                                var total=0;
                                byYearGroup.all().forEach(function(d,m) {
                                    if(d.key==i-1){
                                        total=d.value.fresh+d.value.upgraded+d.value.downgraded+d.value.maintained;
                                    }
                                    if(d.key==i){
                                        d.value.lapsed=total-(d.value.upgraded+d.value.downgraded+d.value.maintained);
                                        g.push({key:d.key,value:d.value});
                                        flag=1;
                                    }
                                });
                                if(flag==0){
                                    k.lapsed=total;
                                    g.push({key:i, value:k});
                                }
                            }
                            return g;
                        }
                };

                var gender      = ndx.dimension(function(d){return d.gender_id});
                var genderGroup = gender.group().reduce(countAdd,removeCount, initialCount);

                var age         = ndx.dimension(function(d){
                    if(d.birth_date=="")
                        return "Unspecified";
                    var a=d3.time.years(d.birth_date, currentDate).length-1;
                    if(a<10)
                        return "1-10";
                    if(a<20)
                        return "10-20";
                    if(a<30)
                        return "20-30";
                    if(a<40)
                        return "30-40";
                    if(a<50)
                        return "40-50";
                    if(a<60)
                        return "50-60";
                    if(a<70)
                        return "60-70";
                    if(a<80)
                        return "70-80";
                    if(a<90)
                        return "80-90";
                    else
                        return "More than 90";
                });
                var ageGroup    = age.group().reduce(countAdd,removeCount, initialCount);

                var list        = ndx.dimension(function(d){return d.contact_id});

                var grouped=ndx.groupAll().reduce(countAdd,removeCount,initialCount);

                contactNumber
                    .group(grouped)
                    .valueAccessor(function(d){
                        return d.count;
                    })
                    .html({"some":"<span style='font-weight:800;'>%number</span> Donors","one":"<span style='font-weight:800;'>%number</span> Donor","none":"No Records"});

                donorBar
                    .height(200)
                    .group(group,"New")
                    .dimension(byYear)
                    .valueAccessor(function(d) {
                        return d.value.fresh;
                    })
                    .centerBar(true)
                    .gap(10)
                    .hidableStacks(true)
                    .elasticY(true)
                    .round(function(n) {
                        return Math.floor(n)+0.5}
                        )
                    .x(d3.scale.linear().domain([minYear-1, maxYear+1]))
                    .legend(dc.legend().x(50).y(10).itemHeight(13).gap(5))
                    .stack(group,"Upgraded", function(d){return d.value.upgraded;})
                    .stack(group,"Downgraded", function(d){return d.value.downgraded;})
                    .stack(group,"Maintained", function(d){return d.value.maintained;})
                    .stack(group,"Lapsed", function(d){return d.value.lapsed;});

                genderPie
                    .dimension(gender)
                    .height(250)
                    .group(genderGroup)
                    .valueAccessor(function(d){
                        return d.value.count;
                    });

                ageRow
                    .height(250)
                    .dimension(age)
                    .group(ageGroup)
                    .valueAccessor(function(d){
                        return d.value.count;
                    });

                dataTable
                    .dimension(list)
                    .group(function(d) {return d.year;})
                // dynamic columns creation using an array of closures

                .columns([
                    function(d) {return d.display_name; },
                    function(d) {return d.gender_id;},
                    function(d) {return d.age;},
                    function(d) {return d.total_amount;}
                    ])
                    .sortBy(function (d) {
                        return d.sd;
                    });

                dc.renderAll();
            });
        }
        else {
            cj('#donortrends').html('<div style="color:red; font-size:18px;">Civisualize Error. Please contact Admin.'+data.error+'</div>');
        }
    {/literal}
</script>