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

// --------------------------------------------------------------
// base

static InstanceSyncingGUI = new Namespace;

static configuredObjects = new Std.DataWrapper( [] );
InstanceSyncingGUI.configure := fn(objs...){	configuredObjects(objs);	};

static entryTraitRegistry = module('./GUI_entryTraitRegistry');

InstanceSyncingGUI.configureIdleMode := fn(){	InstanceSyncingGUI.configure('frameSetup','headPosition','serverCreate','clientConnect');	};

InstanceSyncingGUI.createConfigEntry := fn(gui,obj,ctxt...){
	var entry = gui.create({
		GUI.TYPE : GUI.TYPE_TREE_GROUP,
		GUI.FLAGS : GUI.COLLAPSED_ENTRY,
		GUI.OPTIONS : [{
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.SIZE :  [GUI.WIDTH_REL|GUI.HEIGHT_CHILDREN_ABS , 1,0 ]
		}]
	});
	var trait = entryTraitRegistry[obj];
	if(!trait){
		for(var type = obj.getType(); !trait&&type; type = type.getBaseType())
			trait = entryTraitRegistry[type];
	}
	if(trait){
		Std.Traits.addTrait( entry, trait, obj, ctxt... );
	}else{
		entry.getFirstChild() += ""+obj;
	}	
	return entry;
};

/*! A simple GUI.TreeViewEntry having a single container with flow layout.
	Adds the following attributes:
		.container      the container		*/
{
	var t = new Std.Traits.GenericTrait;
	entryTraitRegistry['simpleEntry'] = t;
	
	t.onInit += fn(GUI.TreeViewEntry entry){
		var container = entry.getGUI().create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
//			GUI.FLAGS : GUI.BORDER,
			GUI.LAYOUT : GUI.LAYOUT_FLOW, 
			GUI.SIZE :  [GUI.WIDTH_REL|GUI.HEIGHT_CHILDREN_ABS , 1,2 ]
		});
		entry.container := container;
		entry.getFirstChild() += container;

	};
}
module.on('PADrend/gui', fn(gui){
	gui.register('PADrend_MainWindowTabs.21_Sync', [gui]=>fn(gui){
		var treeview = gui.create({
			GUI.TYPE : GUI.TYPE_TREE,
			GUI.OPTIONS : []
		});
		configuredObjects.onDataChanged += [treeview] => fn(treeview, Array objs){
			if(treeview.isDestroyed())
				return $REMOVE;
			treeview.destroyContents();
			foreach(objs as var obj)
				treeview += InstanceSyncingGUI.createConfigEntry(treeview.getGUI(),obj);
		};
		configuredObjects.forceRefresh();
		return {
			GUI.TYPE : GUI.TYPE_TAB,
			GUI.TAB_CONTENT : treeview,
			GUI.LABEL : "Sync"
		};	
	});

	InstanceSyncingGUI.configureIdleMode();
	
});

//! \see [ext:InstanceSyncing_AddClientFeatures]
registerExtension('InstanceSyncing_AddClientFeatures', fn(client){
	InstanceSyncingGUI.configure( client,'headPosition' );
	client.onClose += InstanceSyncingGUI.configureIdleMode;
},Extension.LOW_PRIORITY);  // low priority to allow features to extend the gui
				
//! \see [ext:InstanceSyncing_AddServerFeatures]
registerExtension('InstanceSyncing_AddServerFeatures', fn(server){
	InstanceSyncingGUI.configure( 'frameSetup', 'headPosition',server );
	server.onClose += InstanceSyncingGUI.configureIdleMode;
},Extension.LOW_PRIORITY);  // low priority to allow features to extend the gui

// --------------------------------------------------------------
// client

{
	var t = new Std.Traits.GenericTrait;
	entryTraitRegistry['clientConnect'] = t;
	
	t.onInit += fn(GUI.TreeViewEntry entry,...){
		Std.Traits.addTrait(entry,entryTraitRegistry['simpleEntry']);

		//! \see 'simpleEntry'
		entry.container += '----';
		entry.container++;
		entry.container += "[Client]  ";
		entry.container += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "Server",
			GUI.DATA_WRAPPER : Util.requirePlugin('InstanceSyncing').serverName,
			GUI.SIZE : [GUI.WIDTH_FILL_REL,0.5,1]
		};
		entry.container += {
			GUI.TYPE : GUI.TYPE_NUMBER,
			GUI.LABEL : "Port",
			GUI.DATA_WRAPPER : Util.requirePlugin('InstanceSyncing').serverPort,
			GUI.WIDTH : 100
		};
		entry.container += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "connect",
			GUI.WIDTH : 70,
			GUI.ON_CLICK : fn(){	
				var InstanceSyncing = Util.requirePlugin('InstanceSyncing');
				InstanceSyncing.connectClient(InstanceSyncing.serverName(),InstanceSyncing.serverPort());	
			}
		};
		foreach(entry.getGUI().createComponents('InstanceSyncing_ClientConnectEntry') as var c)
			entry.container += c;

	};
}


{
	var t = new Std.Traits.GenericTrait;
	entryTraitRegistry[ module('./Client') ] = t;
	
	t.onInit += fn(GUI.TreeViewEntry entry, client, ...){
		Std.Traits.addTrait(entry,entryTraitRegistry['simpleEntry']);

		entry.container += "[Client]  Connected to "+client.getServerName()+":"+client.getServerPort();
		entry.container += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "close",
			GUI.ON_CLICK : client->client.close,
			GUI.WIDTH : 50
		};
		foreach(entry.getGUI().createComponents({
					GUI.TYPE : GUI.TYPE_COMPONENTS,
					GUI.PROVIDER : 'InstanceSyncing_ClientEntry',
					GUI.CONTEXT : client }) as var c)
			entry.container += c;

	};
}


//-----------------------------------
// server

{
	var t = new Std.Traits.GenericTrait;
	entryTraitRegistry['serverCreate'] = t;
	
	t.onInit += fn(GUI.TreeViewEntry entry,...){
		Std.Traits.addTrait(entry,entryTraitRegistry['simpleEntry']);
		
		
		//! \see 'simpleEntry'
		entry.container += '----';
		entry.container++;
		entry.container += "[Server]      ";
		entry.container += {
			GUI.TYPE : GUI.TYPE_NUMBER,
			GUI.LABEL : "Port",
			GUI.DATA_WRAPPER : Util.requirePlugin('InstanceSyncing').serverPort,
			GUI.WIDTH : 100
		};
		entry.container += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "create",
			GUI.ON_CLICK : fn(){ 
				Util.requirePlugin('InstanceSyncing').createServer(Util.requirePlugin('InstanceSyncing').serverPort());
			},
			GUI.WIDTH : 70,
		};
		foreach(entry.getGUI().createComponents('InstanceSyncing_ServerCreateEntry') as var c)
			entry.container += c;

	};
}

{
	static Server = module('./Server');
	var t = new Std.Traits.GenericTrait;
	entryTraitRegistry[ Server ] = t;
	
	t.onInit += fn(GUI.TreeViewEntry entry, Server server){
		Std.Traits.addTrait(entry,entryTraitRegistry['simpleEntry']);
		
		entry.open();
		//! \see 'simpleEntry'
		entry.container += '----';
		entry.container++;
		entry.container += "[Server]      ";
		entry.container += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Close",
			GUI.WIDTH : 70,
			GUI.ON_CLICK : server->server.close
		};
		entry.container += {
			GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
			GUI.LABEL : "exit all",
			GUI.WIDTH : 70,
			GUI.ON_CLICK : [server]=>fn(server){
				PADrend.CommandHandling.executeRemoteCommand(fn(){exit();});
				PADrend.planTask(0.5, [server]=>fn(server){server.close(); });
				PADrend.planTask(1.0, fn(){exit();} );
			}
		};
		entry.container += {
			GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
			GUI.LABEL : "restart all",
			GUI.WIDTH : 70,
			GUI.ON_CLICK : [server]=>fn(server){
				PADrend.CommandHandling.executeRemoteCommand(fn(){PADrend.restart();}); 
				PADrend.planTask(0.5, [server]=>fn(server){server.close(); });
				PADrend.planTask(1.0, fn(){PADrend.restart();});
			}
		};
		entry.container += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "save config",
			GUI.WIDTH : 70,
			GUI.ON_CLICK :fn(){
				PADrend.executeCommand(fn(){
					PADrend.message("Save config...");
					systemConfig.save();
				});
			}
		};
		entry += InstanceSyncingGUI.createConfigEntry(entry.getGUI(),'connectedClients',server);
	};
}

{
	var t = new Std.Traits.GenericTrait;
	entryTraitRegistry[ 'connectedClients' ] = t;
	
	static Server = module('./Server');
	t.onInit += fn(GUI.TreeViewEntry entry, dummyString, Server server){
		Std.Traits.addTrait(entry,entryTraitRegistry['simpleEntry']);
		
		//! \see 'simpleEntry'
		entry.container += "[Connected clients]";

		var subentriesRefresher = [entry] => fn(entry, ...){
			if(entry.isDestroyed())
				return $REMOVE;
			entry.refreshSubentries(); //! \see GUI.TreeViewEntry.DynamicSubentriesTrait
		};
		server.onNewClientStub += subentriesRefresher;

		//! \see GUI.TreeViewEntry.DynamicSubentriesTrait
		Std.Traits.addTrait(entry,GUI.TreeViewEntry.DynamicSubentriesTrait,[server,subentriesRefresher,entry.getGUI()] => fn(server,subentriesRefresher,gui){
			var stubEntries = [];
			foreach(server.getConnectedClients() as var clientStub){
				stubEntries += InstanceSyncingGUI.createConfigEntry( gui,clientStub );
				clientStub.onClose += subentriesRefresher;
			}
			return stubEntries;
		});

		entry.open();
	};
}

{
	static ClientStub = module('./ClientStub');
	var t = new Std.Traits.GenericTrait;
	entryTraitRegistry[ ClientStub ] = t;
	
	t.onInit += fn(GUI.TreeViewEntry entry, ClientStub clientStub){
		Std.Traits.addTrait(entry,entryTraitRegistry['simpleEntry']);
		foreach(entry.getGUI().createComponents({
					GUI.TYPE : GUI.TYPE_COMPONENTS,
					GUI.PROVIDER : 'InstanceSyncing_ClientStubEntry',
					GUI.CONTEXT : clientStub }) as var c)
			entry.container += c;
	};
}

return InstanceSyncingGUI;

// ----------------------------------------------------------------------------------------------------------
