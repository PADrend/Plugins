/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! [InstanceSyncing.Client] Connects to a InstanceSyncing.Server. It offers a MultiChannelTCPConnection and MultiChannelUDP-communication.
	To add features (like SyncVars or RCP-bindings), extend the .onStart(mcTCPConnection,mcUDPSocket) after creating a client instance.
	The expendable .onClose() is called when the connection is closed,
	Example:
	
		var client = new (Std.module('InstanceSyncing/Client'));
		client.onStart += fn(mcTCPConnection,mcUDPSocket){
			//! \see Util.Network.MultiChannel_RemoteProcedureServer_Trait
			Std.Traits.addTrait(mcUDPSocket, Util.Network.MultiChannel_RemoteProcedureServer_Trait,0x0202,outln);
		};
		client.connect("localhost",2000);
		
	\note Depends on high-level PADrend features.
*/
var T =  new Type;

T.serverPort @(private) := void;
T.serverName @(private) := void;
T.services := void;

T._constructor ::= fn(String _serverName,Number _serverPort){
	this.serverName = _serverName;
	this.serverPort = _serverPort;
};

T.onStart @(init) := MultiProcedure;	// fn(mcTCPConnection,mcUDPSocket) cleared after connecting
T.onClose @(init) := MultiProcedure;	// fn() cleared after closing

T.connect ::= fn(){
	var ServiceBundle = Std.module('LibUtilExt/Network/ServiceBundle');
	var ExtTCPConnection = Std.module('LibUtilExt/Network/ExtTCPConnection');
	var MultiChannelTCPConnectionTrait = Std.module('LibUtilExt/Network/MultiChannelTCPConnectionTrait');
	var ExtUDPSocket = Std.module('LibUtilExt/Network/ExtUDPSocket');
	var UDPAutoRegisterTrait = Std.module('LibUtilExt/Network/UDPAutoRegisterTrait');
	var UDPMultiChannelReceiverTrait = Std.module('LibUtilExt/Network/UDPMultiChannelReceiverTrait');

	// close before ending the application
	var exitHandler = this->this.close;
	Util.registerExtension('PADrend_Exit', exitHandler);
	this.onClose += [exitHandler] => fn(exitHandler){	removeExtension('PADrend_Exit', exitHandler);	};


	this.services = new ServiceBundle;
	this.onClose += services->services.close;

	// Multi channel TCP connection
	var mcTCPConnection;
	try{
		mcTCPConnection = ExtTCPConnection.connect(this.serverName,this.serverPort);
		services += mcTCPConnection;
		
		//! \see LibUtilExt/Network/MultiChannelTCPConnectionTrait	
		Std.Traits.addTrait(mcTCPConnection, MultiChannelTCPConnectionTrait);

	}catch(e){
		PADrend.message("Could not connect to "+this.serverName+":"+this.serverPort);
		this.close();
		throw e;
	}

	// Multi channel UDP "Connection"
	var udpSocket;
	try{
		udpSocket = new ExtUDPSocket;
		services += udpSocket;
		
		//! \see LibUtilExt/Network/UDPAutoRegisterTrait
		Std.Traits.addTrait(udpSocket, UDPAutoRegisterTrait, this.serverName, this.serverPort);

		//! \see LibUtilExt/Network/UDPMultiChannelReceiverTrait
		Std.Traits.addTrait(udpSocket, UDPMultiChannelReceiverTrait);
	}catch(e){
		PADrend.message("Could not open UDPSocket.");
		this.close();
		throw e;
	}

	this.onStart(mcTCPConnection,udpSocket);
	this.onStart.clear();

	Util.registerExtension('PADrend_AfterFrame',[mcTCPConnection] => this->fn(mcTCPConnection){
		while(mcTCPConnection.isOpen()){
			this.services.execute();
			yield;
		}
		this.close();
		return $REMOVE;
	},Extension.LOW_PRIORITY);

////// // this produces an EScript empty stack error when disconnecting
//////	Util.registerExtension('PADrend_AfterFrame',[mcTCPConnection] => this->fn(mcTCPConnection){
//////		while(mcTCPConnection.isOpen()){
//////			services.execute();
//////			yield;
//////		}
//////		InstanceSyncing.Client.close();
//////		return $REMOVE;
//////	},Extension.LOW_PRIORITY);


	PADrend.message("[InstanceSyncing] connected.");
};

T.close ::= fn(){
	this.onClose();
	this.onClose.clear();
};
T.getServerPort ::= fn(){	return this.serverPort;	};
T.getServerName ::= fn(){	return this.serverName;	};

return T;
