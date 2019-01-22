/**
 * The geo choropleth chart is designed as an easy way to create a crossfilter driven choropleth map
 * from GeoJson data. This chart implementation was inspired by
 * {@link http://bl.ocks.org/4060606 the great d3 choropleth example}.
 *
 * Examples:
 * - {@link http://dc-js.github.com/dc.js/vc/index.html US Venture Capital Landscape 2011}
 * @class geoChoroplethChart
 * @memberof dc
 * @mixes dc.colorMixin
 * @mixes dc.baseMixin
 * @example
 * // create a choropleth chart under '#us-chart' element using the default global chart group
 * var chart1 = dc.geoChoroplethChart('#us-chart');
 * // create a choropleth chart under '#us-chart2' element using chart group A
 * var chart2 = dc.compositeChart('#us-chart2', 'chartGroupA');
 * @param {String|node|d3.selection} parent - Any valid
 * {@link https://github.com/d3/d3-selection/blob/master/README.md#select d3 single selector} specifying
 * a dom block element such as a div; or a dom element or d3 selection.
 * @param {String} [chartGroup] - The name of the chart group this chart instance should be placed in.
 * Interaction with a chart will only trigger events and redraws within the chart's group.
 * @returns {dc.geoChoroplethChart}
 */
dc.geoChoroplethChart = function (parent, chartGroup) {
    var _chart = dc.colorMixin(dc.baseMixin({}));

    _chart.colorAccessor(function (d) {
        return d || 0;
    });

    var _geoPath = d3.geoPath();
    var _projectionFlag;
    var _projection;

    var _geoJsons = [];

    _chart._doRender = function () {
        _chart.resetSvg();
        for (var layerIndex = 0; layerIndex < _geoJsons.length; ++layerIndex) {
            var states = _chart.svg().append('g')
                .attr('class', 'layer' + layerIndex);

            var regionG = states.selectAll('g.' + geoJson(layerIndex).name)
                .data(geoJson(layerIndex).data);

            regionG = regionG.enter()
                    .append('g')
                    .attr('class', geoJson(layerIndex).name)
                .merge(regionG);

            regionG
                .append('path')
                .attr('fill', 'white')
                .attr('d', _getGeoPath());

            regionG.append('title');

            plotData(layerIndex);
        }
        _projectionFlag = false;
    };

    function plotData (layerIndex) {
        var data = generateLayeredData();

        if (isDataLayer(layerIndex)) {
            var regionG = renderRegionG(layerIndex);

            renderPaths(regionG, layerIndex, data);

            renderTitle(regionG, layerIndex, data);
        }
    }

    function generateLayeredData () {
        var data = {};
        var groupAll = _chart.data();
        for (var i = 0; i < groupAll.length; ++i) {
            data[_chart.keyAccessor()(groupAll[i])] = _chart.valueAccessor()(groupAll[i]);
        }
        return data;
    }

    function isDataLayer (layerIndex) {
        return geoJson(layerIndex).keyAccessor;
    }

    function renderRegionG (layerIndex) {
        var regionG = _chart.svg()
            .selectAll(layerSelector(layerIndex))
            .classed('selected', function (d) {
                return isSelected(layerIndex, d);
            })
            .classed('deselected', function (d) {
                return isDeselected(layerIndex, d);
            })
            .attr('class', function (d) {
                var layerNameClass = geoJson(layerIndex).name;
                var regionClass = dc.utils.nameToId(geoJson(layerIndex).keyAccessor(d));
                var baseClasses = layerNameClass + ' ' + regionClass;
                if (isSelected(layerIndex, d)) {
                    baseClasses += ' selected';
                }
                if (isDeselected(layerIndex, d)) {
                    baseClasses += ' deselected';
                }
                return baseClasses;
            });
        return regionG;
    }

    function layerSelector (layerIndex) {
        return 'g.layer' + layerIndex + ' g.' + geoJson(layerIndex).name;
    }

    function isSelected (layerIndex, d) {
        return _chart.hasFilter() && _chart.hasFilter(getKey(layerIndex, d));
    }

    function isDeselected (layerIndex, d) {
        return _chart.hasFilter() && !_chart.hasFilter(getKey(layerIndex, d));
    }

    function getKey (layerIndex, d) {
        return geoJson(layerIndex).keyAccessor(d);
    }

    function geoJson (index) {
        return _geoJsons[index];
    }

    function renderPaths (regionG, layerIndex, data) {
        var paths = regionG
            .select('path')
            .attr('fill', function () {
                var currentFill = d3.select(this).attr('fill');
                if (currentFill) {
                    return currentFill;
                }
                return 'none';
            })
            .on('click', function (d) {
                return _chart.onClick(d, layerIndex);
            });

        dc.transition(paths, _chart.transitionDuration(), _chart.transitionDelay()).attr('fill', function (d, i) {
            return _chart.getColor(data[geoJson(layerIndex).keyAccessor(d)], i);
        });
    }

    _chart.onClick = function (d, layerIndex) {
        var selectedRegion = geoJson(layerIndex).keyAccessor(d);
        dc.events.trigger(function () {
            _chart.filter(selectedRegion);
            _chart.redrawGroup();
        });
    };

    function renderTitle (regionG, layerIndex, data) {
        if (_chart.renderTitle()) {
            regionG.selectAll('title').text(function (d) {
                var key = getKey(layerIndex, d);
                var value = data[key];
                return _chart.title()({key: key, value: value});
            });
        }
    }

    _chart._doRedraw = function () {
        for (var layerIndex = 0; layerIndex < _geoJsons.length; ++layerIndex) {
            plotData(layerIndex);
            if (_projectionFlag) {
                _chart.svg().selectAll('g.' + geoJson(layerIndex).name + ' path').attr('d', _getGeoPath());
            }
        }
        _projectionFlag = false;
    };

    /**
     * **mandatory**
     *
     * Use this function to insert a new GeoJson map layer. This function can be invoked multiple times
     * if you have multiple GeoJson data layers to render on top of each other. If you overlay multiple
     * layers with the same name the new overlay will override the existing one.
     * @method overlayGeoJson
     * @memberof dc.geoChoroplethChart
     * @instance
     * @see {@link http://geojson.org/ GeoJSON}
     * @see {@link https://github.com/topojson/topojson/wiki TopoJSON}
     * @see {@link https://github.com/topojson/topojson-1.x-api-reference/blob/master/API-Reference.md#wiki-feature topojson.feature}
     * @example
     * // insert a layer for rendering US states
     * chart.overlayGeoJson(statesJson.features, 'state', function(d) {
     *      return d.properties.name;
     * });
     * @param {geoJson} json - a geojson feed
     * @param {String} name - name of the layer
     * @param {Function} keyAccessor - accessor function used to extract 'key' from the GeoJson data. The key extracted by
     * this function should match the keys returned by the crossfilter groups.
     * @returns {dc.geoChoroplethChart}
     */
    _chart.overlayGeoJson = function (json, name, keyAccessor) {
        for (var i = 0; i < _geoJsons.length; ++i) {
            if (_geoJsons[i].name === name) {
                _geoJsons[i].data = json;
                _geoJsons[i].keyAccessor = keyAccessor;
                return _chart;
            }
        }
        _geoJsons.push({name: name, data: json, keyAccessor: keyAccessor});
        return _chart;
    };

    /**
     * Gets or sets a custom geo projection function. See the available
     * {@link https://github.com/d3/d3-geo/blob/master/README.md#projections d3 geo projection functions}.
     *
     * Starting version 3.0 it has been deprecated to rely on the default projection being
     * {@link https://github.com/d3/d3-geo/blob/master/README.md#geoAlbersUsa d3.geoAlbersUsa()}. Please
     * set it explicitly. {@link https://bl.ocks.org/mbostock/5557726
     * Considering that `null` is also a valid value for projection}, if you need
     * projection to be `null` please set it explicitly to `null`.
     * @method projection
     * @memberof dc.geoChoroplethChart
     * @instance
     * @see {@link https://github.com/d3/d3-geo/blob/master/README.md#projections d3.projection}
     * @see {@link https://github.com/d3/d3-geo-projection d3-geo-projection}
     * @param {d3.projection} [projection=d3.geoAlbersUsa()]
     * @returns {d3.projection|dc.geoChoroplethChart}
     */
    _chart.projection = function (projection) {
        if (!arguments.length) {
            return _projection;
        }

        _projection = projection;
        _projectionFlag = true;
        return _chart;
    };

    var _getGeoPath = function () {
        if (_projection === undefined) {
            dc.logger.warn('choropleth projection default of geoAlbers is deprecated,' +
                ' in next version projection will need to be set explicitly');
            return _geoPath.projection(d3.geoAlbersUsa());
        }

        return _geoPath.projection(_projection);
    };

    /**
     * Returns all GeoJson layers currently registered with this chart. The returned array is a
     * reference to this chart's internal data structure, so any modification to this array will also
     * modify this chart's internal registration.
     * @method geoJsons
     * @memberof dc.geoChoroplethChart
     * @instance
     * @returns {Array<{name:String, data: Object, accessor: Function}>}
     */
    _chart.geoJsons = function () {
        return _geoJsons;
    };

    /**
     * Returns the {@link https://github.com/d3/d3-geo/blob/master/README.md#paths d3.geoPath} object used to
     * render the projection and features.  Can be useful for figuring out the bounding box of the
     * feature set and thus a way to calculate scale and translation for the projection.
     * @method geoPath
     * @memberof dc.geoChoroplethChart
     * @instance
     * @see {@link https://github.com/d3/d3-geo/blob/master/README.md#paths d3.geoPath}
     * @returns {d3.geoPath}
     */
    _chart.geoPath = function () {
        return _geoPath;
    };

    /**
     * Remove a GeoJson layer from this chart by name
     * @method removeGeoJson
     * @memberof dc.geoChoroplethChart
     * @instance
     * @param {String} name
     * @returns {dc.geoChoroplethChart}
     */
    _chart.removeGeoJson = function (name) {
        var geoJsons = [];

        for (var i = 0; i < _geoJsons.length; ++i) {
            var layer = _geoJsons[i];
            if (layer.name !== name) {
                geoJsons.push(layer);
            }
        }

        _geoJsons = geoJsons;

        return _chart;
    };

    return _chart.anchor(parent, chartGroup);
};
