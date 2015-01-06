/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/**
 *	[Plugin:Evaluator] Evaluator/Plugin.escript
 *	2010-04-28	Benjamin Eikel	Creation.
 */

/*!	EvaluatorPlugin ---|> Plugin */
GLOBALS.EvaluatorPlugin := new Plugin({
		Plugin.NAME : 'Evaluator',
		Plugin.DESCRIPTION : 'Selection and configuration of evaluators.',
		Plugin.VERSION : 1.1,
		Plugin.AUTHORS : "Benjamin Eikel, Claudius Jaehn",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : [
			/* [ext:Evaluator_QueryEvaluators]
			 * Add Evaluators to the list of availabe evaluators.
			 * @param   List of evaluators
			 * @result  void
			 */
			'Evaluator_QueryEvaluators',

			/* [ext:Evaluator_OnEvaluatorSelected]
			 * Called whenever the selected evaluator changes.
			 * @param   Currently selected evaluator
			 * @result  void
			 */
			'Evaluator_OnEvaluatorSelected',

			/* [ext:Evaluator_OnEvaluatorDescriptionChanged]
			 * Called whenever the name of an evaluator, containing a
			 * description for many evaluators, changes.
			 * @param   Evaluator whose description changed
			 * @param   New description of the evaluator
			 * @result  void
			 */
			'Evaluator_OnEvaluatorDescriptionChanged'
		]});

/*!	Plugin initialization.
	---|> Plugin	*/
EvaluatorPlugin.init = fn() {
	if(!MinSG.isSet($Evaluator)){
		out("MinSG.Evaluator not found!\n");
		return false;

	}
	{
		Std.require('Evaluator/extendEvaluator');
		Std.require('Evaluator/registerEvaluators');
	}
	{ /// Register ExtensionPointHandler:
		registerExtension('PADrend_Init', this->fn(){
			gui.registerComponentProvider('PADrend_PluginsMenu.evaluator',{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Evaluator",
				GUI.ON_CLICK : fn() {
					if(!GLOBALS.gui.windows['Evaluator']) {
						GLOBALS.gui.windows['Evaluator'] = EvaluatorPlugin.createWindow( 10, 40);
					}else{
						GLOBALS.gui.windows['Evaluator'].toggleVisibility();
					}
					this.setSwitch(GLOBALS.gui.windows['Evaluator'].isVisible());
				}
			});
		});
		registerExtension('PADrend_Init', this->this.ex_Init);

		registerExtension('Evaluator_QueryEvaluators', this->this.ex_QueryEvaluators,Extension.HIGH_PRIORITY);
	}
	return true;
};

/*!	[ext:PADrend_Init */
EvaluatorPlugin.ex_Init := fn() {

	Std.require('Evaluator/EvaluatorManager').updateEvaluatorList( PADrend.configCache.getValue('Evaluator.selectedEvaluator') );
	
	// store selected evaluator in config
	registerExtension('Evaluator_OnEvaluatorSelected', fn(e) {
		PADrend.configCache.setValue('Evaluator.selectedEvaluator', e.getEvaluatorTypeName());
		outln("Evaluator '", e.getEvaluatorTypeName(), "' selected.");
	});
};

/*! [ext:Evaluator_QueryEvaluators]
	Initialize standard evaluators.	*/
EvaluatorPlugin.ex_QueryEvaluators := fn(Array evaluatorList) {
	evaluatorList += new MinSG.VisibilityEvaluator(MinSG.Evaluator.SINGLE_VALUE);
	evaluatorList += new MinSG.AreaEvaluator(MinSG.Evaluator.SINGLE_VALUE);
	evaluatorList += new MinSG.StatsEvaluator(MinSG.Evaluator.SINGLE_VALUE);
	evaluatorList += new MinSG.OccOverheadEvaluator(MinSG.Evaluator.SINGLE_VALUE);
	evaluatorList += new MinSG.OverdrawFactorEvaluator(MinSG.Evaluator.SINGLE_VALUE);
	evaluatorList += new MinSG.TrianglesEvaluator();
	evaluatorList += new MinSG.AdaptCullEvaluator();
	evaluatorList += new MinSG.ColorVisibilityEvaluator();
	
	var dir=systemConfig.getValue('Evaluator.scriptEvaluatorPath',"./evaluators");
	if(IO.isDir(dir))	{
		var files=Util.getFilesInDir(dir,[".escript"]);
		foreach(files as var file){
			try{
				var result=load(file.substr("file://".length()));
				if(!result)
					continue;
				if(! (result---|>Array))
					result = [result];
				evaluatorList.append(result);
			}catch(e){
				Runtime.warn(e);
			}
		}
	}
	
};

/*!	[static] */
EvaluatorPlugin.createWindow := fn( posX, posY) {
	var width=460;
	var height=400;
	var window=gui.createWindow(width, height, "Evaluator");
	window.setPosition(posX, posY);

	window += EvaluatorPlugin.createConfigPanel();

	window.setEnabled(true);
	return window;
};


//! (static)
EvaluatorPlugin.createConfigPanel := fn() {
	static EvaluatorManager = Std.require('Evaluator/EvaluatorManager');
	var panel = gui.create({
		GUI.TYPE			:	GUI.TYPE_CONTAINER,
		GUI.SIZE			:	GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT			:	GUI.LAYOUT_FLOW
	});

	{ // eval selector
		var dd = gui.create({
			GUI.TYPE			:	GUI.TYPE_SELECT,
			GUI.OPTIONS			:	[],
			GUI.ON_DATA_CHANGED	:	EvaluatorManager.selectEvaluator
		});

		panel += dd;

		registerExtension('Evaluator_OnEvaluatorSelected', dd -> fn(e) {
			if(e != getData()) {
				setData(e);
			}
		});

		dd.refresh := fn(){
			var selection = EvaluatorManager.getSelectedEvaluator();
			this.clear();
			var sortedEvaluators = EvaluatorManager.evaluators.clone();
			sortedEvaluators.sort(fn(a,b){return a.getEvaluatorTypeName()<b.getEvaluatorTypeName();});
			foreach(sortedEvaluators as var e){
				this.addOption(e,e.getEvaluatorTypeName());
			}
			this.setData( selection );
		};
		dd.refresh();

		panel+={
			GUI.TYPE			:	GUI.TYPE_BUTTON,
			GUI.LABEL			:	"refresh",
			GUI.TOOLTIP			:	"Update the list of available evaluators. This also re-parses the scripting evaluators in the scripting evaluator folder.",
			GUI.ON_CLICK		:	dd->fn() { EvaluatorManager.updateEvaluatorList(); this.refresh(); }
		};

	}
	panel++;
	panel += "----";
	panel++;
	{ // config panel container
		var p = gui.create({
			GUI.TYPE			:	GUI.TYPE_CONTAINER,
			GUI.SIZE			:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_FILL_ABS, 2, 2]
		});
		panel += p;

		p.refresh := fn() {
			destroyContents();
			var evaluator = EvaluatorManager.getSelectedEvaluator();
			if(!evaluator) {
				return;
			}
			add(evaluator.createConfigPanel());
		};
		registerExtension('Evaluator_OnEvaluatorSelected', p -> fn(...) {
			refresh();
		});
		p.refresh();
	}
	return panel;
};


return EvaluatorPlugin;
