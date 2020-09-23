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

T.directions @(private,init) := fn() { 
	return [
		new Geometry.Vec3( 1,1,1), new Geometry.Vec3( 1,1,-1), new Geometry.Vec3( 1,-1,1), new Geometry.Vec3( 1,-1,-1),
		new Geometry.Vec3(-1,1,1), new Geometry.Vec3(-1,1,-1), new Geometry.Vec3(-1,-1,1), new Geometry.Vec3(-1,-1,-1)
	]; 
};
T.setDirections @(public) ::= fn(Array dir) { if(dir.count() != directions.count()) dirty = true;  directions = dir; return this; };
T.getDirections @(public) ::= fn() { return directions; };
T.getTextureLayers @(public) ::= fn() { return directions.count(); };

T.mipmapping @(private) := false;
T.setMipMapping @(public) ::= fn(Bool v) { if(mipmapping != v) dirty = true; mipmapping = v; return this; };
T.getMipMapping @(public) ::= fn() { return mipmapping; };

T.t_depth @(private) := void;
T.getDepthBuffer @(public) ::= fn() { return t_depth; };

T.t_color @(private) := void;
T.useColor @(private) := true;
T.colorLocation @(private) := 0;
T.enableColor @(public) ::= fn(Bool v) { if(useColor != v) dirty = true; useColor = v; return this; };
T.getColorBuffer @(public) ::= fn() { return t_color; };

T.t_position @(private) := void;
T.usePosition @(private) := true;
T.positionLocation @(private) := 0;
T.enablePosition @(public) ::= fn(Bool v) { if(usePosition != v) dirty = true; usePosition = v; return this; };
T.getPositionBuffer @(public) ::= fn() { return t_position; };

T.t_normal @(private) := void;
T.useNormal @(private) := true;
T.normalLocation @(private) := 0;
T.enableNormal @(public) ::= fn(Bool v) { if(useNormal != v) dirty = true; useNormal = v; return this; };
T.getNormalBuffer @(public) ::= fn() { return t_normal; };

T.t_primitiveIds @(private) := void;
T.usePrimitiveIds @(private) := false;
T.primitiveIdLocation @(private) := 0;
T.enablePrimitiveIds @(public) ::= fn(Bool v) { if(usePrimitiveIds != v) dirty = true; usePrimitiveIds = v; return this; };
T.getPrimitiveIdBuffer @(public) ::= fn() { return t_primitiveIds; };

T.alphaMask @(private) := 0.1;
T.setAlphaMask @(public) ::= fn(Number v) { if(alphaMask != v) dirty = true; alphaMask = v; return this; };

T.dirty @(private) := true;

T.placeCameras @(public) ::= fn(MinSG.Node node) {
	return Utils.placeCamerasAroundNode(node, resolution, directions);
};

T.initialize ::= fn() {
	if(!dirty) return;
	dirty = false;
	var defines = new Map;
	var shaderFile = __DIR__ + "/../resources/shader/RasterizeShader.sfn";
	var layers = directions.count();
	this.fbo := new Rendering.FBO;
	var drawBuffers = 0;

	// depth buffer
	this.t_depth = Rendering.createDepthTexture(resolution, resolution, layers);
	if(mipmapping)
		t_depth.createMipmaps(renderingContext);
	
	// color buffer
	this.t_color = void;
	if(useColor) {
		this.colorLocation = drawBuffers++;
		this.t_color = Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.UINT8, 4);
		if(mipmapping)
			t_color.createMipmaps(renderingContext);
		defines['COLOR_LOCATION'] = colorLocation;
		fbo.attachColorTexture(renderingContext,t_color,colorLocation,0,0);
	}
	
	// position buffer
	this.t_position = void;
	if(usePosition) {
		this.positionLocation = drawBuffers++;
		this.t_position = Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.FLOAT, 4);
		if(mipmapping)
			t_position.createMipmaps(renderingContext);
		defines['POSITION_LOCATION'] = positionLocation;
		fbo.attachColorTexture(renderingContext,t_position,positionLocation,0,0);
	}
	
	// normal buffer
	this.t_normal = void;
	if(useNormal) {
		this.normalLocation = drawBuffers++;
		this.t_normal = Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.FLOAT, 3);
		if(mipmapping)
			t_normal.createMipmaps(renderingContext);
		defines['NORMAL_LOCATION'] = normalLocation;
		fbo.attachColorTexture(renderingContext,t_normal,normalLocation,0,0);
	}
	
	// primitive id buffer
	this.t_primitiveIds = void;
	if(usePrimitiveIds) {
		this.primitiveIdLocation = drawBuffers++;
		this.t_primitiveIds = Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, resolution, resolution, layers, Util.TypeConstant.UINT32, 1);
		if(mipmapping)
			t_primitiveIds.createMipmaps(renderingContext);
		defines['PRIMITIVE_ID_LOCATION'] = primitiveIdLocation;
		fbo.attachColorTexture(renderingContext,t_primitiveIds,primitiveIdLocation,0,0);
	}

	if(alphaMask < 1) {
		defines['ALPHA_MASK'] = alphaMask;
	}

	// shader
	this.shader := Rendering.Shader.createFromFile(shaderFile, defines);
	renderingContext.pushAndSetShader(shader);
	renderingContext.popShader();
	
	// fbo
	fbo.setDrawBuffers(renderingContext, drawBuffers);
};

/**
 * Render node from multiple directions and stores resulting pixels in a mesh
 */
T.rasterize @(public) ::= fn(MinSG.Node node) {
	initialize();
	
	// set up cameras
	var cameras = placeCameras(node);
	frameContext.pushCamera();
	var matrix_worldToImpostorRel = node.getWorldTransformationMatrix().inverse();
		
	// initialize FBO
	renderingContext.pushAndSetFBO(fbo);
	renderingContext.pushViewport();
	renderingContext.pushScissor();
	if(useColor) t_color.clear(new Util.Color4f(0,0,0,0));
	if(usePosition) t_position.clear(new Util.Color4f(0,0,0,0));
	if(useNormal) t_normal.clear(new Util.Color4f(0,0,0,0));
	if(usePrimitiveIds) t_primitiveIds.clear(new Util.Color4f(MinSG.countTriangles(node),0,0,0));
	
	// render scene from multiple directions
	renderingContext.pushAndSetShader(shader);
	foreach(cameras as var layer, var camera) {
		frameContext.setCamera(camera);
		fbo.attachDepthTexture(renderingContext,t_depth,0,layer);
		if(useColor) fbo.attachColorTexture(renderingContext,t_color,colorLocation,0,layer);
		if(usePosition) fbo.attachColorTexture(renderingContext,t_position,positionLocation,0,layer);
		if(useNormal) fbo.attachColorTexture(renderingContext,t_normal,normalLocation,0,layer);
		if(usePrimitiveIds) fbo.attachColorTexture(renderingContext,t_primitiveIds,primitiveIdLocation,0,layer);
		
		// clear screen
		renderingContext.setViewport(0,0,resolution,resolution);
		renderingContext.setScissor(new Rendering.ScissorParameters);	
		renderingContext.clearScreen(new Util.Color4f(0,0,0,0));
		
		// set up transformation matrix
		var matrix_cameraToImpostorRel = matrix_worldToImpostorRel * camera.getWorldTransformationMatrix();
		renderingContext.setGlobalUniform('sg_mrt_matrix_cameraToCustom', Rendering.Uniform.MATRIX_4X4F, [matrix_cameraToImpostorRel]);
		
		// render scene from the current camera
		frameContext.displayNode(node, (new MinSG.RenderParam).setFlags(MinSG.USE_WORLD_MATRIX).setRenderingLayers(PADrend.getRenderingLayers()));
	}
	renderingContext.popShader();
	renderingContext.popViewport();
	renderingContext.popScissor();
	renderingContext.popFBO();
	frameContext.popCamera();
	
	return [t_depth, t_color, t_position, t_normal];
};

T.showDebugTextures ::= fn() {
	var debugTextures = [];
	foreach([t_position, t_normal, t_color] as var t) {
		if(t) {
			t.download(renderingContext);
			debugTextures += Rendering.createTextureFromBitmap(Rendering.createBitmapFromTexture(renderingContext, t));
		}
	}
	if(debugTextures.count() == 0)
		return;
	var width = debugTextures[0].getWidth();
	var height = debugTextures[0].getHeight();
	var screen = renderingContext.getWindowClientArea();
	var scale = height <= screen.getHeight() ? (screen.getWidth() / (3*width)) : (screen.getHeight() / height);
	var vp = new Geometry.Rect(0,0,width*scale,height*scale);
	
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
	
	//drawTextures();
	//PADrend.SystemUI.swapBuffers();
	//for(var i=clock()+0.5;clock()<i;);
	
	Util.registerExtension('PADrend_AfterFrame', drawTextures);
};



return T;