/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! Simple usage example: 
	\code
		static HTTP = Std.module( 'LibUtilExt/Network/HTTP' );
		static HTTPConnectionTrait = Std.module( 'LibUtilExt/Network/HTTPConnectionTrait' );

		static isAllowed =  fn( String authLine, String method, String query){
			var parts = authLine.split(" ");
			if(parts[1]=='Basic'){
				var userAndPass = Util.decodeString_base64(parts[2]).split(":");
				return userAndPass[0] == 'Hubert' && userAndPass[1] == "1234";
			}
			return false;
		};
		static handleGETRequest = fn(Array queryPath,Map queryParameters){
			var filePath = queryPath.implode("/"); //! \todo important!! Restric access to safe folders!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

			if(filePath && IO.isFile(filePath)){
				var msg = new HTTP.Message( HTTP.STATUS_OK,{
						HTTP.HEADER_CONNECTION : HTTP.HEADER_CONNECTION_KEEP_ALIVE,
						HTTP.HEADER_CONTENT_TYPE : HTTP.getHTTPContentType(filePath)
					}, "[This is the content of file "+filePath+"]" );
				outln("Sending file: '",filePath,"'");
				return [msg,true];
			}
			outln("File not found: '",queryPath.implode("/"),"'");
			return [new HTTP.Message( HTTP.STATUS_NOT_FOUND,void,"File not found!" ),false];
		};

		var services = new (Std.module('LibUtilExt/Network/ServiceBundle'));

		var tcpServer;
		try{

			tcpServer = new (Std.module('LibUtilExt/Network/ExtTCPServer'))( 8081 );
			services += tcpServer;

			static ExtTCPConnection = Std.module('LibUtilExt/Network/ExtTCPConnection');
			tcpServer.onConnect += [services] => fn(services, ExtTCPConnection newConnection){
				//! \see HTTPConnectionTrait
				Std.Traits.addTrait(newConnection, );
				
				newConnection.isAllowed @(override) := isAllowed; //! \see HTTPConnectionTrait
				newConnection.handleGETRequest @(override) := handleGETRequest; //! \see HTTPConnectionTrait
				
				services += newConnection;
				outln("[HTTP] New client.");
			};
		}catch(e){
			services.close();
			throw e;
		}
	\endcode
*/



static HTTP = Std.module( 'LibUtilExt/Network/HTTP' );

var t = new Traits.GenericTrait;

t.attributes.lastActiveClock := void;

//! ---o Override with own implementation! 
t.attributes.handleGETRequest := fn(Array queryPath,Map queryParameters){
	var msg = new HTTP.Message( 
		HTTP.STATUS_OK,{
			HTTP.HEADER_CONNECTION : HTTP.HEADER_CONNECTION_KEEP_ALIVE,
			HTTP.HEADER_CONTENT_TYPE : 'text/plain;charset=utf-8'
		}, "PADrend over HTTP. Its working!\n"+toJSON(queryPath)+"\n"+toJSON(queryParameters) );
	print_r(queryPath);
	print_r(queryParameters);
	return [msg,false];
};


//! ---o Override with own implementation! 
t.attributes.isAllowed := fn( String authLine, String method, String query){
	outln(__FILE__,":",__LINE__,": No access!");
	return false;
};

t.attributes.handleHTTPRequest @(private) := fn(method,queryString){ // -> [msg, keepConnection]
	if(method == "OPTIONS"){
		return[ new HTTP.Message( HTTP.STATUS_OK,{HTTP.HEADER_CONNECTION : HTTP.HEADER_CONNECTION_KEEP_ALIVE}), true];
	}else if(method == "GET"){
		var queryPath;
		var queryParameters = new Map;
		
		var p = queryString.split("?");	// e.g. /rpc/someRPCFunction?p=1&p=2 -> [ "/rpc/someRPCFunction" , "p=1&p=2"]
		queryPath = p[0].split("/"); // e.g. /rpc/someRPCFunction -> [ "","rpc","someRPCFunction"]
		queryPath.popFront(); // remove empty first entry
		if(p[1]){ // has queryParameters
			foreach(p[1].split('&') as var paramStr){
				var paramParts = paramStr.split('=');
				var key = paramParts[0];
				var value = paramParts.count()>1 ? paramParts[1] : void;
				if(queryParameters[key]){
					queryParameters[key] += value ;
				}else{
					queryParameters[key] = [value];
				}
			}
		}
		return this.handleGETRequest( queryPath, queryParameters );
	}else{
		outln("Invalid request method:",method);
		return [new HTTP.Message( HTTP.STATUS_METHOD_NOT_ALLOWED,void,"Invalid request method:"+method ) ,false ];
	}
};

t.attributes.execute := fn(){
	var request = this.getConnection().receiveString('\n'); // e.g. GET /files/foo.html HTTP/1.1
	if(!request){
		if( this.lastActiveClock && clock()-this.lastActiveClock >  10.0){
			outln("Timeout.");
			this.close();
		}
		return;
	}
	this.lastActiveClock = clock();
	request = request.split(" ");
	print_r(request);

	var rqHeader = [];
	var authLine = "";
	while(true){
		var line = this.getConnection().receiveString('\n');
		if(!line)
			break;
		if(line.beginsWith("Authorization:")){
			authLine = line;
		}
		rqHeader+=line;
	}
	var msg;
	var keepConnection = false;
	var method = request[0];
	var query = HTTP.decodeURIString( request[1] ); //! unescape %a3% special characters

	// check authorization
	var allowed = this.isAllowed( authLine, method, query);
	try{
		if(allowed){
			var result = this.handleHTTPRequest(method,query);
			msg = result[0];
			keepConnection = result[1];
		}else{
			msg = new HTTP.Message( HTTP.STATUS_UNAUTHORIZED,{
				HTTP.HEADER_CONNECTION : HTTP.HEADER_CONNECTION_CLOSE,
				HTTP.HEADER_CONTENT_TYPE : 'text/plain;charset=utf-8',
				'WWW-Authenticate' : 'Basic realm="PADrend"',
			}, "Wrong username or password." );
			keepConnection = false;
		}
	}catch(e){
		Runtime.warn(e);
		msg = new HTTP.Message( HTTP.STATUS_SERVER_ERROR,void,"Internal server error." );
	}

	if(msg)
		this.getConnection().sendString( msg.createString() );
	if(!keepConnection || !msg)
		this.close();
};

static ExtTCPConnection = Std.module('LibUtilExt/Network/ExtTCPConnection');
t.onInit += fn(ExtTCPConnection connection){};


return t;
