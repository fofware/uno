$(function () {
    "use strict";
	var dataDB = {}
	function jsonSend(ws,res){
		ws.send(JSON.stringify(res) );
		console.log("Envio ----------------------------")
		console.log(res);
	}
	function saveAs(blob, fileName) {
		var url = window.URL.createObjectURL(blob);
	
		var anchorElem = document.createElement("a");
		anchorElem.style = "display: none";
		anchorElem.href = url;
		anchorElem.download = fileName;
	
		document.body.appendChild(anchorElem);
		anchorElem.click();
	
		document.body.removeChild(anchorElem);
	
		// On Edge, revokeObjectURL should be called only after
		// a.click() has completed, atleast on EdgeHTML 15.15048
		setTimeout(function() {
			window.URL.revokeObjectURL(url);
		}, 1000);
	}
	function setUsers(clients,account){
		for ( var id in clients ) {
//			console.log("client ID ------",id);
			var username = clients[id].username;
			if ( id != user.id ) {
				var el = $("#"+id);
				var caption = $("#"+id+"caption");
				var content
				if ( !el.length ){
					el = $("<div />").attr({id:id}).addClass("box");
					el.append($("<h3 />").attr({id:id+"caption"}).addClass("caption"));
					var container = $("<div />").attr({id:+id+"container"}).addClass("container");
					container.append($("<div />").attr({id:id+"time"}));
//					container.append($("<div />").attr({id:id+"status"}));
					el.append(container);
					el.appendTo($("#webclient"));
				} 
				el.removeClass("offline online").addClass(clients[id].status);
				$("#"+id+"caption").text(clients[id].username);
				$("#"+id+"caption").removeClass("offline online").addClass(clients[id].status);
				$("#"+id+"time").text(new Date().toLocaleString());
//				$("#"+id+"status").text(clients[id].status);
			}
		}
	}
	function switchbt(param, rounded=false){
		var el = $("<label />").addClass("switch");
		var swEl = $("<input />")
					.attr({type:"checkbox"})
					.attr(param)
					.on( "click", function(){
						var data = JSON.parse( $(this).attr("param"));
						console.log("click_data",data)
						var account = user.account;
						var id = $(this).attr("controlerId");
						var msg = {dst:{},data:{}};
						msg.cmd = "proxy"

						msg.dst.account = account;
						msg.dst.group = "controler";
						msg.dst.id = id;

						msg.data.pin = data.actuador.pin;
						msg.data.cmd=data.actuador.cmd;

						if( $(this).is(':checked') ){
							msg.data.value = data.actuador[msg.data.cmd][data.actuador.value]
//							console.log("El checkbox con valor " + data.actuador.value + " ha sido seleccionado");
						} else {
//							console.log("El checkbox con valor " + data.actuador.value + " ha sido deseleccionado");
							msg.data.value = data.actuador[msg.data.cmd][data.actuador.value]
						}
						jsonSend(connection,msg)
					})
		el.append(swEl);
		if (rounded) {
			el.append($("<div />").addClass("slider round"))
		} else {
			el.append($("<div />").addClass("slider"))
		}
		return el;
	}
	function setCosas(controler,account){
		for ( var id in controler ) {
//			console.log("controler ID ------",id);
//			console.log("controler---",controler);
			var cosas = controler[id];
			var curTime = new Date().toLocaleString();
//			console.log(cosas);
//			if ( id != user.id ) {
				var el = $("#"+id);
				if ( !el.length ){
					el = $("<div />").attr({id:id}).addClass("box");
					el.append($("<h3 />").attr({id:id+"_caption"}).addClass("caption").text(controler[id].name));
					var container = $("<div />").attr({id:id+"_container"}).addClass("container");
					container.append($("<div />").attr({id:id+"_name"}).text("Controler Id: "+id));
					container.append($("<div />").attr({id:id+"_site"}).text("Lugar: "+controler[id].site));
					container.append($("<div />").attr({id:id+"_time"}));
					container.append($("<button />").attr({ctrlId:id}).text("Reset").on("click", function(){
						var msg = {dst:{},data:{}};
						msg.cmd = "proxy"

						msg.dst.account = user.account;
						msg.dst.group = "controler";
						msg.dst.id = $(this).attr("ctrlId");

						msg.data.cmd="reset";
						$("#"+id+"_caption").removeClass("offline online").addClass("offline");
						jsonSend(connection,msg)
					}));
					container.append($("<button />").attr({ctrlId:id}).text("List Files").on("click", function(){
						var msg = {dst:{},data:{}};
						msg.cmd = "proxy"

						msg.dst.account = user.account;
						msg.dst.group = "controler";
						msg.dst.id = $(this).attr("ctrlId");

						msg.data.cmd="filelist";
						msg.data.dst = {
							account: user.account
							,group: "clients"
							,id: user.id
						}
						jsonSend(connection,msg)
					}));
					container.append($("<button />").attr({ctrlId:id}).text("Read File").on("click", function(){
						var msg = {dst:{},data:{}};
						msg.cmd = "proxy"

						msg.dst.account = user.account;
						msg.dst.group = "controler";
						msg.dst.id = $(this).attr("ctrlId");

						msg.data.cmd="fileupload";
						msg.data.filename="/FLASH/init.lua";
						msg.data.dst = {
							account: user.account
							,group: "clients"
							,id: user.id
						}
						jsonSend(connection,msg)
					}));
					container.append($("<button />").attr({ctrlId:id}).text("Send File").on("click", function(){
						var msg = {dst:{},data:{}};
						msg.cmd = "proxy"

						msg.dst.account = user.account;
						msg.dst.group = "controler";
						msg.dst.id = $(this).attr("ctrlId");

						msg.data.cmd="filerecibe";
						msg.data.filename="/FLASH/prueba.txt";
						msg.data.dst = {
							account: user.account
							,group: "clients"
							,id: user.id
						}
						msg.data.data="asdfasdf asdf asdfa sdf asdf asdfasdfasdfasdfasdf asdf asdf asdf asdf asdf asdf"
						jsonSend(connection,msg)
					}));
					var cosasEl = $("<div />").attr({id:id+"_cosas"});//.addClass("cosa_item")
					for ( var cosa in controler[id]){
						var addEl = false;
						var obj = controler[id][cosa];
						var cosacontainer = $("<div />").attr({id:id+cosa+"_contentainer"}).addClass("cosa_container");
						cosacontainer.append(
							$("<div />").attr({id:id+cosa+"_caption"}).addClass("cosa_caption").text(controler[id][cosa].name+" "+controler[id][cosa].site)
						);
						if (obj.actuador){
							var cosacontent = $("<div />").attr({id:id+cosa+"_item"}).addClass("flex").appendTo(cosacontainer);
//							cosacontent.append($("<label />").text("Interrruptor"));
							cosacontent.append(
//								$("<div />").addClass("cosa_item_left").append(switchbt({id:id+cosa+"_sw",param:JSON.stringify(controler[id][cosa]),account:user.account,controlerId:id},false))
								$("<div />").append(switchbt({id:id+cosa+"_sw",param:JSON.stringify(controler[id][cosa]),account:user.account,controlerId:id},false))
							);
//							cosacontent.append(
//								$("<div />").addClass("cosa_item_col").append($("<label />").css({"font-size":"1em"}).attr({id:id+cosa+"_actuador_time"}).text(curTime))
//							)
							cosacontent.append(
//								$("<div />").addClass("cosa_item_right").append($("<label />").attr({id:id+cosa+"_actuador"}).text(controler[id][cosa].actuador.value))
								$("<div />").append($("<label />").attr({id:id+cosa+"_actuador"}).text(controler[id][cosa].actuador.value))
							)
							addEl = true;
						}
						if (obj.sensor){
							for (var fld in controler[id][cosa].sensor){
								var cosacontent = $("<div />").attr({id:id+cosa+"_item"}).addClass("flex").appendTo(cosacontainer);
								cosacontent.append(
									$("<div />")		//.addClass("cosa_item_left")
									.append(
										$("<label />").text(fld)
									)
								);
								cosacontent.append(
									$("<div />")		//.addClass("cosa_item_right")
									.append(
										$("<label />").attr({id:id+cosa+"_"+fld}).text(controler[id][cosa].sensor[fld])
									)
								);
								cosacontainer.append(cosacontent)
//								cosacontent.append($("<br>"));
							}
/*
							var cosacontent = $("<div />").attr({id:id+cosa+"_item"}).addClass("flex").appendTo(cosacontainer);
							cosacontent.append(
								$("<div />")			//.addClass("cosa_item_left")
								.append(
									$("<label />").text("value")
								)
							);
							cosacontent.append(
								$("<div />")			//.addClass("cosa_item_right")
								.append(
									$("<label />").attr({id:id+cosa+"_value"}).text(controler[id][cosa].sensor.value)
								)
							);
							var cosacontent = $("<div />").attr({id:id+cosa+"_item"}).addClass("flex").appendTo(cosacontainer);
							cosacontent.append(
								$("<div />")			//.addClass("cosa_item_left")
								.append(
									$("<label />").text("time")
								)
							);
							cosacontent.append(
								$("<div />")			//.addClass("cosa_item_right")
								.append(
									$("<label />").attr({id:id+cosa+"_time"}).text(controler[id][cosa].sensor.time)
								)
							);

							cosacontainer.append(cosacontent)
*/
							addEl = true;
						}
						cosacontainer.append(
							$("<div />").attr({id:id+cosa+"_last"}).addClass("cosa_footer")
						);
						if (addEl) cosasEl.append(cosacontainer);
					}
					el.append(container);
					el.append(cosasEl);
					el.appendTo($("#devices"));
				}
				for ( var cosa in controler[id]) {
					if (controler[id][cosa].actuador){
						$("#"+id+cosa+"_sw").text(controler[id][cosa].actuador.value).attr({param:JSON.stringify(dataDB.controler[id][cosa])});
						if (controler[id][cosa].actuador.value == "off"){
							$("#"+id+cosa+"_sw").prop("checked",false)
						}else{
							$("#"+id+cosa+"_sw").prop("checked",true)
						}
						$("#"+id+cosa+"_actuador").text(controler[id][cosa].actuador.value);
//						$("#"+id+cosa+"_actuador_time").text(curTime)
						$("#"+id+cosa+"_last").text(curTime);
					}	
					if (controler[id][cosa].sensor){
						$("#"+id+cosa+"_acumulador").text(controler[id][cosa].sensor.acumulador);
						$("#"+id+cosa+"_value").text(controler[id][cosa].sensor.value);
						$("#"+id+cosa+"_time").text(controler[id][cosa].sensor.time);
						$("#"+id+cosa+"_last").text(curTime);
					}
				}
				
//				$("#"+id+"_caption").text(controler[id].name);
//				$("#"+id+"_name").text("Controler Id: "+id);
//				$("#"+id+"_site").text("Lugar: "+controler[id].site);
				$("#"+id+"_time").text(curTime);
				if (controler[id].status)
					$("#"+id+"_caption").removeClass("offline online").addClass(controler[id].status);
//			}
		}
	}
	var funciones = {
		getinfo: function (ws,obj) {
			console.log("Funcion getinfo")
		}
		,initData: function(ws,obj){
			$.extend(true,dataDB,obj.data);
//			console.log("dataDB",dataDB);
			setUsers(obj.data.clients,obj.data.account);
			setCosas(obj.data.controler,obj.data.account);
		}
		,fileread(ws,obj){
			if (obj.data.chunk == "ini") {
				ws.tmpfile = "";
				ws.tmpfstat = obj.data.stat;
			}
			ws.tmpfile += obj.data.data;
			if (obj.data.chunk == "end"){
				var blob2 = new Blob([ws.tmpfile], {type: "text/plain"});
				var fileName2 = ws.tmpfstat.name;
				saveAs(blob2, fileName2);
				delete(ws.tmpfile);
				delete(ws.tmpfstat);
			}
		}
		,setclients: function(ws,obj){
//			console.log(obj.data);
			$.extend(true,dataDB,obj.data);
//			console.log("dataDB",dataDB);
			setUsers(obj.data.clients,obj.data.account);
		}
		,setcontroler: function (ws,obj){
			console.log(obj.data);
			$.extend(true,dataDB,obj.data);
			console.log("dataDB",dataDB);
			setCosas(obj.data.controler,obj.data.account);
		}
		,filelist: function (ws,obj){
			console.log(obj.data);
			$.extend(true,dataDB,obj.data);
			console.log("dataDB",dataDB);
			setCosas(obj.data.controler,obj.data.account);
		}
	}
    // for better performance - to avoid searching in DOM
    var content = $('#content');
    var input = $('#input');
    var status = $('#status');
    var estado = $('#estado');

    // my color assigned by the server
    var myColor = false;
    // my name sent to the server
    var myName = user.username;

	
    // if user is running mozilla then use it's built-in WebSocket
    window.WebSocket = window.WebSocket || window.MozWebSocket;

    // if browser doesn't support WebSocket, just show some notification and exit
    if (!window.WebSocket) {
        content.prepend($('<p>', { text: 'Sorry, but your browser doesn\'t '
                                    + 'support WebSockets.'} ));
        input.hide();
        $('span').hide();
        return;
    }
	var connection = null;
	function ws_connect(){
	// open connection
		var myurl = window.location.href.replace("http", "ws");
		connection = new WebSocket(myurl);
		connection.onopen = function () {
			// first we want users to enter their names
			var info = user;
			info.cmd = "info";
			info.device ="webclient";
			input.removeAttr('disabled').val("");
			status.text('Choose name:');
            if ( myName !== false) {
				status.text(myName+':');
//				connection.send(myName);
            }
			console.log("info",info);
			connection.send(JSON.stringify(info));
		};
		connection.onerror = function (error) {
			// just in there were some problems with conenction...
			content.prepend($('<p>', { text: 'Sorry, but there\'s some problem with your '
										+ 'connection or the server is down.' } ));
		};
		connection.onclose = function(event){
			console.log('[close]', event.code, event.reason);
		}
		// most important part - incoming messages
		connection.onmessage = function (message) {
			// try to parse JSON message. Because we know that the server always returns
			// JSON this should work without any problem but we should make sure that
			// the massage is not chunked or otherwise damaged.
//			$("#content").prepend("<p>"+message.data+"</p>");
			try {
				var json = JSON.parse(message.data);
			} catch (e) {
				console.log('This doesn\'t look like a valid JSON: ', message.data);
				return;
			}

//			console.log(json);
			// NOTE: if you're not sure about the JSON structure
			// check the server source code above
			console.log("Recibo -----------------")
			switch (json.cmd) {
				case 'message':
					input.removeAttr('disabled'); // let the user write another message
					addMessage(json.data.author, json.data.text,
						json.data.color, new Date(json.data.time));
				break;
				
				default:
//					console.log(json.cmd);
					if (typeof funciones[json.cmd] === "function") {
						console.log(json);
						funciones[json.cmd](connection,json);
					} else {
						content.prepend("<p>"+message.data+"</p>");
						console.log('Hmm..., I\'ve never seen JSON like this: ', json);
					}
				break;
			}
		};
	}
	

    /**
     * Send mesage when user presses Enter key
     */
    input.keydown(function(e) {
        if (e.keyCode === 13) {
            var msg = $(this).val();
            if (!msg) {
                return;
            }
            // send the message as an ordinary text
            connection.send(msg);
            $(this).val('');
            // disable the input field to make the user wait until server
            // sends back response
//            input.attr('disabled', 'disabled');

            // we know that the first message sent from a user their name
            if (myName === false) {
                myName = msg;
            }
        }
    });

    setInterval(function() {
        if (!connection || connection.readyState == 3 ) {
            status.text('Error');
            input.attr('disabled', 'disabled').val('Unable to comminucate '
                                                 + 'with the WebSocket server.');
			ws_connect();
		}
    }, 1000);
/*
    setInterval(function() {
		var info = {};
		info.type = "ping";
		console.log("info",info);
		connection.send(JSON.stringify(info));
    }, 10000);
*/
    /**
     * Add message to the chat window
     */
    function addMessage(author, message, color, dt) {
        content.prepend('<p><span style="color:' + color + '">' + author + '</span> @ ' +
             + (dt.getHours() < 10 ? '0' + dt.getHours() : dt.getHours()) + ':'
             + (dt.getMinutes() < 10 ? '0' + dt.getMinutes() : dt.getMinutes())
             + ': ' + message + '</p>');
    }
});