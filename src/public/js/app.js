/* Your application javascript goes here */

$(function(){
	var alertTimer = null;

    //remove () from facet values
    //$('#q').val( $('#q').val().replace(/[()]/g,'') )

	$('#q')
		.bind( "keydown", function( event ) {
			if ( event.keyCode === $.ui.keyCode.TAB &&
				$( this ).data( "autocomplete" ).menu.active ) {
				event.preventDefault();
			}
		})
		.autocomplete({
			source: function(request, response) {
				var list = [];
				$.getJSON(
          "/appbuilder/autocomplete.json?q=" + request.term, function(data) {
            for (var key in data) {
              console.log("autocomplete", key, data[key]);
              list.push(
                {'label': key + " " + data[key],
                 'value': 'concept:' + key});
            }
					  response(list);
				  });
			},
			minLength: 3,
			delay: 200,
			select: function(evt, ui) {
				if(ui.item) {
					$(evt.target).val(ui.item.value);
				}
				$(evt.target.form).submit();
			}
		});

	function showNotificationBar(message, duration, bgColor, txtColor, height) {
	    /*set default values*/
	    bgColor = typeof bgColor !== 'undefined' ? bgColor : "#F4E0E1";
	    txtColor = typeof txtColor !== 'undefined' ? txtColor : "#A42732";
	    height = typeof height !== 'undefined' ? height : 40;
	    /*create the notification bar div if it doesn't exist*/
	    if ($('#notification-bar').size() == 0) {
	        var HTMLmessage = "<div class='notification-message' style='text-align:center; line-height: " + height + "px;'> " + message + " </div>";
	        $('body').prepend("<div id='notification-bar' style='display:none; width:100%; height:" + height + "px; background-color: " + bgColor + "; position: fixed; z-index: 100; color: " + txtColor + ";border-bottom: 1px solid " + txtColor + ";'>" + HTMLmessage + "</div>");
	    }
	    /*animate the bar*/
	    $('#notification-bar').slideDown(function() {
	        if (duration) {
	        	setTimeout(function() {
	            	$('#notification-bar').slideUp(function() {});
	        	}, duration);
	        }
	    });
	}

	$(document).on('click', "#view_matches", function(evt, ui) {
		evt.preventDefault();
		$.cookie("match-check", new Date(), {expires: 5000, path: '/'});
		window.location.href = "/appbuilder/detail.html?subtab=2&matches=any&mature=false&q=saved-search%3Aall";
	});

	$(document).on('click', '#clear_matches', function(evt, ui) {
		evt.preventDefault();
		$.cookie("match-check", new Date(), {expires: 5000, path: '/'});
		$('#notification-bar').slideUp(function() {});
	});

    $(document).on('click', '.facet_green', function(evt, ui) {
        $.ajax({
            url: '/saved-search/delete.json',
            data: {'id': $(this).data('id')},
            type: 'post',
            success: function(data) {
                window.location.reload();
            }
        });
    });

	$(document).on('click', '.delete_saved_search', function(evt, ui) {

		$.ajax({
			url: '/saved-search/delete.json',
			data: {'id': $(this).data('id')},
			type: 'post',
			success: function(data) {
				window.location.reload();
			}
		});
	});

	function zeroPad(num) {
		if (num < 10) {
			return '0' + num.toString();
		} else {
			return num.toString();
		}
    }
    function alertCheck() {
		var since = new Date($.cookie('match-check'));
		var month = zeroPad(since.getUTCMonth() + 1);
		var date = zeroPad(since.getUTCDate());
		var hours = zeroPad(since.getUTCHours());
		var minutes = zeroPad(since.getUTCMinutes());
		var seconds = zeroPad(since.getUTCSeconds());
		$.ajax({
			url: '/saved-search/new-match-check.json?since=' + since.getUTCFullYear() + '-' + month + '-' + date + 'T' + hours + ':' + minutes + ':' + seconds + '.000Z',
			type: 'get',
			dataType: 'json',
			cache: false,
			success: function(data) {
				var count = data['matches'];
				if (count > 0) {
					if (!$('#notification-bar').is(':visible')) {
						showNotificationBar('<span id="match_count">' + count + '</span> new documents match your saved queries. <a href="#" id="view_matches">View</a> <a href="#" id="clear_matches">Clear</a>');
					} else {
						$('#match_count').text(count.toString());
					}
				}
			}
		});
	}

	if (window.location.href.search('alertmatch%3A') == -1) { 
		alertTimer = setInterval(alertCheck, 300000);
	}

	if (!$.cookie("match-check")) {
		$.cookie("match-check", new Date(), {expires: 5000, path: '/'});
	}
});
