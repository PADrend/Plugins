/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2016 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

//! MinSG.SurfelRenderer ---|> NodeRendererState
MinSG.ScriptedSurfelRenderer3 := new Type( MinSG.ScriptedNodeRendererState ); 

static Renderer = MinSG.ScriptedSurfelRenderer3;
Renderer._printableName @(override) ::= $SurfelRenderer3;

registerExtension( 'NodeEditor_QueryAvailableStates' , Renderer->fn(states){
	if(MinSG.ScriptedSurfelRenderer3!=this)
		return Extension.REMOVE_EXTENSION;
	
	states[ "[scripted] "+_printableName ] = fn(){return new Renderer;};
});

Renderer.targetCount @(init) := fn(){ return new Std.DataWrapper(10000); };
Renderer.targetPointSize @(init) := fn(){ return new Std.DataWrapper(3); };
Renderer.useTargetPointSize @(init) := fn(){ return new Std.DataWrapper(true); };
Renderer.backfacingFactor @(init) := fn(){ return new Std.DataWrapper(2); };

Renderer._constructor ::= fn()@(super(MinSG.FrameContext.DEFAULT_CHANNEL)){ };
	
Renderer.displayNode @(override) ::= fn(node,params){
	var surfels = MinSG.BlueSurfels.locateSurfels(node);
	if(surfels){
		if(!node.isSet($getSurfelCountForDistance) || !node.isSet($getSurfelDistanceForCount)){
			var bsg = new MinSG.BlueSurfels.SurfelGenerator;
			var d_1000 = bsg.getMedianOfNthClosestNeighbours(surfels,1000,2);			
			node.getSurfelCountForDistance := [d_1000]=>fn(d_1000,d_n){
				return 1000*d_1000*d_1000/(d_n*d_n);
			};
			node.getSurfelDistanceForCount := [d_1000]=>fn(d_1000,s){
				return d_1000 * (1000/s).sqrt();
			};
		}
		
		var meterPerPixel;
		{
			var centerWorld = node.localPosToWorldPos( node.getBB().getCenter() );
			var oneMeterVector = frameContext.getCamera().localDirToWorldDir( [1,0,0] ).normalize()*0.1;
			var screenPos1 = frameContext.convertWorldPosToScreenPos(centerWorld);
			var screenPos2 = frameContext.convertWorldPosToScreenPos(centerWorld+oneMeterVector);
			var d = screenPos1.distance(screenPos2)*10;
			var nodeScale = node.getWorldTransformationSRT().getScale();
			meterPerPixel = 1/(d!=0?d:1) / nodeScale;
		}
	
		var mesh = surfels;
		var maxCount = mesh.isUsingIndexData() ?  mesh.getIndexCount() : mesh.getVertexCount();
		
		var count = 0;
		var pSize = 1;
		var meterPerSurfel;
		if(this.useTargetPointSize()) {
			pSize = this.targetPointSize();
			meterPerSurfel = meterPerPixel*pSize/this.backfacingFactor();
			count = node.getSurfelCountForDistance(meterPerSurfel);
		} else {
			count = this.targetCount();
			pSize = (node.getSurfelDistanceForCount(count) / meterPerPixel * this.backfacingFactor()).clamp(1,32);
			meterPerSurfel = meterPerPixel*pSize/this.backfacingFactor();
		}
		
		var renderOriginal = count>maxCount && node.getSurfelDistanceForCount(maxCount) > meterPerSurfel;
		var surfelCount = (count>maxCount ? 2*maxCount-count : count).clamp(0,maxCount);

		if(surfelCount>0){
			renderingContext.setGlobalUniform(new Rendering.Uniform('renderSurfels',  Rendering.Uniform.BOOL,[true]));
			renderingContext.pushAndSetPointParameters(new Rendering.PointParameters(pSize));
			renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
			renderingContext.multMatrix_modelToCamera(node.getWorldTransformationMatrix());
			
			frameContext.displayMesh(mesh,	0, surfelCount );
			renderingContext.popMatrix_modelToCamera();
			renderingContext.popPointParameters();			
			renderingContext.setGlobalUniform(new Rendering.Uniform('renderSurfels',  Rendering.Uniform.BOOL,[false]));
		}
		return renderOriginal ? MinSG.FrameContext.PASS_ON : MinSG.FrameContext.NODE_HANDLED;
	}
	return MinSG.FrameContext.PASS_ON;
};

NodeEditor.registerConfigPanelProvider( Renderer, fn(renderer, panel){

    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.RANGE : [1000,40000],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.LABEL : "Target Count",
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,2,0],
		GUI.DATA_WRAPPER : renderer.targetCount,
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.RANGE : [1,32],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.LABEL : "Target Point Size",
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,2,0],
		GUI.DATA_WRAPPER : renderer.targetPointSize,
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Use Point Size",
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,2,0],
		GUI.DATA_WRAPPER : renderer.useTargetPointSize,
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.RANGE : [1,5],
		GUI.RANGE_STEP_SIZE : 0.1,
		GUI.LABEL : "Backfacing Factor",
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,2,0],
		GUI.DATA_WRAPPER : renderer.backfacingFactor,
    };
    panel++;
});



Std.module.on( 'LibMinSGExt/ScriptedStateImportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(description){	
		print_r(description);
		var state = new Renderer;
		if(	description['targetCount'] )	state.targetCount(description['targetCount']);
		if(	description['targetPointSize'] )	state.targetPointSize(description['targetPointSize']);
		if(	description['useTargetPointSize'] )	state.useTargetPointSize(description['useTargetPointSize']);
		if(	description['backfacingFactor'] )	state.backfacingFactor(description['backfacingFactor']);
		return state;
	};
});


Std.module.on( 'LibMinSGExt/ScriptedStateExportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(state,description){	
		description['targetCount'] = state.targetCount();
		description['targetPointSize'] = state.targetPointSize();
		description['useTargetPointSize'] = state.useTargetPointSize();
		description['backfacingFactor'] = state.backfacingFactor();
	};
});
