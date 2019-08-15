/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2019 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static Utils = Std.module("BlueSurfels/Utils");

static T = new Type;
T._printableName := $Rasterizer;

T.resolution @(private) := 512;
T.setResolution @(public) ::= fn(Number v) { if(resolution != v) dirty = true; resolution = v; return this; };
T.getResolution @(public) ::= fn() { return resolution; };

T.mipmapping @(private) := false;
T.setMipMapping @(public) ::= fn(Bool v) { if(mipmapping != v) dirty = true; mipmapping = v; return this; };
T.getMipMapping @(public) ::= fn() { return mipmapping; };


T.directions @(private,init) := fn() { 
	return [
		new Geometry.Vec3(-1,0,0),new Geometry.Vec3(0,-1,0),new Geometry.Vec3(0,0,-1),
		new Geometry.Vec3(1,0,0),new Geometry.Vec3(0,1,0),new Geometry.Vec3(0,0,1)
	]; 
};
T.setDirections @(public) ::= fn(Array dir) { if(dir.count() != directions.count()) dirty = true;  directions = dir; return this; };
T.getDirections @(public) ::= fn() { return directions; };

T.maxLayers @(private) := 3;
T.setPeelLayers @(public) ::= fn(Number v) { if(maxLayers != v) dirty = true; maxLayers = v; return this; };
T.getPeelLayers @(public) ::= fn() { return maxLayers; };

T.getTextureLayers @(public) ::= fn() { return directions.count() * maxLayers; };

T.dirty @(private) := true;

T.placeCameras @(public) ::= fn(MinSG.Node node) {
	var cameras = Utils.placeCamerasAroundNode(node, resolution, directions);
	var peelCams = [];
	foreach(cameras as var cam) {
		for(var i=0; i<maxLayers; ++i)
			peelCams += cam;
	}
	return peelCams;
};

T.initialize ::= fn() {
	if(!dirty) return;
	dirty = false;	
	
	// textures
	var layers = directions.count() * maxLayers;
	this.t_depth := Rendering.createHDRDepthTexture(resolution, resolution, layers);
	this.t_color := Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.UINT8, 4);	
	this.t_position := Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.FLOAT, 4);	
	this.t_normal := Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.FLOAT, 3);

	if(mipmapping) {
		t_depth.createMipmaps(renderingContext);
		t_color.createMipmaps(renderingContext);
		t_position.createMipmaps(renderingContext);
		t_normal.createMipmaps(renderingContext);
	}

	// shader
	var file = __DIR__ + "/../resources/shader/PeelShader.sfn";
	this.shader := Rendering.Shader.loadShader(file, file);
	renderingContext.pushAndSetShader(shader);
	renderingContext.popShader();
	
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
	
	// disable culling
	renderingContext.pushAndSetCullFace((new Rendering.CullFaceParameters()).disable());
	renderingContext.pushAndSetTexture(7, t_depth);
	
	// initialize FBO
	renderingContext.pushAndSetFBO(fbo);
	renderingContext.pushViewport();
	renderingContext.pushScissor();
	t_position.clear(new Util.Color4f(0,0,0,0));
	t_normal.clear(new Util.Color4f(0,0,0,0));
	t_color.clear(new Util.Color4f(0,0,0,0));
	t_depth.clear(new Util.Color4f(0,0,0,0));
	
	var color_textures = [];
	var position_textures = [];
	var normal_textures = [];
	var depth_textures = [];
	
	// render scene from multiple directions
	renderingContext.pushAndSetShader(shader);
	foreach(cameras as var camId, var camera) {
		var preLayer = camId * maxLayers + 1;
		for(var peelLayer=0; peelLayer<maxLayers; ++peelLayer) {
			var layer = camId * maxLayers + peelLayer;
			frameContext.setCamera(camera);
			
			fbo.attachDepthTexture(renderingContext,t_depth,0,layer);
			fbo.attachColorTexture(renderingContext,t_position,1,0,layer);
			fbo.attachColorTexture(renderingContext,t_normal,2,0,layer);
			fbo.attachColorTexture(renderingContext,t_color,4,0,layer);
						
			// clear screen
			renderingContext.setViewport(0,0,resolution,resolution);
			renderingContext.setScissor(new Rendering.ScissorParameters);	
			renderingContext.clearScreen(new Util.Color4f(0,0,0,0));
			
			// set up transformation matrix
			var matrix_cameraToImpostorRel = matrix_worldToImpostorRel * camera.getWorldTransformationMatrix();
			renderingContext.setGlobalUniform('sg_mrt_matrix_cameraToCustom', Rendering.Uniform.MATRIX_4X4F, [matrix_cameraToImpostorRel]);
			shader.setUniform(renderingContext, 'layer', Rendering.Uniform.INT, [preLayer]);
			preLayer = layer;
			
			// render scene from the current camera
			frameContext.displayNode(node, (new MinSG.RenderParam).setFlags(MinSG.USE_WORLD_MATRIX).setRenderingLayers(PADrend.getRenderingLayers()));
		}
	}
	renderingContext.popShader();
	renderingContext.popViewport();
	renderingContext.popScissor();
	renderingContext.popFBO();
	renderingContext.popTexture(7);
	renderingContext.popCullFace();
	frameContext.popCamera();
	
	return [ t_depth, t_color, t_position, t_normal ];
};

return T;