/**
 * Composite charts are a special kind of chart that render multiple charts on the same Coordinate
 * Grid. You can overlay (compose) different bar/line/area charts in a single composite chart to
 * achieve some quite flexible charting effects.
 * @class compositeChart
 * @memberof dc
 * @mixes dc.coordinateGridMixin
 * @example
 * // create a composite chart under #chart-container1 element using the default global chart group
 * var compositeChart1 = dc.compositeChart('#chart-container1');
 * // create a composite chart under #chart-container2 element using chart group A
 * var compositeChart2 = dc.compositeChart('#chart-container2', 'chartGroupA');
 * @param {String|node|d3.selection} parent - Any valid
 * {@link https://github.com/d3/d3-selection/blob/master/README.md#select d3 single selector} specifying
 * a dom block element such as a div; or a dom element or d3 selection.
 * @param {String} [chartGroup] - The name of the chart group this chart instance should be placed in.
 * Interaction with a chart will only trigger events and redraws within the chart's group.
 * @returns {dc.compositeChart}
 */
dc.compositeChart = function (parent, chartGroup) {

    var SUB_CHART_CLASS = 'sub';
    var DEFAULT_RIGHT_Y_AXIS_LABEL_PADDING = 12;

    var _chart = dc.coordinateGridMixin({});
    var _children = [];

    var _childOptions = {};

    var _shareColors = false,
        _shareTitle = true,
        _alignYAxes = false;

    var _rightYAxis = d3.axisRight(),
        _rightYAxisLabel = 0,
        _rightYAxisLabelPadding = DEFAULT_RIGHT_Y_AXIS_LABEL_PADDING,
        _rightY,
        _rightAxisGridLines = false;

    _chart._mandatoryAttributes([]);
    _chart.transitionDuration(500);
    _chart.transitionDelay(0);

    dc.override(_chart, '_generateG', function () {
        var g = this.__generateG();

        for (var i = 0; i < _children.length; ++i) {
            var child = _children[i];

            generateChildG(child, i);

            if (!child.dimension()) {
                child.dimension(_chart.dimension());
            }
            if (!child.group()) {
                child.group(_chart.group());
            }

            child.chartGroup(_chart.chartGroup());
            child.svg(_chart.svg());
            child.xUnits(_chart.xUnits());
            child.transitionDuration(_chart.transitionDuration(), _chart.transitionDelay());
            child.parentBrushOn(_chart.brushOn());
            child.brushOn(false);
            child.renderTitle(_chart.renderTitle());
            child.elasticX(_chart.elasticX());
        }

        return g;
    });

    _chart.on('filtered.dcjs-composite-chart', function (chart) {
        // Propagate the filters onto the children
        // Notice that on children the call is .replaceFilter and not .filter
        //   the reason is that _chart.filter() returns the entire current set of filters not just the last added one
        for (var i = 0; i < _children.length; ++i) {
            _children[i].replaceFilter(_chart.filter());
        }
    });

    _chart._prepareYAxis = function () {
        var left = (leftYAxisChildren().length !== 0);
        var right = (rightYAxisChildren().length !== 0);
        var ranges = calculateYAxisRanges(left, right);

        if (left) { prepareLeftYAxis(ranges); }
        if (right) { prepareRightYAxis(ranges); }

        if (leftYAxisChildren().length > 0 && !_rightAxisGridLines) {
            _chart._renderHorizontalGridLinesForAxis(_chart.g(), _chart.y(), _chart.yAxis());
        } else if (rightYAxisChildren().length > 0) {
            _chart._renderHorizontalGridLinesForAxis(_chart.g(), _rightY, _rightYAxis);
        }
    };

    _chart.renderYAxis = function () {
        if (leftYAxisChildren().length !== 0) {
            _chart.renderYAxisAt('y', _chart.yAxis(), _chart.margins().left);
            _chart.renderYAxisLabel('y', _chart.yAxisLabel(), -90);
        }

        if (rightYAxisChildren().length !== 0) {
            _chart.renderYAxisAt('yr', _chart.rightYAxis(), _chart.width() - _chart.margins().right);
            _chart.renderYAxisLabel('yr', _chart.rightYAxisLabel(), 90, _chart.width() - _rightYAxisLabelPadding);
        }
    };

    function calculateYAxisRanges (left, right) {
        var lyAxisMin, lyAxisMax, ryAxisMin, ryAxisMax;
        var ranges;

        if (left) {
            lyAxisMin = yAxisMin();
            lyAxisMax = yAxisMax();
        }

        if (right) {
            ryAxisMin = rightYAxisMin();
            ryAxisMax = rightYAxisMax();
        }

        if (_chart.alignYAxes() && left && right) {
            ranges = alignYAxisRanges(lyAxisMin, lyAxisMax, ryAxisMin, ryAxisMax);
        }

        return ranges || {
            lyAxisMin: lyAxisMin,
            lyAxisMax: lyAxisMax,
            ryAxisMin: ryAxisMin,
            ryAxisMax: ryAxisMax
        };
    }

    function alignYAxisRanges (lyAxisMin, lyAxisMax, ryAxisMin, ryAxisMax) {
        // since the two series will share a zero, each Y is just a multiple
        // of the other. and the ratio should be the ratio of the ranges of the
        // input data, so that they come out the same height. so we just min/max

        // note: both ranges already include zero due to the stack mixin (#667)
        // if #667 changes, we can reconsider whether we want data height or
        // height from zero to be equal. and it will be possible for the axes
        // to be aligned but not visible.
        var extentRatio = (ryAxisMax - ryAxisMin) / (lyAxisMax - lyAxisMin);

        return {
            lyAxisMin: Math.min(lyAxisMin, ryAxisMin / extentRatio),
            lyAxisMax: Math.max(lyAxisMax, ryAxisMax / extentRatio),
            ryAxisMin: Math.min(ryAxisMin, lyAxisMin * extentRatio),
            ryAxisMax: Math.max(ryAxisMax, lyAxisMax * extentRatio)
        };
    }

    function prepareRightYAxis (ranges) {
        var needDomain = _chart.rightY() === undefined || _chart.elasticY(),
            needRange = needDomain || _chart.resizing();
        if (_chart.rightY() === undefined) {
            _chart.rightY(d3.scaleLinear());
        }
        if (needDomain) {
            _chart.rightY().domain([ranges.ryAxisMin, ranges.ryAxisMax]);
        }
        if (needRange) {
            _chart.rightY().rangeRound([_chart.yAxisHeight(), 0]);
        }

        _chart.rightY().range([_chart.yAxisHeight(), 0]);
        _chart.rightYAxis(_chart.rightYAxis().scale(_chart.rightY()));

        // In D3v4 create a RightAxis
        // _chart.rightYAxis().orient('right');
    }

    function prepareLeftYAxis (ranges) {
        var needDomain = _chart.y() === undefined || _chart.elasticY(),
            needRange = needDomain || _chart.resizing();
        if (_chart.y() === undefined) {
            _chart.y(d3.scaleLinear());
        }
        if (needDomain) {
            _chart.y().domain([ranges.lyAxisMin, ranges.lyAxisMax]);
        }
        if (needRange) {
            _chart.y().rangeRound([_chart.yAxisHeight(), 0]);
        }

        _chart.y().range([_chart.yAxisHeight(), 0]);
        _chart.yAxis(_chart.yAxis().scale(_chart.y()));

        // In D3v4 create a LeftAxis
        // _chart.yAxis().orient('left');
    }

    function generateChildG (child, i) {
        child._generateG(_chart.g());
        child.g().attr('class', SUB_CHART_CLASS + ' _' + i);
    }

    _chart.plotData = function () {
        for (var i = 0; i < _children.length; ++i) {
            var child = _children[i];

            if (!child.g()) {
                generateChildG(child, i);
            }

            if (_shareColors) {
                child.colors(_chart.colors());
            }

            child.x(_chart.x());

            child.xAxis(_chart.xAxis());

            if (child.useRightYAxis()) {
                child.y(_chart.rightY());
                child.yAxis(_chart.rightYAxis());
            } else {
                child.y(_chart.y());
                child.yAxis(_chart.yAxis());
            }

            child.plotData();

            child._activateRenderlets();
        }
    };

    /**
     * Get or set whether to draw gridlines from the right y axis.  Drawing from the left y axis is the
     * default behavior. This option is only respected when subcharts with both left and right y-axes
     * are present.
     * @method useRightAxisGridLines
     * @memberof dc.compositeChart
     * @instance
     * @param {Boolean} [useRightAxisGridLines=false]
     * @returns {Boolean|dc.compositeChart}
     */
    _chart.useRightAxisGridLines = function (useRightAxisGridLines) {
        if (!arguments) {
            return _rightAxisGridLines;
        }

        _rightAxisGridLines = useRightAxisGridLines;
        return _chart;
    };

    /**
     * Get or set chart-specific options for all child charts. This is equivalent to calling
     * {@link dc.baseMixin#options .options} on each child chart.
     *
     * Note: currently you must call this before `compose` in order for the options to be propagated.
     * @method childOptions
     * @memberof dc.compositeChart
     * @instance
     * @param {Object} [childOptions]
     * @returns {Object|dc.compositeChart}
     */
    _chart.childOptions = function (childOptions) {
        if (!arguments.length) {
            return _childOptions;
        }
        _childOptions = childOptions;
        _children.forEach(function (child) {
            child.options(_childOptions);
        });
        return _chart;
    };

    _chart.fadeDeselectedArea = function (brushSelection) {
        if (_chart.brushOn()) {
            for (var i = 0; i < _children.length; ++i) {
                var child = _children[i];
                child.fadeDeselectedArea(brushSelection);
            }
        }
    };

    /**
     * Set or get the right y axis label.
     * @method rightYAxisLabel
     * @memberof dc.compositeChart
     * @instance
     * @param {String} [rightYAxisLabel]
     * @param {Number} [padding]
     * @returns {String|dc.compositeChart}
     */
    _chart.rightYAxisLabel = function (rightYAxisLabel, padding) {
        if (!arguments.length) {
            return _rightYAxisLabel;
        }
        _rightYAxisLabel = rightYAxisLabel;
        _chart.margins().right -= _rightYAxisLabelPadding;
        _rightYAxisLabelPadding = (padding === undefined) ? DEFAULT_RIGHT_Y_AXIS_LABEL_PADDING : padding;
        _chart.margins().right += _rightYAxisLabelPadding;
        return _chart;
    };

    /**
     * Combine the given charts into one single composite coordinate grid chart.
     *
     * Note: currently due to the way it is implemented, you must call this function at the end of
     * initialization of the composite chart, in particular after `shareTitle`, `childOptions`,
     * `width`, `height`, and `margins`, in order for the settings to get propagated to the children
     * correctly.
     * @method compose
     * @memberof dc.compositeChart
     * @instance
     * @example
     * moveChart.compose([
     *     // when creating sub-chart you need to pass in the parent chart
     *     dc.lineChart(moveChart)
     *         .group(indexAvgByMonthGroup) // if group is missing then parent's group will be used
     *         .valueAccessor(function (d){return d.value.avg;})
     *         // most of the normal functions will continue to work in a composed chart
     *         .renderArea(true)
     *         .stack(monthlyMoveGroup, function (d){return d.value;})
     *         .title(function (d){
     *             var value = d.value.avg?d.value.avg:d.value;
     *             if(isNaN(value)) value = 0;
     *             return dateFormat(d.key) + '\n' + numberFormat(value);
     *         }),
     *     dc.barChart(moveChart)
     *         .group(volumeByMonthGroup)
     *         .centerBar(true)
     * ]);
     * @param {Array<Chart>} [subChartArray]
     * @returns {dc.compositeChart}
     */
    _chart.compose = function (subChartArray) {
        _children = subChartArray;
        _children.forEach(function (child) {
            child.height(_chart.height());
            child.width(_chart.width());
            child.margins(_chart.margins());

            if (_shareTitle) {
                child.title(_chart.title());
            }

            child.options(_childOptions);
        });
        return _chart;
    };

    /**
     * Returns the child charts which are composed into the composite chart.
     * @method children
     * @memberof dc.compositeChart
     * @instance
     * @returns {Array<dc.baseMixin>}
     */
    _chart.children = function () {
        return _children;
    };

    /**
     * Get or set color sharing for the chart. If set, the {@link dc.colorMixin#colors .colors()} value from this chart
     * will be shared with composed children. Additionally if the child chart implements
     * Stackable and has not set a custom .colorAccessor, then it will generate a color
     * specific to its order in the composition.
     * @method shareColors
     * @memberof dc.compositeChart
     * @instance
     * @param {Boolean} [shareColors=false]
     * @returns {Boolean|dc.compositeChart}
     */
    _chart.shareColors = function (shareColors) {
        if (!arguments.length) {
            return _shareColors;
        }
        _shareColors = shareColors;
        return _chart;
    };

    /**
     * Get or set title sharing for the chart. If set, the {@link dc.baseMixin#title .title()} value from
     * this chart will be shared with composed children.
     *
     * Note: currently you must call this before `compose` or the child will still get the parent's
     * `title` function!
     * @method shareTitle
     * @memberof dc.compositeChart
     * @instance
     * @param {Boolean} [shareTitle=true]
     * @returns {Boolean|dc.compositeChart}
     */
    _chart.shareTitle = function (shareTitle) {
        if (!arguments.length) {
            return _shareTitle;
        }
        _shareTitle = shareTitle;
        return _chart;
    };

    /**
     * Get or set the y scale for the right axis. The right y scale is typically automatically
     * generated by the chart implementation.
     * @method rightY
     * @memberof dc.compositeChart
     * @instance
     * @see {@link https://github.com/d3/d3-scale/blob/master/README.md d3.scale}
     * @param {d3.scale} [yScale]
     * @returns {d3.scale|dc.compositeChart}
     */
    _chart.rightY = function (yScale) {
        if (!arguments.length) {
            return _rightY;
        }
        _rightY = yScale;
        _chart.rescale();
        return _chart;
    };

    /**
     * Get or set alignment between left and right y axes. A line connecting '0' on both y axis
     * will be parallel to x axis. This only has effect when {@link #dc.coordinateGridMixin+elasticY elasticY} is true.
     * @method alignYAxes
     * @memberof dc.compositeChart
     * @instance
     * @param {Boolean} [alignYAxes=false]
     * @returns {Chart}
     */
    _chart.alignYAxes = function (alignYAxes) {
        if (!arguments.length) {
            return _alignYAxes;
        }
        _alignYAxes = alignYAxes;
        _chart.rescale();
        return _chart;
    };

    function leftYAxisChildren () {
        return _children.filter(function (child) {
            return !child.useRightYAxis();
        });
    }

    function rightYAxisChildren () {
        return _children.filter(function (child) {
            return child.useRightYAxis();
        });
    }

    function getYAxisMin (charts) {
        return charts.map(function (c) {
            return c.yAxisMin();
        });
    }

    delete _chart.yAxisMin;
    function yAxisMin () {
        return d3.min(getYAxisMin(leftYAxisChildren()));
    }

    function rightYAxisMin () {
        return d3.min(getYAxisMin(rightYAxisChildren()));
    }

    function getYAxisMax (charts) {
        return charts.map(function (c) {
            return c.yAxisMax();
        });
    }

    delete _chart.yAxisMax;
    function yAxisMax () {
        return dc.utils.add(d3.max(getYAxisMax(leftYAxisChildren())), _chart.yAxisPadding());
    }

    function rightYAxisMax () {
        return dc.utils.add(d3.max(getYAxisMax(rightYAxisChildren())), _chart.yAxisPadding());
    }

    function getAllXAxisMinFromChildCharts () {
        return _children.map(function (c) {
            return c.xAxisMin();
        });
    }

    dc.override(_chart, 'xAxisMin', function () {
        return dc.utils.subtract(d3.min(getAllXAxisMinFromChildCharts()), _chart.xAxisPadding(), _chart.xAxisPaddingUnit());
    });

    function getAllXAxisMaxFromChildCharts () {
        return _children.map(function (c) {
            return c.xAxisMax();
        });
    }

    dc.override(_chart, 'xAxisMax', function () {
        return dc.utils.add(d3.max(getAllXAxisMaxFromChildCharts()), _chart.xAxisPadding(), _chart.xAxisPaddingUnit());
    });

    _chart.legendables = function () {
        return _children.reduce(function (items, child) {
            if (_shareColors) {
                child.colors(_chart.colors());
            }
            items.push.apply(items, child.legendables());
            return items;
        }, []);
    };

    _chart.legendHighlight = function (d) {
        for (var j = 0; j < _children.length; ++j) {
            var child = _children[j];
            child.legendHighlight(d);
        }
    };

    _chart.legendReset = function (d) {
        for (var j = 0; j < _children.length; ++j) {
            var child = _children[j];
            child.legendReset(d);
        }
    };

    _chart.legendToggle = function () {
        console.log('composite should not be getting legendToggle itself');
    };

    /**
     * Set or get the right y axis used by the composite chart. This function is most useful when y
     * axis customization is required. The y axis in dc.js is an instance of a
     * [d3.axisRight](https://github.com/d3/d3-axis/blob/master/README.md#axisRight) therefore it supports any valid
     * d3 axis manipulation.
     *
     * **Caution**: The right y axis is usually generated internally by dc; resetting it may cause
     * unexpected results.  Note also that when used as a getter, this function is not chainable: it
     * returns the axis, not the chart,
     * {@link https://github.com/dc-js/dc.js/wiki/FAQ#why-does-everything-break-after-a-call-to-xaxis-or-yaxis
     * so attempting to call chart functions after calling `.yAxis()` will fail}.
     * @method rightYAxis
     * @memberof dc.compositeChart
     * @instance
     * @see {@link https://github.com/d3/d3-axis/blob/master/README.md#axisRight}
     * @example
     * // customize y axis tick format
     * chart.rightYAxis().tickFormat(function (v) {return v + '%';});
     * // customize y axis tick values
     * chart.rightYAxis().tickValues([0, 100, 200, 300]);
     * @param {d3.axisRight} [rightYAxis]
     * @returns {d3.axisRight|dc.compositeChart}
     */
    _chart.rightYAxis = function (rightYAxis) {
        if (!arguments.length) {
            return _rightYAxis;
        }
        _rightYAxis = rightYAxis;
        return _chart;
    };

    return _chart.anchor(parent, chartGroup);
};
