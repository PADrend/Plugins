/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Paul Justus
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Measurement] Measurement/Plugin.escript
 **  2008-09-02
 **  2010-02-16 - Benjamin Eikel - Added test method (sample only on waypoints).
 **  2010-03-17 - Paul Justus - Integrated InterpolatedTest (does interpolated test between waypoints).
 **  2010-03-24 - Paul Justus - GUI of MeasurementPlugin structured (using titled panels).
 **  2011-09-02 - Benjamin Eikel - Rework of EScript code.
 **/

//! MeasurementPlugin ---|> Plugin
GLOBALS.MeasurementPlugin := new Plugin({
		Plugin.NAME : 'Measurement',
		Plugin.DESCRIPTION : "Measurements along camera paths.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Benjamin Eikel, Claudius Jaehn, Paul Justus",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['Evaluator', 'Waypoints']
});

/**
 * Plugin initialization.
 * ---|> Plugin
 */
MeasurementPlugin.init:=fn() {
	loadOnce("LibUtilExt/DataTable.escript");

	load(__DIR__+"/SamplePath.escript");
	load(__DIR__+"/InterpolatedTest.escript");

	registerExtension('PADrend_Init',this->fn(){
		gui.registerComponentProvider('PADrend_MainWindowTabs.50_Measurement', this->createTab);
	});

	return true;
};


MeasurementPlugin.createTab @(private) := fn() {

	var page = gui.createPanel();

	//===============================================================================

	//============= Tests along current path using selected evaluator ==============
	page.nextRow();
	{
		var panel = gui.create({
			GUI.TYPE				:	GUI.TYPE_CONTAINER,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 10, 10],
			GUI.FLAGS				:	GUI.RAISED_BORDER,
			GUI.LAYOUT				: 	GUI.LAYOUT_FLOW
		});
		page += panel;
		
		panel += "*Tests along current path using evaluator*";
		panel++;

		var currentEvaluator = EvaluatorManager.getSelectedEvaluator();
		var evaluatorName = DataWrapper.createFromValue(currentEvaluator ? currentEvaluator.name() : "");
		panel += {
			GUI.TYPE				:	GUI.TYPE_TEXT,
			GUI.LABEL				:	"Selected evaluator:",
			GUI.TOOLTIP				:	"Evaluator that is selected in the 'Evaluator' plugin.",
			GUI.DATA_WRAPPER		:	evaluatorName,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
			GUI.FLAGS				:	GUI.LOCKED
		};
		registerExtension('Evaluator_OnEvaluatorDescriptionChanged',
			(fn(evaluator, description, dataWrapper) {
				if(evaluator) {
					dataWrapper(description);
				}
			}).bindLastParams(evaluatorName));
		panel++;
		
		var outputFileName = DataWrapper.createFromValue("output.tsv");
		panel += {
			GUI.TYPE				:	GUI.TYPE_FILE,
			GUI.ENDINGS				:	[".tsv"],
			GUI.LABEL				:	"Output file:",
			GUI.TOOLTIP				:	"File that is used to write the measured data into.",
			GUI.DATA_WRAPPER		:	outputFileName,
			GUI.SIZE				:	[GUI.WIDTH_REL, 0.7, 0]
		};
		panel += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"Suggest",
			GUI.TOOLTIP				:	"Suggest a file name based on the current scene,\ncamera path, renderer, and evaluator.",
			GUI.ON_CLICK			:	fn(DataWrapper fileName, DataWrapper evaluatorName) {
											var suggestions = [];
											var scene = PADrend.getCurrentScene();
											if(scene && scene.isSet($filename) && !scene.filename.empty()) {
												var slashPos = scene.filename.rFind("/");
												suggestions += scene.filename.substr(slashPos + 1, scene.filename.rFind(".") - slashPos - 1);
											}
											var path = WaypointsPlugin.getCurrentPath();
											if(path && path.isSet($name) && !path.name.empty()) {
												var slashPos = path.name.rFind("/");
												suggestions += path.name.substr(slashPos + 1, path.name.rFind(".") - slashPos - 1);
											}
											if(scene && scene.hasStates()) {
												var states = scene.getStates();
												foreach(states as var state) {
													if(!state.isActive()) {
														continue;
													}
													if(state ---|> MinSG.OccRenderer) {
														suggestions += "CHC";
													} else if(state ---|> MinSG.CHCppRenderer) {
														suggestions += "CHC++";
													} else if(MinSG.isSet($SVS) && state ---|> MinSG.SVS.Renderer) {
														suggestions += "SVS";
													} else if(MinSG.isSet($SVS) && state ---|> MinSG.SVS.BudgetRenderer) {
														suggestions += "Budget" + state.getBudget().format(0, false);
													}
												}
											}
											if(!evaluatorName().empty()) {
												suggestions += evaluatorName();
											}
											fileName(suggestions.implode("_") + ".tsv");
										}.bindFirstParams(outputFileName, evaluatorName),
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		
		var pointIterations = DataWrapper.createFromValue(3);
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.RANGE				:	[1, 10],
			GUI.RANGE_STEPS			:	9,
			GUI.LABEL				:	"Point iterations:",
			GUI.TOOLTIP				:	"Number of measurement iterations for every point on the path.",
			GUI.DATA_WRAPPER		:	pointIterations,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		
		var pathIterations = DataWrapper.createFromValue(1);
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.RANGE				:	[1, 10],
			GUI.RANGE_STEPS			:	9,
			GUI.LABEL				:	"Path iterations:",
			GUI.TOOLTIP				:	"Number of measurement iterations for the whole path.",
			GUI.DATA_WRAPPER		:	pathIterations,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		
		var stepSize = DataWrapper.createFromValue(1.0);
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.RANGE				:	[0.5, 100.0],
			GUI.RANGE_STEPS			:	199,
			GUI.LABEL				:	"Step size:",
			GUI.TOOLTIP				:	"Time duration between two consecutive points on the path.",
			GUI.DATA_WRAPPER		:	stepSize,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
		
		panel += {
			GUI.TYPE				:	GUI.TYPE_BUTTON,
			GUI.LABEL				:	"Start measurement",
			GUI.TOOLTIP				:	"Jump to points on the current path and use the currently selected evaluator to sample values.",
			GUI.ON_CLICK			:	(MeasurementPlugin.samplePath).bindFirstParams(outputFileName, pointIterations, pathIterations, stepSize),
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
	
	}
	page++;

	//===============================================================================

	//============= Tests along current path using stats & data table ==============
	page.nextRow();
	{
		var panel = gui.create({
			GUI.TYPE				:	GUI.TYPE_CONTAINER,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 10, 10],
			GUI.FLAGS				:	GUI.RAISED_BORDER,
			GUI.LAYOUT				: 	GUI.LAYOUT_FLOW
		});
		page += panel;

		panel+="*Tests along current path using stats*";
		panel++;
		
		var configData = new ExtObject();
		configData.exportFilename := "output.tsv";
		configData.numSteps := 100;
		
		panel+={
			GUI.TYPE : GUI.TYPE_FILE,
			GUI.LABEL : "Output file:",
			'ending' : [".tsv"],
			'object' : configData,
			'attr' : $exportFilename
		};
		panel++;
		panel+={
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Num steps",
			GUI.RANGE : [10,1000],
			'steps' : 100,
			'object' : configData,
			GUI.TOOLTIP : "The timestamps for frame n on the selected path is\n (n * path.getMaxTime()/numSteps)",
			'attr' : $numSteps
		};
		panel++;
		panel+={
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "execute",
			GUI.ON_CLICK : configData->fn(){
				// init
				var path = WaypointsPlugin.getCurrentPath();
				if(!path)
					return;

				var statistics = PADrend.frameStatistics;

				var data = [];
				for(var i=0;i<statistics.getNumCounters();i++)
					data+=[];

				
				var stepSize = path.getMaxTime() / this.numSteps;
				
				// run along path
				var stop=false;
				for(var time = 0; time<=path.getMaxTime() && !stop; time+=stepSize){
					PADrend.getDolly().setSRT(path.getWorldPosition(time));
					frameContext.beginFrame();
					PADrend.renderScene( PADrend.getRootNode(), PADrend.getActiveCamera(), PADrend.getRenderingFlags(), PADrend.getBGColor());
					frameContext.endFrame(true);
					PADrend.getEventQueue().process();
					while(PADrend.getEventQueue().getNumEventsAvailable() > 0) {
						var evt = PADrend.getEventQueue().popEvent(); // stop on key
						if(evt.type == Util.UI.EVENT_KEYBOARD && evt.pressed)
							stop=true;
					}
					for(var i=0;i<statistics.getNumCounters();i++)
						data[i]+=statistics.getValue(i);
					PADrend.SystemUI.swapBuffers();
				}
				
				// export data
				var table = new DataTable( "frame" );
				for(var i=0;i<statistics.getNumCounters();i++){
					if(statistics.getDescription(i)=="?") continue;
					table.addDataRow(statistics.getDescription(i),statistics.getUnit(i),data[i],"#ff0000" );
				}
				table.exportCSV(this.exportFilename);
				table.exportSVG(this.exportFilename+".svg");
			}
		};

	}
	page.nextRow();

	//===============================================================================

	//====================== Example for using DataTable ============================
/*	{
		var panel = gui.createPanel(width, 60, GUI.AUTO_LAYOUT|GUI.RAISED_BORDER);

		var title = gui.createLabel("Simple example illustrating use of DataTable");
		title.setFont(GUI.FONT_HELVETICA_12);
		panel.add(title);
		panel.nextRow(10);

		var b=gui.createButton(100,15, "DataTable-Test");
		b.onClick=fn() {

			var m1=new Map();
			var m2=new Map();
			var m3=new Map();
			for(var i=0;i<30;i+=0.5){
				m1[i] = i;
				m2[i] = i*i;
				m3[i] = i*i*i;
			}
			var dataTable=new DataTable("x");
			dataTable.addDataRow( "linear","y",m1,"#888888" );
			dataTable.addDataRow( "quadratic","y",m2,"#ff0000" );
			dataTable.addDataRow( "cubic","y",m3,"#00ff00" );

			dataTable.exportCSV("1.csv");
			dataTable.exportSVG("1.svg");
		};
		panel.add(b);
		page.add(panel);
	}
	page.nextRow();*/
	//===============================================================================

	//============== Tests along interpolated path using Statistics & DataTable =====
	{
		var panel = gui.create({
			GUI.TYPE				:	GUI.TYPE_CONTAINER,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS | GUI.HEIGHT_CHILDREN_ABS, 10, 10],
			GUI.FLAGS				:	GUI.RAISED_BORDER,
			GUI.LAYOUT				: 	GUI.LAYOUT_FLOW
		});
		page += panel;
		panel.setTooltip(
				"Allows tests along interpolated path; It is possible to record frameduration, #rendered polygons, #rendered"+
				"\nmeshes/vbos and #box tests using statistics, and #visible boxes (#objects that are classified as visible),"+
				"\n#visible objects, #triangles in visible boxes and #triangles in visible objects using BoxQualityEvaluator."+
				"\nRecorded data for each of these attributes is exported to a CSV-file and a SVG-file. Besides there is a"+
				"\npossibility to get average distance between neighbouring waypoints for any selected path; this can be helpful"+
				"\nto set reasonable step distance.\n");

		panel+="*Tests along interpolated path using Stat. & DataTable*";

		// average distance label
		var avgLabel = gui.createLabel("average distance :");
		avgLabel.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
		avgLabel.setTooltip("average distance between neighbouring waypoint of current path");
		panel.nextRow(10);
		panel.add(avgLabel);

		// output of average distance
		var avgDistOutput = gui.createLabel(80, 15, " 0.0", GUI.LOWERED_BORDER);
		avgDistOutput.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
		panel.nextColumn();
		panel.add(avgDistOutput);

		// calculate avg. distance button
		var button0 = gui.createButton(60, 15, "calculate");
		button0.avgDistOutput := avgDistOutput;
		button0.setTooltip("calculate average distance between two neighbouring waypoints for current path");
		button0.onClick = fn() {
			avgDistOutput.setText(MeasurementPlugin.calculateAvgDistance(WaypointsPlugin.getCurrentPath()););
		};
		panel.nextColumn();
		panel.add(button0);

		// filename prefix
		var prefixLabel = gui.createLabel("filename prefix :");
		prefixLabel.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
		prefixLabel.setTooltip("this text is added as prefix to names of exported CSV/SVG-files.");
		panel.nextRow(10);
		panel.add(prefixLabel);

		var prefixInput = gui.createTextfield(80, 15, "test");
		panel.nextColumn();
		panel.add(prefixInput);

		// input of step-distance
		var distLabel = gui.createLabel("step distance :");
		distLabel.setTextStyle(GUI.TEXT_ALIGN_MIDDLE);
		distLabel.setTooltip("step distance between neighbouring waypoints. If  '0.0'  is chosen \nas step distance, no interpolating will be done.");
		panel.nextRow();
		panel.add(distLabel);

		panel.nextColumn();
		var stepDistInput = gui.createTextfield(80, 15, "0.0");
		panel.add(stepDistInput);
		panel.nextRow(20);

		var button1 = gui.createButton(140, 15, "execute using statistics");
		button1.setTooltip(
			"execute tests for all registered scenes using statistics. These record frameduration, #rendered objects,\n"+
			"#rendered polygons and #box tests");
		button1.stepDistInput := stepDistInput;
		button1.prefixInput := prefixInput;
		button1.onClick=fn() {
			var test = new MeasurementPlugin.InterpolatedTest(void);

			// calculate additional SRTs to fill the gap between neighbouring waypoints
			var success = test.interpolateSRTs(stepDistInput.getText().toNumber());

			// execute the test for all scenes
			if (success)
				test.executeAllScenes(prefixInput.getText());
			else out("MeasurementPlugin: couldn't execute test!\n");
		};
		panel.add(button1);

		var button2 = gui.createButton(180, 15, "execute with BoxQualityEvaluator");
		button2.setTooltip(
			"execute tests for all registered scenes using MinSG.BoxQualityEvaluator(). This measures #visible boxes,\n"+
			"visible objects, #triangles in visible boxes and #triangles in visible objects");
		button2.stepDistInput := stepDistInput;
		button2.prefixInput := prefixInput;
		button2.onClick=fn() {
			var test = new MeasurementPlugin.InterpolatedTest(void);

			// calculate additional SRTs to interpolate the gap between neighbouring waypoints
			var success = test.interpolateSRTs(stepDistInput.getText().toNumber());

			// execute the test for all scenes
			if (success)
				test.executeAllScenesWithBQEvaluator(prefixInput.getText());
			else out("MeasurementPlugin: couldn't execute test!\n");
		};
		panel.add(button2);
	}
	
	// -----------------------------------------------------------------------
	
	return {
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.LABEL : "Measurement",
		GUI.TOOLTIP : getDescription(),
		GUI.TAB_CONTENT : page
	};

};

return MeasurementPlugin;
// ------------------------------------------------------------------------------
