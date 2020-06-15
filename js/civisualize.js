CRM.civisualize = CRM.civisualize || {
  charts: {},
  bindResetLinks: function() {

    [].forEach.call(document.querySelectorAll('a.civisualize-reset.reset'), function (el, index, array) {
      // We only need to do this once per thing.
      if (el.civisualizeProcessed) {
        return;
      }
      el.civisualizeProcessed = true;
      el.addEventListener('click', CRM.civisualize.resetItem);
      // Hide by default.
      el.style.display = 'none';
    });

  },
  resetItem: function(e) {
    e.preventDefault();
    e.stopPropagation();
    e.target.dataset.chartName.split(',').forEach(function(chartName) {
      CRM.civisualize.charts[chartName].filterAll();
    });
    CRM.civisualize.dc.redrawAll();
  }
};
