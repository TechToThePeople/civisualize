/**
 * A heat map is matrix that represents the values of two dimensions of data using colors.
 * @class heatMap
 * @memberof dc
 * @mixes dc.colorMixin
 * @mixes dc.marginMixin
 * @mixes dc.baseMixin
 * @example
 * // create a heat map under #chart-container1 element using the default global chart group
 * var heatMap1 = dc.heatMap('#chart-container1');
 * // create a heat map under #chart-container2 element using chart group A
 * var heatMap2 = dc.heatMap('#chart-container2', 'chartGroupA');
 * @param {String|node|d3.selection} parent - Any valid
 * {@link https://github.com/d3/d3-selection/blob/master/README.md#select d3 single selector} specifying
 * a dom block element such as a div; or a dom element or d3 selection.
 * @param {String} [chartGroup] - The name of the chart group this chart instance should be placed in.
 * Interaction with a chart will only trigger events and redraws within the chart's group.
 * @returns {dc.heatMap}
 */
dc.heatMap = function (parent, chartGroup) {

    var DEFAULT_BORDER_RADIUS = 6.75;

    var _chartBody;

    var _cols;
    var _rows;
    var _colOrdering = d3.ascending;
    var _rowOrdering = d3.ascending;
    var _colScale = d3.scaleBand();
    var _rowScale = d3.scaleBand();

    var _xBorderRadius = DEFAULT_BORDER_RADIUS;
    var _yBorderRadius = DEFAULT_BORDER_RADIUS;

    var _chart = dc.colorMixin(dc.marginMixin(dc.baseMixin({})));
    _chart._mandatoryAttributes(['group']);
    _chart.title(_chart.colorAccessor());

    var _colsLabel = function (d) {
        return d;
    };
    var _rowsLabel = function (d) {
        return d;
    };

    /**
     * Set or get the column label function. The chart class uses this function to render
     * column labels on the X axis. It is passed the column name.
     * @method colsLabel
     * @memberof dc.heatMap
     * @instance
     * @example
     * // the default label function just returns the name
     * chart.colsLabel(function(d) { return d; });
     * @param  {Function} [labelFunction=function(d) { return d; }]
     * @returns {Function|dc.heatMap}
     */
    _chart.colsLabel = function (labelFunction) {
        if (!arguments.length) {
            return _colsLabel;
        }
        _colsLabel = labelFunction;
        return _chart;
    };

    /**
     * Set or get the row label function. The chart class uses this function to render
     * row labels on the Y axis. It is passed the row name.
     * @method rowsLabel
     * @memberof dc.heatMap
     * @instance
     * @example
     * // the default label function just returns the name
     * chart.rowsLabel(function(d) { return d; });
     * @param  {Function} [labelFunction=function(d) { return d; }]
     * @returns {Function|dc.heatMap}
     */
    _chart.rowsLabel = function (labelFunction) {
        if (!arguments.length) {
            return _rowsLabel;
        }
        _rowsLabel = labelFunction;
        return _chart;
    };

    var _xAxisOnClick = function (d) { filterAxis(0, d); };
    var _yAxisOnClick = function (d) { filterAxis(1, d); };
    var _boxOnClick = function (d) {
        var filter = d.key;
        dc.events.trigger(function () {
            _chart.filter(filter);
            _chart.redrawGroup();
        });
    };

    function filterAxis (axis, value) {
        var cellsOnAxis = _chart.selectAll('.box-group').filter(function (d) {
            return d.key[axis] === value;
        });
        var unfilteredCellsOnAxis = cellsOnAxis.filter(function (d) {
            return !_chart.hasFilter(d.key);
        });
        dc.events.trigger(function () {
            var selection = unfilteredCellsOnAxis.empty() ? cellsOnAxis : unfilteredCellsOnAxis;
            var filters = selection.data().map(function (kv) {
                return dc.filters.TwoDimensionalFilter(kv.key);
            });
            _chart._filter([filters]);
            _chart.redrawGroup();
        });
    }

    dc.override(_chart, 'filter', function (filter) {
        if (!arguments.length) {
            return _chart._filter();
        }

        return _chart._filter(dc.filters.TwoDimensionalFilter(filter));
    });

    /**
     * Gets or sets the values used to create the rows of the heatmap, as an array. By default, all
     * the values will be fetched from the data using the value accessor.
     * @method rows
     * @memberof dc.heatMap
     * @instance
     * @param  {Array<String|Number>} [rows]
     * @returns {Array<String|Number>|dc.heatMap}
     */

    _chart.rows = function (rows) {
        if (!arguments.length) {
            return _rows;
        }
        _rows = rows;
        return _chart;
    };

    /**
     #### .rowOrdering([orderFunction])
     Get or set an accessor to order the rows.  Default is d3.ascending.
     */
    _chart.rowOrdering = function (_) {
        if (!arguments.length) {
            return _rowOrdering;
        }
        _rowOrdering = _;
        return _chart;
    };

    /**
     * Gets or sets the keys used to create the columns of the heatmap, as an array. By default, all
     * the values will be fetched from the data using the key accessor.
     * @method cols
     * @memberof dc.heatMap
     * @instance
     * @param  {Array<String|Number>} [cols]
     * @returns {Array<String|Number>|dc.heatMap}
     */
    _chart.cols = function (cols) {
        if (!arguments.length) {
            return _cols;
        }
        _cols = cols;
        return _chart;
    };

    /**
     #### .colOrdering([orderFunction])
     Get or set an accessor to order the cols.  Default is ascending.
     */
    _chart.colOrdering = function (_) {
        if (!arguments.length) {
            return _colOrdering;
        }
        _colOrdering = _;
        return _chart;
    };

    _chart._doRender = function () {
        _chart.resetSvg();

        _chartBody = _chart.svg()
            .append('g')
            .attr('class', 'heatmap')
            .attr('transform', 'translate(' + _chart.margins().left + ',' + _chart.margins().top + ')');

        return _chart._doRedraw();
    };

    _chart._doRedraw = function () {
        var data = _chart.data(),
            rows = _chart.rows() || data.map(_chart.valueAccessor()),
            cols = _chart.cols() || data.map(_chart.keyAccessor());
        if (_rowOrdering) {
            rows = rows.sort(_rowOrdering);
        }
        if (_colOrdering) {
            cols = cols.sort(_colOrdering);
        }
        rows = _rowScale.domain(rows);
        cols = _colScale.domain(cols);

        var rowCount = rows.domain().length,
            colCount = cols.domain().length,
            boxWidth = Math.floor(_chart.effectiveWidth() / colCount),
            boxHeight = Math.floor(_chart.effectiveHeight() / rowCount);

        cols.rangeRound([0, _chart.effectiveWidth()]);
        rows.rangeRound([_chart.effectiveHeight(), 0]);

        var boxes = _chartBody.selectAll('g.box-group').data(_chart.data(), function (d, i) {
            return _chart.keyAccessor()(d, i) + '\0' + _chart.valueAccessor()(d, i);
        });

        boxes.exit().remove();

        var gEnter = boxes.enter().append('g')
            .attr('class', 'box-group');

        gEnter.append('rect')
            .attr('class', 'heat-box')
            .attr('fill', 'white')
            .attr('x', function (d, i) { return cols(_chart.keyAccessor()(d, i)); })
            .attr('y', function (d, i) { return rows(_chart.valueAccessor()(d, i)); })
            .on('click', _chart.boxOnClick());

        boxes = gEnter.merge(boxes);

        if (_chart.renderTitle()) {
            gEnter.append('title');
            boxes.select('title').text(_chart.title());
        }

        dc.transition(boxes.select('rect'), _chart.transitionDuration(), _chart.transitionDelay())
            .attr('x', function (d, i) { return cols(_chart.keyAccessor()(d, i)); })
            .attr('y', function (d, i) { return rows(_chart.valueAccessor()(d, i)); })
            .attr('rx', _xBorderRadius)
            .attr('ry', _yBorderRadius)
            .attr('fill', _chart.getColor)
            .attr('width', boxWidth)
            .attr('height', boxHeight);

        var gCols = _chartBody.select('g.cols');
        if (gCols.empty()) {
            gCols = _chartBody.append('g').attr('class', 'cols axis');
        }
        var gColsText = gCols.selectAll('text').data(cols.domain());

        gColsText.exit().remove();

        gColsText = gColsText
            .enter()
                .append('text')
                .attr('x', function (d) {
                    return cols(d) + boxWidth / 2;
                })
                .style('text-anchor', 'middle')
                .attr('y', _chart.effectiveHeight())
                .attr('dy', 12)
                .on('click', _chart.xAxisOnClick())
                .text(_chart.colsLabel())
            .merge(gColsText);

        dc.transition(gColsText, _chart.transitionDuration(), _chart.transitionDelay())
               .text(_chart.colsLabel())
               .attr('x', function (d) { return cols(d) + boxWidth / 2; })
               .attr('y', _chart.effectiveHeight());

        var gRows = _chartBody.select('g.rows');
        if (gRows.empty()) {
            gRows = _chartBody.append('g').attr('class', 'rows axis');
        }

        var gRowsText = gRows.selectAll('text').data(rows.domain());

        gRowsText.exit().remove();

        gRowsText = gRowsText
            .enter()
            .append('text')
                .style('text-anchor', 'end')
                .attr('x', 0)
                .attr('dx', -2)
                .attr('y', function (d) { return rows(d) + boxHeight / 2; })
                .attr('dy', 6)
                .on('click', _chart.yAxisOnClick())
                .text(_chart.rowsLabel())
            .merge(gRowsText);

        dc.transition(gRowsText, _chart.transitionDuration(), _chart.transitionDelay())
              .text(_chart.rowsLabel())
              .attr('y', function (d) { return rows(d) + boxHeight / 2; });

        if (_chart.hasFilter()) {
            _chart.selectAll('g.box-group').each(function (d) {
                if (_chart.isSelectedNode(d)) {
                    _chart.highlightSelected(this);
                } else {
                    _chart.fadeDeselected(this);
                }
            });
        } else {
            _chart.selectAll('g.box-group').each(function () {
                _chart.resetHighlight(this);
            });
        }
        return _chart;
    };

    /**
     * Gets or sets the handler that fires when an individual cell is clicked in the heatmap.
     * By default, filtering of the cell will be toggled.
     * @method boxOnClick
     * @memberof dc.heatMap
     * @instance
     * @example
     * // default box on click handler
     * chart.boxOnClick(function (d) {
     *     var filter = d.key;
     *     dc.events.trigger(function () {
     *         _chart.filter(filter);
     *         _chart.redrawGroup();
     *     });
     * });
     * @param  {Function} [handler]
     * @returns {Function|dc.heatMap}
     */
    _chart.boxOnClick = function (handler) {
        if (!arguments.length) {
            return _boxOnClick;
        }
        _boxOnClick = handler;
        return _chart;
    };

    /**
     * Gets or sets the handler that fires when a column tick is clicked in the x axis.
     * By default, if any cells in the column are unselected, the whole column will be selected,
     * otherwise the whole column will be unselected.
     * @method xAxisOnClick
     * @memberof dc.heatMap
     * @instance
     * @param  {Function} [handler]
     * @returns {Function|dc.heatMap}
     */
    _chart.xAxisOnClick = function (handler) {
        if (!arguments.length) {
            return _xAxisOnClick;
        }
        _xAxisOnClick = handler;
        return _chart;
    };

    /**
     * Gets or sets the handler that fires when a row tick is clicked in the y axis.
     * By default, if any cells in the row are unselected, the whole row will be selected,
     * otherwise the whole row will be unselected.
     * @method yAxisOnClick
     * @memberof dc.heatMap
     * @instance
     * @param  {Function} [handler]
     * @returns {Function|dc.heatMap}
     */
    _chart.yAxisOnClick = function (handler) {
        if (!arguments.length) {
            return _yAxisOnClick;
        }
        _yAxisOnClick = handler;
        return _chart;
    };

    /**
     * Gets or sets the X border radius.  Set to 0 to get full rectangles.
     * @method xBorderRadius
     * @memberof dc.heatMap
     * @instance
     * @param  {Number} [xBorderRadius=6.75]
     * @returns {Number|dc.heatMap}
     */
    _chart.xBorderRadius = function (xBorderRadius) {
        if (!arguments.length) {
            return _xBorderRadius;
        }
        _xBorderRadius = xBorderRadius;
        return _chart;
    };

    /**
     * Gets or sets the Y border radius.  Set to 0 to get full rectangles.
     * @method yBorderRadius
     * @memberof dc.heatMap
     * @instance
     * @param  {Number} [yBorderRadius=6.75]
     * @returns {Number|dc.heatMap}
     */
    _chart.yBorderRadius = function (yBorderRadius) {
        if (!arguments.length) {
            return _yBorderRadius;
        }
        _yBorderRadius = yBorderRadius;
        return _chart;
    };

    _chart.isSelectedNode = function (d) {
        return _chart.hasFilter(d.key);
    };

    return _chart.anchor(parent, chartGroup);
};
