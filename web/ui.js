$(document).ready(function () {
	var player = null;

	// submit ajax requests
	submitRequest = function(event, errorFun, successFun) {
		$.ajax({
			type: $(event.target).attr("method"),
			url: $(event.target).attr("action"),
			data: $(event.target).serialize(),
			error: errorFun(event),			
			success: successFun(event)
		});
	}

	$(".nav-link").click(function () {
		var item = $(this).attr("href").substr(1).toLowerCase();
		$(".nav-link").removeClass("active");
		$(this).addClass("active");

		$("[id^=container]").hide();
		$("#container-" + item).show();
		$("#container-" + item).trigger("activated");
	});

	$("#container-play").on("activated", function () {
		$("#button-start").focus();
	});

	$("#button-start").click(function () {
		var message = {};
		message.request = "start_new_game";
		socket.send(JSON.stringify(message));
	});

	$("#form-register").submit(function (event) {
		event.preventDefault();
		submitRequest(event);
	});
});
