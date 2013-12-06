/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2013 Claudius Jähn <claudius@uni-paderborn.de>
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

// MinSG.Evaluator.name @(init) := fn() { return DataWrapper.createFromValue(""); };

/// (static)
MinSG.Evaluator.defaultMeasurementResolutionExpressions ::= [
	"[wWidth, wHeight]",
	"[wWidth / 4, wWidth / 4]",
	"[wWidth, wHeight].min()",
	"200",
	"[800, 480]"
];

// -----------------------------------------------------

/*!	Called once upon registration. */
MinSG.Evaluator.init ::= fn() {
	this.__camera := new MinSG.CameraNode();
	this.cameraAngle := DataWrapper.createFromConfig(PADrend.configCache, 'MinSG.Evaluator.cameraAngle', 120);
	this.cameraAngle.onDataChanged += this -> fn(...) { this.refreshCamera(); };
	this.measurementResolution := void;
	this.measurementResolutionExpression := void;
	this.name := DataWrapper.createFromValue(this.createName());
	setMeasurementResolutionExpression(MinSG.Evaluator.defaultMeasurementResolutionExpressions[0]);
};


/**
 * Return a string containing the name of the type of the evaluator. The string
 * has to be different for different types of evaluators. Therefore, the
 * function has to be overridden in classes that inherit ScriptedEvaluator.
 */
MinSG.Evaluator.getEvaluatorTypeName ::= fn() {
	return this.getTypeName();
};

MinSG.Evaluator.getCamera ::= fn(){
	return this.__camera;
};


MinSG.Evaluator.getCameraAngle ::= fn() {
	return this.cameraAngle();
};

/*! Setup camera used by the Evaluator.
	- Create it if it does not yet exist.
	- Set the near and far plane according to the global camera
	- Set the angle
*/
MinSG.Evaluator.refreshCamera ::= fn() {
	this.__camera.setNearFar(GLOBALS.camera.getNearPlane(),GLOBALS.camera.getFarPlane());
	this.__camera.applyVerticalAngle(cameraAngle());
};

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
			this.measurementResolution = new Geometry.Rect(0, 0, newRes, newRes);
		} else if(newRes ---|> Array && newRes.size() == 2) {
			this.measurementResolution = new Geometry.Rect(0, 0, newRes[0], newRes[1]);
		} else {
			Runtime.warn("Invalid measurement resolution (must be a Number or an Array with two entries).");
		}
	} catch(e) {
		Runtime.warn("Cannot parse measurement resolution expression.\n" + e);
	}
};

/*!	MinSG.Evaluator ---o	*/
MinSG.Evaluator.createName ::= fn(){
    return this.getEvaluatorTypeName()+" ("+(this.getMode()==MinSG.Evaluator.DIRECTION_VALUES?"directional":"single")+")";
};

/*!	MinSG.Evaluator ---o	*/
MinSG.Evaluator.update ::= fn() {
    this.name(this.createName());
    executeExtensions('Evaluator_OnEvaluatorDescriptionChanged', this, this.name());
	this.refreshCamera();
};

/*!	MinSG.Evaluator ---o	*/
MinSG.Evaluator.createConfigPanel ::= fn(){
    var panel = gui.create({
		GUI.TYPE				:	GUI.TYPE_PANEL,
		GUI.SIZE				:	GUI.SIZE_MAXIMIZE
	});

	var heading = gui.create({
		GUI.TYPE				:	GUI.TYPE_LABEL,
		GUI.LABEL				:	this.name(),
		GUI.FONT				:	GUI.FONT_ID_HEADING
	});
	this.name.onDataChanged += heading -> heading.setText;
	panel += heading;
	panel++;

	panel += {
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Measurement resolution:",
		GUI.OPTIONS				:	MinSG.Evaluator.defaultMeasurementResolutionExpressions,
		GUI.ON_DATA_CHANGED		:	this -> fn(data) {
										this.setMeasurementResolutionExpression(data);
										this.update();
									},
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Measurement aperture:",
		GUI.OPTIONS				:	[120, 90, 60],
		GUI.DATA_WRAPPER		:	this.cameraAngle,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += {
		GUI.TYPE				:	GUI.TYPE_BOOL,
		GUI.LABEL				:	"Direction-dependant",
		GUI.ON_DATA_CHANGED		:	this -> fn(data) {
										this.setMode(data ? MinSG.Evaluator.DIRECTION_VALUES : MinSG.Evaluator.SINGLE_VALUE);
										this.update();
									},
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += "----";
	panel++;

	panel += "*Preview*";
	panel++;

	var resultDataWrapper = DataWrapper.createFromValue("");
	panel += {
		GUI.TYPE				:	GUI.TYPE_TEXT,
		GUI.LABEL				:	"Result:",
		GUI.TOOLTIP				:	"Output of the evaluator's result.",
		GUI.DATA_WRAPPER		:	resultDataWrapper,
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0],
		GUI.FLAGS				:	GUI.LOCKED
	};
	panel++;

	panel += {
		GUI.TYPE				:	GUI.TYPE_BUTTON,
		GUI.LABEL				:	"Measure",
		GUI.TOOLTIP				:	"Execute a measurement with the current evalutor and settings.",
		GUI.ON_CLICK			:	[this, resultDataWrapper] => fn(MinSG.Evaluator evaluator, DataWrapper resultOutput) {
										var viewport = evaluator.measurementResolution;

										var measurementCamera = PADrend.getActiveCamera().clone();
										measurementCamera.setViewport(viewport);
										measurementCamera.applyVerticalAngle(evaluator.cameraAngle());
										measurementCamera.setMatrix(PADrend.getActiveCamera().getWorldMatrix());

										frameContext.pushCamera();
										frameContext.setCamera(measurementCamera);

										evaluator.beginMeasure();
										evaluator.measure(frameContext, PADrend.getCurrentScene(), viewport);
										evaluator.endMeasure(frameContext);

										frameContext.popCamera();

										var results = evaluator.getResults();
										if(results.empty()) {
											resultOutput("(empty)");
										} else {
											resultOutput(results.front().toString());
										}
									},
		GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;

	panel += "----";
	panel++;

    return panel;
};


/*!	Array Evaluator.cubeMeasure(...)
	\note the camera needs to have the right angle
*/
MinSG.Evaluator.cubeMeasure::=fn( 	MinSG.Node sceneNode, Geometry.Vec3 position, Array directions=[0,1,2,3,4,5]) {

	this.refreshCamera();
	
	var rect = this.measurementResolution.clone();
	var displace = renderingContext.getWindowWidth() >= rect.getWidth() * 4 && renderingContext.getWindowHeight() >= rect.getHeight() * 3;

	var c=this.getCamera();
	c.setRelPosition(position);

	this.beginMeasure();
	var rc=GLOBALS.frameContext;
	rc.pushCamera();

	// left
	if(displace) {
		rect.setY(rect.getY() + rect.getHeight());
	}
	if(directions.contains(0)){
		rc.setCamera(c.setViewport(rect).setRelRotation_rad(Math.PI_2,new Geometry.Vec3(0,1,0)));
		this.measure(rc,sceneNode,rect);
	}

	// front
	if(displace) {
		rect.setX(rect.getX() + rect.getWidth());
	}
	if(directions.contains(1)){
		rc.setCamera(c.setViewport(rect).setRelRotation_rad(0,new Geometry.Vec3(0,0,0)));
		this.measure(rc,sceneNode,rect);
	}

	// right
	if(displace) {
		rect.setX(rect.getX() + rect.getWidth());
	}
	if(directions.contains(2)){
		rc.setCamera(c.setViewport(rect).setRelRotation_rad(Math.PI_2,new Geometry.Vec3(0,-1,0)));
		this.measure(rc,sceneNode,rect);
	}

	// back
	if(displace) {
		rect.setX(rect.getX() + rect.getWidth());
	}
	if(directions.contains(3)){
		rc.setCamera(c.setViewport(rect).setRelRotation_rad(Math.PI,new Geometry.Vec3(0,-1,0)));
		this.measure(rc,sceneNode,rect);
	}

	// bottom
	if(displace) {
		rect.setX(rect.getX() - rect.getWidth() * 2);
		rect.setY(rect.getY() - rect.getHeight());
	}
	if(directions.contains(4)){
		rc.setCamera(c.setViewport(rect).setRelRotation_rad(Math.PI_2,new Geometry.Vec3(-1,0,0)));
		this.measure(rc,sceneNode,rect);
	}

	// top
	if(displace) {
		rect.setY(rect.getY() + rect.getHeight() * 2);
	}
	if(directions.contains(5)){
		rc.setCamera(c.setViewport(rect).setRelRotation_rad(Math.PI_2,new Geometry.Vec3(1,0,0)));
		this.measure(rc,sceneNode,rect);
	}

	this.endMeasure(rc);
	rc.popCamera();

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
	var result=new ExtObject();

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
		diffRatioVec[direction] = maxValue!=0 ? (maxValue - minVec[direction]) / maxValue : void;
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
