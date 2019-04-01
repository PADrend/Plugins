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

Renderer.start @(init) :=  fn(){ return new Std.DataWrapper(0); };
Renderer.end @(init) := fn(){ return new Std.DataWrapper(1); };
Renderer.pointSize @(init) := fn(){ return new Std.DataWrapper(1.0); };
Renderer.showMesh @(init) := fn(){ return new Std.DataWrapper(false); };
Renderer.highlight @(init) := fn(){ return new Std.DataWrapper(false); };
Renderer.cameraOriented @(init) := fn(){ return new Std.DataWrapper(false); };
Renderer.sizeToCover := false;
Renderer.prefixToCover := false;
Renderer.surfelShader := void;
Renderer.splatShader := void;
Renderer.fbo := void;
Renderer.depthTexture := void;
//Renderer.colorTexture := void;
Renderer.needsRefresh := true;

Renderer.init ::= fn() {
	// renders 3d discs
	this.surfelShader = Rendering.Shader.createGeometryFromFile(__DIR__ + "/../resources/shader/BlueSurfelShaderGS.sfn", {"SURFEL_CULLING" : 0});
	// simply colors the underlying object
	this.splatShader = Rendering.Shader.createGeometryFromFile(__DIR__ + "/../resources/shader/DebugSplatShader.sfn");
	
	this.fbo = new Rendering.FBO;
	var vp = frameContext.getCamera().getViewport();
	this.depthTexture = Rendering.createDepthTexture(vp.width(), vp.height());
	//this.colorTexture = Rendering.createStdTexture(vp.width(), vp.height(), false);
	fbo.attachDepthTexture(renderingContext, depthTexture);
	//fbo.attachColorTexture(renderingContext, colorTexture);
	needsRefresh = false;
};

Renderer.doEnableState @(override) ::= fn(node,params) {
	if(needsRefresh)
		init();
	if(showMesh()) {
		renderingContext.pushAndSetColorMaterial(new Util.Color4f(0.75,0.75,0.75));
		return MinSG.STATE_OK;
	} else {
		doDisableState(node, params); // STATE_SKIP_RENDERING also skips doDisableState
		return MinSG.STATE_SKIP_RENDERING;
	}
};

Renderer.doDisableState @(override) ::= fn(node,params) {
	if(showMesh()) {
		renderingContext.popMaterial();
		
		renderingContext.pushAndSetFBO(fbo);
		renderingContext.clearScreen(new Util.Color4f(0,0,0));
		var rp = (new MinSG.RenderParam).setFlags(MinSG.USE_WORLD_MATRIX | MinSG.NO_STATES).setRenderingLayers(PADrend.getRenderingLayers());
		frameContext.displayNode(node, rp);
		renderingContext.popFBO();
	}
	
	var surfels = Utils.locateSurfels(node);
	if(surfels) {
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
		if(showMesh()) {
			renderingContext.pushAndSetShader(splatShader);
			renderingContext.pushAndSetTexture(0, depthTexture);
			renderingContext.pushAndSetDepthBuffer(true, false, Rendering.Comparison.ALWAYS);
			splatShader.setUniform(renderingContext, 'cameraOriented', Rendering.Uniform.BOOL, [cameraOriented()]);
			splatShader.setUniform(renderingContext, 'debugColor', Rendering.Uniform.VEC4F, [highlight() ? new Geometry.Vec4(1,0,0,1) : new Geometry.Vec4(1,0,0,0)]);
			frameContext.displayMesh(surfels, first, count);
			renderingContext.popDepthBuffer();
			renderingContext.popTexture(0);
			renderingContext.popShader();
		} else {
			renderingContext.pushAndSetShader(surfelShader);
			surfelShader.setUniform(renderingContext, 'debugColor', Rendering.Uniform.VEC4F, [highlight() ? new Geometry.Vec4(1,0,0,1) : new Geometry.Vec4(1,0,0,0)]);
			frameContext.displayMesh(surfels, first, count);
			renderingContext.popShader();
		}
		renderingContext.popPointParameters();
	}
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
		GUI.RANGE : [1,128],
		GUI.RANGE_STEP_SIZE : 1,
	};
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Cover",
		GUI.ON_CLICK : renderer->fn() {
			this.sizeToCover = true;
		},
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Show Mesh",
		GUI.DATA_WRAPPER : renderer.showMesh,
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Highlight",
		GUI.DATA_WRAPPER : renderer.highlight,
	};
	panel++;
	panel += {
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Camera Oriented",
		GUI.DATA_WRAPPER : renderer.cameraOriented,
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
		if(	description['start'] )	state.start(0+description['start']);
		if(	description['end'] )	state.end(0+description['end']);
		if(	description['pointSize'] )	state.pointSize(0+description['pointSize']);
		if(	description['highlight'] )	state.highlight(0+description['highlight'] > 0);
		if(	description['showMesh'] )	state.showMesh(0+description['showMesh'] > 0);
		if(	description['cameraOriented'] )	state.cameraOriented(0+description['cameraOriented'] > 0);
		return state;
	};
});


Std.module.on( 'LibMinSGExt/ScriptedStateExportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(state,description){	
		description['start'] = state.start();
		description['end'] = state.end();
		description['pointSize'] = state.pointSize();
		description['highlight'] = state.highlight().toNumber();
		description['showMesh'] = state.showMesh().toNumber();
		description['cameraOriented'] = state.cameraOriented().toNumber();
	};
});

return Renderer;