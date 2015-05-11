$(function() {
    var chart;
    var duration = 10;
    var today = new Date();
    var xMin = null;
    var xMax = null;
    var table1 = null, table2 = null, table3 = null, table4 = null;
    var init = true;
    var zoom = 'year';
    var months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    var days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    var timeline_series = [];

    function mlDate(seconds) {
        var d = new Date(seconds);
        var month = d.getMonth() + 1;
        var day = d.getDate();
        var date = d.getFullYear() + '-' + (month < 10 ? '0' + month : month) + '-' + (day < 10 ? '0' + day : day) + 'T00:00:00';
        return date;
    }

    function drawChart() {
        var start = (xMin != null) ? '&start=' + mlDate(xMin) : "";
        var end = (xMax != null) ? '&end=' + mlDate(xMax) : "";
        $.ajax({
            async: true,
            url: "/appbuilder/aggregate-timeline.json?" + window.location.search.replace(/\?/, '') + start + end,
            success: function(data) {
                var series_data = {};
                for (var key in data) {
                    var arr = data[key];
                    if (!(arr instanceof Array)) {
                        arr = [arr];
                    }
                    for (var i=0; i<arr.length; i++) {
                        var obj = arr[i];
                        var datestr = obj['x'];
                        var year = parseInt(datestr.slice(0, 4));
                        var month = parseInt(datestr.slice(5, 7)) - 1;
                        var day = parseInt(datestr.slice(8, 10));
                        var hours = parseInt(datestr.slice(11, 13));
                        var minutes = parseInt(datestr.slice(14, 16));
                        var seconds = parseInt(datestr.slice(17, 19));
                        obj['x'] = (new Date(year, month, day, hours, minutes, seconds)).valueOf();
                    }
                    arr.sort(function(a, b){if (a['x'] > b['x']) {return 1} else if (b['x'] > a['x']) {return -1} else {return 0}});
                    series_data[key] = arr;
                }

                if (init) {
                    for (var key in series_data) {
                        var visible = ($.inArray(key, timeline_series) == -1) ? false : true;
                        chart.addSeries({name: key, data: series_data[key], visible: visible}, false);
                    }
                    chart.redraw();
                    init = false;
                } else {
                    for (var i=0; i < chart.series.length; i++) {
                        var name = chart.series[i]['name'];
                        chart.series[i].setData(series_data[name]);
                    }
                }

                if (zoom != 'year') {
                    $('#reset_zoom_button').show();
                } else {
                    $('#reset_zoom_button').hide();
                }
            }
        });
    }

    function updateTable1() {
        var length = $.cookie('DataTables_Table_0_length');
        var length = (length) ? parseInt(length) : 10;
        if (table1 == null) {
            table1 = $('#table_1 div.container table').dataTable({
                "bProcessing": true,
                "bServerSide": true,
                "bPaginate": true,
                "iDisplayLength": length,
                "sAjaxSource": "/appbuilder/results-diag-table.json" + window.location.search,
                "fnDrawCallback": function(oSettings) {
                    $('#table_1 table tbody tr').each(function(idx, element) {
                        var title_cell = $(this).find('td:first');
                        title_cell.attr('title', title_cell.text());    //default to the diagnosis code
                    });
                    $.ajax({
                        url: '/appbuilder/icd-code-lookup.json',
                        type: 'post',
                        traditional: true,
                        data: {icd9code: $('#table_1 table tbody tr').find('td:first').map(function(){return $(this).text()}).get()},
                        success: function(data) {
                            table1.find('tbody tr').each(function(idx, element) {
                                var td = $(this).find('td:first');
                                //td.text( data[td.text()] );   //overwrite the code with the description
                                //td.attr('title', data[td.text()]);
                                if (location.hash.search("hideInterface") != -1) {
                                    var text = td.text();
                                    if (text.length > 30) {
                                        td.text(text.slice(0, 27) + "...");
                                    }
                                }
                            });
                        }
                    });
                }
            });
        } else {
            table1.fnSettings().sAjaxSource = "/appbuilder/results-diag-table.json" + window.location.search;
            table1.fnDraw();
        }
    }

    function updateTable2() {
        var length = $.cookie('DataTables_Table_1_length');
        var length = (length) ? parseInt(length) : 10;
        if (table2 == null) {
            table2 = $('#table_2 div.container table').dataTable({
                "bProcessing": true,
                "bServerSide": true,
                "bPaginate": true,
                "iDisplayLength": length,
                "sAjaxSource": "/appbuilder/results-rx-table.json" + window.location.search,
                "fnDrawCallback": function(oSettings) {
                    $('#table_2 table tbody tr').each(function(idx, element) {
                        var title_cell = $(this).find('td:first');
                        title_cell.attr('title', title_cell.text());
                        if (location.hash.search("hideInterface") != -1) {
                            var text = title_cell.text();
                            if (text.length > 30) {
                                title_cell.text(text.slice(0, 27) + "...");
                            }
                        }
                    });
                }
            });
        } else {
            table2.fnSettings().sAjaxSource = "/appbuilder/results-rx-table.json" + window.location.search;
            table2.fnDraw();
        }
    }

    function updateTable3() {
        var length = $.cookie('DataTables_Table_2_length');
        var length = (length) ? parseInt(length) : 10;
        if (table3 == null) {
            table3 = $('#table_3 div.container table').dataTable({
                "bProcessing": true,
                "bServerSide": true,
                "bPaginate": true,
                "iDisplayLength": length,
                "sAjaxSource": "/appbuilder/results-facility-table.json" + window.location.search,
                "fnDrawCallback": function(oSettings) {
                    $('#table_3 table tbody tr').each(function(idx, element) {
                        var title_cell = $(this).find('td:first');
                        title_cell.attr('title', title_cell.text());
                        if (location.hash.search("hideInterface") != -1) {
                            var text = title_cell.text();
                            if (text.length > 30) {
                                title_cell.text(text.slice(0, 27) + "...");
                            }
                        }
                    });
                }
            });
        } else {
            table3.fnSettings().sAjaxSource = "/appbuilder/results-facility-table.json" + window.location.search;
            table3.fnDraw();
        }
    }

    function updateTable4() {
        var length = $.cookie('DataTables_Table_3_length');
        var length = (length) ? parseInt(length) : 10;
        if (table4 == null) {
            table4 = $('#table_4 div.container table').dataTable({
                "bProcessing": true,
                "bServerSide": true,
                "bPaginate": true,
                "iDisplayLength": length,
                "sAjaxSource": "/appbuilder/results-procedure-table.json" + window.location.search,
                "fnDrawCallback": function(oSettings) {
                    $('#table_4 table tbody tr').each(function(idx, element) {
                        var title_cell = $(this).find('td:first');
                        title_cell.attr('title', title_cell.text());
                        if (location.hash.search("hideInterface") != -1) {
                            var text = title_cell.text();
                            if (text.length > 30) {
                                title_cell.text(text.slice(0, 27) + "...");
                            }
                        }
                    });
                    if (location.hash.search("hideInterface") != -1) {window.print()};
                }
            });
        } else {
            table4.fnSettings().sAjaxSource = "/appbuilder/results-procedure-table.json" + window.location.search;
            table4.fnDraw();
        }
    }


    function hideInterface() {
        $('.dataTables_paginate,.dataTables_filter,.dataTables_length,.web-interface,div.col2,div.search,div.user').hide();
        $('div.colleft').css('right', '0');
        var html = $('div.col1').html();
        $('div.colmask').html(html);
        $('table.quad_table').width('98%');
        $('td:first-child').each(function(idx, el) {
            var text = $(this).text();
            if (text.length > 30) {
                $(this).text(text.slice(0, 27) + '...');
            }
        });
    }

    $(document).on('ip401:search', function(evt, ui) {
        if (location.hash.search("hideInterface") != -1) {
            hideInterface();
            initChart();
            chart.setSize(650, 450, false);
        } else {
            $('#print_button').remove();
            $('.col1 div.ui-tabs').append('<button id="print_button">Print Report</button>');
        }
        updateTable1();
        updateTable2();
        updateTable3();
        updateTable4();
        drawChart();
    });

    $('#reset_zoom_button').on('click', function(evt, ui) {
        evt.preventDefault();
        xMin = null;
        xMax = null;
        zoom = 'year';
        $.removeCookie('timeline_zoom');
        $.cookie('timeline_xMax', xMax, {expires: 5000, path: '/'});
        $.cookie('timeline_xMin', xMin, {expires: 5000, path: '/'});
        drawChart();
    });

    $(document).on('click', '#print_button', function(evt, ui) {
        window.open(window.location.href + '#hideInterface', '_blank');
    });

    $(document).on('change', 'div.dataTables_length select', function(evt, ui) {
        var id = $(this).parents('div.dataTables_length').attr('id');
        $.cookie(id, $(this).val());
    });



    function initChart() {
        chart = new Highcharts.Chart({
            chart: {
                renderTo: 'timeline_div',
                type: 'line',
                selection: function(event) {
                    if (event.resetSelection) {

                    }
                }
            },
            title: {
                text: 'Timeline'
            },
            xAxis: {
                title: {
                    enabled: true,
                    text: 'Year'
                },
                type: 'datetime',
                showLastLabel: true,
                minTickInterval: 24 * 3600 * 1000,
                events: {
                    afterSetExtremes: function() {
                        var ext = this.getExtremes();
                        xMin = ext['userMin'] || ext['min'];
                        xMax = ext['userMax'] || ext['max'];

                        //drawChart();
                        //$(document).trigger('ip401:search');
                    }
                },
                min: (xMin) ? new Date(xMin) : null,
                max: (xMax) ? new Date(xMax) : null
            },
            yAxis: {
                title: {
                    text: 'Count'
                },
                labels: {
                    enabled: true
                },
                allowDecimals: false
            },
            tooltip: {
                formatter: function() {
                    var x = new Date(this.point.x);
                    if (zoom == 'year') {
                        return 'Year: ' + x.getFullYear() + '<br/>Count: ' + this.point.y;
                    } else if (zoom == 'month') {
                        return 'Month: ' + months[x.getMonth()] + ' ' + x.getFullYear() + '<br/>Count: ' + this.point.y;
                    } else if (zoom == 'day') {
                        return 'Day: ' + days[x.getDay()] + ', ' + months[x.getMonth()] + ' ' + x.getDate() + ' ' + x.getFullYear() + '<br/>Count: ' + this.point.y;
                    }
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
                series: {
                    cursor: 'pointer',
                    point: {
                        events: {
                            click: function() {
                                var date = new Date(this.x);
                                if (zoom == 'year') {
                                    xMin = date.valueOf();
                                    xMax = (new Date(date.getFullYear() + 1, 0, 0, 0, 0, 0, 0)).valueOf();
                                    zoom = 'month';
                                    drawChart();
                                } else if (zoom == 'month') {
                                    var newYear = (date.getMonth() == 11) ? date.getFullYear() + 1 : date.getFullYear();
                                    var newMonth = (date.getMonth() == 11) ? 0 : date.getMonth() + 1;
                                    xMin = date.valueOf();
                                    xMax = (new Date(newYear, newMonth, 0, 0, 0, 0, 0)).valueOf();
                                    zoom = 'day';
                                    drawChart();
                                }

                                $.cookie('timeline_zoom', zoom, {expires: 5000, path: '/'});
                                $.cookie('timeline_xMax', xMax, {expires: 5000, path: '/'});
                                $.cookie('timeline_xMin', xMin, {expires: 5000, path: '/'});
                            }
                        }
                    }
                },
                line: {
                    events: {
                        legendItemClick: function() {
                            if (!this.visible) {
                                if ($.inArray(this.name, timeline_series) == -1) {
                                    timeline_series.push(this.name);
                                }
                            } else {
                                var idx = $.inArray(this.name, timeline_series);
                                if (idx != -1) {
                                    timeline_series.splice(idx, 1);
                                }
                            }
                            $.cookie('timeline_series', '["' + timeline_series.join('","') + '"]', {expires: 5000, path: '/'});
                        }
                    }
                }
            },
            series: []
        });
    }
    if (location.hash.search("hideInterface") == -1) {
        initChart();
    }

    if ($.cookie('timeline_series')) {
        timeline_series = $.parseJSON($.cookie('timeline_series'));
    } else {
        timeline_series = ['Vitals'];
    }

    if ($.cookie('timeline_zoom')) {
        zoom = $.cookie('timeline_zoom');
        xMax = parseInt($.cookie('timeline_xMax'));
        xMin = parseInt($.cookie('timeline_xMin'));
    } else {
        zoom = 'year';
    }



});
