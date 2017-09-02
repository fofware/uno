var WebSocket = require('faye-websocket');
var EventSource = WebSocket.EventSource;
var skts = [ ];
var accounts = {};
/*
LogData
----------------------
{
	datetime
	,account
	,from={id,type}
	,to={}
	,cmd
	,data={}
}
--------------
	dateTime,account,tipodedispositivo,iddispositivo,cosaid,
*/

function clone( obj ) {
    if ( obj === null || typeof obj  !== 'object' ) {
        return obj;
    }
    var temp = obj.constructor();
    for ( var key in obj ) {
        temp[ key ] = clone( obj[ key ] );
    }
    return temp;
}

var funciones = {
	filelist: function(ws,msg){
		console.log(msg);
		var respObj ={[ws.userId]:{}};
		respObj[ws.userId].filelist=msg.data;
		var res = {
			dst: msg.dst
			,data: {
				cmd: "filelist"
				,data: {controler:respObj}
			}
		}
		response(ws,res);
	}
	,fileread: function(ws,msg){
		console.log("proxy_send",msg);
		var respObj ={[ws.userId]:{}};
		respObj[ws.userId]=msg.data;
//		respObj.filename = msg.filename
		var res = {
			dst: msg.dst
			,data: {
				cmd: "fileread"
//				,data: {controler:respObj}
				,data: msg.data
				,id: ws.userId
				,type: "controler"
			}
		}
		response(ws,res);
		if (msg.data.chunk != "end"){
			var cont = {
				cmd:"filecontinue"
			}
			jsonSend(ws,cont)
		}
	}
/*
	,ping: function(ws,msg){
		var sec = Math.floor(new Date().getTime() / 1000);
		var usec = ((new Date().getTime())%1000)*1000;
		res = {
//			type: "pong",
			cmd: "pong",
			sec: sec,
			usec: usec
		}
		jsonSend(ws,res);
		res = {};
//		res.type="setcontroler";
		res.cmd="setcontroler";
		res.account = ws.userAccount;
		res.group = "clients";
		res.data = {controler:{[ws.userId]:accounts[ws.userAccount].controler[ws.userId]}};
		response(ws,res);
	}
*/
	,info: function (ws,msg){
		var res = newClient(ws,msg);
		response(ws,res);
	}
	,new_data: function(ws,msg){
		var account = ws.userAccount;
		var group = ws.userType;
		var id = ws.userId;
		console.log(msg)
		var obj = msg[ws.userType];
//		console.log("Obj----", ws.userId,obj);
		var respObj ={[id]:{}};
//		respObj[id]={};
		for (var cosa in obj){
//			console.log("cosa:",cosa);
			if (!respObj[id][cosa]) respObj[id][cosa] = {};
			if (obj[cosa].actuador){
//				respObj[id][cosa].actuador=accounts[ws.userAccount][ws.userType][ws.userId][cosa].actuador;
				respObj[id][cosa].actuador=obj[cosa].actuador;
				for (var fld in obj[cosa].actuador) {
//					console.log(fld)
					accounts[ws.userAccount][ws.userType][ws.userId][cosa].actuador[fld] = obj[cosa].actuador[fld];
				}
			}
			if (obj[cosa].sensor){
				console.log(cosa,obj[cosa].sensor);
				if (!respObj[id][cosa]) respObj[id][cosa]={}; //accounts[ws.userAccount][ws.userType][ws.userId][cosa].sensor;
				respObj[id][cosa].sensor = obj[cosa].sensor;
				for (var fld in obj[cosa].sensor){
					accounts[ws.userAccount][ws.userType][ws.userId][cosa].sensor[fld] = obj[cosa].sensor[fld];
				}
			}
		}
			
		res = {dst:{},data:{}};
//		res.type="setcontroler";
		res.dst.account = ws.userAccount;
		res.dst.group = "clients";
		res.data.cmd ="setcontroler";
		res.data.data = {controler: respObj};
		response(ws,res);

//		accounts[ws.userAccount][ws.userType][ws.userId]
	}	
	,proxy: function(ws,msg){
/*
		console.log("====================================")
		console.log(msg);
*/
		console.log("Proxy data ------------------------------------")
		console.log(msg);
		response(ws,msg)
	}
}
function newClient(ws,msg){
	var id = msg.id;
	var account = msg.account || msg.id;
	delete msg.id;
	delete msg.account;
	var res = {dst:{},data:{}};
	if (!accounts[account]) accounts[account] = {clients:{},controler:{}}
	if (msg.device === "webclient"){
		// set id en socket
		ws.userType = "clients";
		ws.userAccount = account;
		ws.userId = id;

		delete msg.passwd;
		delete msg.id;

//		if (!skts[account]) skts[account] = { clients:{},controler:{}};
//		skts[account].clients[id] = ws;


		if (!accounts[account].clients[id]) {
			accounts[account].clients[id] = {};
		}
		accounts[account].clients[id].name = msg.name;
		accounts[account].clients[id].email = msg.email;
		accounts[account].clients[id].username = msg.username;
		accounts[account].clients[id].status="online";
		
		if (!skts[ws.userAccount]) skts[ws.userAccount] = { clients:{},controler:{}};
		skts[ws.userAccount][ws.userType][ws.userId] = ws;
		accounts[ws.userAccount][ws.userType][ws.userId].status = "online";

//		res.type = "setclients";
		res.dst.account = account;
		res.dst.group = "clients";
		res.data.data = {account:account,clients:{[id]:accounts[account].clients[id]}};
		res.data.cmd = "setclients";
		
		var cres = {};
//		cres.type = "initData";
		cres.cmd = "initData";
		cres.data = accounts[account];
		jsonSend(ws,cres);
	} else {
//		delete(msg.type);
		delete(msg.cmd);
		delete(msg.macAddres);
		if (!accounts[account].controler[id]) accounts[account].controler[id] = {};
		
		for (var key in msg) {
			if ( key != "controler" ){
				accounts[account].controler[id][key] = msg[key];
			} else {
				for ( var cosaKey in msg.controler ) {
					accounts[account].controler[id][cosaKey] = msg.controler[cosaKey];
				}
			}
		}

		ws.userType = "controler";
		ws.userAccount = account;
		ws.userId = id;
		
//		sockets.push({type:"controler",account:account,[id]:id,skt:ws});
//		if (!skts[account]) skts[account] = {};
//		skts[account].controler[id] = ws;

//		accounts[account].controler[id].status="online";
		if (!skts[ws.userAccount]) skts[ws.userAccount] = { clients:{},controler:{}};
//		console.log(ws.userAccount,ws.userType,ws.userId);
		skts[ws.userAccount][ws.userType][ws.userId] = ws;
		accounts[ws.userAccount][ws.userType][ws.userId].status = "online";

//		res.type="setcontroler";
		res.dst.account = account;
		res.dst.group = "clients";
		
//		accounts[account].controler[id]=msg;
//		res.data.data = {account:account,controler:{[id]:accounts[account].controler[id]}};
		res.data.data = {account:account,controler:{[id]:accounts[account].controler[id]}};
		res.data.cmd = "setcontroler";
	}
	return res;
}
function jsonSend(sk,res){
	sk.send( JSON.stringify(res) );
	console.log("Envia ----------------");
//	console.log(JSON.stringify(res));
	wsSetInterval(sk);
/*
	console.log(res);
	if (sk.userAccount)
		console.log(sk.userAccount,sk.userType,sk.userId);
*/
/*
	console.log("Envio -------------------------------------------------------");
	console.log(res);
	console.log("to ---------------");
	console.log(ws.userAccount,ws.userType,ws.userId);
	console.log("======================")
*/
}
function response(ws,res){
	var offlineAccounts = {};
/*
	console.log("========================================")
	console.log(res)
	console.log("----------------------------------------")
*/
	if (res.dst.account){
		if (res.dst.group){
			if (res.dst.id){
				var sk = skts[res.dst.account][res.dst.group][res.dst.id];
				//if (ws != sk && sk.readyState === 1 ) 
					jsonSend(sk,res.data);
			}else{
				for ( id in skts[res.dst.account][res.dst.group]){
					var sk = skts[res.dst.account][res.dst.group][id];
					if (ws != sk && sk.readyState === 1 ) jsonSend(sk,res.data);
				}
			}
		} else {
			for ( var group in skts[res.dst.account]){
				for ( var id in skts[res.dst.account][group]){
					var sk = skts[res.dst.account][res.dst.group][id];
					if (ws != sk && sk.readyState === 1 ) jsonSend(sk,res.data);
				}
			}
		}
	} else {
		var exit = false;
		for ( var account in skts){
			if (res.dst.group){
				if (res.dst.id){
					var sk = skts[account][res.dst.group][res.dst.id];
					if (ws != sk && sk.readyState === 1 ) jsonSend(sk,res.data);
//					exit = true;
//					break;
				} else {
					for ( var id in skts[account][res.dst.group]){
						var sk = skts[account][res.dst.group][id];
						if (ws != sk && sk.readyState === 1 ) jsonSend(sk,res.data);
					}
				}
			} else {
				for ( var group in skts[account]){
					if (res.dst.id){
						var sk = skts[account][group][res.dst.id];
						if (ws != sk && sk.readyState === 1 ) jsonSend(sk,res.data);
//						exit = true;
//						break;
					} else {
						for ( var id in skts[account][group]){
							var sk = skts[account][group][id];
							if (ws != sk && sk.readyState === 1 ) jsonSend(sk,res.data);
						}
					}
				}
			}
//			if (exit == true) break;
		}
	}
}
/*
function response(ws,res){
	var offlineAccounts = {};
	for (var i = sockets.length-1; i >= 0; i--) {
		var obj = sockets[i];
//		console.log(obj.skt);
		if (obj.skt.readyState === 1){
			if (ws != obj.skt){
				if ( res.account ){
					if ( res.group ) {
						if ( res.id ){
							if ( res.account == obj.account && res.group == obj.type && res.id == obj.id) jsonSend(obj.skt,res,obj);
						} else {
							if ( res.account == obj.account && res.group == obj.type ) jsonSend(obj.skt,res,obj);
						}
					} else {
						if ( res.account == obj.account ) jsonSend(obj.skt,res,obj);
					}
				} else {
					jsonSend(obj.skt,res,obj);
				}
			}
		} else {
			if (!offlineAccounts[obj.account]) offlineAccounts[obj.account] = {clients:{},controler:{}};
			accounts[obj.account][obj.type][obj.id].status="offline";
			offlineAccounts[obj.account][obj.type][obj.id] = accounts[obj.account][obj.type][obj.id];
			sockets.splice(i,1);
		}
	}
	for (var account in offlineAccounts ){
		var cres = {};
		cres.type = "initData";
		cres.data = accounts[account];
		for (var i = sockets.length-1; i>=0; i--){
			obj=sockets[i];
			console.log(obj);
			if (obj.account == account && obj.type == "clients"){
				jsonSend(obj.skt,cres);
			}
		}
	}
	console.log(sockets.length)
}
*/
function infoSocketState(ws){
	res = {dst:{},data:{}};
	res.dst.account = ws.userAccount;
	res.dst.group = "clients";
	res.data = {[ws.userType]:{[ws.userId]:accounts[ws.userAccount][ws.userType][ws.userId]}};
	if ( ws.userType == "clients" ){
//		res.type = "setclients";
		res.data.cmd = "setclients";
	} else {
//		res.type = "setcontroler";
		res.data.cmd = "setcontroler";
	}
	response(ws,res);
}

function wsSetInterval(ws){
	clearInterval(ws.loop);
	if (!ws.userNoSet) ws.userNoSet = 0;
	ws.loop = setInterval(function() {
		if (ws.userNoSet >= 3) ws.close();
			
		clearInterval(ws.nopong);
		ws.nopong = setInterval(function (){
			if (ws) {
				if ( ws.userAccount && ws.userType && ws.userId ) {
					if (accounts[ws.userAccount][ws.userType][ws.userId].status != "offline"){
						accounts[ws.userAccount][ws.userType][ws.userId].status="offline";
						infoSocketState(ws);
					}
					ws.close();
				} else {
					ws.userNoSet++;
					console.log("user no set", ws.userNoSet);
				}
			}
			clearInterval(ws.nopong);
			clearInterval(ws.loop);
		},4500);
		ws.ping("ping", function(){
//			console.log("Recibe pong",ws.userId);
			clearInterval(ws.nopong);
			if ( ws.userAccount && ws.userType && ws.userId ) {
				if (accounts[ws.userAccount][ws.userType][ws.userId].status != "online"){
					accounts[ws.userAccount][ws.userType][ws.userId].status="online";
					infoSocketState(ws);
				}
			} else {
				ws.userNoSet++;
				console.log("user no set", ws.userNoSet);
			}
		});
	}, 5000 );
}
function process(request, socket, body){
	if (WebSocket.isWebSocket(request)) {
		var ws = new WebSocket(request, socket, body);
console.log(request)
//		var ws = new EventSource(request, response);
//		wsSetInterval(ws);
		ws.on('message', function (event){
//			console.log(event.data);
			clearInterval(ws.nopong);
			try {
				var json = JSON.parse(event.data);
			} catch (e) {
				console.log('This doesn\'t look like a valid JSON: ', event.data);
				return;
			}
			if (json==null) {
				console.log('Empty message event.data is null', event.data);
				return;
			}
//			console.log(json);
			var res = null;
/*
			switch (json.type) {
				default:
					if ( typeof funciones[json.type] === "function") {
						res = funciones[json.type](ws,json);
					} else {
						console.log('Hmm..., I\'ve never seen JSON like this: ', json);
					}
				break;
			}
*/
			switch (json.cmd) {
				default:
					if ( typeof funciones[json.cmd] === "function") {
						console.log("Recibe",json.cmd);
						res = funciones[json.cmd](ws,json);
					} else {
						console.log('Hmm..., I\'ve never seen JSON like this: ', json);
					}
				break;
			}
		});
		ws.on('open', function(event) {
			console.log("open");
			console.log("sec-websocket-key",request.headers["sec-websocket-key"]);
			var sec = Math.floor(new Date().getTime() / 1000);
			var usec = ((new Date().getTime())%1000)*1000;
			res = {
//				type: "setTime",
				cmd: "setTime",
				sec: sec,
				usec: usec
			}
			jsonSend(ws,res);
			
		});
		ws.on('error', function(event) {
			if (ws.usersAccount && ws.userType && ws.userId)
				console.log("Error en ",accounts[ws.userAccount][ws.userType][ws.userId].name)
			else console.log("Error ")
		});
		ws.on('close', function(event) {
			if (ws.userAccount && ws.userType && ws.userId){
				console.log('close',accounts[ws.userAccount][ws.userType][ws.userId].name, event.code, event.reason);
				accounts[ws.userAccount][ws.userType][ws.userId].status="offline";
				res = {dst:{},data:{}};
				res.data.data = {[ws.userType]:{[ws.userId]:accounts[ws.userAccount][ws.userType][ws.userId]}};
				res.dst.account = ws.userAccount;
				res.dst.group = "clients";
				if ( ws.userType == "clients" ){
//					res.type = "setclients";
					res.data.cmd = "setclients";
//					res.data = {clients:{[ws.userId]:accounts[ws.userAccount].clients[ws.userId]}};
				} else {
//					res.type = "setcontroler";
					res.data.cmd = "setcontroler";
//					res.data = {controler:{[ws.userId]:accounts[ws.userAccount].controler[ws.userId]}};
				}
				response(ws,res);
				clearInterval(ws.loop);
				clearInterval(ws.nopong);
				ws = null;
			} else {
				console.log("close", event.code, event.reason);
			}
		});
	}
}

//module.exports.clients = clients;
module.exports.ws_process = process;
