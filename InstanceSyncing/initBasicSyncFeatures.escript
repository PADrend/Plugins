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

// ------------------
/*! Per client sync vars feature
	The syncVars are initially set from the client side, but may be changed from 
	the server side.
	\note adds a .syncVars DataWrapperContainer to the ClientStub on the server side and to the Client on client side.
*/
static ClientStub = module('./ClientStub');

//! \see [ext:InstanceSyncing_AddServerFeatures]
Util.registerExtension('InstanceSyncing_AddServerFeatures', fn(server){
	server.onNewClientStub += fn(ClientStub clientStub){
	
		clientStub.syncVars := new DataWrapperContainer;
		//! \see LibUtilExt/Network/MultiChannel_SyncVarReceiver_Trait
		Std.Traits.addTrait(clientStub.getMCConnection(), Std.module('LibUtilExt/Network/MultiChannel_SyncVarReceiver_Trait'), 
							0x0205, clientStub.syncVars, PADrend.deserialize);
							
		// if the server changes a variable, send it to the client
		var sendUpdatesToClient = new MultiProcedure;
		//! \see LibUtilExt/Network/MultiChannel_RemoteProcedureClient_Trait
		Std.Traits.addTrait(clientStub.getMCConnection(), Std.module('LibUtilExt/Network/MultiChannel_RemoteProcedureClient_Trait'),
							0x0206,sendUpdatesToClient, PADrend.serialize); 
		clientStub.syncVars.onDataChanged += sendUpdatesToClient;
		clientStub.syncVars.onDataChanged += [sendUpdatesToClient] => fn(sendUpdatesToClient,key,value){
			if(void!==value)
				sendUpdatesToClient(key,value);
		};
	};
},Extension.HIGH_PRIORITY);

//! \see [ext:InstanceSyncing_AddClientFeatures]
Util.registerExtension('InstanceSyncing_AddClientFeatures', fn(client){
	client.syncVars := new DataWrapperContainer;

	client.onStart += fn(mcTCPConnection,mcUDPSocket){
		// send client side data
		//! \see LibUtilExt/Network/MultiChannel_SyncVarSender_Trait
		Std.Traits.addTrait(mcTCPConnection, Std.module('LibUtilExt/Network/MultiChannel_SyncVarSender_Trait'),
							0x0205, this.syncVars, PADrend.serialize);
		
		// receive updates from the server
		//! \see LibUtilExt/Network/MultiChannel_RemoteProcedureServer_Trait
		Std.Traits.addTrait(mcTCPConnection, Std.module('LibUtilExt/Network/MultiChannel_RemoteProcedureServer_Trait'),
							0x0206, [this.syncVars] => fn(syncVars, key,value){
			if(void!==value && value!==syncVars[key]){
				syncVars[key] = value;
				outln("Update received: ",key," : ",value);
			}
		},PADrend.deserialize);
	};
},Extension.HIGH_PRIORITY);


// ---------------------------------------

// ------------------
// auto connect/create feature
{
	static AutoConnect = new Namespace;

	static activeComponent;

	static autoCreateServer = Std.DataWrapper.createFromConfig(systemConfig,'MultiView.autoCreateServer',false); 
	autoCreateServer.onDataChanged += fn(enabled){
		if(enabled){
			@(once) PADrend.planTask(2.0,fn(){
				if(autoCreateServer()){
					if(!activeComponent)
						Util.requirePlugin('InstanceSyncing').createServer(Util.requirePlugin('InstanceSyncing').serverPort());
					return 2.0;
				}
			});
		}
	};
	autoCreateServer.forceRefresh();

	// register a running server as active component
	//! \see [ext:InstanceSyncing_AddServerFeatures]
	Util.registerExtension('InstanceSyncing_AddServerFeatures', fn(server){
		server.onStart += fn(tcpServer,udpSocket){		activeComponent = this;	};
		server.onClose += fn(){		activeComponent = void;	};
	});

	static autoConnectClient = Std.DataWrapper.createFromConfig(systemConfig,'MultiView.autoConnectClient',false); 
	autoConnectClient.onDataChanged += fn(enabled){
		if(enabled){
			@(once)	PADrend.planTask(1.0,fn(){
				if(autoConnectClient()){
					if(!activeComponent){
						var InstanceSyncing = Util.requirePlugin('InstanceSyncing');
						try{
							InstanceSyncing.connectClient(InstanceSyncing.serverName(),InstanceSyncing.serverPort());
						}catch(e){
							Runtime.warn("[InstanceSyncing] Could not connect to server : "+InstanceSyncing.serverName()+":"+InstanceSyncing.serverPort());
						}
					}
					return 4.0;
				}
			});
		}
	};
	autoConnectClient.forceRefresh();

	// register a running server as active component
	//! \see [ext:InstanceSyncing_AddClientFeatures]
	Util.registerExtension('InstanceSyncing_AddClientFeatures', fn(client){
		client.onStart += fn(tcpServer,udpSocket){		activeComponent = this;	};
		client.onClose += fn(){	activeComponent = void;	};
	});

	// gui
	module.on('PADrend/gui', fn(gui){
		gui.register('InstanceSyncing_ServerCreateEntry.autoCreate', fn(){
			return {
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "auto",
				GUI.DATA_WRAPPER : autoCreateServer,
				GUI.WIDTH : 20,
				GUI.TOOLTIP : "auto create server"
			};

		});
		gui.register('InstanceSyncing_ClientConnectEntry.autoConnect', fn(){
			return {
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "auto",
				GUI.DATA_WRAPPER : autoConnectClient,
				GUI.WIDTH : 20,
				GUI.TOOLTIP : "auto connect client"
			};

		});
	});
}

// ------------------
// clientId feature
//! \note requires per client sync vars.
{

static clientId =Std.DataWrapper.createFromConfig(systemConfig,'MultiView.clientId',"Client"); // this instance's clientId.

//! \see [ext:InstanceSyncing_AddServerFeatures]
Util.registerExtension('InstanceSyncing_AddServerFeatures', fn(server){
	server.onNewClientStub += fn(ClientStub clientStub){
		assert(clientStub.syncVars);
		clientStub.syncVars.addDataWrapper('clientId',DataWrapper.createFromValue(void));
	};
});

//! \see [ext:InstanceSyncing_AddClientFeatures]
Util.registerExtension('InstanceSyncing_AddClientFeatures', fn(client){
	assert(client.syncVars);
	client.syncVars.addDataWrapper('clientId', clientId); // sync the global clientId using this client
});

module.on('PADrend/gui', fn(gui){
	static ClientStub = module('./ClientStub');
	gui.register('InstanceSyncing_ClientStubEntry.clientId', fn(ClientStub clientStub){
		return {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "ClientId",
			GUI.DATA_WRAPPER : clientStub.syncVars.getDataWrapper('clientId'),
			GUI.WIDTH : 150
		};

	});
	static Client = module('./Client');
	gui.register('InstanceSyncing_ClientEntry.clientId', fn(Client client){
		return {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "ClientId",
			GUI.DATA_WRAPPER : client.syncVars.getDataWrapper('clientId'),
			GUI.WIDTH : 150
		};

	});
});

}
// ------------------
// command broadcast feature
//! \see [ext:InstanceSyncing_AddServerFeatures]
Util.registerExtension('InstanceSyncing_AddServerFeatures', fn(server){
	// command broadcaster
	var broadcastCommand = new MultiProcedure;
	
	// while the server is running, intercept PADrend's commands 
	server.onStart += [broadcastCommand] => fn(broadcastCommand, tcpServer,udpSocket){
		static Command = Std.module('LibUtilExt/Command');
		Util.registerExtension('PADrend_CommandHandling_OnExecution',
			[tcpServer,broadcastCommand] => fn(tcpServer,broadcastCommand, command){
				if(!tcpServer.isOpen()){
					out("Command bye!");
					return $REMOVE;
				}
				if( (command.getFlags()&Command.FLAG_SEND_TO_SLAVES) != 0){
					var command2 = command.clone();
					command2.setFlags( (command.getFlags() | Command.FLAG_EXECUTE_LOCALLY)-Command.FLAG_SEND_TO_SLAVES);
					out("(send command)");
					broadcastCommand(PADrend.serialize(command2));
				}
			}
		);
	};
	// connect new clients to broadcastCommand-procedure
	server.onNewClientStub += [broadcastCommand] => fn(broadcastCommand, ClientStub clientStub){
		//! \see LibUtilExt/Network/MultiChannel_RemoteProcedureClient_Trait
		Std.Traits.addTrait(clientStub.getMCConnection(), Std.module('LibUtilExt/Network/MultiChannel_RemoteProcedureClient_Trait'),
						0x0202,broadcastCommand);
	};
});
//! \see [ext:InstanceSyncing_AddClientFeatures]
Util.registerExtension('InstanceSyncing_AddClientFeatures', fn(client){
	client.onStart += fn(mcTCPConnection,mcUDPSocket){
		//! \see LibUtilExt/Network/MultiChannel_RemoteProcedureServer_Trait
		Std.Traits.addTrait(mcTCPConnection, Std.module('LibUtilExt/Network/MultiChannel_RemoteProcedureServer_Trait'),0x0202,
					fn(commandStr){	
						var cmd = PADrend.deserialize(commandStr); 
						PADrend.executeCommand(cmd);	
					});
	};
});

// ------------------
// rpc suppport (based on PADrend/RemoteControl) 
// Util.requirePlugin('PADrend/RemoteControl').broadcast( rpcName, parameters... );
{
	
static CHANNEL_ID = 0x0208;

//! \see [ext:InstanceSyncing_AddServerFeatures]
Util.registerExtension('InstanceSyncing_AddServerFeatures', fn(server){
	
	// command broadcaster
	static broadcastCommand = new MultiProcedure;

	// while the server is running, intercept PADrend's rpc broadcasts 
	server.onStart += fn(tcpServer,udpSocket){
		static rpcPlugin = Util.requirePlugin('PADrend/RemoteControl');
		
		rpcPlugin.broadcast += [tcpServer] => fn(tcpServer, funName, parameters...){
			if(!tcpServer.isOpen()){
				out("RCP-Server feature bye!");
				return $REMOVE;
			}
//			broadcastCommand( toJSON(funNameAndParamters) );
		outln(" Sending RCP:",funName );
			broadcastCommand( funName,parameters... );
		};
	};
	// connect new clients to broadcastCommand-procedure
	server.onNewClientStub += fn(ClientStub clientStub){
		//! \see LibUtilExt/Network/MultiChannel_RemoteProcedureClient_Trait
		Std.Traits.addTrait(clientStub.getMCConnection(), Std.module('LibUtilExt/Network/MultiChannel_RemoteProcedureClient_Trait'),CHANNEL_ID,broadcastCommand);
	};
});
//! \see [ext:InstanceSyncing_AddClientFeatures]
Util.registerExtension('InstanceSyncing_AddClientFeatures', fn(client){
	client.onStart += fn(mcTCPConnection,mcUDPSocket){
		//! \see LibUtilExt/Network/MultiChannel_RemoteProcedureServer_Trait
		Std.Traits.addTrait(mcTCPConnection, Std.module('LibUtilExt/Network/MultiChannel_RemoteProcedureServer_Trait'),CHANNEL_ID,
					fn( funName, parameters... ){
						outln("Received rcp: ", funName,"(", toJSON(parameters,false),")");
						@(once) static rpcPlugin = Util.requirePlugin('PADrend/RemoteControl');
						rpcPlugin.callFunction(funName,parameters...);
					});
	};
});

}
// ------------------
// syncVarFeature
//! \see [ext:InstanceSyncing_AddServerFeatures]
Util.registerExtension('InstanceSyncing_AddServerFeatures', fn(server){
	server.onNewClientStub += fn(ClientStub clientStub){
		// connect to PADrend.syncVars
		//! \see LibUtilExt/Network/MultiChannel_SyncVarSender_Trait
		Std.Traits.addTrait(clientStub.getMCConnection(), Std.module('LibUtilExt/Network/MultiChannel_SyncVarSender_Trait'),
							0x0200,PADrend.syncVars,PADrend.serialize);
	};
});
//! \see [ext:InstanceSyncing_AddClientFeatures]
Util.registerExtension('InstanceSyncing_AddClientFeatures', fn(client){
	client.onStart += fn(mcTCPConnection,mcUDPSocket){
		//! \see LibUtilExt/Network/MultiChannel_SyncVarReceiver_Trait
		Std.Traits.addTrait(mcTCPConnection, Std.module('LibUtilExt/Network/MultiChannel_SyncVarReceiver_Trait'), 
							0x0200,PADrend.syncVars,PADrend.deserialize);
	};
});

// ------------------
// timeSyncFeature

//! \see [ext:InstanceSyncing_AddServerFeatures]
Util.registerExtension('InstanceSyncing_AddServerFeatures', fn(server){
	server.onStart += [server] => fn(server, tcpServer,udpSocket){
		var timeSyncServer = Util.Network.ClockSynchronizer.createServer(1+server.getPort());
		server.onClose += timeSyncServer->timeSyncServer.close;
	};
});

//! \see [ext:InstanceSyncing_AddClientFeatures]
Util.registerExtension('InstanceSyncing_AddClientFeatures', fn(client){
	client.onStart += [client] => fn(client, mcTCPConnection,mcUDPSocket){
		var restore = fn(){		PADrend.getSyncClock = thisFn.clockBackup;		};
		restore.clockBackup := PADrend.getSyncClock;
		client.onClose += restore;
		
		var timeSyncClient = Util.Network.ClockSynchronizer.createClient(client.getServerName(), 1+client.getServerPort());
		PADrend.getSyncClock = timeSyncClient->timeSyncClient.getClockSec;
		client.onClose += timeSyncClient -> timeSyncClient.close;
	};
});

// ------------------------------------------------------------------------------
return true;
