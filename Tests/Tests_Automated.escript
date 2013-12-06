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
 **	[Plugin:Tests] Test/Tests_Automated.escript
 **/

declareNamespace( $Tests );

Tests.AutomatedTestsPlugin := new Plugin({
		Plugin.NAME : 'Tests/Tests_Automated',
		Plugin.DESCRIPTION : 'Various automated tests.',
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [ 'Tests' ],
		Plugin.EXTENSION_POINTS : []
});
var plugin = Tests.AutomatedTestsPlugin;

//!	---|> Plugin
plugin.init:=fn(){
	{ // Register ExtensionPointHandler:
		if(queryPlugin('Tests')){
			registerExtension('PADrend_Init', this->fn(){
				gui.registerComponentProvider('Tests_TestsMenu.automatedTests',[{
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Automated tests...",
						GUI.ON_CLICK : this->fn() {
							showResults(execute());
						}
				}]);
			});
		}
    }
    return true;
};


//! (internal)
plugin.execute:=fn(){
	out("\n[[-- Automated tests... \n");
	
	var testFiles = IO.dir(__DIR__+"/AutomatedTests").filter(fn(file){ return file.endsWith(".escript");}) ;

	var results = {
		'parts' : [],
		'result' : true,
		'resultString' : "undefined"
	};

	var exceptionWhileLoading = false;
	var tests = [];
	foreach(testFiles as var f){
		try{
			out("Loading '"+f+"'\n" );
			tests.append(load(f));
		}catch(e){
			Runtime.warn(e);
			results['result'] &= false;
			results['parts'] += {
				'description' : "Exception while loading test '"+f+"'",
				'resultString' : e.toString(),
				'result' : false,
				'parts' :[]
			};
		}
	}
	foreach(tests as var t){
		t.execute();
	}
	
	foreach(tests as var t){
		var parts = [];
		results['parts']+={
			'description' : t.getDescription(),
			'resultString' : t.getResultMessage(),
			'result' : t.getResult(),
			'parts' : parts
		};
		foreach(t.getPartialResults() as var partialResult){
			parts += {
				'description' : partialResult[0],
				'resultString' : partialResult[1] ? "ok" : "failed",
				'result' : partialResult[1]
			};
		}
		results['result'] &= t.getResult();
	}
	results['resultString'] = results['result'] ? "Everything ok :-)" : "Failed!";
	
	out("\n--]]\n");
	return results;
};


//! (internal)
plugin.showResults:=fn(Map results){
	
	var p=gui.createPopupWindow( 300,300,"Results");
	foreach(results['parts'] as var result){
		p.addOption({
			GUI.TYPE : GUI.LABEL,
			GUI.LABEL : result['description']+"..."+result['resultString'],
			GUI.COLOR : result['result'] ? GUI.DARK_GREEN : GUI.RED
		});
		foreach(result['parts'] as var partialResult){
			p.addOption({
				GUI.TYPE : GUI.LABEL,
				GUI.LABEL : " > "+partialResult['description']+" : "+partialResult['resultString'],
				GUI.COLOR : partialResult['result'] ? GUI.DARK_GREEN : GUI.RED
			});
		}
		p.addOption("----");
	}
	p.addAction( results['resultString'] );
	p.addAction( "Retry" , this->fn() {	showResults(execute());	} );
	p.init();
	
};

// ---------------------------------------------------------
return plugin;
