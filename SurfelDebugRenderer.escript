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
			var medianCount = [1000, maxCount].min();
			var medianDist = MinSG.BlueSurfels.getMedianOfNthClosestNeighbours(surfels, medianCount, 2);
			var mpp = MinSG.BlueSurfels.getMeterPerPixel(PADrend.getActiveCamera(), node);
			var surface = medianCount * medianDist * medianDist;
			var prefix = end() * maxCount;
			var radius = (surface / prefix).sqrt();
			pointSize(MinSG.BlueSurfels.radiusToSize(radius, mpp));
		}		
		
		if(prefixToCover) {
			prefixToCover = false;
			var medianCount = [1000, maxCount].min();
			var medianDist = MinSG.BlueSurfels.getMedianOfNthClosestNeighbours(surfels, medianCount, 2);
			var mpp = MinSG.BlueSurfels.getMeterPerPixel(PADrend.getActiveCamera(), node);
			var surface = medianCount * medianDist * medianDist;
			var radius = MinSG.BlueSurfels.sizeToRadius(pointSize(), mpp);
			var prefix = [maxCount, surface / (radius * radius)].min();
			end(prefix/maxCount);
		}		
		
		var first = [start(),0.0].max() * maxCount;
		first = [first,maxCount].min();
		var count = [[end()-start(),0.0].max(),1.0].min() * maxCount;		
		
		
		renderingContext.pushAndSetPointParameters(new Rendering.PointParameters(pointSize()));
		renderingContext.setGlobalUniform(new Rendering.Uniform('renderSurfels',  Rendering.Uniform.BOOL,[true]));
		
		frameContext.displayMesh(surfels, first, count);
		renderingContext.popPointParameters();
		
		renderingContext.setGlobalUniform(new Rendering.Uniform('renderSurfels',  Rendering.Uniform.BOOL,[false]));
		return MinSG.STATE_SKIP_RENDERING;	
	}
	return MinSG.STATE_OK;
};

NodeEditor.registerConfigPanelProvider( Renderer, fn(renderer, panel){
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Start",
		GUI.DATA_WRAPPER : renderer.start,
		GUI.RANGE : [0,0],
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "End",
		GUI.DATA_WRAPPER : renderer.end,
		GUI.RANGE : [0,1],
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