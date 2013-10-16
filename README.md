It's a work in progress. 

civisualize
===========

CiviCRM vizualisation framework

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


Display data
-----------
you simply have to add your template into template/Dataviz/Something.tpl
and you can access it from http://yoursite.org/civicrm/dataviz/something

no matter if you use {crmAPI} or {crmSQL}, you end up with a json and a d3 loaded and ready to rock

In the template, put

   <div id="theplacetograph"></div>
   <script>
     var mydata={crmAPI or crmSQL};
    {literal}
    d3("#theplacetograph").selectAll(...).data(mydata.values).domagic(...);
    
    
You have a "work in progress" few templates, the most interesting one is probably either the dashboard or /civicrm/dataviz/dc




















