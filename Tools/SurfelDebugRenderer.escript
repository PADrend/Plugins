/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014-2018 Sascha Brandt <myeti@mail.uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static Utils = Std.module("BlueSurfels/Utils");

static Renderer = new Type( MinSG.ScriptedState );
Renderer._printableName @(override) ::= $SurfelDebugRenderer;


registerExtension( 'NodeEditor_QueryAvailableStates' , Renderer->fn(states){
	if(Renderer!=this)
		return Extension.REMOVE_EXTENSION;
	
	states[ "[scripted] "+_printableName ] = this->fn(){return new this();};
});

Renderer.start @(init) :=  fn(){	return new Std.DataWrapper(0);	};
Renderer.end @(init) := fn(){	return new Std.DataWrapper(1);	};
Renderer.pointSize @(init) := fn(){	return new Std.DataWrapper(1.0);	};
Renderer.sizeToCover := false;
Renderer.prefixToCover := false;

Renderer.doEnableState @(override) ::= fn(node,params){
	
	var surfels = Utils.locateSurfels(node);
	
	if( surfels ){
		var maxCount = surfels.isUsingIndexData() ?  surfels.getIndexCount() : surfels.getVertexCount();
	
		if(sizeToCover) {
			sizeToCover = false;
	    var packing = MinSG.BlueSurfels.computeSurfelPacking(surfels);
			var dp = MinSG.BlueSurfels.computeRelPixelSize(PADrend.getActiveCamera(), node);
			var prefix = end() * maxCount;
			var radius = MinSG.BlueSurfels.getRadiusForPrefix(prefix, packing);
			pointSize(MinSG.BlueSurfels.radiusToSize(radius, dp));
			outln("Packing: ", packing);
			outln("Rel. Pixel Size: ", dp);
			outln("Prefix: ", prefix);
			outln("Radius: ", radius);
			outln("Point Size: ", pointSize());
		}		
		
		if(prefixToCover) {
			prefixToCover = false;
	    var packing = MinSG.BlueSurfels.computeSurfelPacking(surfels);
			var dp = MinSG.BlueSurfels.computeRelPixelSize(PADrend.getActiveCamera(), node);
			var radius = MinSG.BlueSurfels.sizeToRadius(pointSize(), dp);
			var prefix = [maxCount, MinSG.BlueSurfels.getPrefixForRadius(radius, packing)].min();
			end(prefix/maxCount);
			outln("Packing: ", packing);
			outln("Rel. Pixel Size: ", dp);
			outln("Prefix: ", prefix);
			outln("Radius: ", radius);
			outln("Point Size: ", pointSize());
		}		
		
		var first = [start(),0.0].max() * maxCount;
		first = [first,maxCount].min();
		var count = [[end()-start(),0.0].max(),1.0].min() * maxCount;		
				
		renderingContext.pushAndSetPointParameters(new Rendering.PointParameters(pointSize()));
		renderingContext.setGlobalUniform(new Rendering.Uniform('renderSurfels',  Rendering.Uniform.BOOL,[true]));
		renderingContext.pushAndSetColorMaterial(new Util.Color4f(1,0,0));
		
		frameContext.displayMesh(surfels, first, count);
		renderingContext.popPointParameters();
		
		renderingContext.popMaterial();
		renderingContext.setGlobalUniform(new Rendering.Uniform('renderSurfels',  Rendering.Uniform.BOOL,[false]));
		//return MinSG.STATE_SKIP_RENDERING;	
	}
	
	renderingContext.pushAndSetColorMaterial(new Util.Color4f(0.4,0.4,0.4));
	renderingContext.pushAndSetPolygonOffset(0.9, 0);
	return MinSG.STATE_OK;
};

Renderer.doDisableState @(override) ::= fn(node,params){
	renderingContext.popMaterial();
	renderingContext.popPolygonOffset();
};

NodeEditor.registerConfigPanelProvider( Renderer, fn(renderer, panel) {
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Start",
		GUI.DATA_WRAPPER : renderer.start,
		GUI.RANGE : [0,1],
		GUI.RANGE_STEP_SIZE : 0.01,
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "End",
		GUI.DATA_WRAPPER : renderer.end,
		GUI.RANGE : [0,1],
		GUI.RANGE_STEP_SIZE : 0.01,
    };
    panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Cover",
		GUI.ON_CLICK : renderer->fn() {
				this.prefixToCover = true;
			},
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "PointSize",
		GUI.DATA_WRAPPER : renderer.pointSize,
		GUI.RANGE : [1,128]
    };
    panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Cover",
		GUI.ON_CLICK : renderer->fn() {
				this.sizeToCover = true;
			},
    };
    panel++;

});

Std.module.on( 'LibMinSGExt/ScriptedStateImportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(description){	
		print_r(description);
		var state = new Renderer;
		if(	description['start'] )	state.start(0+description['start']);
		if(	description['end'] )	state.end(0+description['end']);
		if(	description['pointSize'] )	state.pointSize(0+description['pointSize']);
		return state;
	};
});


Std.module.on( 'LibMinSGExt/ScriptedStateExportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(state,description){	
		description['start'] = state.start();
		description['end'] = state.end();
		description['pointSize'] = state.pointSize();
	};
});