jQuery.extend( jQuery.fn.dataTableExt.oSort, {
    "data-date-pre" : function(el) {
        // force type-conversion to number
        return $(el).data('date');
    },
    "data-date-asc" : function(a, b) {
        return ((a < b) ? -1 : ((a > b) ? 1 : 0));
    },
    "data-date-desc": function(a,b) {
        return ((a < b) ? 1 : ((a > b) ? -1 : 0));
    }
} );


$(function(){
	var chart;

        var show_timeline = (!(navigator.userAgent.match("MSIE 7")));

    var options = {
        chart: {
            renderTo: 'Timeline_tab',
            type: 'scatter',
            zoomType: 'xy'
        },
        title: {
            text: 'Patient History'
        },
        xAxis: {
            title: {
                enabled: true,
                text: 'Year'
            },
            type: 'datetime',
            startOnTick: true,
            endOnTick: true,
            showLastLabel: true
        },
        yAxis: {
            title: {
                text: ''
            },
            labels: {
                enabled: false
            }
        },
        tooltip: {
            formatter: function () {
                return this.point.data;
            }
        },
        legend: {
            layout: 'vertical',
            align: 'left',
            verticalAlign: 'top',
            x: 100,
            y: 70,
            floating: true,
            backgroundColor: '#FFFFFF',
            borderWidth: 1
        },
        plotOptions: {
            scatter: {
                marker: {
                    radius: 5,
                    states: {
                        hover: {
                            enabled: true,
                            lineColor: 'rgb(100,100,100)'
                        }
                    }
                },
                states: {
                    hover: {
                        marker: {
                            enabled: false
                        }
                    }
                }
            }
        },
        series: []
    };

    if (show_timeline) {
        chart = new Highcharts.Chart(options);
    }
    function drawChart(category, data) {
    	if (!show_timeline) {
    		return;
    	}

        var obj = {'name': category, 'data': data};
        chart.addSeries(obj);
        chart.redraw();
    }

    $('#data_selector a').on('click', function(evt) {
        evt.preventDefault();
        var href = $(this).attr('href');
        $(href).css({'display': 'block'}).siblings('div').css({'display': 'none'});
        $(this).parent('li').addClass('active').siblings('li').removeClass('active');
        if (href == '#Timeline_tab') {
            chart.setSize($('#Timeline_tab').width(), $('#Timeline_tab').height());
        }
    });

    $('.dataTables_length select').on('change', function(evt) {
        if (evt.originalEvent !== undefined) {
            var val = $(this).val();
            $.cookie('table_length', val, {expires: 5000, path: '/'});
            $('.dataTables_length select').not(this).val(val).trigger('change');
        }
    });

    $('.export_button').on('click', function(evt) {
        evt.preventDefault();
        var button = this;
        $('#export_dialog').dialog({
            width: '500px',
            modal: true,
            buttons: {
                "Export This Subset": function() {
                    window.open('/appbuilder/raw.xml?path=' + $(button).data('path'), '_blank');
                },
                "Export Full Patient Record": function() {
                    window.open('/appbuilder/raw.xml?path=' + $(button).data('docuri'), '_blank');
                }
            }
        });
    });

    $('.content_link').on('click', function (evt) {
        evt.preventDefault();
        var href = $(this).attr('href');
        $.ajax({
            url: href,
            success: function(data) {
                $('#content_dialog').html('<p>' + data + '</p>').dialog({
                    width: '700px',
                    modal: true,
                    buttons: {
                        'Ok': function() {
                            $(this).dialog('close');
                        }
                    }
                });
            }
        });
    });

    $($('li.active a').attr('href')).siblings('div').css({'display': 'none'});

    $('.horz_tab').css('min-height', $('#data_selector').height() + 'px');
    
    if (!show_timeline) {
        $('a[href="#Timeline_tab"]').parent('li').remove();
    }

    $('.horz_tab').tabs().eq(0).show();

    $('.data_table').each(function(idx, element) {
        $(this).dataTable({
            "bProcessing": true,
            "bServerSide": true,
            "sAjaxSource": "/appbuilder/patient-category.json?id=" + patient_id + "&site=" + site + "&cat=" + (idx + 1),
            "fnDrawCallback": function(oSettings) {
                var count = oSettings.fnRecordsTotal();
                var tabId = $(element).parents('.horz_tab').attr('id');
                var name = $(element).parents('.horz_tab').data('name');

                var tab = $('#data_selector a[href=#' + tabId + ']').text(name + ' (' + count + ')');

                if (count > 0){
                    tab.css("font-style", "normal").css("font-weight", "bold"); // TODO: Move to CSS
                } else {
                    tab.css("font-style", "italic").css("font-weight", "normal");
                }


                if (show_timeline) {
                    $.ajax({
                        "url": "/appbuilder/patient-category.json?timeline=1&id=" + patient_id + "&site=" + site + "&cat=" + (idx + 1),
                        "success": function(data) {
                            var datapoints = data['data'];
                            for (var i = 0; i < datapoints.length; i++) {
                                datapoints[i]['x'] = new Date(datapoints[i]['x'].replace(/-/g, "/").replace("T", " "));
                            }
                            drawChart(data['category'], datapoints);
                        }
                    });
                }
            }
        });
    });
});
