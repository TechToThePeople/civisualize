/**
 * Stack Mixin is an mixin that provides cross-chart support of stackability using d3.stackD3v3.
 * @name stackMixin
 * @memberof dc
 * @mixin
 * @param {Object} _chart
 * @returns {dc.stackMixin}
 */
dc.stackMixin = function (_chart) {

    function prepareValues (layer, layerIdx) {
        var valAccessor = layer.accessor || _chart.valueAccessor();
        layer.name = String(layer.name || layerIdx);
        var allValues = layer.group.all().map(function (d, i) {
            return {
                x: _chart.keyAccessor()(d, i),
                y: layer.hidden ? null : valAccessor(d, i),
                data: d,
                layer: layer.name,
                hidden: layer.hidden
            };
        });

        layer.domainValues = allValues.filter(domainFilter());
        layer.values = _chart.evadeDomainFilter() ? allValues : layer.domainValues;
    }

    var _stackLayout = d3.stack();

    var _stack = [];
    var _titles = {};

    var _hidableStacks = false;
    var _evadeDomainFilter = false;

    function domainFilter () {
        if (!_chart.x()) {
            return dc.utils.constant(true);
        }
        var xDomain = _chart.x().domain();
        if (_chart.isOrdinal()) {
            // TODO #416
            //var domainSet = d3.set(xDomain);
            return function () {
                return true; //domainSet.has(p.x);
            };
        }
        if (_chart.elasticX()) {
            return function () { return true; };
        }
        return function (p) {
            //return true;
            return p.x >= xDomain[0] && p.x <= xDomain[xDomain.length - 1];
        };
    }

    /**
     * Stack a new crossfilter group onto this chart with an optional custom value accessor. All stacks
     * in the same chart will share the same key accessor and therefore the same set of keys.
     *
     * For example, in a stacked bar chart, the bars of each stack will be positioned using the same set
     * of keys on the x axis, while stacked vertically. If name is specified then it will be used to
     * generate the legend label.
     * @method stack
     * @memberof dc.stackMixin
     * @instance
     * @see {@link https://github.com/crossfilter/crossfilter/wiki/API-Reference#group-map-reduce crossfilter.group}
     * @example
     * // stack group using default accessor
     * chart.stack(valueSumGroup)
     * // stack group using custom accessor
     * .stack(avgByDayGroup, function(d){return d.value.avgByDay;});
     * @param {crossfilter.group} group
     * @param {String} [name]
     * @param {Function} [accessor]
     * @returns {Array<{group: crossfilter.group, name: String, accessor: Function}>|dc.stackMixin}
     */
    _chart.stack = function (group, name, accessor) {
        if (!arguments.length) {
            return _stack;
        }

        if (arguments.length <= 2) {
            accessor = name;
        }

        var layer = {group: group};
        if (typeof name === 'string') {
            layer.name = name;
        }
        if (typeof accessor === 'function') {
            layer.accessor = accessor;
        }
        _stack.push(layer);

        return _chart;
    };

    dc.override(_chart, 'group', function (g, n, f) {
        if (!arguments.length) {
            return _chart._group();
        }
        _stack = [];
        _titles = {};
        _chart.stack(g, n);
        if (f) {
            _chart.valueAccessor(f);
        }
        return _chart._group(g, n);
    });

    /**
     * Allow named stacks to be hidden or shown by clicking on legend items.
     * This does not affect the behavior of hideStack or showStack.
     * @method hidableStacks
     * @memberof dc.stackMixin
     * @instance
     * @param {Boolean} [hidableStacks=false]
     * @returns {Boolean|dc.stackMixin}
     */
    _chart.hidableStacks = function (hidableStacks) {
        if (!arguments.length) {
            return _hidableStacks;
        }
        _hidableStacks = hidableStacks;
        return _chart;
    };

    function findLayerByName (n) {
        var i = _stack.map(dc.pluck('name')).indexOf(n);
        return _stack[i];
    }

    /**
     * Hide all stacks on the chart with the given name.
     * The chart must be re-rendered for this change to appear.
     * @method hideStack
     * @memberof dc.stackMixin
     * @instance
     * @param {String} stackName
     * @returns {dc.stackMixin}
     */
    _chart.hideStack = function (stackName) {
        var layer = findLayerByName(stackName);
        if (layer) {
            layer.hidden = true;
        }
        return _chart;
    };

    /**
     * Show all stacks on the chart with the given name.
     * The chart must be re-rendered for this change to appear.
     * @method showStack
     * @memberof dc.stackMixin
     * @instance
     * @param {String} stackName
     * @returns {dc.stackMixin}
     */
    _chart.showStack = function (stackName) {
        var layer = findLayerByName(stackName);
        if (layer) {
            layer.hidden = false;
        }
        return _chart;
    };

    _chart.getValueAccessorByIndex = function (index) {
        return _stack[index].accessor || _chart.valueAccessor();
    };

    _chart.yAxisMin = function () {
        var min = d3.min(flattenStack(), function (p) {
            return (p.y < 0) ? (p.y + p.y0) : p.y0;
        });

        return dc.utils.subtract(min, _chart.yAxisPadding());

    };

    _chart.yAxisMax = function () {
        var max = d3.max(flattenStack(), function (p) {
            return (p.y > 0) ? (p.y + p.y0) : p.y0;
        });

        return dc.utils.add(max, _chart.yAxisPadding());
    };

    function flattenStack () {
        var valueses = _chart.data().map(function (layer) { return layer.domainValues; });
        return Array.prototype.concat.apply([], valueses);
    }

    _chart.xAxisMin = function () {
        var min = d3.min(flattenStack(), dc.pluck('x'));
        return dc.utils.subtract(min, _chart.xAxisPadding(), _chart.xAxisPaddingUnit());
    };

    _chart.xAxisMax = function () {
        var max = d3.max(flattenStack(), dc.pluck('x'));
        return dc.utils.add(max, _chart.xAxisPadding(), _chart.xAxisPaddingUnit());
    };

    /**
     * Set or get the title function. Chart class will use this function to render svg title (usually interpreted by
     * browser as tooltips) for each child element in the chart, i.e. a slice in a pie chart or a bubble in a bubble chart.
     * Almost every chart supports title function however in grid coordinate chart you need to turn off brush in order to
     * use title otherwise the brush layer will block tooltip trigger.
     *
     * If the first argument is a stack name, the title function will get or set the title for that stack. If stackName
     * is not provided, the first stack is implied.
     * @method title
     * @memberof dc.stackMixin
     * @instance
     * @example
     * // set a title function on 'first stack'
     * chart.title('first stack', function(d) { return d.key + ': ' + d.value; });
     * // get a title function from 'second stack'
     * var secondTitleFunction = chart.title('second stack');
     * @param {String} [stackName]
     * @param {Function} [titleAccessor]
     * @returns {String|dc.stackMixin}
     */
    dc.override(_chart, 'title', function (stackName, titleAccessor) {
        if (!stackName) {
            return _chart._title();
        }

        if (typeof stackName === 'function') {
            return _chart._title(stackName);
        }
        if (stackName === _chart._groupName && typeof titleAccessor === 'function') {
            return _chart._title(titleAccessor);
        }

        if (typeof titleAccessor !== 'function') {
            return _titles[stackName] || _chart._title();
        }

        _titles[stackName] = titleAccessor;

        return _chart;
    });

    /**
     * Gets or sets the stack layout algorithm, which computes a baseline for each stack and
     * propagates it to the next.
     * @method stackLayout
     * @memberof dc.stackMixin
     * @instance
     * @see {@link https://github.com/d3/d3-3.x-api-reference/blob/master/Stack-Layout.md d3.stackD3v3}
     * @param {Function} [stack=d3.stackD3v3]
     * @returns {Function|dc.stackMixin}
     */
    _chart.stackLayout = function (stack) {
        if (!arguments.length) {
            return _stackLayout;
        }
        _stackLayout = stack;
        return _chart;
    };

    /**
     * Since dc.js 2.0, there has been {@link https://github.com/dc-js/dc.js/issues/949 an issue}
     * where points are filtered to the current domain. While this is a useful optimization, it is
     * incorrectly implemented: the next point outside the domain is required in order to draw lines
     * that are clipped to the bounds, as well as bars that are partly clipped.
     *
     * A fix will be included in dc.js 2.1.x, but a workaround is needed for dc.js 2.0 and until
     * that fix is published, so set this flag to skip any filtering of points.
     *
     * Once the bug is fixed, this flag will have no effect, and it will be deprecated.
     * @method evadeDomainFilter
     * @memberof dc.stackMixin
     * @instance
     * @param {Boolean} [evadeDomainFilter=false]
     * @returns {Boolean|dc.stackMixin}
     */
    _chart.evadeDomainFilter = function (evadeDomainFilter) {
        if (!arguments.length) {
            return _evadeDomainFilter;
        }
        _evadeDomainFilter = evadeDomainFilter;
        return _chart;
    };

    function visibility (l) {
        return !l.hidden;
    }

    _chart.data(function () {
        var layers = _stack.filter(visibility);
        if (!layers.length) {
            return [];
        }
        layers.forEach(prepareValues);
        var v4data = layers[0].values.map(function (v, i) {
            var col = {x: v.x};
            layers.forEach(function (layer) {
                col[layer.name] = layer.values[i].y;
            });
            return col;
        });
        var keys = layers.map(function (layer) { return layer.name; });
        var v4result = _chart.stackLayout().keys(keys)(v4data);
        v4result.forEach(function (series, i) {
            series.forEach(function (ys, j) {
                layers[i].values[j].y0 = ys[0];
                layers[i].values[j].y1 = ys[1];
            });
        });
        return layers;
    });

    _chart._ordinalXDomain = function () {
        var flat = flattenStack().map(dc.pluck('data'));
        var ordered = _chart._computeOrderedGroups(flat);
        return ordered.map(_chart.keyAccessor());
    };

    _chart.colorAccessor(function (d) {
        var layer = this.layer || this.name || d.name || d.layer;
        return layer;
    });

    _chart.legendables = function () {
        return _stack.map(function (layer, i) {
            return {
                chart: _chart,
                name: layer.name,
                hidden: layer.hidden || false,
                color: _chart.getColor.call(layer, layer.values, i)
            };
        });
    };

    _chart.isLegendableHidden = function (d) {
        var layer = findLayerByName(d.name);
        return layer ? layer.hidden : false;
    };

    _chart.legendToggle = function (d) {
        if (_hidableStacks) {
            if (_chart.isLegendableHidden(d)) {
                _chart.showStack(d.name);
            } else {
                _chart.hideStack(d.name);
            }
            //_chart.redraw();
            _chart.renderGroup();
        }
    };

    return _chart;
};
