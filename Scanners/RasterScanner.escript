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
T._printableName := $RasterScanner;

T.statistics @(private,init) := Map;
T.getStatistics @(public) ::= fn() { return statistics; };

T.resolution @(private) := 512;
T.setResolution @(public) ::= fn(Number v) { resolution = v; return this; };
T.getResolution @(public) ::= fn() { return resolution; };

T.debug @(private) := false;
T.setDebug @(public) ::= fn(Bool v) {	debug = v; return this; };
T.getDebug @(public) ::= fn() { return debug; };

T.directions @(private,init) := fn() { 
	return [
		new Geometry.Vec3( 1,1,1), new Geometry.Vec3( 1,1,-1), new Geometry.Vec3( 1,-1,1), new Geometry.Vec3( 1,-1,-1),
		new Geometry.Vec3(-1,1,1), new Geometry.Vec3(-1,1,-1), new Geometry.Vec3(-1,-1,1), new Geometry.Vec3(-1,-1,-1)
	]; 
};
T.setDirections @(public) ::= fn(Array dir) { directions = dir;	return this; };
T.getDirections @(public) ::= fn() { return directions; };

/**
 * Render node from multiple directions and stores resulting pixels in a mesh
 */
T.scanSurface @(public) ::= fn(MinSG.Node node) {		
	statistics = new Map;
	var timer = new Util.Timer;
	
	// set up cameras	
	var cameras = Utils.placeCamerasAroundNode(node, resolution, directions);
	frameContext.pushCamera();
	var matrix_worldToImpostorRel = node.getWorldTransformationMatrix().inverse();
		
	// create textures
	var layers = directions.count();
	var t_depth = Rendering.createDepthTexture(resolution, resolution, layers);
	var t_color = Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.UINT8, 4);	
	var t_position = Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.FLOAT, 3);	
	var t_normal = Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.FLOAT, 3);	
	
	// initialize FBO
	var fbo = new Rendering.FBO;
	renderingContext.pushAndSetFBO(fbo);
	renderingContext.applyChanges();
	fbo.setDrawBuffers(5);
	
	//renderingContext.pushAndSetCullFace((new Rendering.CullFaceParameters).disable());
	
	// render scene from multiple directions 
	{	
		static surfel_shader;
		@(once) {
			var file = __DIR__ + "/../resources/shader/RasterScanShader.sfn";
			surfel_shader = Rendering.Shader.loadShader(file, file, Rendering.Shader.USE_UNIFORMS);	
		}
		
		var layer = 0;
		renderingContext.pushAndSetShader(surfel_shader);
		foreach(cameras as var camera) {
			renderingContext.applyChanges();
			fbo.attachDepthTexture(renderingContext,t_depth,0,layer);
			fbo.attachColorTexture(renderingContext,t_color,4,0,layer);
			fbo.attachColorTexture(renderingContext,t_position,1,0,layer);
			fbo.attachColorTexture(renderingContext,t_normal,2,0,layer);
			++layer;
			renderingContext.clearScreen(new Util.Color4f(0,0,0,0));
			
			var matrix_cameraToImpostorRel = matrix_worldToImpostorRel * camera.getWorldTransformationMatrix();
	    renderingContext.setGlobalUniform('sg_mrt_matrix_cameraToCustom', Rendering.Uniform.MATRIX_4X4F, [matrix_cameraToImpostorRel]);
			
			frameContext.setCamera(camera);
			frameContext.displayNode(node, (new MinSG.RenderParam).setFlags(MinSG.USE_WORLD_MATRIX).setRenderingLayers(PADrend.getRenderingLayers()));
		}
		renderingContext.popShader();
	}
	
	//renderingContext.popCullFace();
	renderingContext.popFBO();
	frameContext.popCamera();
	
	//renderingContext.finish();
	
	statistics["t_renderScene"] = timer.getSeconds();
	
	if(debug) {
		Rendering.showDebugTexture(t_depth);
		Rendering.showDebugTexture(t_color);
		Rendering.showDebugTexture(t_position);
		Rendering.showDebugTexture(t_normal);
	}
	
	var packTimer = new Util.Timer;
	var mesh = Utils.packMesh(t_depth, t_color, t_position, t_normal, resolution, layers);	
	statistics["t_downloadMesh"] = packTimer.getSeconds();
	
	return mesh;
};

return T;