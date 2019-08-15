/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014-2019 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static Utils = Std.module("BlueSurfels/Utils");

static Renderer = new Type( MinSG.ScriptedState );
Renderer._printableName @(override) ::= $TextureBombRenderer;

registerExtension( 'NodeEditor_QueryAvailableStates' , Renderer->fn(states){
	if(Renderer!=this)
		return Extension.REMOVE_EXTENSION;
	
	states[ "[scripted] "+_printableName ] = this->fn(){return new this();};
});

Renderer.tile1count @(init) :=  fn(){ return new Std.DataWrapper(100); };
Renderer.tile2count @(init) :=  fn(){ return new Std.DataWrapper(200); };
Renderer.tile3count @(init) :=  fn(){ return new Std.DataWrapper(400); };
Renderer.tile4count @(init) :=  fn(){ return new Std.DataWrapper(800); };
Renderer.tile1size @(init) :=  fn(){ return new Std.DataWrapper(0.08); };
Renderer.tile2size @(init) :=  fn(){ return new Std.DataWrapper(0.04); };
Renderer.tile3size @(init) :=  fn(){ return new Std.DataWrapper(0.02); };
Renderer.tile4size @(init) :=  fn(){ return new Std.DataWrapper(0.01); };
Renderer.bombShader := void;
Renderer.fbo := void;
Renderer.depthTexture := void;
Renderer.tileTexture := void;
Renderer.needsRefresh := true;

Renderer.init ::= fn() {
	// simply colors the underlying object
	this.bombShader = Rendering.Shader.createGeometryFromFile(__DIR__ + "/../resources/shader/TextureBombShader.sfn");
	
	this.fbo = new Rendering.FBO;
	var vp = frameContext.getCamera().getViewport();
	this.depthTexture = Rendering.createDepthTexture(vp.width(), vp.height());
	this.tileTexture = Rendering.createTextureFromFile(__DIR__ + "/../resources/shapes.png");
	//this.colorTexture = Rendering.createStdTexture(vp.width(), vp.height(), false);
	fbo.attachDepthTexture(renderingContext, depthTexture);
	//fbo.attachColorTexture(renderingContext, colorTexture);
	needsRefresh = false;
};

Renderer.doEnableState @(override) ::= fn(node,params) {
	if(needsRefresh)
		init();
	return MinSG.STATE_OK;
};

Renderer.doDisableState @(override) ::= fn(node,params) {		
	renderingContext.pushAndSetFBO(fbo);
	renderingContext.clearScreen(new Util.Color4f(0,0,0));
	var rp = (new MinSG.RenderParam).setFlags(MinSG.USE_WORLD_MATRIX | MinSG.NO_STATES).setRenderingLayers(PADrend.getRenderingLayers());
	frameContext.displayNode(node, rp);
	renderingContext.popFBO();
	
	var surfels = Utils.locateSurfels(node);
	if(surfels) {
		var maxCount = surfels.isUsingIndexData() ?  surfels.getIndexCount() : surfels.getVertexCount();
		var sampleCount = [tile1count()+tile2count()+tile3count()+tile4count(), maxCount].min();
		
		bombShader.setUniform(renderingContext, 'tileOffsets', Rendering.Uniform.VEC4F, [new Geometry.Vec4(tile1count(),tile2count(),tile3count(),tile4count())]);
		bombShader.setUniform(renderingContext, 'tileSizes', Rendering.Uniform.VEC4F, [new Geometry.Vec4(tile1size(),tile2size(),tile3size(),tile4size())]);
		
		renderingContext.pushAndSetShader(bombShader);
		renderingContext.pushAndSetTexture(0, depthTexture);
		renderingContext.pushAndSetTexture(1, tileTexture);
		renderingContext.pushAndSetDepthBuffer(true, false, Rendering.Comparison.ALWAYS);
		renderingContext.pushAndSetBlending(new Rendering.BlendingParameters(Rendering.BlendFunc.SRC_ALPHA, Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA));
		frameContext.displayMesh(surfels, 0, sampleCount);
		renderingContext.popBlending();
		renderingContext.popDepthBuffer();
		renderingContext.popTexture(1);
		renderingContext.popTexture(0);
		renderingContext.popShader();
	}
};

NodeEditor.registerConfigPanelProvider( Renderer, fn(renderer, panel) {
	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "tile1count",
		GUI.DATA_WRAPPER : renderer.tile1count,
		GUI.RANGE : [0,10000],
		GUI.RANGE_STEP_SIZE : 1,
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "tile2count",
		GUI.DATA_WRAPPER : renderer.tile2count,
		GUI.RANGE : [0,10000],
		GUI.RANGE_STEP_SIZE : 1,
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "tile3count",
		GUI.DATA_WRAPPER : renderer.tile3count,
		GUI.RANGE : [0,10000],
		GUI.RANGE_STEP_SIZE : 1,
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "tile4count",
		GUI.DATA_WRAPPER : renderer.tile4count,
		GUI.RANGE : [0,10000],
		GUI.RANGE_STEP_SIZE : 1,
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "tile1size",
		GUI.DATA_WRAPPER : renderer.tile1size,
		GUI.RANGE : [0,1],
		GUI.RANGE_STEP_SIZE : 0.01,
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "tile2size",
		GUI.DATA_WRAPPER : renderer.tile2size,
		GUI.RANGE : [0,1],
		GUI.RANGE_STEP_SIZE : 0.01,
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "tile3size",
		GUI.DATA_WRAPPER : renderer.tile3size,
		GUI.RANGE : [0,1],
		GUI.RANGE_STEP_SIZE : 0.01,
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "tile4size",
		GUI.DATA_WRAPPER : renderer.tile4size,
		GUI.RANGE : [0,1],
		GUI.RANGE_STEP_SIZE : 0.01,
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Refresh",
		GUI.ON_CLICK : renderer->fn() { this.needsRefresh = true; },
	};
});

Std.module.on( 'LibMinSGExt/ScriptedStateImportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(description){	
		print_r(description);
		var state = new Renderer;
		if(	description['tile1count'] )	state.tile1count(0+description['tile1count']);
		if(	description['tile2count'] )	state.tile2count(0+description['tile2count']);
		if(	description['tile3count'] )	state.tile3count(0+description['tile3count']);
		if(	description['tile4count'] )	state.tile4count(0+description['tile4count']);
		if(	description['tile1size'] )	state.tile1size(0+description['tile1size']);
		if(	description['tile2size'] )	state.tile2size(0+description['tile2size']);
		if(	description['tile3size'] )	state.tile3size(0+description['tile3size']);
		if(	description['tile4size'] )	state.tile4size(0+description['tile4size']);
		return state;
	};
});


Std.module.on( 'LibMinSGExt/ScriptedStateExportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(state,description){
		description['tile1count'] = state.tile1count();
		description['tile2count'] = state.tile2count();
		description['tile3count'] = state.tile3count();
		description['tile4count'] = state.tile4count();
		description['tile1size'] = state.tile1size();
		description['tile2size'] = state.tile2size();
		description['tile3size'] = state.tile3size();
		description['tile4size'] = state.tile4size();
	};
});

return Renderer;