/**
 * The data count widget is a simple widget designed to display the number of records selected by the
 * current filters out of the total number of records in the data set. Once created the data count widget
 * will automatically update the text content of child elements with the following classes:
 *
 * * `.total-count` - total number of records
 * * `.filter-count` - number of records matched by the current filters
 *
 * Note: this widget works best for the specific case of showing the number of records out of a
 * total. If you want a more general-purpose numeric display, please use the
 * {@link dc.numberDisplay} widget instead.
 *
 * Examples:
 * - {@link http://dc-js.github.com/dc.js/ Nasdaq 100 Index}
 * @class dataCount
 * @memberof dc
 * @mixes dc.baseMixin
 * @example
 * var ndx = crossfilter(data);
 * var all = ndx.groupAll();
 *
 * dc.dataCount('.dc-data-count')
 *     .dimension(ndx)
 *     .group(all);
 * @param {String|node|d3.selection} parent - Any valid
 * {@link https://github.com/d3/d3-selection/blob/master/README.md#select d3 single selector} specifying
 * a dom block element such as a div; or a dom element or d3 selection.
 * @param {String} [chartGroup] - The name of the chart group this chart instance should be placed in.
 * Interaction with a chart will only trigger events and redraws within the chart's group.
 * @returns {dc.dataCount}
 */
dc.dataCount = function (parent, chartGroup) {
    var _formatNumber = d3.format(',d');
    var _chart = dc.baseMixin({});
    var _html = {some: '', all: ''};

    /**
     * Gets or sets an optional object specifying HTML templates to use depending how many items are
     * selected. The text `%total-count` will replaced with the total number of records, and the text
     * `%filter-count` will be replaced with the number of selected records.
     * - all: HTML template to use if all items are selected
     * - some: HTML template to use if not all items are selected
     * @method html
     * @memberof dc.dataCount
     * @instance
     * @example
     * counter.html({
     *      some: '%filter-count out of %total-count records selected',
     *      all: 'All records selected. Click on charts to apply filters'
     * })
     * @param {{some:String, all: String}} [options]
     * @returns {{some:String, all: String}|dc.dataCount}
     */
    _chart.html = function (options) {
        if (!arguments.length) {
            return _html;
        }
        if (options.all) {
            _html.all = options.all;
        }
        if (options.some) {
            _html.some = options.some;
        }
        return _chart;
    };

    /**
     * Gets or sets an optional function to format the filter count and total count.
     * @method formatNumber
     * @memberof dc.dataCount
     * @instance
     * @see {@link https://github.com/d3/d3-format/blob/master/README.md#format d3.format}
     * @example
     * counter.formatNumber(d3.format('.2g'))
     * @param {Function} [formatter=d3.format('.2g')]
     * @returns {Function|dc.dataCount}
     */
    _chart.formatNumber = function (formatter) {
        if (!arguments.length) {
            return _formatNumber;
        }
        _formatNumber = formatter;
        return _chart;
    };

    _chart._doRender = function () {
        var tot = _chart.dimension().size(),
            val = _chart.group().value();
        var all = _formatNumber(tot);
        var selected = _formatNumber(val);

        if ((tot === val) && (_html.all !== '')) {
            _chart.root().html(_html.all.replace('%total-count', all).replace('%filter-count', selected));
        } else if (_html.some !== '') {
            _chart.root().html(_html.some.replace('%total-count', all).replace('%filter-count', selected));
        } else {
            _chart.selectAll('.total-count').text(all);
            _chart.selectAll('.filter-count').text(selected);
        }
        return _chart;
    };

    _chart._doRedraw = function () {
        return _chart._doRender();
    };

    return _chart.anchor(parent, chartGroup);
};
