/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


var T = new Type;
T.port @(private) := void;
T.onClose @(init) := Std.MultiProcedure;			// fn() cleared after server stopped
T.onExecute @(init) := Std.MultiProcedure; 			// fn() cleared after server stopped
T.onStart @(init) := Std.MultiProcedure;  			// fn(tcpServer,udpSocket) cleared after server stopped
T.onNewClientStub @(init) := Std.MultiProcedure; 	// fn(connection) cleared after server stopped
T.connectedClients @(init) := Array;

T._constructor ::=  fn(Number _port){
	this.port = _port;
};

T.close ::= fn(){
	this.onClose();
	this.onClose.clear();
	this.onNewClientStub.clear();
	this.onExecute.clear();
};
T.getPort ::= fn(){		return port;	};
T.getConnectedClients ::= fn(){		return connectedClients;	};

T.start ::= fn(){
	// close before ending the application
	var exitHandler = this->this.close;
	Util.registerExtension('PADrend_Exit', exitHandler);
	this.onClose += [exitHandler] => fn(exitHandler){	Util.removeExtension('PADrend_Exit', exitHandler);	};


					
	var services = new (Std.module('LibUtilExt/Network/ServiceBundle'));
	this.onClose += services->services.close;

	// tcp network server
	var tcpServer;
	try{
		tcpServer = new (Std.module('LibUtilExt/Network/ExtTCPServer'))(this.getPort());
		services += tcpServer;

		static ExtTCPConnection = Std.module('LibUtilExt/Network/ExtTCPConnection');
		tcpServer.onConnect += [services] => this->fn(services, ExtTCPConnection newConnection){
			// setup multi channel connection
			//! \see LibUtilExt/Network/MultiChannelTCPConnectionTrait
			Std.Traits.addTrait(newConnection, Std.module('LibUtilExt/Network/MultiChannelTCPConnectionTrait')); 

			var clientStub = new (module('./ClientStub'))(newConnection);
			this.connectedClients += clientStub;
			clientStub.onClose += [this.connectedClients,clientStub] =>  fn(connectedClients,client){ connectedClients.removeValue(client);	};
			
			services += clientStub;
			PADrend.message("[InstanceSyncing] New client.");

			this.onNewClientStub(clientStub);
		};

	}catch(e){
		this.close();
		throw e;
	}

	// server udp socket
	var udpSocket;
	try{
		udpSocket = new (Std.module('LibUtilExt/Network/ExtUDPSocket'))(this.getPort());
		services += udpSocket;

		// automatically respond to UDP requests
		//!		\see LibUtilExt/Network/UDPAutoTargetResponderTrait
		Std.Traits.addTrait(udpSocket, Std.module('LibUtilExt/Network/UDPAutoTargetResponderTrait'));
		
		// setup multi channel connection over UDP
		//!		\see LibUtilExt/Network/UDPMultiChannelSenderTrait
		Std.Traits.addTrait(udpSocket, Std.module('LibUtilExt/Network/UDPMultiChannelSenderTrait'));
	}catch(e){
		this.close();
		throw e;
	}

	this.onStart(tcpServer,udpSocket);
	this.onStart.clear();
	
	Util.registerExtension('PADrend_AfterFrame',[tcpServer,services,onExecute] => this->fn(tcpServer,services,onExecute){
		var t = new Util.Timer;
		while(tcpServer.isOpen()){
			if(t.getMilliseconds()<0.8333){		// limit updates to 120hz
				yield;
				continue;
			} 
			t.reset();
			onExecute();

			services.execute();	// execute network tasks
			yield;
		}
		this.close();
		return $REMOVE;
	},Extension.LOW_PRIORITY);
};

return T;
