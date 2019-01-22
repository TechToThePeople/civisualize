/**
 * Concrete row chart implementation.
 *
 * Examples:
 * - {@link http://dc-js.github.com/dc.js/ Nasdaq 100 Index}
 * @class rowChart
 * @memberof dc
 * @mixes dc.capMixin
 * @mixes dc.marginMixin
 * @mixes dc.colorMixin
 * @mixes dc.baseMixin
 * @example
 * // create a row chart under #chart-container1 element using the default global chart group
 * var chart1 = dc.rowChart('#chart-container1');
 * // create a row chart under #chart-container2 element using chart group A
 * var chart2 = dc.rowChart('#chart-container2', 'chartGroupA');
 * @param {String|node|d3.selection} parent - Any valid
 * {@link https://github.com/d3/d3-selection/blob/master/README.md#select d3 single selector} specifying
 * a dom block element such as a div; or a dom element or d3 selection.
 * @param {String} [chartGroup] - The name of the chart group this chart instance should be placed in.
 * Interaction with a chart will only trigger events and redraws within the chart's group.
 * @returns {dc.rowChart}
 */
dc.rowChart = function (parent, chartGroup) {

    var _g;

    var _labelOffsetX = 10;
    var _labelOffsetY = 15;
    var _hasLabelOffsetY = false;
    var _dyOffset = '0.35em';  // this helps center labels https://github.com/d3/d3-3.x-api-reference/blob/master/SVG-Shapes.md#svg_text
    var _titleLabelOffsetX = 2;

    var _gap = 5;

    var _fixedBarHeight = false;
    var _rowCssClass = 'row';
    var _titleRowCssClass = 'titlerow';
    var _renderTitleLabel = false;

    var _chart = dc.capMixin(dc.marginMixin(dc.colorMixin(dc.baseMixin({}))));

    var _x;

    var _elasticX;

    var _xAxis = d3.axisBottom();

    var _rowData;

    _chart.rowsCap = _chart.cap;

    function calculateAxisScale () {
        if (!_x || _elasticX) {
            var extent = d3.extent(_rowData, _chart.cappedValueAccessor);
            if (extent[0] > 0) {
                extent[0] = 0;
            }
            if (extent[1] < 0) {
                extent[1] = 0;
            }
            _x = d3.scaleLinear().domain(extent)
                .range([0, _chart.effectiveWidth()]);
        }
        _xAxis.scale(_x);
    }

    function drawAxis () {
        var axisG = _g.select('g.axis');

        calculateAxisScale();

        if (axisG.empty()) {
            axisG = _g.append('g').attr('class', 'axis');
        }
        axisG.attr('transform', 'translate(0, ' + _chart.effectiveHeight() + ')');

        dc.transition(axisG, _chart.transitionDuration(), _chart.transitionDelay())
            .call(_xAxis);
    }

    _chart._doRender = function () {
        _chart.resetSvg();

        _g = _chart.svg()
            .append('g')
            .attr('transform', 'translate(' + _chart.margins().left + ',' + _chart.margins().top + ')');

        drawChart();

        return _chart;
    };

    _chart.title(function (d) {
        return _chart.cappedKeyAccessor(d) + ': ' + _chart.cappedValueAccessor(d);
    });

    _chart.label(_chart.cappedKeyAccessor);

    /**
     * Gets or sets the x scale. The x scale can be any d3
     * {@link https://github.com/d3/d3-scale/blob/master/README.md d3.scale}.
     * @method x
     * @memberof dc.rowChart
     * @instance
     * @see {@link https://github.com/d3/d3-scale/blob/master/README.md d3.scale}
     * @param {d3.scale} [scale]
     * @returns {d3.scale|dc.rowChart}
     */
    _chart.x = function (scale) {
        if (!arguments.length) {
            return _x;
        }
        _x = scale;
        return _chart;
    };

    function drawGridLines () {
        _g.selectAll('g.tick')
            .select('line.grid-line')
            .remove();

        _g.selectAll('g.tick')
            .append('line')
            .attr('class', 'grid-line')
            .attr('x1', 0)
            .attr('y1', 0)
            .attr('x2', 0)
            .attr('y2', function () {
                return -_chart.effectiveHeight();
            });
    }

    function drawChart () {
        _rowData = _chart.data();

        drawAxis();
        drawGridLines();

        var rows = _g.selectAll('g.' + _rowCssClass)
            .data(_rowData);

        removeElements(rows);
        rows = createElements(rows)
            .merge(rows);
        updateElements(rows);
    }

    function createElements (rows) {
        var rowEnter = rows.enter()
            .append('g')
            .attr('class', function (d, i) {
                return _rowCssClass + ' _' + i;
            });

        rowEnter.append('rect').attr('width', 0);

        createLabels(rowEnter);

        return rowEnter;
    }

    function removeElements (rows) {
        rows.exit().remove();
    }

    function rootValue () {
        var root = _x(0);
        return (root === -Infinity || root !== root) ? _x(1) : root;
    }

    function updateElements (rows) {
        var n = _rowData.length;

        var height;
        if (!_fixedBarHeight) {
            height = (_chart.effectiveHeight() - (n + 1) * _gap) / n;
        } else {
            height = _fixedBarHeight;
        }

        // vertically align label in center unless they override the value via property setter
        if (!_hasLabelOffsetY) {
            _labelOffsetY = height / 2;
        }

        var rect = rows.attr('transform', function (d, i) {
                return 'translate(0,' + ((i + 1) * _gap + i * height) + ')';
            }).select('rect')
            .attr('height', height)
            .attr('fill', _chart.getColor)
            .on('click', onClick)
            .classed('deselected', function (d) {
                return (_chart.hasFilter()) ? !isSelectedRow(d) : false;
            })
            .classed('selected', function (d) {
                return (_chart.hasFilter()) ? isSelectedRow(d) : false;
            });

        dc.transition(rect, _chart.transitionDuration(), _chart.transitionDelay())
            .attr('width', function (d) {
                return Math.abs(rootValue() - _x(_chart.cappedValueAccessor(d)));
            })
            .attr('transform', translateX);

        createTitles(rows);
        updateLabels(rows);
    }

    function createTitles (rows) {
        if (_chart.renderTitle()) {
            rows.select('title').remove();
            rows.append('title').text(_chart.title());
        }
    }

    function createLabels (rowEnter) {
        if (_chart.renderLabel()) {
            rowEnter.append('text')
                .on('click', onClick);
        }
        if (_chart.renderTitleLabel()) {
            rowEnter.append('text')
                .attr('class', _titleRowCssClass)
                .on('click', onClick);
        }
    }

    function updateLabels (rows) {
        if (_chart.renderLabel()) {
            var lab = rows.select('text')
                .attr('x', _labelOffsetX)
                .attr('y', _labelOffsetY)
                .attr('dy', _dyOffset)
                .on('click', onClick)
                .attr('class', function (d, i) {
                    return _rowCssClass + ' _' + i;
                })
                .text(function (d) {
                    return _chart.label()(d);
                });
            dc.transition(lab, _chart.transitionDuration(), _chart.transitionDelay())
                .attr('transform', translateX);
        }
        if (_chart.renderTitleLabel()) {
            var titlelab = rows.select('.' + _titleRowCssClass)
                    .attr('x', _chart.effectiveWidth() - _titleLabelOffsetX)
                    .attr('y', _labelOffsetY)
                    .attr('dy', _dyOffset)
                    .attr('text-anchor', 'end')
                    .on('click', onClick)
                    .attr('class', function (d, i) {
                        return _titleRowCssClass + ' _' + i ;
                    })
                    .text(function (d) {
                        return _chart.title()(d);
                    });
            dc.transition(titlelab, _chart.transitionDuration(), _chart.transitionDelay())
                .attr('transform', translateX);
        }
    }

    /**
     * Turn on/off Title label rendering (values) using SVG style of text-anchor 'end'.
     * @method renderTitleLabel
     * @memberof dc.rowChart
     * @instance
     * @param {Boolean} [renderTitleLabel=false]
     * @returns {Boolean|dc.rowChart}
     */
    _chart.renderTitleLabel = function (renderTitleLabel) {
        if (!arguments.length) {
            return _renderTitleLabel;
        }
        _renderTitleLabel = renderTitleLabel;
        return _chart;
    };

    function onClick (d) {
        _chart.onClick(d);
    }

    function translateX (d) {
        var x = _x(_chart.cappedValueAccessor(d)),
            x0 = rootValue(),
            s = x > x0 ? x0 : x;
        return 'translate(' + s + ',0)';
    }

    _chart._doRedraw = function () {
        drawChart();
        return _chart;
    };

    /**
     * Get or sets the x axis for the row chart instance.
     * See the {@link https://github.com/d3/d3-axis/blob/master/README.md d3.axis}
     * documention for more information.
     * @method xAxis
     * @memberof dc.rowChart
     * @instance
     * @example
     * // customize x axis tick format
     * chart.xAxis().tickFormat(function (v) {return v + '%';});
     * // customize x axis tick values
     * chart.xAxis().tickValues([0, 100, 200, 300]);
     * // use a top-oriented axis. Note: position of the axis and grid lines will need to
     * // be set manually, see https://dc-js.github.io/dc.js/examples/row-top-axis.html
     * chart.xAxis(d3.axisTop())
     * @returns {d3.axis}
     */
    _chart.xAxis = function (xAxis) {
        if (!arguments.length) {
            return _xAxis;
        }
        _xAxis = xAxis;
        return this;
    };

    /**
     * Get or set the fixed bar height. Default is [false] which will auto-scale bars.
     * For example, if you want to fix the height for a specific number of bars (useful in TopN charts)
     * you could fix height as follows (where count = total number of bars in your TopN and gap is
     * your vertical gap space).
     * @method fixedBarHeight
     * @memberof dc.rowChart
     * @instance
     * @example
     * chart.fixedBarHeight( chartheight - (count + 1) * gap / count);
     * @param {Boolean|Number} [fixedBarHeight=false]
     * @returns {Boolean|Number|dc.rowChart}
     */
    _chart.fixedBarHeight = function (fixedBarHeight) {
        if (!arguments.length) {
            return _fixedBarHeight;
        }
        _fixedBarHeight = fixedBarHeight;
        return _chart;
    };

    /**
     * Get or set the vertical gap space between rows on a particular row chart instance.
     * @method gap
     * @memberof dc.rowChart
     * @instance
     * @param {Number} [gap=5]
     * @returns {Number|dc.rowChart}
     */
    _chart.gap = function (gap) {
        if (!arguments.length) {
            return _gap;
        }
        _gap = gap;
        return _chart;
    };

    /**
     * Get or set the elasticity on x axis. If this attribute is set to true, then the x axis will rescle to auto-fit the
     * data range when filtered.
     * @method elasticX
     * @memberof dc.rowChart
     * @instance
     * @param {Boolean} [elasticX]
     * @returns {Boolean|dc.rowChart}
     */
    _chart.elasticX = function (elasticX) {
        if (!arguments.length) {
            return _elasticX;
        }
        _elasticX = elasticX;
        return _chart;
    };

    /**
     * Get or set the x offset (horizontal space to the top left corner of a row) for labels on a particular row chart.
     * @method labelOffsetX
     * @memberof dc.rowChart
     * @instance
     * @param {Number} [labelOffsetX=10]
     * @returns {Number|dc.rowChart}
     */
    _chart.labelOffsetX = function (labelOffsetX) {
        if (!arguments.length) {
            return _labelOffsetX;
        }
        _labelOffsetX = labelOffsetX;
        return _chart;
    };

    /**
     * Get or set the y offset (vertical space to the top left corner of a row) for labels on a particular row chart.
     * @method labelOffsetY
     * @memberof dc.rowChart
     * @instance
     * @param {Number} [labelOffsety=15]
     * @returns {Number|dc.rowChart}
     */
    _chart.labelOffsetY = function (labelOffsety) {
        if (!arguments.length) {
            return _labelOffsetY;
        }
        _labelOffsetY = labelOffsety;
        _hasLabelOffsetY = true;
        return _chart;
    };

    /**
     * Get of set the x offset (horizontal space between right edge of row and right edge or text.
     * @method titleLabelOffsetX
     * @memberof dc.rowChart
     * @instance
     * @param {Number} [titleLabelOffsetX=2]
     * @returns {Number|dc.rowChart}
     */
    _chart.titleLabelOffsetX = function (titleLabelOffsetX) {
        if (!arguments.length) {
            return _titleLabelOffsetX;
        }
        _titleLabelOffsetX = titleLabelOffsetX;
        return _chart;
    };

    function isSelectedRow (d) {
        return _chart.hasFilter(_chart.cappedKeyAccessor(d));
    }

    return _chart.anchor(parent, chartGroup);
};
