jQuery(function($){
  $(".menu.secondary").append('<li class="civisualize-help"><a href="#" class="glyphicon glyphicon-question-sign" aria-hidden="true"></a></li>');
  $(".civisualize-help").click(function(){
    var url=window.location.href.replace("dataviz","datadoc");
    if (typeof marqued == "function")
      CRM.loadPage(url);
    else 
      $.getScript(CRM.vars.civisualize.baseUrl + "js/marked.min.js", function(){
        CRM.loadPage(url);
      });
  });
});
