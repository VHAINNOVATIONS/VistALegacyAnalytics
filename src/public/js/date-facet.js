$(function() {
  //need to use '/' in date instead of '-' for IE8 compatibilty in calling the Date() constructor,
  //will get a NaN if '-' is used in the date.
  $('#start_date').datepicker(
    {dateFormat: "yy/mm/ddT00:00:00Z", defaultDate: new Date('1984/01/01')});
  $('#end_date').datepicker(
    {dateFormat: "yy/mm/ddT00:00:00Z", defaultDate: new Date('1999/12/31')});

  if (!window.console) { console = { log: function() {}}};

  function convertToVprDate(date) {
    var year = (date.getUTCFullYear() - 1700) * 10000;
    var month = (date.getUTCMonth() + 1) * 100;
    var day = date.getUTCDate();
    return vprdate = year + month + day;
  }

  function dateTerm(val, op) {
      if (null == val || val == "") return '';
      var i = val.indexOf('T');
      if (i >= 0)
          val = val.substr(0, i);

      var dateObj = new Date(val);
      return convertToVprDate(dateObj);
  }

  $('#apply_date').on('click', function(evt, ui) {
    var search = $('#q').val();

    //get previous search date filters if they exist
    var previousEndDateValue = getPreviousDateValue(search, "LT");
    var previousStartDateValue = getPreviousDateValue(search, "GT");

    var start = $('#start_date').val();
    var end = $('#end_date').val();

    console.log('[date-facet apply] init',
                'search', search, 'start', start, 'end', end,
                'previousEndDateValue', previousEndDateValue, 'previousStartDateValue', previousStartDateValue);

    // convert ISO-8601 to VPR, as needed
    start = dateTerm(start, 'GT');
    end = dateTerm(end, 'LT');

    //compare the new and previous dates and use the winner
    start = getFilterStartDate(previousStartDateValue, start);
    end = getFilterEndDate(previousEndDateValue, end);

    console.log('[date-facet apply] init',
          'search', search, 'start', start, 'end', end,
          'previousEndDateValue', previousEndDateValue, 'previousStartDateValue', previousStartDateValue);

    search = createSearchText(search, start, end);

    console.log('[date-facet apply]',
                'start', start, 'end', end, 'search', search);

    $('#q').val(search);
    $('#searchform').submit();
  });

  function getPreviousDateValue(searchText, op) {
      var dateValue = "";
      var regExString = "diag-date " + op + " [0-9]*"
      var regEx = new RegExp(regExString);
      var m = regEx.exec(searchText);
      if (m != null) {
          var previousDateFacet = m[0];
          dateValue = previousDateFacet.substr(13, previousDateFacet.length - 13);
      }
      return dateValue;
  }

    function getFilterStartDate(previousStartDateValue, newStartDate) {
        var vprStartDate = "";
        // if there is a new start date and there is not a previous start date, use the new start date.
        // if there is not a new start date and there is a previous start date, do not use a start date
        // if there is a new start date and a previous start date, use the latest of the two dates.
        if( newStartDate && (previousStartDateValue == "")) {
            vprStartDate = newStartDate;
        }
        else if( newStartDate && previousStartDateValue) {
            if(newStartDate > previousStartDateValue) {
                vprStartDate = newStartDate;
            }
            else {
                vprStartDate = previousStartDateValue;
            }
        }
        return vprStartDate;
    }

    function getFilterEndDate(previousEndDateValue, newEndDate) {
        var vprEndDate = "";
        // if there is a new end date and there is not a previous end date, use the new end date.
        // if there is not a new end date and there is a previous end date, do not use a end date
        // if there is a new end date and a previous end date, use the earliest of the two dates.
        if( newEndDate && (previousEndDateValue == "")) {
            vprEndDate = newEndDate;
        }
        else if( newEndDate && previousEndDateValue) {
            if(newEndDate < previousEndDateValue) {
                vprEndDate = newEndDate;
            }
            else {
                vprEndDate = previousEndDateValue;
            }
        }
        return vprEndDate;
    }

    function createSearchText(searchText, startVprDate, endVprDate)
    {
        //remove any existing date filters from the search text
        var regularExpression = new RegExp("diag-date GT [0-9]*", "g");
        searchText = searchText.replace(regularExpression, "");
        regularExpression = new RegExp("diag-date LT [0-9]*", "g");
        searchText = searchText.replace(regularExpression, "");

        //trim leading and trailing white space
        searchText = searchText.replace(/^\s+|\s+$/g,'')

        //append new search filters to the search text
        if(startVprDate)
            searchText = searchText + " diag-date GT " + startVprDate;

        if(endVprDate)
            searchText = searchText + " diag-date LT " + endVprDate;

        //trim leading and trailing white space
        searchText = searchText.replace(/^\s+|\s+$/g,'')

        return searchText;
    }

});

// date-facet.js
