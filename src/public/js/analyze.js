$(function() {

    function vprDate(seconds) {
        var d = new Date(seconds);
        var date = (d.getFullYear() - 1700) * 10000;
        date += (d.getMonth() + 1) * 100;
        date += d.getDate();
        return date.toString();
    }

    /*
    $(document).ready(function () {
        $('.rotate').css('height', $('.rotate').width());
    });
    */

    function updateFacets() {
        $.ajax({
            url: window.location.href,
            type: 'get',
            success: function(data) {
                $('div.col2').replaceWith($(data).find('div.col2'));
            }
        });
    }

    $(document).on('change', '#addfacet_select', function(evt, ui) {
        if ($(this).val() != 'none') {
            var facet = $(this).val();
            var facets = $.cookie('facets');
            $.cookie('facets', facets + ' ' + facet, {expires: 5000, path: '/'});
            $.ajax({
                url: window.location.href,
                type: 'get',
                cache: false,
                success: function(data) {
                    $('div#sidebar').replaceWith($(data).find('div#sidebar'));

                }
            });
        }
    });

    function triggerSearch() {
        $(document).trigger('ip401:search');
    }

    function displayDiagnosisDateInputsControl() {
        var searchText = $('#q').val();
        if(searchText.indexOf("diag:") !== -1)
            $('#diagnosisDateInputs').show();
        else
            $('#diagnosisDateInputs').hide();
    }

    // This timeout is needed for IE7 rendering of the timeline.
    setTimeout(triggerSearch, 100);

    var resetQString = $(location).attr('search');

    $(document).on('click', 'img.remove_facet', function(evt, ui) {
        var category = $(this).parents('div.category');
        var name = category.find('h4').text();
        var facet = category.data('facet');
        var facets = $.cookie('facets');
        facets = facets.replace(facet, "").replace(/\s+/, " ");
        category.remove();
        $.cookie('facets', facets, {expires: 5000, path: '/'});
        $('#addfacet_select').append('<option value=' + facet + '>' + name + '</option>');
    });


});
