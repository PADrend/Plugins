/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius JÃ¤hn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
//! Extensions for Util.Network

if(!GLOBALS.isSet($Network))
	GLOBALS.Network := Util.Network;

//----------------------------

//! \name NetworkService basics
//!	\{

/*! Marks an Object (or Type) as NetworkService.
	Assures the following interface:
		+ void close()
		+ Bool isOpen()
		+ void execute()	*/
{
	var t = new Std.Traits.GenericTrait('NetworkServiceTrait');
	
	t.onInit += fn(service){
		if(service---|>Type){
			if(!service.isSet($close))
				service.close ::= UserFunction.pleaseImplement;
			if(!service.isSet($isOpen))
				service.isOpen ::= UserFunction.pleaseImplement;
			if(!service.isSet($execute))
				service.execute ::= UserFunction.pleaseImplement;
		}else{
			if(!service.isSet($close))
				service.close := UserFunction.pleaseImplement;
			if(!service.isSet($isOpen))
				service.isOpen := UserFunction.pleaseImplement;
			if(!service.isSet($execute))
				service.execute := UserFunction.pleaseImplement;
		}
	};
	Std._registerModule('LibUtilExt/Network/NetworkServiceTrait',t);
	Util.Network.NetworkServiceTrait := t;
}

/*! A collection of NetworkServices.
	\see LibUtilExt/Network/NetworkServiceTrait	*/

{
	var T = new Type;
	Traits.addTrait(T,Traits.PrintableNameTrait,$ServiceBundle);						//! \see 	Traits.PrintableNameTrait
	
	T.services @(private,init) := Array;
	
	//!	Add network service
	T."+="				::= fn(c){	
		Traits.requireTrait(c, Std.require('LibUtilExt/Network/NetworkServiceTrait'));	//!	\see 	'LibUtilExt/Network/NetworkServiceTrait'
		this.services += c;	
	};
	//!	Remove network service
	T."-="				::= fn(c){	this.services.removeValue(c);	};

	//!	Return true iff empty
	T.empty				::=	fn(){	return this.services.empty();	};
	
	//! Allows foreach loops.
	T.getIterator		::=	fn(){	return this.services.getIterator();	};
	
	//! Calls close() on all services.
	T.close ::=	fn(){
		while(!services.empty()){
			var s = services.popBack();
			s.close();
		}
		return this;
	};
	
	/*! Execute all open services; all closed services are removed.
		This function should be called regularly (e.g. in the application's main event loop).	*/
	T.execute ::= fn(){
		var closedServices = [];
		foreach(this as var service){
			if(service.isOpen()){
				service.execute();
			}else{
				closedServices += service;
			}
		}
		foreach(closedServices as var s)
			this -= s;
	};
	Std._registerModule('LibUtilExt/Network/ServiceBundle',T);
	Util.Network.ServiceBundle := T;
}
//!	\}

//----------------------------

//! \name MultiChannel basics
//!	\{

/*! Marks an Object (or Type) as to be able to send data over a channel based connection.
	Assures the following interface:
	 + sendValue( channelNr, stringData )
*/
{
	var t = new Std.Traits.GenericTrait('MultiChannelSenderTrait');

	t.onInit += fn(obj){
		if(obj---|>Type){
			if(!obj.isSet($sendValue))
				obj.sendValue ::= UserFunction.pleaseImplement;
		}else{
			if(!obj.isSet($sendValue))
				obj.sendValue := UserFunction.pleaseImplement;
		}
	};
	Std._registerModule('LibUtilExt/Network/MultiChannelSenderTrait',t);
	Util.Network.MultiChannelSenderTrait := t;
}

/*! Marks an Object (or Type) as to be able to receive data using a channel handler.
	Assures the following interface:
	 + setChannelHandler( channelNr, channelListener )
*/
{
	var t = new Std.Traits.GenericTrait('MultiChannelReceiverTrait');

	t.onInit += fn(obj){
		if(obj---|>Type){
			if(!obj.isSet($setChannelHandler))
				obj.setChannelHandler ::= UserFunction.pleaseImplement;
		}else{
			if(!obj.isSet($setChannelHandler))
				obj.setChannelHandler := UserFunction.pleaseImplement;
		}
	};
	Std._registerModule('LibUtilExt/Network/MultiChannelReceiverTrait',t);
	Util.Network.MultiChannelReceiverTrait := t;
}

//----------------------------

//! \name MultiChannel traits
//!	\{

/*! Extends a multi channel connection to support ping (and pong) messages.
	\note requires the LibUtilExt/Network/MultiChannelReceiverTrait and the 'LibUtilExt/Network/MultiChannelSenderTrait'
	Adds the following methods:
	 + sendPing()
	 + Number|false getPongReceivedClock()	result is relative to clock()
	 + Number|false getPingReceivedClock()	result is relative to clock()
*/
{
	Util.Network.CHANNEL_ID_PING := 0x0101;

	var t = new Std.Traits.GenericTrait('MultiChannel_Ping_Trait');
	
	t.attributes.sendPing ::= fn(){
		this.sendValue(Util.Network.CHANNEL_ID_PING,"ping");													//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
	};
	t.attributes.lastPingReceiveClock @(private) := false;
	t.attributes.lastPongReceiveClock @(private) := false;
	t.attributes.getPongReceivedClock ::= fn(){	return lastPongReceiveClock;};
	t.attributes.getPingReceivedClock ::= fn(){	return lastPingReceiveClock;};

	t.onInit += fn(connection){
		Traits.requireTrait(connection, Std.require('LibUtilExt/Network/MultiChannelReceiverTrait'));	//!	\see	LibUtilExt/Network/MultiChannelReceiverTrait
		Traits.requireTrait(connection, Std.require('LibUtilExt/Network/MultiChannelSenderTrait'));		//!	\see	LibUtilExt/Network/MultiChannelSenderTrait

		//! \see MultiChannelReceiverTrait
		connection.setChannelHandler(Util.Network.CHANNEL_ID_PING,fn(data){
			if(data=="ping"){
				this.sendValue(Util.Network.CHANNEL_ID_PING,"pong");
				this.lastPingReceiveClock = clock();
//				out("(i)");
			}else if(data=="pong"){
				this.lastPongReceiveClock = clock();
				out("(pong)");
			}
		});
	};
	Std._registerModule('LibUtilExt/Network/MultiChannel_Ping_Trait',t);
	Util.Network.MultiChannel_Ping_Trait := t;
}

/*! Sets up a channel for RCP (client).
	\note requires the 'LibUtilExt/Network/MultiChannelSenderTrait' and the LibUtilExt/Network/NetworkServiceTrait
	\param uint16_t channelId				unique channel used for the data transfer 
	\param MultiFunction rpcFunction		A (empty) function that is set up as rcp-proxy
	\param Callable serialize				(optional) serialization function	*/
{
	var t = new Std.Traits.GenericTrait('MultiChannel_RemoteProcedureClient_Trait');
	t.allowMultipleUses();

	t.onInit += fn(connection,Number channelId, multiFun, serialize=fn(p){return toJSON(p,false);}){
		Traits.requireTrait(connection, Std.require('LibUtilExt/Network/MultiChannelSenderTrait'));		//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
		Traits.requireTrait(connection, Std.require('LibUtilExt/Network/NetworkServiceTrait'));			//!	\see	LibUtilExt/Network/NetworkServiceTrait
		Traits.requireTrait(multiFun,Traits.CallableTrait);												//!	\see	Traits.CallableTrait

		multiFun += [connection,channelId,serialize]=>fn(connection,channelId,serialize, p...){
			if(!connection.isOpen())																	//!	\see	LibUtilExt/Network/NetworkServiceTrait
				return $REMOVE;
			connection.sendValue(channelId,serialize(p) );
		};
	};
	Std._registerModule('LibUtilExt/Network/MultiChannel_RemoteProcedureClient_Trait',t);
	Util.Network.MultiChannel_RemoteProcedureClient_Trait := t;
}

/*! Sets up a channel for RCP (server).
	\note requires the LibUtilExt/Network/MultiChannelReceiverTrait
	\param uint16_t channelId				unique channel used for the data transfer 
	\param function							the function to be called
	\param Callable deserialize				(optional) deserialize function	*/
{
	var t = new Std.Traits.GenericTrait('MultiChannel_RemoteProcedureServer_Trait');
	t.allowMultipleUses();

	t.onInit += fn(connection,Number channelId, fun, deserialize=parseJSON){
		Traits.requireTrait(connection, Std.require('LibUtilExt/Network/MultiChannelReceiverTrait'));	//!	\see	LibUtilExt/Network/MultiChannelReceiverTrait
		Traits.requireTrait(fun,Traits.CallableTrait);													//!	\see	Traits.CallableTrait
		
		//!	\see LibUtilExt/Network/MultiChannelReceiverTrait
		connection.setChannelHandler(channelId, [fun,deserialize] => fn(fun,deserialize, data){
			fun(deserialize(data)...);
		});
	};
	Std._registerModule('LibUtilExt/Network/MultiChannel_RemoteProcedureServer_Trait',t);	
	Util.Network.MultiChannel_RemoteProcedureServer_Trait := t;
}


/*! Extends a multi channel connection to send the content and updates of a DataWrapperContainer.
	\note requires the LibUtilExt/Network/MultiChannelReceiverTrait
	\note requires the LibUtilExt/Network/MultiChannelSenderTrait
	\param uint16_t channelId				unique channel used for the data transfer 
	\param DataWrapperContainer syncVars	the synced values
	\param Callable serialize				(optional) serialization function	*/
{
	var t = new Std.Traits.GenericTrait('MultiChannel_SyncVarSender_Trait');
	t.allowMultipleUses();

	t.onInit += fn(connection,Number channelId, DataWrapperContainer syncVars,serialize=fn(p){return toJSON(p,false);}){
		Traits.requireTrait(connection, Std.require('LibUtilExt/Network/NetworkServiceTrait'));		//!	\see	LibUtilExt/Network/NetworkServiceTrait
		Traits.requireTrait(connection, Std.require('LibUtilExt/Network/MultiChannelSenderTrait'));	//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
		Traits.requireTrait(connection, Std.require('LibUtilExt/Network/MultiChannelReceiverTrait'));	//!	\see	LibUtilExt/Network/MultiChannelReceiverTrait
		Traits.requireTrait(serialize,Traits.CallableTrait);										//!	\see	Traits.CallableTrait
		
		var sender = [connection,channelId,serialize] => fn(connection,channelId,serialize, key,value){
			if(!connection.isOpen())																//!	\see	LibUtilExt/Network/NetworkServiceTrait
				return $REMOVE;
			connection.sendValue(channelId,key+"§"+serialize(value) );								//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
			outln("Send ["+channelId+"]" + key+" : "+serialize(value));
		};
		
		// wait for receiver to subscribe
		//! \see LibUtilExt/Network/MultiChannelReceiverTrait
		connection.setChannelHandler(channelId, [syncVars,sender] => fn(syncVars,sender, data){
			if(data!='subscribe'){
				Runtime.warn("MultiChannel_SyncVarSender_Trait received invalid data: '"+data+"'");
				return;
			}
			PADrend.message("Successfully subscribed! ");
			syncVars.onDataChanged += sender;

			// initial send
			foreach(syncVars.getValues() as var key,var value)
				sender(key,value);
			// return $REMOVE; // $REMOVE is ignored...
		});
	};
	Std._registerModule('LibUtilExt/Network/MultiChannel_SyncVarSender_Trait',t);
	Util.Network.MultiChannel_SyncVarSender_Trait := t;
}



/*! Extends a multi channel connection to receive the content and updates of a DataWrapperContainer.
	\note requires the LibUtilExt/Network/MultiChannelReceiverTrait
	\note requires the LibUtilExt/Network/MultiChannelSenderTrait
	\param uint16_t channelId				unique channel used for the data transfer 
	\param DataWrapperContainer syncVars	the synced values
	\param Callable deserialize				(optional) deserialize function	*/
{
	var t = new Std.Traits.GenericTrait('MultiChannel_SyncVarReceiver_Trait');
	t.allowMultipleUses();

	t.onInit += fn(connection,Number channelId, targetMap,deserialize=parseJSON){
		Traits.requireTrait(connection, Std.require('LibUtilExt/Network/MultiChannelReceiverTrait'));//!	\see	LibUtilExt/Network/MultiChannelReceiverTrait
		Traits.requireTrait(connection, Std.require('LibUtilExt/Network/MultiChannelSenderTrait'));	//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
		Traits.requireTrait(deserialize,Traits.CallableTrait);										//!	\see	Traits.CallableTrait
		
		//!	\see MultiChannelReceiverTrait
		connection.setChannelHandler(channelId,[channelId,targetMap,deserialize] => fn(channelId,targetMap,deserialize, data){
			var a = data.split("§",2);
			var key = a[0];
			var value = deserialize(a[1]);
			outln("Receive [",channelId,"] ",key," : ",value);
			targetMap.setValue(key,value,false);
		});
		connection.sendValue(channelId,'subscribe' );												//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
	};
	Std._registerModule('LibUtilExt/Network/MultiChannel_SyncVarReceiver_Trait',t);
	Util.Network.MultiChannel_SyncVarReceiver_Trait := t;
}
//!	\}

//----------------------------

//! \name TCP-based implementations
//!	\{

/*! A wrapper for a TCPConnection object (expendable with traits.)
	\see LibUtilExt/Network/NetworkServiceTrait	*/
{
	var T = new Type;
	Traits.addTrait(T,Traits.PrintableNameTrait,$ExtTCPConnection); 								//! \see		Traits.PrintableNameTrait
	Traits.addTrait(T, Std.require('LibUtilExt/Network/NetworkServiceTrait'));						//! \see		LibUtilExt/Network/NetworkServiceTrait
	
	T.connection @(private) := void;

	T._constructor ::= fn(Util.Network.TCPConnection c){
		this.connection = c;
	};
	//! (static) Factory
	T.connect ::= fn(host,port){
		var c =	Util.Network.TCPConnection.connect(host,port);
		if(!c)
			Runtime.exception("Could not connect to "+host+":"+port);
		return new this(c);
	};
	
	//!\see LibUtilExt/Network/NetworkServiceTrait
	T.close 		@(override) ::= fn(){		this.connection.close();	return this;	};

	//! ---o \see LibUtilExt/Network/NetworkServiceTrait
	T.execute		@(override) ::= fn(){};
	
	//! (internal) Access the wrapped connection.
	T.getConnection				::=	fn(){		return this.connection;	};
	
	//!\see LibUtilExt/Network/NetworkServiceTrait
	T.isOpen		@(override) ::= fn(){		return this.connection.isOpen();	};

	Std._registerModule('LibUtilExt/Network/ExtTCPConnection',T);	
	Util.Network.ExtTCPConnection := T;
}



/*! A wrapper for a TCPServer object (expendable with traits.)
	- calls onConnect(new connection) when a new connection is available.
	\see LibUtilExt/Network/NetworkServiceTrait	*/
{
	var T = new Type;
	Traits.addTrait(T,Traits.PrintableNameTrait,$ExtTCPServer); 								//!	\see 	Traits.PrintableNameTrait
	Traits.addTrait(T,Std.require('LibUtilExt/Network/NetworkServiceTrait'));					//! \see	LibUtilExt/Network/NetworkServiceTrait
	
	T.server @(private) := void;
	T.onConnect @(init,public) := MultiProcedure;
	
	T._constructor ::= fn(Number port){
		this.server = Util.Network.TCPServer.create(port);
		if(!this.server)
			Runtime.exception("Could not create tcpServer on port "+port);
	};

	//!\see LibUtilExt/Network/NetworkServiceTrait
	T.close 	@(override) ::= fn(){	this.server.close();	return this;	};
	//!\see LibUtilExt/Network/NetworkServiceTrait
	T.isOpen	@(override) ::= fn(){	return this.server.isOpen();	};
	
	static ExtTCPConnection = Std.require('LibUtilExt/Network/ExtTCPConnection');
	//!\see LibUtilExt/Network/NetworkServiceTrait
	T.execute	@(override) ::= fn(){
		if(this.isOpen()){
			while(var newConnections = this.server.getIncomingConnection()){
				var extConnection = new ExtTCPConnection(newConnections);
				this.onConnect(extConnection);
			}
		}
	};
	Std._registerModule('LibUtilExt/Network/ExtTCPServer',T);
	Util.Network.ExtTCPServer := T;
}


/*!	Extends an ExtTCPConnection to support communication using multiple channels.
	\note Internally uses a Util.Network.DataConnection.
	\note Overrides the connection's execute() method \see NetworkServiceTrait
	\note adds the MultiChannelSenderTrait-interface
	\note adds the MultiChannelReceiverTrait-interface
	\note The internal Util.Network.TCPConnection object should NOT be accessed if adding this trait.
	Implements the following methods:
	 + setChannelHandler( channelNr, callable )		\see 	LibUtilExt/Network/MultiChannelReceiverTrait
	 + sendValue( channelNr, stringData )    		\see 	LibUtilExt/Network/MultiChannelSenderTrait
*/
{
	var t = new Std.Traits.GenericTrait('MultiChannelTCPConnectionTrait');
	
	t.attributes.channelHandler @(init,private) := Map;
	
	//! \see LibUtilExt/Network/MultiChannelReceiverTrait
	t.attributes.setChannelHandler ::= fn(Number channel,listener){
		Traits.requireTrait(listener,Traits.CallableTrait);										//!	\see	Traits.CallableTrait
		channelHandler[channel] = listener;
	};
	
	//! \see LibUtilExt/Network/MultiChannelSenderTrait
	t.attributes.sendValue ::= fn(Number channel,String value){
		this.getConnection().sendValue(channel,value);											//! \see	LibUtilExt/Network/ExtTCPConnection
		return this;
	};
	//!\see LibUtilExt/Network/NetworkServiceTrait
	t.attributes.execute ::= fn(){
		while(var data = this.getConnection().receiveValue()){
			var handler = this.channelHandler[data.channelId];
			if(handler){
				(this->handler)(data.data);
			}else{
				outln("No handler for '",data.data,"'@",data.channelId);
			}
		}
//		this.sendString(toJSON(data,false));
//		return this;
	};
	static ExtTCPConnection = Std.require('LibUtilExt/Network/ExtTCPConnection');
	t.onInit += fn(ExtTCPConnection connection){
		Traits.addTrait(connection, Std.require('LibUtilExt/Network/MultiChannelReceiverTrait'));	//!	\see 	LibUtilExt/Network/MultiChannelReceiverTrait
		Traits.addTrait(connection, Std.require('LibUtilExt/Network/MultiChannelSenderTrait'));		//!	\see 	LibUtilExt/Network/MultiChannelSenderTrait
		
		// replace normal tcpConnection by DataConnection.
		//! \see LibUtilExt/Network/ExtTCPConnection
		(connection -> fn(){		this.connection = new Util.Network.DataConnection(this.connection);		})();
	};
	Std._registerModule('LibUtilExt/Network/MultiChannelTCPConnectionTrait',t);
	Util.Network.MultiChannelTCPConnectionTrait := t;	
}
//!	\}

//----------------------------

//! \name UDP implementation
//!	\{

/*! A wrapper for an UDPSocket object (expendable with traits.)
	\see LibUtilExt/Network/NetworkServiceTrait	*/
{
	var T = new Type;
	Traits.addTrait(T,Traits.PrintableNameTrait,$ExtUDPSocket); 								//!	\see Traits.PrintableNameTrait
	Traits.addTrait(T,Std.require('LibUtilExt/Network/NetworkServiceTrait'));					//!\see LibUtilExt/Network/NetworkServiceTrait
	
	T.socket @(private) := void;
	T.onDataReceived @(init) := MultiProcedure;
	T.onExecute @(init) := MultiProcedure;

	T._constructor ::= fn(p...){
		this.socket = Util.Network.createUDPNetworkSocket(p...);
		if(!this.socket)
			Runtime.exception("Could not create UDP Socket: "+p.implode(","));
		this.socket.open(); // ???? why is this necessary
		if(!this.socket.isOpen())
			Runtime.exception("Could not create UDP Socket: "+p.implode(","));
	};
	
	//!\see LibUtilExt/Network/NetworkServiceTrait
	T.close 		@(override) ::= fn(){		this.socket.close();	return this;	};

	//! ---o \see LibUtilExt/Network/NetworkServiceTrait
	T.execute		@(override) ::= fn(){
		while(var data = this.socket.receive())
			this.onDataReceived(data);
		this.onExecute();
		return this;
	};
	
	//! (internal) Access the wrapped socket.
	T.getSocket					::=	fn(){		return this.socket;	};
	
	//!\see LibUtilExt/Network/NetworkServiceTrait
	T.isOpen		@(override) ::= fn(){		return this.socket.isOpen();	};
	
	
	T.sendString				::= fn(p...){	return this.socket.sendString(p...);	};
	T.addTarget					::= fn(p...){	this.socket.addTarget(p...); return this;	};
	T.removeTarget				::= fn(p...){	this.socket.removeTarget(p...); return this;	};
	
	Std._registerModule('LibUtilExt/Network/ExtUDPSocket',T);
	Util.Network.ExtUDPSocket := T;
}

/*!	Extends an ExtUDPSocket to support automatically registering targets.
	If a request packet is received from an address, the sender is added to the set of targets for a while.
	\param Number duration		(optional) time in seconds after which an idle target is removed.
*/
{
	var t = new Std.Traits.GenericTrait('UDPAutoTargetResponderTrait');
	
	t.attributes.targets @(init,private) := Map; // ip:port -> [ip,target,timeout]
	t.attributes.duration @(private) := void;
	t.attributes.timeToCheck @(private) := 0;
	
	static ExtUDPSocket = Std.require('LibUtilExt/Network/ExtUDPSocket');
	t.onInit += fn(ExtUDPSocket socket, Number duration=10){
		(socket->fn(duration){
			this.onExecute += this->fn(){
				var t = clock();
				if(t>this.timeToCheck){
					foreach(targets as var key,var tArr){
						if(tArr && t>tArr[2]){
							outln("UDP remove target:",key);
							this.removeTarget(tArr[0],tArr[1]);
							targets[key]=void;
						}
					}
					this.timeToCheck = t+1;
				}
			};
		
			this.duration = duration;
			this.onDataReceived += this->fn(data){
				var key = ""+data.host+":"+data.port;
				 if(!targets[key]){
					this.addTarget(data.host,data.port);
					print_r("New UDP Target:",data._getAttributes());
				 }
				 targets[key] = [data.host,data.port,clock()+this.duration];
			};
		
		})(duration);
	};
	Std._registerModule('LibUtilExt/Network/UDPAutoTargetResponderTrait',t);
	Util.Network.UDPAutoTargetResponderTrait := t;
}

/*!	Extends an ExtUDPSocket to periodically register at a remote socket having an UDPAutoTargetResponderTrait.
	\param targetHost			host name or ip
	\param uint16_t targetPort
	\param Number duration		(optional) time in seconds after which the registration is refreshed
*/
{
	var t = new Std.Traits.GenericTrait('UDPAutoRegisterTrait');
	
	t.attributes.timeToRegister @(private) := 0;
	
	static ExtUDPSocket = Std.require('LibUtilExt/Network/ExtUDPSocket');
	t.onInit += fn(ExtUDPSocket socket, targetHost, Number targetPort, Number duration=1){
		socket.addTarget(targetHost,targetPort);
		(socket->fn(duration){
		
			this.onExecute += [duration]=> this->fn(duration){
				var t = clock();
				if(t>this.timeToRegister){
					this.sendString("!");
					this.timeToRegister = t+duration;
				}
			};
	
		})(duration);
	};
	Std._registerModule('LibUtilExt/Network/UDPAutoRegisterTrait',t);	
	Util.Network.UDPAutoRegisterTrait := t;
}

/*! MultiChannelSenderTrait implementation for ExtUDPSockets.
	\see LibUtilExt/Network/MultiChannelSenderTrait	*/
{
	var t = new Std.Traits.GenericTrait('UDPMultiChannelSenderTrait');

	//! \see LibUtilExt/Network/MultiChannelSenderTrait
	t.attributes.sendValue ::= fn(Number channel,String strData){
		this.sendString(""+channel+":"+strData);
		return this;
	};
	static ExtUDPSocket = Std.require('LibUtilExt/Network/ExtUDPSocket');
	t.onInit += fn(ExtUDPSocket socket){
		Traits.addTrait(socket, Std.require('LibUtilExt/Network/MultiChannelSenderTrait'));			//!	\see	LibUtilExt/Network/MultiChannelSenderTrait
	};
	Std._registerModule('LibUtilExt/Network/UDPMultiChannelSenderTrait',t);
	Util.Network.UDPMultiChannelSenderTrait := t;		
}

/*! MultiChannelReceiverTrait implementation for ExtUDPSockets.
	\see LibUtilExt/Network/MultiChannelReceiverTrait	*/
{
	var t = new Std.Traits.GenericTrait('UDPMultiChannelReceiverTrait');

	t.attributes.channelHandler @(private,init) := Map;
	
	//! \see LibUtilExt/Network/MultiChannelReceiverTrait
	t.attributes.setChannelHandler ::= fn(Number channel,listener){
		Traits.requireTrait(listener,Traits.CallableTrait);
		this.channelHandler[channel] = listener;
		return this;
	};
	static ExtUDPSocket = Std.require('LibUtilExt/Network/ExtUDPSocket');
	t.onInit += fn(ExtUDPSocket socket){
		Traits.addTrait(socket, Std.require('LibUtilExt/Network/MultiChannelReceiverTrait'));		//!	\see	LibUtilExt/Network/MultiChannelReceiverTrait
		socket.onDataReceived += fn(data){
			var parts = data.data.split(":",2);
			if(parts.count()==2){
				var handler = this.channelHandler[parts[0]];
				if(handler)
					handler(parts[1]);
			}
		};
	};
	
	Std._registerModule('LibUtilExt/Network/UDPMultiChannelReceiverTrait',t);
	Util.Network.UDPMultiChannelReceiverTrait := t;
}

//!	\}

//------------------------------------------------

