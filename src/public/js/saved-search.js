
$(function(){

    $(document).ready(function(){
        $('#savedSearches').dataTable( {
            "bProcessing": true,
            "bServerSide": true,
            "sAjaxSource": "/saved-search/getSavedSearches",
            "fnRowCallback": function( nRow, aData, iDisplayIndex ) {
                //convert aData[0] to display date format
                if ( aData[0] != null ) {
                    var dateColumnContent = convertStringToDisplayDate(aData[0]);
                    $('td:eq(0)', nRow).html( dateColumnContent );
                }

                //convert aData[1] to url
                //<a href="/?q=saved-search:{$id}">{fn:substring($search,1,30)}</a>
                if ( (aData[1] != null) && (aData[2] != null) ) {
                    var urlColumnContent = '<a href="/?q=' + encodeURIComponent(aData[1]) + '">' + aData[1] + '</a>';
                    $('td:eq(1)', nRow).html( urlColumnContent );
                }

                //convert aData[2] to delete icon
                if ( aData[2] != null ) {
                    var deleteColumnContent = '<img src="/images/delete_remove.png" class="delete_saved_search" data-id="' + aData[2] + '"/>';
                    $('td:eq(2)', nRow).html( deleteColumnContent );
                }
            }
        });

        $('#savedSearches td:first-child').addClass('dateCol');
        $('#savedSearches td:last').css('text-align', 'center').css('width','25px');

        // input: 2013-07-25T12:08:57.379341-04:00
        // output: 07/25/13 11:59 am
        function convertStringToDisplayDate(dateTimeString)
        {
            /*
             2013-07-25T12:08:57.379341-04:00
             07/25/13 11:59 am
             declare function local:format-date($date)
             {
             fn:format-dateTime($date, "[M01]/[D01]/[Y01] [h01]:[m01] [Pn]")
             };
             */
            var dateString = dateTimeString.substr(0, dateTimeString.indexOf('T'));
            var dateTokens = dateString.split('-');
            var year = dateTokens[0].substr(2,2);
            var month = dateTokens[1];
            var day = dateTokens[2];

            var timeString = dateTimeString.substr(dateTimeString.indexOf('T') + 1, dateTimeString.length);
            var timeTokens = timeString.split(':');
            var hours = timeTokens[0];
            var minutes = timeTokens[1];

            var postfix = "am";
            if(hours > 12) {
                postfix = "pm";
                hours = hours - 12;
            }

            var displayDateTime = month + '/' + day + '/' + year +
                ' ' + hours + ':' + minutes + ' ' + postfix;

            return displayDateTime;
        }

    });

});
