/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017 Claudius Jähn <myeti@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

//! MinSG.SurfelRenderer ---|> NodeRendererState
MinSG.StagedSurfelShader := new Type( MinSG.ScriptedState ); 

static Renderer = MinSG.StagedSurfelShader;
Renderer._printableName @(override) ::= $StagedSurfelShader;

registerExtension( 'NodeEditor_QueryAvailableStates' , Renderer->fn(states){
	if(MinSG.StagedSurfelShader!=this)
		return Extension.REMOVE_EXTENSION;	
	states[ "[scripted] "+_printableName ] = fn(){return new Renderer;};
});

Renderer.surfelRendererId @(init) := fn() { return new Std.DataWrapper("SurfelRenderer"); };
Renderer.surfelRenderer := void;

Renderer.shaderStage1Id @(init) := fn() { return new Std.DataWrapper("universal3_surfels.shader"); };
Renderer.shaderStage1 := void;

Renderer.shaderStage2Id @(init) := fn() { return new Std.DataWrapper("universal3_surfelsElliptic.shader"); };
Renderer.shaderStage2 := void;
Renderer.stage2Size @(init) :=  fn(){	return new Std.DataWrapper(2); };

Renderer.shaderStage3Id @(init) := fn() { return new Std.DataWrapper(__DIR__ + "/resources/SurfelGeometry.shader"); };
Renderer.shaderStage3 := void;
Renderer.stage3Size @(init) :=  fn(){	return new Std.DataWrapper(8); };


Renderer._constructor ::= fn() {  
  
  this.oldHideSurfels := false;
  this.oldDeferredSurfels := false;
  
	surfelRendererId.onDataChanged += this->fn(value){
    var sm = PADrend.getResponsibleSceneManager(PADrend.getCurrentScene());
    var renderer = sm.getRegisteredState(value);
    surfelRenderer = renderer ? renderer : void;
	};
	surfelRendererId.forceRefresh();
  
	shaderStage1Id.onDataChanged += this->fn(value){    
  	var renderingShaderState = new MinSG.ShaderState;
  	(renderingShaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME))( value );
  	renderingShaderState.recreateShader( PADrend.getSceneManager() );
    shaderStage1 = renderingShaderState.getShader() ? renderingShaderState.getShader() : void;
	};
	shaderStage1Id.forceRefresh();
  
	shaderStage2Id.onDataChanged += this->fn(value){    
  	var renderingShaderState = new MinSG.ShaderState;
  	(renderingShaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME))( value );
  	renderingShaderState.recreateShader( PADrend.getSceneManager() );
    shaderStage2 = renderingShaderState.getShader() ? renderingShaderState.getShader() : void;
	};
	shaderStage2Id.forceRefresh();
  
	shaderStage3Id.onDataChanged += this->fn(value){    
  	var renderingShaderState = new MinSG.ShaderState;
  	(renderingShaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME))( value );
  	renderingShaderState.recreateShader( PADrend.getSceneManager() );
    shaderStage3 = renderingShaderState.getShader() ? renderingShaderState.getShader() : void;
	};
	shaderStage3Id.forceRefresh();
  
  PADrend.planTask(0, this->fn(...){surfelRendererId.forceRefresh();});
};

Renderer.doEnableState @(override) ::= fn(node,params){
  if(!surfelRenderer)
    return MinSG.STATE_OK;
  
  oldHideSurfels = surfelRenderer.getDebugHideSurfels();
  oldDeferredSurfels = surfelRenderer.getDeferredSurfels();
  surfelRenderer.setDebugHideSurfels(true);
  surfelRenderer.setDeferredSurfels(true);
	return MinSG.STATE_OK;
};

Renderer.doDisableState @(override) ::= fn(node,params){
  if(!surfelRenderer)
    return;
    
  surfelRenderer.setDebugHideSurfels(oldHideSurfels);
  surfelRenderer.setDeferredSurfels(oldDeferredSurfels);
  
  if(shaderStage1) {
    renderingContext.pushAndSetShader(shaderStage1);
  	surfelRenderer.drawSurfels(frameContext, 0, stage2Size()); 
  	renderingContext.popShader();    
  }
  
  if(shaderStage2) {
    renderingContext.pushAndSetShader(shaderStage2);
  	surfelRenderer.drawSurfels(frameContext, stage2Size(), stage3Size()); 
  	renderingContext.popShader();    
  }
  
  if(shaderStage3) {
    renderingContext.pushAndSetShader(shaderStage3);
  	surfelRenderer.drawSurfels(frameContext, stage3Size(), 1024); 
  	renderingContext.popShader();    
  }
};


NodeEditor.registerConfigPanelProvider( Renderer, fn(renderer, panel){
    panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Surfel Renderer",
		GUI.DATA_WRAPPER : renderer.surfelRendererId,
    };
    panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Refresh",
		GUI.ON_CLICK : renderer->fn(){surfelRendererId.forceRefresh();},
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Stage 1 Shader",
		GUI.DATA_WRAPPER : renderer.shaderStage1Id,
    };
    panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Refresh",
		GUI.ON_CLICK : renderer->fn(){shaderStage1Id.forceRefresh();},
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Stage 2 Shader",
		GUI.DATA_WRAPPER : renderer.shaderStage2Id,
    };
    panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Refresh",
		GUI.ON_CLICK : renderer->fn(){shaderStage2Id.forceRefresh();},
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Stage 3 Shader",
		GUI.DATA_WRAPPER : renderer.shaderStage3Id,
    };
    panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Refresh",
		GUI.ON_CLICK : renderer->fn(){shaderStage3Id.forceRefresh();},
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Stage 2 Size",
		GUI.DATA_WRAPPER : renderer.stage2Size,
		GUI.RANGE : [1,128],
		GUI.RANGE_STEP_SIZE : 1,
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "stage 3 Size",
		GUI.DATA_WRAPPER : renderer.stage3Size,
		GUI.RANGE : [1,128],
		GUI.RANGE_STEP_SIZE : 1,
    };
    panel++;
});



Std.module.on( 'LibMinSGExt/ScriptedStateImportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(description){	
		print_r(description);
		var state = new Renderer;
		if(	description['surfelRendererId'] )	state.surfelRendererId(description['surfelRendererId']);
		if(	description['shaderStage1Id'] )	state.shaderStage1Id(description['shaderStage1Id']);
		if(	description['shaderStage2Id'] )	state.shaderStage2Id(description['shaderStage2Id']);
		if(	description['shaderStage3Id'] )	state.shaderStage3Id(description['shaderStage3Id']);
		if(	description['stage2Size'] )			state.stage2Size(0+description['stage2Size']);
		if(	description['stage3Size'] )			state.stage3Size(0+description['stage3Size']);
		return state;
	};
});


Std.module.on( 'LibMinSGExt/ScriptedStateExportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(state,description){	
		description['surfelRendererId'] = state.surfelRendererId();
		description['shaderStage1Id'] = state.shaderStage1Id();
		description['shaderStage2Id'] = state.shaderStage2Id();
		description['shaderStage3Id'] = state.shaderStage3Id();
		description['stage2Size'] = state.stage2Size();
		description['stage3Size'] = state.stage3Size();
	};
});
