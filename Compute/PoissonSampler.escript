/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2018-2019 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static T = new Type;
T._printableName := $PoissonSampler;

T.resolution @(private) := 512;
T.setResolution @(public) ::= fn(Number v) { if(resolution != v) dirty = true; resolution = v; return this; };
T.getResolution @(public) ::= fn() { return resolution; };

T.radius @(private) := 0.01;
T.setRadius @(public) ::= fn(Number v) { if(radius != v) dirty = true; radius = v; return this; };
T.getRadius @(public) ::= fn() { return radius; };

T.dirty @(private) := true;

static GROUP_SIZE = 256;

static merge = fn(mapA, mapB) {
	var map = new Map;
	map.merge(mapA);
	return map.merge(mapB);
};

static dispatchCompute = fn(shader, fnName, threads) {
	if(!shader.isActive(renderingContext))
		renderingContext.setShader(shader);
	renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, [fnName]);
	renderingContext.dispatchCompute((threads / GROUP_SIZE).ceil());
	renderingContext.barrier();
};

T.initialize ::= fn() {
	if(!dirty) return;
	dirty = false;
	var rc = renderingContext;
	this.maxCount := (1/(radius * radius * 0.5 * 3.sqrt())).ceil();
	
	// defines for shaders
	var defines = {
		'GROUP_SIZE' : GROUP_SIZE,
		'RESOLUTION' : resolution.toIntStr(),
		'MAX_SAMPLES' : maxCount.toIntStr(),
	};
	
	this.dart_shader := Rendering.Shader.createGeometryFromFile(__DIR__ + "/shader/poisson.sfn", merge(defines, {'DART_THROW':1}));
	this.conflict_shader := Rendering.Shader.createGeometryFromFile(__DIR__ + "/shader/poisson.sfn", merge(defines, {'CONFLICT_REMOVAL':1}));
	this.compute_shader := Rendering.Shader.createComputeFromFile(__DIR__ + "/shader/poisson.sfn", defines);
	//compute_shader.attachCSFile(__DIR__ + "/shader/random.sfn");
	
	// compile shaders
	rc.pushShader();
	rc.setShader(dart_shader);
	rc.setShader(conflict_shader);
	rc.setShader(compute_shader);
	rc.popShader();
	
	// textures
	this.t_depth := Rendering.createDepthTexture(resolution, resolution);
	this.t_coverage := Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D, resolution, resolution, 1, Util.TypeConstant.UINT32, 1);
	
	// buffers
	this.paramBuffer := (new Rendering.BufferObject).allocate(16);	
	this.freePixels := (new Rendering.BufferObject).allocate(4 * resolution * resolution);
	var sampleFormat = (new Rendering.VertexDescription).appendUnsignedIntAttribute("dart",1,false);
	this.samples := (new Rendering.Mesh(sampleFormat, maxCount, 0)).setDrawPoints().setUseIndexData(false).allocateGLData().releaseLocalData();
		
	// fbo
	this.fbo := new Rendering.FBO;	
	fbo.attachDepthTexture(rc,t_depth);
	fbo.attachColorTexture(rc,t_coverage,0);
	t_depth.enableComparision(renderingContext, Rendering.Comparison.GREATER);
};

// -----------------------------------------------------

T.generate @(public) ::= fn(seed=clock()) {
	initialize();
	var rc = renderingContext;
	
	//outln("PixelPie radius ", radius);
	//outln("PixelPie resolution ", resolution);
	//outln("PixelPie maxCount ", maxCount);
	var format = (new Rendering.VertexDescription).appendPosition4DHalf().appendNormalByte().appendColorRGBAByte();
	var result = (new Rendering.Mesh(format, maxCount, 0)).setDrawPoints().setUseIndexData(false).allocateGLData().releaseLocalData();
	
	// initialize FBO
	rc.pushShader();
	rc.pushAndSetFBO(fbo);
	rc.pushDepthBuffer();
	rc.pushColorBuffer();
	rc.pushAndSetViewport(0,0,resolution,resolution);
	rc.pushAndSetScissor(new Rendering.ScissorParameters);
	rc.clearScreen(new Util.Color4f(0,0,0,0));
	rc.pushAndSetTexture(0, t_depth);
	rc.pushAndSetTexture(1, t_coverage);
	
	rc.bindBuffer(paramBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, 0);
	rc.bindBuffer(freePixels, Rendering.TARGET_SHADER_STORAGE_BUFFER, 1);
	rc.bindBuffer(samples, Rendering.TARGET_SHADER_STORAGE_BUFFER, 2);
	rc.bindBuffer(result, Rendering.TARGET_SHADER_STORAGE_BUFFER, 3);
	
	compute_shader.setUniform(rc, 'sg_seed', Rendering.Uniform.INT, [seed]);
	dart_shader.setUniform(rc, 'radius', Rendering.Uniform.FLOAT, [radius]);
	conflict_shader.setUniform(rc, 'radius', Rendering.Uniform.FLOAT, [radius]);
	
	// samples
	paramBuffer.upload([0, 0], 0, Util.TypeConstant.UINT32);
	this.freePixels.clear();
	
	dispatchCompute(compute_shader, 'initPixelList', resolution * resolution);
	
	var pixels = 0;
	var count = maxCount;
	do {	
		this.samples.clear();
		dispatchCompute(compute_shader, 'randomSample', count);
		
		rc.setShader(dart_shader);
		rc.setColorBuffer(false,false,false,false);
		rc.setDepthBuffer(true, true, Rendering.Comparison.LESS);
		rc.clearDepth(1);
		frameContext.displayMesh(samples, 0, count);
		rc.setShader(conflict_shader);
		rc.setColorBuffer(true,true,true,true);
		rc.setDepthBuffer(false, false, Rendering.Comparison.ALWAYS);
		frameContext.displayMesh(samples, 0, count);
		rc.finish();
		
		this.freePixels.clear();
		paramBuffer.upload([0], 0, Util.TypeConstant.UINT32);
		dispatchCompute(compute_shader, 'updatePixels', resolution * resolution);
		[pixels, count] = paramBuffer.download(2, Util.TypeConstant.UINT32);
		//outln("PixelPie pixels ", pixels);
		//outln("PixelPie count ", count);
	} while(pixels > 0);
	
	rc.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, 0);
	rc.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, 1);
	rc.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, 2);
	rc.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, 3);
	
	rc.popTexture(0);
	rc.popTexture(1);
	rc.popViewport();
	rc.popScissor();
	rc.popColorBuffer();
	rc.popDepthBuffer();
	rc.popFBO();
	rc.popShader();
	
	result._resize(count);
	
	return result;
};

return T;