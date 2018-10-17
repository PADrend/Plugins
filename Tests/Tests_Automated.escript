/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2015 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012,2015 Claudius Jähn <claudius@uni-paderborn.de>
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

declareNamespace($Tests);

Tests.AutomatedTestsPlugin := new Plugin({
		Plugin.NAME : 'Tests/Tests_Automated',
		Plugin.DESCRIPTION : 'Various automated tests.',
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [ 'Tests' ],
		Plugin.EXTENSION_POINTS : []
});
static plugin = Tests.AutomatedTestsPlugin;

plugin.init @(override) := fn(){
	module.on('PADrend/gui', fn(gui){
		gui.register('Tests_TestsMenu.automatedTests',[{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Automated tests...",
				GUI.ON_CLICK : fn() {
					plugin.showResults(plugin.execute());
				}
		}]);
	});
	return true;
};


plugin.execute := fn( [Array,void] testFiles=void ){
	outln("\n[[-- Automated tests... ");
	
	if(!testFiles)
		testFiles = IO.dir(__DIR__+"/AutomatedTests").filter(fn(file){ return file.endsWith(".escript");}) ;

	var results = {
		'parts' : [],
		'result' : true,
		'resultString' : "undefined"
	};

	var exceptionWhileLoading = false;
	var tests = [];
	foreach(testFiles as var f){
		try{
			outln("Loading '"+f+"'" );
			foreach(load(f) as var test){
				test.setScriptFile(f);
				tests += test;
			}
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
	foreach(tests as var t)
		t.execute();
	
	foreach(tests as var t){
		var parts = [];
		results['parts']+={
			'description' : t.getDescription(),
			'resultString' : t.getResultMessage(),
			'result' : t.getResult(),
			'file' : t.getScriptFile(),
			'duration' : t.getDuration(),
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
	
	outln("\n--]]\n");
	return results;
};


plugin.showResults := fn(Map results){
	if(testDialog&&!testDialog.isDestroyed())
		testDialog.destroy();
	
	var entries = [];
	var files = new Std.Set;
	foreach(results['parts'] as var result){
		files += result['file'];
		var partEntries = [
			"File: " + result['file'],
			GUI.NEXT_ROW,
			"Duration: " + result['duration']
		];
		foreach(result['parts'] as var partialResult){
			partEntries += GUI.NEXT_ROW;
			partEntries += {
				GUI.TYPE : GUI.LABEL,
				GUI.LABEL : " > "+partialResult['description']+" : "+partialResult['resultString'],
				GUI.COLOR : partialResult['result'] ? GUI.DARK_GREEN : GUI.RED
			};
		}
		entries += {
			GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
			GUI.HEADER : [{
				GUI.TYPE : GUI.LABEL,
				GUI.LABEL : result['description']+"..."+result['resultString'],
				GUI.COLOR : result['result'] ? GUI.DARK_GREEN : GUI.RED,
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Retry tests in file "+result['file'],
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.WIDTH : 16,
				GUI.ICON : "#RefreshSmall",
				GUI.ON_CLICK : [result['file']] => fn(file){	plugin.showResults(plugin.execute([file])); }
			}],
			GUI.COLLAPSED : result['result'],
			GUI.CONTENTS :  [{
				GUI.TYPE : GUI.TYPE_CONTAINER,
				GUI.CONTENTS : partEntries,
				GUI.LAYOUT : GUI.LAYOUT_FLOW,
				GUI.SIZE : GUI.SIZE_MINIMIZE
			}],
			GUI.TOOLTIP : "ScriptFile:" + result['file']
		};
		entries+= GUI.NEXT_ROW;
	}
	
	
	static testDialog = gui.createDialog({
		GUI.TYPE : GUI.TYPE_POPUP_DIALOG,
		GUI.LABEL : "Results",
		GUI.SIZE : [300,400],
		GUI.CONTENTS : entries,
		GUI.ACTIONS : [ [results['resultString']], ["Retry" , [files] => fn(files) { plugin.showResults(plugin.execute(files.toArray())); },"Reload all tests"] ]
	});
	testDialog.init();
	
};

// ---------------------------------------------------------
return plugin;
