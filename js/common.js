jQuery(function($){
  var url=window.location.href.replace("dataviz","datadoc");
  $(".menu.secondary").append('<li class="civisualize-help"><a href="'+url+'" title="Help" class="glyphicon glyphicon-question-sign" aria-hidden="true"></a></li>');
  $(".civisualize-help").click(function(event){
    event.preventDefault();
    if (typeof marqued == "function")
      CRM.loadPage(url);
    else 
      $.getScript(CRM.vars.civisualize.baseUrl + "js/marked.min.js", function(){
        CRM.loadPage(url);
      });
  });
});
