/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*!
 *	[Plugin:Evaluator] Evaluator/Evaluator.escript
 *	EScript extensions for MinSG.Evaluator
 */

// -----------------------------------------------------------------------------------------------------------------------------

// MinSG.Evaluator.name @(init) := fn() { return new Std.DataWrapper(""); };

/// (static)
MinSG.Evaluator.defaultMeasurementResolutionExpressions ::= [
	"[1024,1024]",
	"[wWidth, wHeight]",
	"[wWidth, wHeight].min()",
	"[256,256]"
];

// -----------------------------------------------------
MinSG.Evaluator.getDirectionPresets ::= fn(){
	static presets;
	@(once){
		presets = new Map;

		foreach({ 
					"cube" : Rendering.createCube(),
					"tetrahderon" : Rendering.createTetrahedron(),
					"octrahedron" : Rendering.createOctahedron(),
					"icosahedron" : Rendering.createIcosahedron(),
					"dodecahedron" : Rendering.createDodecahedron()
				}	as var name, var mesh){
			var arr = [];
			var posAcc = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);
			var numVertives = mesh.getVertexCount();
			for(var i = 0; i<numVertives; ++i){
				var dir = posAcc.getPosition(i).normalize();
				var up = new Geometry.Vec3(0,1,0);
				if( dir.dot(up).abs()>0.9 )
					up = new Geometry.Vec3(0,0,1);
				up = dir.cross(up).cross(dir);
				arr += [dir,up];
			}
			presets[ name ] = arr;
		}
	}
	return presets;
};

/*!	Called once upon registration. */
MinSG.Evaluator.init ::= fn() {
	this.cameraAngle := DataWrapper.createFromConfig(PADrend.configCache, 'MinSG.Evaluator.cameraAngle', 120);
	this.measurementResolution := void;
	this.measurementResolutionExpression := void;
	this.directionPresetName := DataWrapper.createFromConfig(PADrend.configCache, 'MinSG.Evaluator.directions', 'octrahedron');
	this.directionPresetName.onDataChanged += this->update;

	this.name := new Std.DataWrapper(this.createName());
	setMeasurementResolutionExpression(MinSG.Evaluator.defaultMeasurementResolutionExpressions[0]);
	
	
};


/**
 * Return a string containing the name of the type of the evaluator. The string
 * has to be different for different types of evaluators. Therefore, the
 * function has to be overridden in classes that inherit ScriptedEvaluator.
 */
MinSG.Evaluator.getEvaluatorTypeName ::=	fn() {	return this.getTypeName();	};

MinSG.Evaluator.getCameraAngle ::= 			fn() {	return this.cameraAngle();	};

/*!
 * Parse the expression that describes the resolution used for the measurement.
 * 
 * @param resExp A string which evaluates to
 * - a single value (e.g. "200" or "[wWidth,wHeight].min()"), or
 * - an array with two values (e.g. "[800, 480]").
 */
MinSG.Evaluator.setMeasurementResolutionExpression ::= fn(String resExp) {
	this.measurementResolutionExpression = resExp;
	try {
		
		var wHeight = renderingContext.getWindowHeight();
		var wWidth = renderingContext.getWindowWidth();
		
		var newRes = eval("fn(wHeight,wWidth){ return ("+ measurementResolutionExpression + "); };")(wHeight,wWidth);
		if(newRes ---|> Number) {
			this.measurementResolution = new Geometry.Vec2( newRes, newRes);
		} else if(newRes ---|> Array && newRes.size() == 2) {
			this.measurementResolution = new Geometry.Vec2( newRes[0], newRes[1]);
		} else {
			Runtime.warn("Invalid measurement resolution (must be a Number or an Array with two entries).");
		}
	} catch(e) {
		Runtime.warn("Cannot parse measurement resolution expression.\n" + e);
	}
};

//!	MinSG.Evaluator ---o
MinSG.Evaluator.createName ::= fn(){
	return this.getEvaluatorTypeName()+" ("+this.directionPresetName()+", "+(this.getMode()==MinSG.Evaluator.DIRECTION_VALUES?"directional":"single")+")";
};

//!	MinSG.Evaluator ---o
MinSG.Evaluator.update ::= fn(...) {
	this.name(this.createName());
	executeExtensions('Evaluator_OnEvaluatorDescriptionChanged', this, this.name());
};

static CONFIG_PREFIX = 'Evaluator_Config_';

Util.registerExtension('PADrend_Init', fn(){

	gui.registerComponentProvider( CONFIG_PREFIX + MinSG.Evaluator.toString(), fn(evaluator){
		var resultDataWrapper = new Std.DataWrapper("");
		return [
			{
				GUI.TYPE				:	GUI.TYPE_LABEL,
				GUI.LABEL				:	"[name]",
				GUI.FONT				:	GUI.FONT_ID_HEADING,
				GUI.DATA_WRAPPER		:	evaluator.name
			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE				:	GUI.TYPE_TEXT,
				GUI.LABEL				:	"Measurement resolution:",
				GUI.OPTIONS				:	MinSG.Evaluator.defaultMeasurementResolutionExpressions,
				GUI.ON_DATA_CHANGED		:	evaluator -> fn(data) {
												this.setMeasurementResolutionExpression(data);
												this.update();
											},
				GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE				:	GUI.TYPE_TEXT,
				GUI.LABEL				:	"Measurement aperture:",
				GUI.OPTIONS				:	[120, 90, 60],
				GUI.DATA_WRAPPER		:	evaluator.cameraAngle,
				GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE				:	GUI.TYPE_SELECT,
				GUI.LABEL				:	"Directions:",
				GUI.OPTIONS				:	{
					var dirOptions = [];
					foreach(evaluator.getDirectionPresets() as var name,var dirs)
						dirOptions += [name , name+ " ("+dirs.count()+")"];
					dirOptions;
				},	
				GUI.DATA_WRAPPER		:	evaluator.directionPresetName,
				GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE				:	GUI.TYPE_BOOL,
				GUI.LABEL				:	"Direction-dependant",
				GUI.ON_DATA_CHANGED		:	evaluator -> fn(data) {
												this.setMode(data ? MinSG.Evaluator.DIRECTION_VALUES : MinSG.Evaluator.SINGLE_VALUE);
												this.update();
											},
				GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
			},
			GUI.NEXT_ROW,
			'----',
			GUI.NEXT_ROW,
			"*Preview*",
			GUI.NEXT_ROW,
			{
				GUI.TYPE				:	GUI.TYPE_TEXT,
				GUI.LABEL				:	"Result:",
				GUI.TOOLTIP				:	"Output of the evaluator's result.",
				GUI.DATA_WRAPPER		:	resultDataWrapper,
				GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
				GUI.FLAGS				:	GUI.LOCKED
			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE				:	GUI.TYPE_BUTTON,
				GUI.LABEL				:	"Measure",
				GUI.TOOLTIP				:	"Execute a measurement with the current evalutor and settings.",
				GUI.ON_CLICK			:	[evaluator, resultDataWrapper] => fn(evaluator, resultOutput) {
											var results = evaluator.singleMeasure( PADrend.getCurrentScene(), PADrend.getActiveCamera()); 
											if(results.empty()) {
												resultOutput("(empty)");
											} else {
												resultOutput(results.front().toString());
											}
										},
				GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
			},
			GUI.NEXT_ROW,
			'----',
			GUI.NEXT_ROW
		];
	
	});

});



/*!	MinSG.Evaluator ---o	*/
MinSG.Evaluator.createConfigPanel ::= fn(){
	var panel = gui.create({
		GUI.TYPE				:	GUI.TYPE_PANEL,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});
	for( var obj = this; obj; obj = obj.isA(Type) ? obj.getBaseType() : obj.getType()){
		var entries = gui.createComponents( {	
			GUI.TYPE 		: 	GUI.TYPE_COMPONENTS, 
			GUI.PROVIDER	:	CONFIG_PREFIX + obj.toString(), 
			GUI.CONTEXT		:	this
		});
		if(!entries.empty()){
			panel.append(entries);
			break;
		}
	}else{
		panel += "?????";
	}

	return panel;
};


static getFBOAndTexture = fn(Geometry.Vec2 resolution){
	static r2;
	static fbo;
	static texture;
	if(resolution != r2){
		fbo = new Rendering.FBO;
		texture = Rendering.createStdTexture(resolution.x(),resolution.y(),false);
		fbo.attachColorTexture( renderingContext, texture );
		fbo.attachDepthTexture( renderingContext, Rendering.createDepthTexture(resolution.x(),resolution.y()));
		r2 = resolution.clone();
		outln( "Evaluator: Recreate FBO (",fbo.getStatusMessage(renderingContext),")" );
	}
	return [fbo,texture];
	
};

/*!	Array Evaluator.cubeMeasure(...)
	\note the camera needs to have the right angle
*/
MinSG.Evaluator.cubeMeasure::=fn( 	MinSG.Node sceneNode, Geometry.Vec3 position) {
	[var fbo,var texture] = getFBOAndTexture(  this.measurementResolution );

	var cam = new MinSG.CameraNode;
	cam.setNearFar(frameContext.getCamera().getNearPlane(), frameContext.getCamera().getFarPlane());
	cam.applyVerticalAngle(cameraAngle());
	
	var viewport = new Geometry.Rect(0,0, this.measurementResolution.x(),this.measurementResolution.y());
	cam.setViewport( viewport );

	this.beginMeasure();
	
	var directions = this.getDirectionPresets()[ this.directionPresetName() ];
	assert( directions&&!directions.empty(), "MinSG.Evaluator.cubeMeasure: invalid directionPresetName '"+directionPresetName()+"'" );

	var screenX = 0;
	var screenDX = renderingContext.getWindowWidth() / directions.count() ;
	var screenY = (renderingContext.getWindowHeight()-screenDX) * 0.5;

	foreach( directions as var dirAndUp ){
		cam.setRelTransformation(  new Geometry.SRT(position,dirAndUp[0],dirAndUp[1] ));
		frameContext.pushCamera();
		frameContext.setCamera(cam);

		renderingContext.pushAndSetFBO( fbo );
		this.measure(frameContext,sceneNode,viewport);
		renderingContext.popFBO( );

		frameContext.popCamera();

		Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(screenX,screenY,screenDX-1,screenDX-1) ,[texture],[new Geometry.Rect(0,0,1,1)]);
		screenX +=  screenDX;
	}

	this.endMeasure(frameContext);

	return this.getResults();
};

MinSG.Evaluator.singleMeasure ::= fn( MinSG.Node scene, MinSG.AbstractCameraNode cam){
	var viewport = new Geometry.Rect(0,0, this.measurementResolution.x(), this.measurementResolution.y());

	var measurementCamera = cam.clone();
	measurementCamera.setViewport(viewport);
	measurementCamera.applyVerticalAngle( this.cameraAngle());
	measurementCamera.setRelTransformation(cam.getWorldTransformationMatrix());

	frameContext.pushCamera();
	frameContext.setCamera(measurementCamera);

	this.beginMeasure();
	this.measure(frameContext, PADrend.getCurrentScene(), viewport);
	this.endMeasure(frameContext);

	frameContext.popCamera();

	return this.getResults();
};

/*!	MinSG.Evaluator ---o
 *	Calculate the value of the region _Node_ based on the samples saved in the node.
 *	The default is to take the direction-wise average.
 *	\return ResultObject:
 *		valueVec 		Array of averaged values for each direction
 *		minVec 			Array of minimum values for each direction
 *		maxVec 			Array of maximum values for each direction
 *		diffRatioVec 	Array of ratios of difference between min and max to the maximum for each direction
 */
MinSG.Evaluator.mergeValues::=fn(Collection samples){
	var result=new ExtObject;

	// init attributes needed for quality calculations
	var maxVec=[];
	var minVec=[];
	var diffRatioVec=[];
	var valueVec=[];

	result.maxVec:=maxVec;
	result.minVec:=minVec;
	result.diffRatioVec:=diffRatioVec;
	result.valueVec:=valueVec;

	if(samples.count()==0){
		maxVec+=0;
		minVec+=0;
		diffRatioVec+=0;
		valueVec+=0;
		return result;
	}
//PADrend.serialize(EvaluatorManager.getSelectedEvaluator());
	
	var first=true;
	// sum up samples and extract min and max
	foreach(samples as var sample){
		if(first){
			// init data
			first = false;
			maxVec.append(sample);
			minVec.append(sample);
			var numDirections=sample.count();
			for(var i=0;i<numDirections;++i)
				valueVec+=0;
		}
		foreach(sample as var direction,var value){
			valueVec[direction]+=value;
			if(value > maxVec[direction]){
				maxVec[direction]=value;
			}else if(value < minVec[direction]){
				minVec[direction]=value;
			}
		}
	}

	// calculate average
	foreach(valueVec as var direction,var summedValue){
		valueVec[direction]/=samples.count();
	}
	// calculate diffs
	foreach(maxVec as var direction,var maxValue){
		diffRatioVec[direction] = maxValue!=0 ? (maxValue - minVec[direction]) / maxValue : 0;
	}

	return result;
};

PADrend.Serialization.registerType( MinSG.Evaluator, "MinSG.Evaluator")
	.enableIdentityTracking()
	.addDescriber( fn(ctxt,MinSG.Evaluator obj,Map d){
		d['attr'] = ctxt.getAttributeDescription(obj);
	})
	.addInitializer( fn(ctxt,MinSG.Evaluator obj,Map d){
		obj.init(); // recreate camera
		ctxt.applyAttributesFromDescription(obj,d['attr']); // restore attributes (except the __camera)
	});
