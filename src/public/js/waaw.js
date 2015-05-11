$(function(){
    $(function() {
        var qsvalue = qs("enableContextEx");
        $('#enableContextExCB').tooltip({ content: "Warning, enabling this feature may result in a run time of several minutes." });
        if(qsvalue) {
            $('#enableContextExCB').attr('checked', true);
            $('.contextExamples').show();
            $('.contextExamplesHeader').show();
            $('#waawReportTable').css('width', '90%');
        }
        else {
            $('#enableContextExCB').attr('checked', false);
            $('.contextExamples').hide();
            $('.contextExamplesHeader').hide();
            $('#waawReportTable').css('width', '300px');
        }

    });

    //get query string parameter
    function qs(key) {
        key = key.replace(/[*+?^$.\[\]{}()|\\\/]/g, "\\$&"); // escape RegEx meta chars
        var match = location.search.match(new RegExp("[?&]"+key+"=([^&]+)(&|$)"));
        return match && decodeURIComponent(match[1].replace(/\+/g, " "));
    }
    /*
	function getParameterByName( name ) {
		name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
		var regexS = "[\\?&]"+name+"=([^&#]*)";
		var regex = new RegExp( regexS );
		var results = regex.exec( window.location.href );
		if( results == null )
			return "";
		else
			return decodeURIComponent(results[1].replace(/\+/g, " "));
	}

	$('#waaw-form input[type="text"]').each(function(idx, element){
		$(this).val(querystring($(this).attr("name")));
	});
    */
});