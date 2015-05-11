/*
 * public/js/map.js
 */

// loader
$(function() {
  if (!window.console) { console = { log: function() {}}};
  console.log("[map] init");

  var radiusMultiplier = 0.0006214;

  // state management
  var lastBounds = null;
  var lastConstraint = '';
  var didSkipRefresh = true;
  var drawEvent = null;
  var isDragging = false;
  var heatmap = null;
  var overlaySkipRefresh = false;

  var originalQuery = $('#originalQuery');
  if (null == originalQuery[0]) {
    console.log("missing #originalQuery");
    return;
  }
  originalQuery = $.trim(originalQuery.attr('value'));

  // Transform JSON into map data.
  var dataFn = function(data, isNew) {
    if (data == null) return [];
    var heatmapData = [];
    var outerBox;
    for (var i=0; i<data.length; i++) {
      var pt = data[i];
      var box = new google.maps.LatLngBounds(
        new google.maps.LatLng(pt[0], pt[1]),
        new google.maps.LatLng(pt[2], pt[3]));
      // https://developers.google.com/maps/documentation/javascript/reference
      // documents WeightedLocation, but the constructor does seem to exist.
      heatmapData[i] = {
        location: box.getCenter(), weight: pt[4] };
      outerBox = outerBox ? outerBox.union(box) : box;
    }
    if (!outerBox) outerBox = new google.maps.LatLngBounds(
      new google.maps.LatLng(-90, -180),
      new google.maps.LatLng(90, 180));
    // For a new map, zoom in as far as possible while showing all points.
    if (isNew && null != map) {
      console.log('[map data] init');
      map.fitBounds(outerBox);
    }
    return heatmapData;
  };

  // Build search string for current map viewport.
  // Any current drawing shape turns into a geo query term.
  var boundsFn = function() {
    var bounds = map.getBounds();
    console.log('[map bounds]', bounds);
    // The map may not be ready yet
    if (null == bounds) return "";

    var ne = bounds.getNorthEast();
    var sw = bounds.getSouthWest();
    // assert sensible bounds
    if (ne.lat() == sw.lat()
        || ne.lng() == sw.lng()) return "";
    return "n=" + ne.lat()
      + "&s=" + sw.lat()
      + "&e=" + ne.lng()
      + "&w=" + sw.lng();
  };

  var constraintFn = function() {
    console.log('[map constraint] drawEvent', drawEvent);
    if (!drawEvent) return "";

    var constraint = null;
    var field = "facility-loc";

    var overlay = drawEvent.overlay;
    var type = drawEvent.type;
    var bounds = null;
    console.log('[map constraint] overlay', type, overlay);
    if (type == google.maps.drawing.OverlayType.CIRCLE) {
      var radiusMeters = overlay.getRadius();
      var radiusMiles = radiusMultiplier * radiusMeters;
      var center = overlay.getCenter();
      var centerCsv = center.lat() + "," + center.lng();
      console.log('[map bounds] circle', radiusMiles, centerCsv);
      constraint = field + ':"@' + radiusMiles + ' ' + centerCsv + '"';
    } else if (type == google.maps.drawing.OverlayType.RECTANGLE) {
      bounds = overlay.getBounds();
      console.log('[map bounds] rectangle', bounds);
      var sw = bounds.getSouthWest();
      var ne = bounds.getNorthEast();
      // syntax: s w n e
      constraint = field + ':"['
        + sw.lat() + ' ' + sw.lng()
        + ' ' + ne.lat() + ' ' + ne.lng()
        + ']"';
    } else {
      console.log('[map bounds] unknown type', type);
    }

    console.log('[map constraint]', constraint);
    return constraint;
  };

  var refreshFn = function(force) {
    var bounds = boundsFn();

    console.log("[map refresh] bounds old", lastBounds,
                "new", bounds);
    var constraint = constraintFn();
    console.log("[map refresh] constraint old", lastConstraint,
                "new", constraint);
    if (null != bounds && bounds == lastBounds && force != true
       && ((null == constraint && null == lastConstraint)
           || constraint == lastConstraint)) {
      console.log("[map refresh] bounds and constraints unchanged");
      return;
    }

    // Fetch and display new data.
    // Also refresh facets, but only if constraint has changed.
    var newData = [];
    var loc = $(location);
    // Need to filter out original q - if any.
    var search = loc.attr('search');
    var params = $.deserialize(search.substr(1));
    delete params['q'];
    search = $.param(params);
    // NB - host includes port
    var url = loc.attr('protocol')
      + "//" + loc.attr('host') + "/appbuilder/map.xml"
      + "?" + search + "&" + bounds
      + "&q=" + escape(originalQuery)
      + (constraint ? " " : "")
      + (constraint ? escape(constraint) : "");
      //+ "&sidebar=" + (constraint != lastConstraint);  //was causing a bug on shape filtering in the dynamic facets, ticket #249
    console.log("[map refresh] requesting " + url);
    jQuery.ajax(url, {
      dataType: "html",
      error: function(jqXHR, textStatus, errorThrown) {
        console.log('[map refresh error]',
                    url, jqXHR, textStatus, errorThrown); },
      success: function(data, textStatus, jqXHR) {
        console.log("[map refresh success]", data);
        // refresh and update state
        var jqData = $(data);
        var heatmapNode = jqData.find('#heatmap');
        console.log('[map refresh success] heatmap', heatmapNode.length);
        var jsonText = heatmapNode.text();
        console.log('[map refresh success] jsonText', jsonText);
        if (jsonText) {
          var json = jQuery.parseJSON(jsonText);
          if (heatmap == null) {
            console.log('[map refresh success] init heatmap');
            heatmap = new google.maps.visualization.HeatmapLayer(
              {data: dataFn(json, true)});
            heatmap.setMap(map);
            // The bounds are different now, because dataFn has side effects.
            bounds = boundsFn();
            // If we have a restored shape, tell the drawing manager.
            if (drawEvent) {
              console.log('[map refresh success] init drawEvent skip refresh');
              overlaySkipRefresh = true;
              google.maps.event.trigger(
                drawingManager, 'overlaycomplete', drawEvent);
              overlaySkipRefresh = false;
              fitShapeFn(drawEvent);
            }
          } else {
            console.log('[map refresh success] heatmap update');
            heatmap.setData(dataFn(json, false));
          }
        }
        // Update sidebar, for facets.
        var sidebar = $('#sidebar');
        var sidebarNew = jqData.find('#sidebar');
        console.log('[map refresh success] sidebar update', sidebarNew);
        if (sidebar.length && sidebarNew.length) {
          sidebar.html(sidebarNew.html());
        }
        // Update tab links as needed.
        if (constraint != lastConstraint) {
          var newQuery = originalQuery
            + ((originalQuery.length && constraint.length) ? ' ' : '')
            + constraint;
          console.log('[map refresh success] updating query', newQuery);
          $('#q').attr('value', newQuery);
          var updateLinkFn = function(i, n) {
            var href = n.getAttribute('href');
            var pre = href.substring(0, 1 + href.indexOf('?'));
            var params = $.deserialize(href.substring(1 + href.indexOf('?')));
            params['q'] = newQuery;
            var newParams = pre + $.param(params);
            n.setAttribute('href', newParams);
            console.log('[map refresh success link update]',
                        href, newParams);
          };
          $('ul[role="tablist"] a[href*="subtab="]').each(updateLinkFn);
        }


        console.log('[map refresh success] new', bounds, constraint);
        lastBounds = bounds;
        lastConstraint = constraint; } }); }

  // Handler for fit-to-shape widget
  var fitShapeFn = function(evt) {
    // zoom map to new shape - circle and rectangle are easy
    var bounds = null;
    if (evt.type == google.maps.drawing.OverlayType.CIRCLE
        || evt.type == google.maps.drawing.OverlayType.RECTANGLE) {
      bounds = drawEvent.overlay.getBounds();
    } else if (evt.type == google.maps.drawing.OverlayType.POLYGON) {
      // walk array of paths to build new bounds
      var n, s, e, w;
      evt.overlay.getPath().forEach(function(pt, i) {
        console.log('[map overlay] polygon path', i, pt);
        if (i == 0) {
          n = pt.lat();
          s = n;
          e = pt.lng();
          w = e;
          console.log('[map overlay]', i, n, e);
          return;
        }
        var lat = pt.lat();
        var lng = pt.lng();
        console.log('[map overlay]', i, lat, n, s, lng, e, w);
        if (n < lat) n = lat;
        if (s > lat) s = lat;
        if (e < lng) e = lng;
        if (w > lng) w = lng;
      });
      console.log('[map overlay]', n, s, e, w);
      bounds = new google.maps.LatLngBounds(
        new google.maps.LatLng(n, w),
        new google.maps.LatLng(s, e));
    } else {
      console.log('[map overlay] unknown type', e.type);
    }
    console.log('[map overlay] bounds', bounds);
    // fit to bounds will trigger a refresh event
    if (bounds) map.fitBounds(bounds);
  };

  // map objects
  // https://developers.google.com/maps/documentation/javascript/layers
  var canvas = $('#mapCanvas');
  if (null == canvas[0]) {
    console.log("missing #mapCanvas");
    return;
  }
  var map = new google.maps.Map(
    canvas[0],
    // en.wikipedia.org/wiki/Geographic_center_of_the_contiguous_United_States
    {center: new google.maps.LatLng(39.5, -98.35),
     // Without maximum zoom, small data sets zoom in much too closely.
     maxZoom: 6,
     mapTypeControl: false,
     mapTypeId: google.maps.MapTypeId.ROADMAP,
     streetViewControl: false,
     zoom: 3});

  // enable drawing tools
  var drawingManager = new google.maps.drawing.DrawingManager({
    drawingControlOptions: {
      position: google.maps.ControlPosition.LEFT_TOP,
      drawingModes: [
        google.maps.drawing.OverlayType.CIRCLE,
        // No polygons, because search API parser does not support them.
        //google.maps.drawing.OverlayType.POLYGON,
        google.maps.drawing.OverlayType.RECTANGLE]},
    circleOptions: { editable: true },
    polygonOptions: { editable: true },
    rectangleOptions: { editable: true }});
  drawingManager.setMap(map);

  // handle drawing events
  google.maps.event.addListener(
    drawingManager, 'overlaycomplete',
    function(evt) {
      var shape = evt.overlay;
      var type = evt.type;
      console.log('[map overlay]', evt, type, shape);
      // turn off drawing mode
      drawingManager.setDrawingMode(null);
      // Unless restoring at init time,
      // delete any existing overlay objects.
      if (drawEvent && !overlaySkipRefresh) {
        drawEvent.overlay.setMap(null);
      }
      // remember the new shape
      drawEvent = evt;
      console.log('[map overlay] drawEvent', drawEvent);

      // allow the user to move and edit shapes
      if (shape.setDraggable) shape.setDraggable(true);
      if (shape.setEditable) shape.setEditable(true);

      // Handle shape edit events.
      // Edits send one event with no mouseup, and the shape is editable.
      // Drags send many events, ending with mouseup. Shape is not editable.
      google.maps.event.addListener(shape, 'mouseup', function() {
        var bounds = shape.getBounds();
        console.log(
          "[map overlay mouseup]",
          type, bounds.getNorthEast(), bounds.getSouthWest(),
          shape.getEditable());
        if (!shape.getEditable()) refreshFn();
      });
      if (type == google.maps.drawing.OverlayType.CIRCLE) {
        // Circle edits only seem to produce radius_changed.
        // Drags send center_changed, but we will wait for mouseup.
        google.maps.event.addListener(shape, 'radius_changed', function() {
          console.log(
            "[map overlay radius_changed]", type, shape.getEditable());
          if (shape.getEditable()) refreshFn();
        });
      } else if (type == google.maps.drawing.OverlayType.RECTANGLE) {
        // rectangle has bounds_changed event
        google.maps.event.addListener(shape, 'bounds_changed', function() {
          var bounds = shape.getBounds();
          console.log(
            "[map overlay bounds_changed]",
            type, bounds.getNorthEast(), bounds.getSouthWest(),
            shape.getEditable());
          if (shape.getEditable()) refreshFn();
        });
      } else console.log("[map overlay] unknown type for edit events", type);

      // ready for refresh
      if (!overlaySkipRefresh) refreshFn();
    });

  // Is there a shape to restore?
  if (originalQuery && (originalQuery.indexOf("facility-loc") > -1)  ) {
    lastConstraint = originalQuery.replace(
        /(.*\b)(facility-loc:"[@|\[][\s\d,\-\.]+\]?")(.*)/, "$2");
    if (lastConstraint && lastConstraint.length) {
      console.log('[map init] lastConstraint', lastConstraint);
      var right = lastConstraint.substr(1 + lastConstraint.indexOf(':'));
      // Fake a drawEvent, with type and overlay.
      drawEvent = {};
      // Infer type from constraint.
      // circle = field:"@radiusMiles centerCsv"
      // rectangle = field:"[s w n e]"
      var type = (right.indexOf('@') == 1)
        ? google.maps.drawing.OverlayType.CIRCLE
        : google.maps.drawing.OverlayType.RECTANGLE;
      drawEvent.type = type;
      console.log('[map init] restoring drawEvent', type);
      if (type == google.maps.drawing.OverlayType.CIRCLE) {
        //var pat = /^("@)([\d\.\-]+)(\s+)([\d\.\-]+)(")$/;

        var parts = right.split(" ");
        var r = parts[0].replace(/@/g,"").replace(/"/g,"");
        r = r / radiusMultiplier;
        var dataPts = parts[1].replace(/"/g,"");
        dataPts = dataPts.split(',');
        var c = new google.maps.LatLng(dataPts[0], dataPts[1]);

        console.log('[map init] restoring drawEvent', type, c, r, right);
        drawEvent.overlay = new google.maps.Circle(
          {center: c, radius: r});
      } else if (type == google.maps.drawing.OverlayType.RECTANGLE) {
        var pat = /^("\[)([\d\.\-]+)(\s+)([\d\.\-]+)(\s+)([\d\.\-]+)(\s+)([\d\.\-]+)(\]")$/;
        var s = right.replace(pat, "$2");
        var w = right.replace(pat, "$4");
        var n = right.replace(pat, "$6");
        var e = right.replace(pat, "$8");
        console.log('[map init] restoring drawEvent', type, s, w, n, e, right);
        drawEvent.overlay = new google.maps.Rectangle(
          {bounds: new google.maps.LatLngBounds(
            new google.maps.LatLng(s, w),
            new google.maps.LatLng(n, e))});
      } else {
        console.log('[map init] unknown type', type);
      }
      // Configure and display the new overlay
      var overlay = drawEvent.overlay;
      if (overlay) overlay.setMap(map);
      console.log('[map init] drawEvent',
                  drawEvent, drawEvent.type, drawEvent.overlay);
      // Rebuild originalQuery without shape, so we only have one.
      originalQuery = $.trim(originalQuery.replace(lastConstraint, ''));
    }
  }

  // handle bounds_changed event,
  // but keep this from happening too frequently when map is dragged.
  // http://code.google.com/p/gmaps-api-issues/issues/detail?id=1371
  google.maps.event.addListener(map, 'dragstart', function() {
    //console.log('dragstart', 'skipped', didSkipRefresh);
    isDragging = true; });
  google.maps.event.addListener(map, 'dragend', function() {
    //console.log('dragend', 'skipped', didSkipRefresh);
    isDragging = false;

    if (!didSkipRefresh) return;

    didSkipRefresh = false;
    refreshFn();
  });
  google.maps.event.addListener(map, 'idle', function() {
    console.log('[map idle]', 'drag', isDragging, 'skipped', didSkipRefresh);
    if (isDragging || !didSkipRefresh) return;

    didSkipRefresh = false;
    refreshFn(); });
  google.maps.event.addListener(map, 'bounds_changed', function() {
    console.log('[map bounds_changed]',
                'drag', isDragging, 'skipped', didSkipRefresh);
    if (!isDragging) return refreshFn();

    // We may be in the middle of a drag, so defer the handler.
    didSkipRefresh = true; });

  // autosize canvas div
  var h = $('body').height()
    - $('#header').height()
    - $('#tabs').height();
  console.log("[map] sizing to match body", h);
  canvas.height(h);

  console.log('[map] controls init');
  var controlFn = function(name, title, clickFn) {
    var n = $('<div style="padding:5px">'
              + '<div style="background:white;border:1px solid;cursor:pointer;'
              + 'text-align:center" title="' + title + '">'
              + '<div style="font-family:Arial,sans-serif;font-size:12px;'
              + 'padding-left:4px;padding-right:4px;">'
              + name + '</div></div></div>')[0];
    if (clickFn) google.maps.event.addDomListener(n, 'click', clickFn);
    return n;
  };
  map.controls[google.maps.ControlPosition.LEFT_TOP].push(
    controlFn('Clear', 'Clear Drawing', function() {
      console.log('[map clear]', drawEvent);
      if (!drawEvent) return;
      drawEvent.overlay.setMap(null);
      drawEvent = null;
      refreshFn();
    }));
  map.controls[google.maps.ControlPosition.LEFT_TOP].push(
    controlFn('Zoom', 'Zoom to Drawing', function() {
      console.log('[map zoom]', drawEvent);
      if (!drawEvent) return;
      fitShapeFn(drawEvent);
    }));

  console.log('[map] init ok');
});

// map.js
