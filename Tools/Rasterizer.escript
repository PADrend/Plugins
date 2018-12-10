/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static Utils = Std.module("BlueSurfels/Utils");

static T = new Type;
T._printableName := $Rasterizer;

T.resolution @(private) := 512;
T.setResolution @(public) ::= fn(Number v) { if(resolution != v) dirty = true; resolution = v; return this; };
T.getResolution @(public) ::= fn() { return resolution; };

T.directions @(private,init) := fn() { 
	return [
		new Geometry.Vec3( 1,1,1), new Geometry.Vec3( 1,1,-1), new Geometry.Vec3( 1,-1,1), new Geometry.Vec3( 1,-1,-1),
		new Geometry.Vec3(-1,1,1), new Geometry.Vec3(-1,1,-1), new Geometry.Vec3(-1,-1,1), new Geometry.Vec3(-1,-1,-1)
	]; 
};
T.setDirections @(public) ::= fn(Array dir) { if(dir.count() != directions.count()) dirty = true;  directions = dir; return this; };
T.getDirections @(public) ::= fn() { return directions; };

T.dirty @(private) := true;

T.initialize ::= fn() {
	if(!dirty) return;
	dirty = false;
	
	// textures
	var layers = directions.count();
	this.t_depth := Rendering.createDepthTexture(resolution, resolution, layers);
	this.t_color := Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.UINT8, 4);	
	this.t_position := Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.FLOAT, 3);	
	this.t_normal := Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.FLOAT, 3);

	// shader
	var file = __DIR__ + "/../resources/shader/RasterScanShader.sfn";
	this.shader := Rendering.Shader.loadShader(file, file);	
	
	// fbo
	this.fbo := new Rendering.FBO;	
	fbo.setDrawBuffers(renderingContext,5);
	fbo.attachDepthTexture(renderingContext,t_depth,0,0);
	fbo.attachColorTexture(renderingContext,t_position,1,0,0);
	fbo.attachColorTexture(renderingContext,t_normal,2,0,0);
	fbo.attachColorTexture(renderingContext,t_color,4,0,0);
};

/**
 * Render node from multiple directions and stores resulting pixels in a mesh
 */
T.rasterize @(public) ::= fn(MinSG.Node node) {
	initialize();
	
	// set up cameras	
	var cameras = Utils.placeCamerasAroundNode(node, resolution, directions);
	frameContext.pushCamera();
	var matrix_worldToImpostorRel = node.getWorldTransformationMatrix().inverse();
		
	// initialize FBO
	renderingContext.pushAndSetFBO(fbo);
	t_position.clear();
	t_normal.clear();
	t_color.clear();
	
	// render scene from multiple directions 	
	renderingContext.pushAndSetShader(shader);
	foreach(cameras as var layer, var camera) {
		frameContext.setCamera(camera);
		fbo.attachDepthTexture(renderingContext,t_depth,0,layer);
		fbo.attachColorTexture(renderingContext,t_position,1,0,layer);
		fbo.attachColorTexture(renderingContext,t_normal,2,0,layer);
		fbo.attachColorTexture(renderingContext,t_color,4,0,layer);
		
		// clear screen
		//renderingContext.pushAndSetViewport(0,0,resolution,resolution);
		renderingContext.clearScreen(new Util.Color4f(0,0,0,0));
		//renderingContext.popViewport();
		
		// set up transformation matrix
		var matrix_cameraToImpostorRel = matrix_worldToImpostorRel * camera.getWorldTransformationMatrix();
    renderingContext.setGlobalUniform('sg_mrt_matrix_cameraToCustom', Rendering.Uniform.MATRIX_4X4F, [matrix_cameraToImpostorRel]);
		
		// render scene from the current camera
		frameContext.displayNode(node, (new MinSG.RenderParam).setFlags(MinSG.USE_WORLD_MATRIX).setRenderingLayers(PADrend.getRenderingLayers()));
	}
	renderingContext.popShader();	
	
	renderingContext.popFBO();
	frameContext.popCamera();
	
	return [t_depth, t_color, t_position, t_normal];
};

T.showDebugTextures ::= fn() {
	var debugTextures = [];
	foreach([t_position, t_normal, t_color] as var t) {
		t.download(renderingContext);
		debugTextures += Rendering.createTextureFromBitmap(Rendering.createBitmapFromTexture(renderingContext, t));
	}
	var scale = renderingContext.getWindowHeight() / (t_color.getHeight() * t_color.getNumLayers());
	var vp = new Geometry.Rect(0,0,debugTextures[0].getWidth()*scale,debugTextures[0].getHeight()*scale);
	
	var drawTextures = [debugTextures, new Util.Timer, vp] => fn(textures, timer, texRect, ...) {
		if(timer.getSeconds() > 1)
			return Extension.REMOVE_EXTENSION;
		renderingContext.pushScissor();
		renderingContext.pushViewport();
		var vp = texRect.clone();
				
		foreach(textures as var t) {
			renderingContext.setScissor(new Rendering.ScissorParameters(vp));
			renderingContext.setViewport(vp);
			Rendering.drawTextureToScreen(renderingContext, texRect, [t], [new Geometry.Rect(0,0,1,1)]);
			vp.setX(vp.getX() + texRect.getWidth());
		}
		
		renderingContext.popScissor();
		renderingContext.popViewport();
		return Extension.CONTINUE;
	};
	
	drawTextures();
	PADrend.SystemUI.swapBuffers();
	//for(var i=clock()+0.5;clock()<i;);
	
	//Util.registerExtension('PADrend_AfterFrame', drawTextures);
};



return T;