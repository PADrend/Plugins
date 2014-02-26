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

static HTTP = new Namespace;

HTTP.STATUS_OK @(const) := 'HTTP/1.1 200 OK';
HTTP.STATUS_NOT_FOUND @(const) := 'HTTP/1.1 404 Not Found';
HTTP.STATUS_METHOD_NOT_ALLOWED @(const) := 'HTTP/1.1 405 Method Not Allowed';
HTTP.STATUS_SERVER_ERROR @(const) := 'HTTP/1.1 500 Internal Server Error';
HTTP.STATUS_UNAUTHORIZED @(const) := 'HTTP/1.1 401 Unauthorized';

HTTP.HEADER_CONNECTION @(const) := 'Connection';
HTTP.HEADER_CONNECTION_CLOSE @(const) := 'close';
HTTP.HEADER_CONNECTION_KEEP_ALIVE @(const) := 'keep-alive';
HTTP.HEADER_CONTENT_LANGUAGE @(const) := 'Content-Language-Type';
HTTP.HEADER_CONTENT_TYPE @(const) := 'Content-Type';
HTTP.HEADER_SERVER @(const) := 'Server';

HTTP.fileEndingContentTypes := {
	'html' : 'text/html',
	'txt' : 'text/plain',
	'jpg' : 'image/jpeg',
	'jpeg' : 'image/jpeg',
	'png' : 'image/png',
	'gif' : 'image/gif',
	'css' : 'text/css',
	'js' : 'application/x-javascript;charset=utf-8',
};
HTTP.getHTTPContentType := fn(filename){
	var contentType =  HTTP.fileEndingContentTypes[(new Util.FileName(filename)).getEnding()];
	return contentType ? contentType : 'application/octet-stream';
};

//! "/H%C3%A4lloW%C3%B6rld" --> "HälloWörld"
HTTP.decodeURIString := fn(encodedURI){
	var decodedURI = "";
	var lastPos = 0;
	while(true){
		var pos = encodedURI.find('%',lastPos);
		if(!pos){
			decodedURI += encodedURI.substr(lastPos);
			break;
		}else{
			decodedURI += encodedURI.substr(lastPos,pos-lastPos);
			var bytes = [];
			while(encodedURI[pos]=='%'){
				var b = 0+("0x"+encodedURI.substr(pos+1,2));
				bytes += b;
				pos += 3;
			}
			decodedURI += String._createFromByteArray(bytes) ;
			lastPos = pos;
		}
	}
	return decodedURI;
};

HTTP.Message := new Type;
{
	var T = HTTP.Message;
	T._printableName @(override) ::= $Message;
	T.content := void;
	T.type := "";

	T.header @(init) := [{
			HTTP.HEADER_CONNECTION : "close",
			"Access-Control-Allow-Headers" : "x-requested-with, origin, x-csrftoken, x-csrf-token, content-type, accept",
			"Allow" : "GET, OPTIONS, HEAD", // POST
//			"Access-Control-Allow-Methods" : "GET, OPTIONS, HEAD", // POST
			"Access-Control-Allow-Origin" : "*",
			"Access-Control-Max-Age" : "1000",
			HTTP.HEADER_SERVER : "PADrend_1.0",
			HTTP.HEADER_CONTENT_TYPE : "text/plain"
		}] => fn(defaultHeader){	return defaultHeader.clone();	};

	T._constructor ::= fn(String _type = HTTP.STATUS_OK, [Map,void] headerOptions = void, [String,void] _content = void){
		this.type = _type;
		if(headerOptions)
			this.header.merge(headerOptions);
		if(_content){
			this.content = _content;
			header['Content-Length'] = content.dataSize().toIntStr();
		}else{
			this.content = "";
		}
	};
	T.createString ::= fn(){
		var s = this.type+"\n";
		foreach(this.header as var key,var value)
			s+=key+": "+value+"\n";
		return s+"\n"+this.content;
	};
}

return HTTP;
