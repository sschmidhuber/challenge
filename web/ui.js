$(document).ready(function () {
	var player = null;

	$(".nav-link").click(function () {
		var item = $(this).attr("href").substr(1).toLowerCase();
		//var item = $(this).text().toLowerCase();
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

		console.log("submit");
		console.log($(this).attr("action"));
		console.log($(this).attr("method"));
		console.log($("#register-name").val());

		var player = $("#register-name").val();
		var cou = $("#register-country").val();
		var pw = $("#register-password").val();

		console.log("name:", player, "\ncountry:", cou, "\npassword:", pw);

		// Send the data using post
		var posting = $.post("http://127.0.0.1:8000/signUp",
		{
			name: player,
			country: cou,
			password: pw
		},
	);
		
		console.log(posting);
	
		/*$.post("/signUp", $("form-register").serialize(),
		function(data) {
			console.log(data);			
		  },
		   'json'
		);*/
	});
});
