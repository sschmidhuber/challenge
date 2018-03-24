$(document).ready(function(){
	var player = null;

	$(".nav-link").click(function(){
		var item = $(this).attr("href").substr(1).toLowerCase();
		//var item = $(this).text().toLowerCase();
		$(".nav-link").removeClass("active");
		$(this).addClass("active");

		$("[id^=container]").hide();
		$("#container-" + item).show();
		$("#container-" + item).trigger("activated");
	});

	$("#container-play").on("activated", function(){
		$("#button-start").focus();
	});

	$("#button-start").click(function(){
	  var message = {};
	  message.request = "start_new_game";
		socket.send(JSON.stringify(message));
	});

	$("#button-register").click( function() {
		$.post("/signUp", $("form-register").serialize(),
		function(data) {
			console.log(data);			
		   },
		   'json'
		);
	});
});
