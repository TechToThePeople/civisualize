It's alpha, probably not going to hurt your data, but you need to know sql and d3 to develop new visualisations. Please let me know what works or doesn't, I'll do my best not to brake too many things, but beware that I might change pretty much anything at one point or another until I reach stable.

CiviCRM data vizualisation framework
===========================

This extension has two parts:
- extract data out of civi
- display it


Extract Data
-------------

for the first part, we are 
- adding getstat as a new action on some entities in the api
- add a new crmSQL to run a query. it has two modes
{crmSQL sql="SELECT count(*) ... group by ...."}
or 
{crmSQL query="somethingcool"}
that will fetch the sql query from /queries/somethingcool.sql

A 3rd option is to be able to fetch data from a report instance using a {crmReport...}. Eileen has done (most of?) the work already. I think it's on 4.5 

Display data
-----------

The principle is to get the data in a template as a json, and apply d3/dc on it until it looks awesome.

you simply have to add your template into templates/dataviz/Something.tpl
and you can access it from http://yoursite.org/civicrm/dataviz/something

To get you started, you can visit http://yoursite.org/civicrm/dataviz/contribute 
This is using the wondefully magic dc, that is a layer of love on the top of d3 and crossfilter. 
Click on the graphs to filter down. magic, I told you.

no matter if you use {crmAPI} or {crmSQL}, you end up with a json and a d3 and dc loaded and ready to rock

In the template, put

```javascript
   <div id="theplacetograph"></div>
   <script>
     var mydata={crmAPI or crmSQL};
    {literal}
    d3("#theplacetograph").selectAll(...).data(mydata.values).domagic(...);
```    

Predefined graphs
----------
dc has a few common graphs (pie charts, barcharts...) that you can use directly with data without having to go through crossfilter (no need to define a domain...). The documentation isn't yet complete, but we've been using it for a [lapsed donor visualization](ata without having to go throu  gh crossfilter (no need to define a domain...). The documentation isn't yet complete, but we've been using it for a [lapsed donor dataviz](https://github.com/TechToThePeople/civisualize/blob/master/templates/dataviz/Lapseddonor.tpl). _one shouldn't use pie charts for that, but that's another topic_

    
You have a "work in progress" few templates, the most interesting one is probably either the dashboard or /civicrm/dataviz/contribute

You can already create a new dataviz extension, write a templates/dataviz/Magic.tpl, visit civicrm/dataviz/magic and, well, whatever magic you want.

I love you
-------
xavier made this. You can find me in civicrm forum, [@eucampaign](http://twitter.com/eucampaign) or in the dc mailing group. Be warned, d3 is awesome, but the learning curve is steep. Worthwhile, the view at the top is beautiful. or so I've been told, I haven't reached it yet.
