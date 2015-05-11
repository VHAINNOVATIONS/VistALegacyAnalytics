Array.prototype.humanSort = function() {
  return this.sort(function(a, b) {
    aa = a.split(/(\d+)/);
    bb = b.split(/(\d+)/);

    for(var x = 0; x < Math.max(aa.length, bb.length); x++) {
      if(aa[x] != bb[x]) {
        var cmp1 = (isNaN(parseInt(aa[x],10)))? aa[x] : parseInt(aa[x],10);
        var cmp2 = (isNaN(parseInt(bb[x],10)))? bb[x] : parseInt(bb[x],10);
        if(cmp1 == undefined || cmp2 == undefined)
          return aa.length - bb.length;
        else
          return (cmp1 < cmp2) ? -1 : 1;
      }
    }
    return 0;
  });
}

$(function() {

    var analysisTable = $('#analysis_co_occurence');

    var all_options = $('#xvals').html();

    var colors = [];
    colors.push('#9966FF');
    colors.push('#667FFF');
    colors.push('#66CCFF');
    colors.push('#66FFE6');
    colors.push('#7FFF66');

	var timeComparisonChart;
	var timeComparisonOptions = {
        chart: {
            renderTo: 'timechart',
            type: 'column'
        },
        title: {
            text: 'Co-occurrence Sequence'
        },
        legend: {
            enabled: false
        },
        xAxis: {
            title: {
                enabled: true,
                text: 'Order'
            },
            categories: ['X before Y', 'Y before X', 'X and Y on same date'],
            type: 'category',
            startOnTick: true,
            endOnTick: true,
            showLastLabel: true
        },
        yAxis: {
            title: {
                text: 'Count'
            },
            min: 0,
            allowDecimals: false,
            type: 'linear',
            labels: {
                enabled: true
            }
        },
        plotOptions: {
            bar: {
                    dataLabels: {
                        enabled: true
                    }
                }
        },
        series: []
    };

    var summaryChart;
    var summaryOptions = {
        chart: {
            renderTo: 'theSummaryChart',
            type: 'bar'
        },
        title: {
            text: 'Patient Summary Statistics'
        },
        legend: {
            enabled: false
        },
        xAxis: {
            title: {
                enabled: true,
                text: 'Statistic'
            },
            categories: [
                'Total Patients',
                'Does not have either x or y',
                'Has both x and y',
                'Has x',
                'Has y'],
            type: 'category',
            startOnTick: true,
            endOnTick: true,
            showLastLabel: true
        },
        yAxis: {
            title: {
                text: 'Patient Count'
            },
            min: 0,
            allowDecimals: false,
            type: 'linear',
            labels: {
                enabled: true
            }
        },
        plotOptions: {
            bar: {
                dataLabels: {
                    enabled: true
                }
            }
        },
        series: []
    };

	function loadTableData(data) {
		var isDT = $.fn.DataTable.fnIsDataTable(analysisTable.get(0));
		if (isDT) {
			analysisTable.fnDestroy();
			analysisTable.empty();
		}
		var rowKeys = Object.keys(data);
		if (rowKeys.length == 0) {
			return;
		}
		var colKeys = [];
		for (var i=0; i<rowKeys.length; i++) {
			var keys = Object.keys(data[rowKeys[i]]);
			for (var j=0; j<keys.length; j++) {
				if (colKeys.indexOf(keys[j]) == -1) {
					colKeys.push(keys[j]);
				}
			}
		}
		colKeys.humanSort();

		var tableData = [];
		for (var i=0; i<rowKeys.length; i++) {
			var row = [];
			row.push(rowKeys[i]);
			for (var j=0; j<colKeys.length; j++) {
				var item = data[rowKeys[i]][colKeys[j]];
				if (!item) {
					item = "";
				}
				row.push('<a class="datalink" href="#" data-x="' + rowKeys[i] +  '" data-y="' + colKeys[j] + '">' + item + '</a>');
			}
			tableData.push(row);
		}

		var headers = [{"sTitle": ""}];
		for (var i=0; i<colKeys.length; i++) {
            headers.push({"sTitle": colKeys[i]});
		}

        analysisTable.dataTable({
            aaData: tableData,
            aoColumns: headers,
            bFilter: false,
            bLengthChange: false,
            bPaginate: false,
            bInfo: false,
            bAutoWidth: false
        });

        //add labels to the headers and cells
        $('#analysis_co_occurence tbody tr td').each( function() {
            this.setAttribute( 'title', $(this).text());
            if(isNumber($(this).text()) == false ) {
                $(this).text(sentenceCaseText($(this).text()));
            }
        });

        $('#analysis_co_occurence thead tr th').each( function() {
            this.setAttribute( 'title', $(this).text());
            $(this).text(sentenceCaseText($(this).text()));
        });

        $('#analyze_co_occurence').css('height', ($('#analysis_co_occurence').height() + 38) + 'px');
	}

    function isNumber(n) {
        return !isNaN(parseFloat(n)) && isFinite(n);
    }

    function sentenceCaseText(text) {
        text = text.toLowerCase();
        text = text.charAt(0).toUpperCase() + text.slice(1);
        return text;
    }

    function populateTimeComparisonChart(data, xval, yval) {
        var darr = [];
        darr.push({ y: parseInt(data["xbefore"]), color: colors[0] });
        darr.push({ y: parseInt(data["xafter"]), color: colors[1] });
        darr.push({ y: parseInt(data["same"]), color: colors[2] });

        timeComparisonChart.xAxis[0].setCategories([xval + ' <b>before</b> ' + yval, xval + ' <b>after</b> ' + yval, xval + ' <b>concurrent with</b> ' + yval]);
        timeComparisonChart.addSeries({name: 'Counts', data: darr});
    }

    function populateSummaryChart(data, xtext, ytext) {
        var darr = [];

        darr.push({ y: parseInt(data["totalRecords"]), color: colors[0] });
        darr.push({ y: parseInt(data["neither"]), color: colors[1] });
        darr.push({ y: parseInt(data["both"]), color: colors[2] });
        darr.push({ y: parseInt(data["onlyFirst"]), color: colors[3] });
        darr.push({ y: parseInt(data["onlySecond"]), color: colors[4] });

        summaryChart.xAxis[0].setCategories([
            'Total patients',
            xtext + ' <b>or</b><br /> ' + ytext,
            xtext + ' <b>and</b><br /> ' + ytext,
            xtext,
            ytext
        ]);
        summaryChart.addSeries({name: 'Counts', data: darr});
    }

    function loadSummaryChart(x, y) {
    	var xarr = x.split('/')
    	x = xarr.slice(0, xarr.length - 1).join('/');
    	var yarr = y.split('/')
    	y = yarr.slice(0, yarr.length - 1).join('/');
        var subx = x.replace(/.*\/va:enrichment([^[]*).*/g, '$1');
        var suby = y.replace(/.*\/va:enrichment([^[]*).*/g, '$1');

        var xtext = $( "#xvals option:selected" ).text();
        var xStart = xtext.indexOf(':');
        if(xStart > 0) {
            xtext = xtext.substring(xStart+1);
            xtext = $.trim(xtext);
        }
        else {
            xtext = null;
        }
        var ytext = $( "#yvals option:selected" ).text();
        var yStart = ytext.indexOf(':');
        if (yStart > 0) {
            ytext = ytext.substring(yStart+1);
            ytext = $.trim(ytext);
        }
        else {
            ytext = null;
        }

        if (subx != "null" && suby != "null" && ytext != null && xtext != null) {

            $('#table_message').hide();
            $('#theSummaryChart').show();

            $.ajax({
                url: '/analytics/runSummaryReport.json?',
                type: 'post',
                data: {xval: subx, yval: suby, xWhere: xtext, yWhere: ytext},
                success: function(data){
                    summaryChart = new Highcharts.Chart(summaryOptions);
                    populateSummaryChart(data, xtext, ytext);
                    summaryChart.redraw();
                }
            });
        } else {
            $('#theSummaryChart').hide();
            $('#table_message').show();
        }
    }

    $('#table_message').css('top', '15px');

	$(document).on('click', 'a.datalink', function(evt, ui) {
		evt.preventDefault();
		var xval = $(this).data('x');
		var yval = $(this).data('y');
		var x = $('#xvals').val();
		var y = $('#yvals').val();

		$.ajax({
			url: '/analytics/run-ordering-report.json',
			data: {xvals: x, yvals: y, xvalue: xval, yvalue: yval},
			type: 'post',
			success: function(data) {
				timeComparisonChart = new Highcharts.Chart(timeComparisonOptions);
                populateTimeComparisonChart(data, xval, yval);
				timeComparisonChart.redraw();
                $('#timechart').show();
			}
		});
		return false;
	});

	$('select').on('change', function(evt) {
        $('#timechart').hide();

		var x = $('#xvals').val();
		var y = $('#yvals').val();

        //analysis_co_occurence table
		if ($(this).attr('id') == 'xvals') {
			$('#yvals').html(all_options);
			if (x != "null") {
				$('#yvals option[value="' + x.replace(/"/g, '\\"') + '"]').remove();
			}
			$('#yvals').val(y);
		}

		if ($(this).attr('id') == 'yvals') {
			$('#xvals').html(all_options);
			if (y != "null") {
				$('#xvals option[value="' + y.replace(/"/g, '\\"') + '"]').remove();
			}
			$('#xvals').val(x);
		}

		if (x != "null" && y != "null") {
			analysisTable.show();
            $('#table_message').hide();
			$.getJSON('/analytics/run.json?xvals=' + x + "&yvals=" + y, function(data){
			    loadTableData(data);
			});
		} else {
			analysisTable.hide();
			$('#table_message').show();
		}

		$.cookie("analytics_x_val", x, {expires: 5000, path: '/'});
		$.cookie("analytics_y_val", y, {expires: 5000, path: '/'});

        loadSummaryChart(x, y)
    });

	var old_x = $.cookie("analytics_x_val");
	var old_y = $.cookie("analytics_y_val");
	if (old_x) {
		$('#xvals').val(old_x).trigger('change');
	}
	if (old_y) {
		$('#yvals').val(old_y).trigger('change');
	}

});