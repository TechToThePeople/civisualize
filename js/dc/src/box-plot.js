
/**
 * A box plot is a chart that depicts numerical data via their quartile ranges.
 *
 * Examples:
 * - {@link http://dc-js.github.io/dc.js/examples/boxplot-basic.html Boxplot Basic example}
 * - {@link http://dc-js.github.io/dc.js/examples/boxplot-enhanced.html Boxplot Enhanced example}
 * - {@link http://dc-js.github.io/dc.js/examples/boxplot-render-data.html Boxplot Render Data example}
 * - {@link http://dc-js.github.io/dc.js/examples/boxplot-time.html Boxplot time example}
 * @class boxPlot
 * @memberof dc
 * @mixes dc.coordinateGridMixin
 * @example
 * // create a box plot under #chart-container1 element using the default global chart group
 * var boxPlot1 = dc.boxPlot('#chart-container1');
 * // create a box plot under #chart-container2 element using chart group A
 * var boxPlot2 = dc.boxPlot('#chart-container2', 'chartGroupA');
 * @param {String|node|d3.selection} parent - Any valid
 * {@link https://github.com/d3/d3-selection/blob/master/README.md#select d3 single selector} specifying
 * a dom block element such as a div; or a dom element or d3 selection.
 * @param {String} [chartGroup] - The name of the chart group this chart instance should be placed in.
 * Interaction with a chart will only trigger events and redraws within the chart's group.
 * @returns {dc.boxPlot}
 */
dc.boxPlot = function (parent, chartGroup) {
    var _chart = dc.coordinateGridMixin({});

    // Returns a function to compute the interquartile range.
    function DEFAULT_WHISKERS_IQR (k) {
        return function (d) {
            var q1 = d.quartiles[0],
                q3 = d.quartiles[2],
                iqr = (q3 - q1) * k,
                i = -1,
                j = d.length;
            do { ++i; } while (d[i] < q1 - iqr);
            do { --j; } while (d[j] > q3 + iqr);
            return [i, j];
        };
    }

    var _whiskerIqrFactor = 1.5;
    var _whiskersIqr = DEFAULT_WHISKERS_IQR;
    var _whiskers = _whiskersIqr(_whiskerIqrFactor);

    var _box = d3.box();
    var _tickFormat = null;
    var _renderDataPoints = false;
    var _dataOpacity = 0.3;
    var _dataWidthPortion = 0.8;
    var _showOutliers = true;
    var _boldOutlier = false;

    // Used in yAxisMin and yAxisMax to add padding in pixel coordinates
    // so the min and max data points/whiskers are within the chart
    var _yRangePadding = 8;

    var _boxWidth = function (innerChartWidth, xUnits) {
        if (_chart.isOrdinal()) {
            return _chart.x().bandwidth();
        } else {
            return innerChartWidth / (1 + _chart.boxPadding()) / xUnits;
        }
    };

    // default to ordinal
    _chart.x(d3.scaleBand());
    _chart.xUnits(dc.units.ordinal);

    // valueAccessor should return an array of values that can be coerced into numbers
    // or if data is overloaded for a static array of arrays, it should be `Number`.
    // Empty arrays are not included.
    _chart.data(function (group) {
        return group.all().map(function (d) {
            d.map = function (accessor) { return accessor.call(d, d); };
            return d;
        }).filter(function (d) {
            var values = _chart.valueAccessor()(d);
            return values.length !== 0;
        });
    });

    /**
     * Get or set the spacing between boxes as a fraction of box size. Valid values are within 0-1.
     * See the {@link https://github.com/d3/d3-scale/blob/master/README.md#scaleBand d3 docs}
     * for a visual description of how the padding is applied.
     * @method boxPadding
     * @memberof dc.boxPlot
     * @instance
     * @see {@link https://github.com/d3/d3-scale/blob/master/README.md#scaleBand d3.scaleBand}
     * @param {Number} [padding=0.8]
     * @returns {Number|dc.boxPlot}
     */
    _chart.boxPadding = _chart._rangeBandPadding;
    _chart.boxPadding(0.8);

    /**
     * Get or set the outer padding on an ordinal box chart. This setting has no effect on non-ordinal charts
     * or on charts with a custom {@link dc.boxPlot#boxWidth .boxWidth}. Will pad the width by
     * `padding * barWidth` on each side of the chart.
     * @method outerPadding
     * @memberof dc.boxPlot
     * @instance
     * @param {Number} [padding=0.5]
     * @returns {Number|dc.boxPlot}
     */
    _chart.outerPadding = _chart._outerRangeBandPadding;
    _chart.outerPadding(0.5);

    /**
     * Get or set the numerical width of the boxplot box. The width may also be a function taking as
     * parameters the chart width excluding the right and left margins, as well as the number of x
     * units.
     * @example
     * // Using numerical parameter
     * chart.boxWidth(10);
     * // Using function
     * chart.boxWidth((innerChartWidth, xUnits) { ... });
     * @method boxWidth
     * @memberof dc.boxPlot
     * @instance
     * @param {Number|Function} [boxWidth=0.5]
     * @returns {Number|Function|dc.boxPlot}
     */
    _chart.boxWidth = function (boxWidth) {
        if (!arguments.length) {
            return _boxWidth;
        }
        _boxWidth = typeof boxWidth === 'function' ? boxWidth : dc.utils.constant(boxWidth);
        return _chart;
    };

    var boxTransform = function (d, i) {
        var xOffset = _chart.x()(_chart.keyAccessor()(d, i));
        return 'translate(' + xOffset + ', 0)';
    };

    _chart._preprocessData = function () {
        if (_chart.elasticX()) {
            _chart.x().domain([]);
        }
    };

    _chart.plotData = function () {
        var _calculatedBoxWidth = _boxWidth(_chart.effectiveWidth(), _chart.xUnitCount());

        _box.whiskers(_whiskers)
            .width(_calculatedBoxWidth)
            .height(_chart.effectiveHeight())
            .value(_chart.valueAccessor())
            .domain(_chart.y().domain())
            .duration(_chart.transitionDuration())
            .tickFormat(_tickFormat)
            .renderDataPoints(_renderDataPoints)
            .dataOpacity(_dataOpacity)
            .dataWidthPortion(_dataWidthPortion)
            .renderTitle(_chart.renderTitle())
            .showOutliers(_showOutliers)
            .boldOutlier(_boldOutlier);

        var boxesG = _chart.chartBodyG().selectAll('g.box').data(_chart.data(), _chart.keyAccessor());

        var boxesGEnterUpdate = renderBoxes(boxesG);
        updateBoxes(boxesGEnterUpdate);
        removeBoxes(boxesG);

        _chart.fadeDeselectedArea(_chart.filter());
    };

    function renderBoxes (boxesG) {
        var boxesGEnter = boxesG.enter().append('g');

        boxesGEnter
            .attr('class', 'box')
            .attr('transform', boxTransform)
            .call(_box)
            .on('click', function (d) {
                _chart.filter(_chart.keyAccessor()(d));
                _chart.redrawGroup();
            });
        return boxesGEnter.merge(boxesG);
    }

    function updateBoxes (boxesG) {
        dc.transition(boxesG, _chart.transitionDuration(), _chart.transitionDelay())
            .attr('transform', boxTransform)
            .call(_box)
            .each(function (d) {
                var color = _chart.getColor(d, 0);
                d3.select(this).select('rect.box').attr('fill', color);
                d3.select(this).selectAll('circle.data').attr('fill', color);
            });
    }

    function removeBoxes (boxesG) {
        boxesG.exit().remove().call(_box);
    }

    function minDataValue () {
        return d3.min(_chart.data(), function (e) {
            return d3.min(_chart.valueAccessor()(e));
        });
    }

    function maxDataValue () {
        return d3.max(_chart.data(), function (e) {
            return d3.max(_chart.valueAccessor()(e));
        });
    }

    function yAxisRangeRatio () {
        return ((maxDataValue() - minDataValue()) / _chart.effectiveHeight());
    }

    _chart.fadeDeselectedArea = function (brushSelection) {
        if (_chart.hasFilter()) {
            if (_chart.isOrdinal()) {
                _chart.g().selectAll('g.box').each(function (d) {
                    if (_chart.isSelectedNode(d)) {
                        _chart.highlightSelected(this);
                    } else {
                        _chart.fadeDeselected(this);
                    }
                });
            } else {
                if (!(_chart.brushOn() || _chart.parentBrushOn())) {
                    return;
                }
                var start = brushSelection[0];
                var end = brushSelection[1];
                var keyAccessor = _chart.keyAccessor();
                _chart.g().selectAll('g.box').each(function (d) {
                    var key = keyAccessor(d);
                    if (key < start || key >= end) {
                        _chart.fadeDeselected(this);
                    } else {
                        _chart.highlightSelected(this);
                    }
                });
            }
        } else {
            _chart.g().selectAll('g.box').each(function () {
                _chart.resetHighlight(this);
            });
        }
    };

    _chart.isSelectedNode = function (d) {
        return _chart.hasFilter(_chart.keyAccessor()(d));
    };

    _chart.yAxisMin = function () {
        var padding = _yRangePadding * yAxisRangeRatio();
        return dc.utils.subtract(minDataValue() - padding, _chart.yAxisPadding());
    };

    _chart.yAxisMax = function () {
        var padding = _yRangePadding * yAxisRangeRatio();
        return dc.utils.add(maxDataValue() + padding, _chart.yAxisPadding());
    };

    /**
     * Get or set the numerical format of the boxplot median, whiskers and quartile labels. Defaults
     * to integer formatting.
     * @example
     * // format ticks to 2 decimal places
     * chart.tickFormat(d3.format('.2f'));
     * @method tickFormat
     * @memberof dc.boxPlot
     * @instance
     * @param {Function} [tickFormat]
     * @returns {Number|Function|dc.boxPlot}
     */
    _chart.tickFormat = function (tickFormat) {
        if (!arguments.length) {
            return _tickFormat;
        }
        _tickFormat = tickFormat;
        return _chart;
    };

    /**
     * Get or set the amount of padding to add, in pixel coordinates, to the top and
     * bottom of the chart to accommodate box/whisker labels.
     * @example
     * // allow more space for a bigger whisker font
     * chart.yRangePadding(12);
     * @method yRangePadding
     * @memberof dc.boxPlot
     * @instance
     * @param {Function} [yRangePadding = 8]
     * @returns {Number|Function|dc.boxPlot}
     */
    _chart.yRangePadding = function (yRangePadding) {
        if (!arguments.length) {
            return _yRangePadding;
        }
        _yRangePadding = yRangePadding;
        return _chart;
    };

    /**
     * Get or set whether individual data points will be rendered.
     * @example
     * // Enable rendering of individual data points
     * chart.renderDataPoints(true);
     * @method renderDataPoints
     * @memberof dc.boxPlot
     * @instance
     * @param {Boolean} [show=false]
     * @returns {Boolean|dc.boxPlot}
     */
    _chart.renderDataPoints = function (show) {
        if (!arguments.length) {
            return _renderDataPoints;
        }
        _renderDataPoints = show;
        return _chart;
    };

    /**
     * Get or set the opacity when rendering data.
     * @example
     * // If individual data points are rendered increase the opacity.
     * chart.dataOpacity(0.7);
     * @method dataOpacity
     * @memberof dc.boxPlot
     * @instance
     * @param {Number} [opacity=0.3]
     * @returns {Number|dc.boxPlot}
     */
    _chart.dataOpacity = function (opacity) {
        if (!arguments.length) {
            return _dataOpacity;
        }
        _dataOpacity = opacity;
        return _chart;
    };

    /**
     * Get or set the portion of the width of the box to show data points.
     * @example
     * // If individual data points are rendered increase the data box.
     * chart.dataWidthPortion(0.9);
     * @method dataWidthPortion
     * @memberof dc.boxPlot
     * @instance
     * @param {Number} [percentage=0.8]
     * @returns {Number|dc.boxPlot}
     */
    _chart.dataWidthPortion = function (percentage) {
        if (!arguments.length) {
            return _dataWidthPortion;
        }
        _dataWidthPortion = percentage;
        return _chart;
    };

    /**
     * Get or set whether outliers will be rendered.
     * @example
     * // Disable rendering of outliers
     * chart.showOutliers(false);
     * @method showOutliers
     * @memberof dc.boxPlot
     * @instance
     * @param {Boolean} [show=true]
     * @returns {Boolean|dc.boxPlot}
     */
    _chart.showOutliers = function (show) {
        if (!arguments.length) {
            return _showOutliers;
        }
        _showOutliers = show;
        return _chart;
    };

    /**
     * Get or set whether outliers will be drawn bold.
     * @example
     * // If outliers are rendered display as bold
     * chart.boldOutlier(true);
     * @method boldOutlier
     * @memberof dc.boxPlot
     * @instance
     * @param {Boolean} [show=false]
     * @returns {Boolean|dc.boxPlot}
     */
    _chart.boldOutlier = function (show) {
        if (!arguments.length) {
            return _boldOutlier;
        }
        _boldOutlier = show;
        return _chart;
    };

    return _chart.anchor(parent, chartGroup);
};

