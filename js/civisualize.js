// In case we are called twice. (Shouldn't happen, but...)
if (!CRM.civisualize) {
  CRM.civisualize = {
    charts: {},
    boot: function(callback) {
      // console.log("civisualize boot running", callback);
      var callCallbackIfReady = function() {
        if (callback.hasBeenCalled) {
          return;
        }
        if (document.readyState === 'complete') {
          // We only want to boot each one once.
          callback.hasBeenCalled = true;
          // Let it run.
          callback();
          // No harm in doing this.
          CRM.civisualize.bindResetLinks();
        }
      };

      // We don't know what state the document is in. It could be loading,
      // 'interactive', or complete already. This is complicated by the
      // dashboard which behaves differently for cached dashlets as for
      // newly added (e.g. Refresh Dashboard Data button).
      // So we listen on readystatechange, and try our luck right away.
      document.addEventListener('readystatechange', callCallbackIfReady);
      callCallbackIfReady();
    },
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
    },
  };

  // See if there's anything queued already.
  if (CRM.civisualizeQueue) {
    // Yes there was, boot each now.
    CRM.civisualizeQueue.forEach(CRM.civisualize.boot);
  }
  // Replace the queue array with an object with a .push method
  // that will immediately call our boot function for future scripts.
  CRM.civisualizeQueue = {push: CRM.civisualize.boot};

}
