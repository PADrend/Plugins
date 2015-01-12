/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:GASP] GASP/SamplingTester/plugin.escript
 **/


var plugin = new Plugin({
		Plugin.NAME : 'SceneAnalyzer/QualityAnalysis',
		Plugin.DESCRIPTION : 'Analyze sampling values.',
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "Claudius",
		Plugin.VERSION : 0.1,
		Plugin.REQUIRES : ['SceneAnalyzer','PADrend','PADrend/GUI'],
		Plugin.EXTENSION_POINTS : [	]
});

static filename = DataWrapper.createFromConfig(PADrend.configCache,'SceneAnalyzerEval.qFile',"qualy_${time}.csv");
static sampleCount = DataWrapper.createFromConfig(PADrend.configCache,'SceneAnalyzerEval.qSampleCount',1000);

static formatFilename = fn(filename){
	if(filename.isA(Util.FileName))
		filename = filename.getPath();
	var r = {
		"${now}" : time().toIntStr(),
		"${time}" : "yearmonmday_hoursminutesseconds".replaceAll(getDate())
	};
	return filename.replaceAll(r);
	
};

static Table = new Type;
Table.data @(init) := Map;
Table.maxX := 0;
Table.maxY := 0;
Table.defaultValue := 0;
Table._key ::= fn(x,y){	return ""+x+":"+y;	};
Table._increaseRange ::= fn(x,y){	
	if(x>this.maxX) 
		this.maxX = x; 
	if(y>this.maxY) 
		this.maxY = y;
};

Table.set ::= fn( addr..., value){
	this.data[ this._key(addr...) ] = value;
	this._increaseRange( addr... );
};
Table.get ::= fn( addr...){
	var value = this.data[ this._key(addr...) ];
	return void == value ? this.defaultValue : value;
};
Table.getString ::= fn(delimiter='\t'){
	var lines = [];
	for(var y=0; y<=this.maxY; ++y){
		var line = [];
		for(var x=0; x<=this.maxX; ++x)
			line += this.get(x,y);
		lines += line.implode(delimiter);
	}
	return lines.implode('\n');
}; 

static measure = fn(){
	var GASPManager = Std.require('SceneAnalyzer/GlobalGASPManager');

	var c = GASPManager.getSelectedGASP();
	var evaluator = Std.require('Evaluator/EvaluatorManager').getSelectedEvaluator();
	var bb = c.getRootNode().getBoundingBox();

	var t = new Table;
	var row = 0;
	t.set(0,row,"cValue");
	t.set(1,row,"realValue");
	t.set(2,row,"diff");
	t.set(3,row,"absDiff");
	
	for(var i=0;i<sampleCount();++i){
		var pos = new Geometry.Vec3( Rand.uniform(bb.getMinX(),bb.getMaxX()),Rand.uniform(bb.getMinY(),bb.getMaxY()), Rand.uniform(bb.getMinZ(),bb.getMaxZ()));
		
		var cValue = c.getValueAtPosition(pos)[0];
		var realValue = evaluator.cubeMeasure( PADrend.getCurrentScene(), pos)[0];

		++row;
		t.set(0,row,cValue);
		t.set(1,row,realValue);
		t.set(2,row,cValue-realValue);
		t.set(3,row,(cValue-realValue).abs());
		outln(i,"\t",pos,"\t",cValue,"\t",realValue);
		
		if(PADrend.SystemUI.checkForKey()){
			PADrend.message( "Break!");
			break;
		}
		
		if( (i%10)==0 )
			PADrend.SystemUI.swapBuffers();
	}
	var f = formatFilename(filename());
	PADrend.message( "Saving to "+f);
	Util.saveFile( f,t.getString(","));
	PADrend.message("done.");
};
static measureDirectional = fn(){
	var GASPManager = Std.require('SceneAnalyzer/GlobalGASPManager');

	var c = GASPManager.getSelectedGASP();
	var evaluator = Std.require('Evaluator/EvaluatorManager').getSelectedEvaluator();
	var bb = c.getRootNode().getBoundingBox();

	var t = new Table;
	var row = 0;
	t.set(0,row,"interpolatedValue");
	t.set(1,row,"realValue");
	t.set(2,row,"maxValue");

	var camera = PADrend.getActiveCamera();
	var revoce = new Std.MultiProcedure;
	revoce += [camera.getRelTransformationSRT()] => camera->camera.setRelTransformation;

	outln("!!!!! Set Cubic Viewport with 90 degree!!!!!");
	
	outln("Evaluator angle: ",evaluator.cameraAngle());
	outln("Evaluator resolution: ",evaluator.measurementResolution);

	for(var i=0;i<sampleCount();++i){
		++row;

		var pos = new Geometry.Vec3( Rand.uniform(bb.getMinX(),bb.getMaxX()),Rand.uniform(bb.getMinY(),bb.getMaxY()), Rand.uniform(bb.getMinZ(),bb.getMaxZ()));

		var dir;
		var up;
		do{
			dir = new Geometry.Vec3( Rand.uniform(-1.0,1.0),Rand.uniform(-1.0,1.0),Rand.uniform(-1.0,1.0));
//			up = new Geometry.Vec3( Rand.uniform(-1.0,1.0),Rand.uniform(-1.0,1.0),Rand.uniform(-1.0,1.0));
			up = new Geometry.Vec3( 0,1,0 );
			
		}while( dir.dot(up).abs()<0.5 );
		
		camera.setWorldTransformation(new Geometry.SRT(pos,dir,up));

		var maxValue = c.getValueAtPosition(pos).max();
		var interpolatedValue = c.getDirectionalValue(camera,evaluator.cameraAngle());
		var realValue = evaluator.singleMeasure(PADrend.getCurrentScene(),camera)[0];
		t.set(0, row, interpolatedValue);
		t.set(1, row, realValue );
		t.set(2, row, maxValue);
		
		outln(i,"\t",pos,dir,"\t",interpolatedValue,"\t",realValue,"\t",maxValue);
		
		if(PADrend.SystemUI.checkForKey()){
			PADrend.message( "Break!");
			break;
		}
		
		if( (i%10)==0 )
			PADrend.SystemUI.swapBuffers();
	}
	revoce();
	
	var f = formatFilename(filename());
	PADrend.message( "Saving to "+f);
	Util.saveFile( f,t.getString(","));
	PADrend.message("done.");
};


//Evaluator.singleMeasure ::= fn( MinSG.Node scene, MinSG.AbstractCameraNode cam){
//	var viewport = new Geometry.Rect(0,0, this.measurementResolution.x(), this.measurementResolution.y());
//
//	var measurementCamera = cam.clone();
//	measurementCamera.setViewport(viewport);
//	measurementCamera.applyVerticalAngle( this.cameraAngle()

plugin.init @(override) := fn(){
    Util.registerExtension('PADrend_Init',fn(){
		gui.registerComponentProvider('SceneAnalyzer_Tabs.90_QualityAnalyzer',fn(){
			return {
				GUI.TYPE : GUI.TYPE_TAB,
				GUI.LABEL : "Q-Anaylsis",
				GUI.TAB_CONTENT : {
					GUI.TYPE : GUI.TYPE_PANEL,
					GUI.CONTENTS : [
						{
							GUI.TYPE : GUI.TYPE_FILE,
							GUI.LABEL : "File",
							GUI.DATA_WRAPPER : filename,
							GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
						},
						GUI.NEXT_ROW,
						{
							GUI.TYPE : GUI.TYPE_NUMBER,
							GUI.LABEL : "sampleCount",
							GUI.DATA_WRAPPER : sampleCount,
							GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
						},
						GUI.NEXT_ROW,
						{
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "measure singleValue",
							GUI.ON_CLICK : measure,
							GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
							GUI.TOOLTIP : "Output:  [cValue, realValue, absDiff] \nfor #sampleCount random positions"
						},
						GUI.NEXT_ROW,
						{
							GUI.TYPE : GUI.TYPE_BUTTON,
							GUI.LABEL : "measure directional",
							GUI.ON_CLICK : measureDirectional,
							GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
							GUI.TOOLTIP : "Output:  [interpolatedValue, realValue, maxValue] \nfor #sampleCount random positions and directions"
						},
						GUI.NEXT_ROW,
					]
				}
			};
		});
	});
    return true;
};
// ---------------------------------------------------------
return plugin;
