$(document).ready(function(){
	$("#button-start").focus();
	var socket = new WebSocket("ws://localhost:8080");
	
	socket.onopen = function(){
	alert("Socket has been opened!");
	socket.send("Test");
};
	
	socket.onmessage = function(msg){
	console.log(msg);	//Awesome!
};

	$(".nav-link").click(function(){
		var item = $(this).text().toLowerCase();
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
});
