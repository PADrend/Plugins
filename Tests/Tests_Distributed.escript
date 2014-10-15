/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tests] Test/Tests_Distributed.escript
 **/

var plugin = new Plugin({
		Plugin.NAME : 'Tests/Tests_Distributed',
		Plugin.DESCRIPTION : "For testing client/server functions.\n***Connect at least on MultiView-Client***",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [ 'Tests' ],
		Plugin.EXTENSION_POINTS : []
});

//!	---|> Plugin
plugin.init:=fn(){
	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_Init', this->fn(){
			gui.registerComponentProvider('Tests_TestsMenu.distributedTests',{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Distributed tests",
				GUI.ON_CLICK : this->execute
			});
		});
    }
    return true;
};


//! (internal)
plugin.execute:=fn(){
	out(" Test... ");

	var DistTest = new Type();
	DistTest._constructor := fn(description,initFun,queryFun){
		this.description := description;
		this.initFun := initFun;
		this.queryFun := queryFun;
		this.result := void;
		this.resultMessage := "?";
	};
	DistTest.init := fn(){
		result=false;
		try{
			result = initFun();
		}catch(e){
			out(e);
			resultMessage = "init exception";
			return;
		}
		resultMessage = result ?"init ok":"init failed";
	};
	DistTest.query := fn(){
		if(!result)
			return;
		try{
			result=queryFun();
		}catch(e){
			out(e);
			resultMessage = "query exception";
			return;
		}
		resultMessage = result ?"query ok":"query failed";
	};
	// ---------------------------
	var tests = [];

	// ---

	tests += new DistTest( "Simple" , fn(){
		return true;
	},fn(){
		return true;
	});

	// ---
	static Command = Std.require('LibUtilExt/Command');
	tests += new DistTest( "Command transmission" , fn(){
		GLOBALS.__TestPlugin_DistributetTests_m1 := 0;
		
		// send a command to all clients
		PADrend.executeCommand( new Command({
			Command.EXECUTE : fn(){
				PADrend.message("Executing command...\n");
				out("ping\n");
				
				// send a command back to the server
				PADrend.executeCommand( new Command({
					Command.EXECUTE : fn(){
						out("pong\n");
						GLOBALS.__TestPlugin_DistributetTests_m1++;
					},
					Command.FLAGS : Command.FLAG_SEND_TO_MASTER
				}));
				
			},
			Command.FLAGS : Command.FLAG_SEND_TO_SLAVES
		}));
		return true;
	},fn(){
		return GLOBALS.__TestPlugin_DistributetTests_m1 > 0;
	});

	// ---


	// ---------------------------
	foreach(tests as var t)
		t.init();
		
	PADrend.message("Please wait...");

	PADrend.planTask( 0.5, (fn(tests){

		var p=gui.createPopupWindow( 400,300,"Distributed Tests");
		p.addOption("*Note: Needs at least one connected MultiView-Client.*");
		var success=true;
		foreach(tests as var t){
			t.query();
			p.addOption( t.description+"..."+t.resultMessage );
			success &= t.result;
		}
		p.addAction( success ? "Everything ok :-)" : "Failed!" );
		p.init();
	}).bindLastParams(tests) );
};


// ---------------------------------------------------------
return plugin;
