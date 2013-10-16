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

A 3rd option is to be able to fetch data from a report instance using a {crmReport...}. It's probably not super complicted, patch welcome and all that.

Display data
-----------

The principle is to get the data in a template as a json, and apply d3 on it until it looks awesome.

you simply have to add your template into templates/dataviz/Something.tpl
and you can access it from http://yoursite.org/civicrm/dataviz/something

no matter if you use {crmAPI} or {crmSQL}, you end up with a json and a d3 loaded and ready to rock

In the template, put

   <div id="theplacetograph"></div>
   <script>
     var mydata={crmAPI or crmSQL};
    {literal}
    d3("#theplacetograph").selectAll(...).data(mydata.values).domagic(...);
    
    
You have a "work in progress" few templates, the most interesting one is probably either the dashboard or /civicrm/dataviz/dc

You can already create a new dataviz extension, write a templates/dataviz/Magic.tpl, visit civicrm/dataviz/magic and, well, whatever magic you want.

