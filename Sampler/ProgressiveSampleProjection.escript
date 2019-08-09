/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2019 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static Utils = Std.module("BlueSurfels/Utils");
static Sorter = Std.module("Compute/Sorter");
static Compactor = Std.module("Compute/Compactor");
static Reducer = Std.module("Compute/Reducer");
static PoissonSampler = Std.module("Compute/PoissonSampler");

static GROUP_SIZE = 256;//6*6*6;
static BLOCK_SIZE = 6;

static sampleFormat = (new Rendering.VertexDescription).appendPosition4DHalf().appendNormalByte().appendColorRGBAByte();
//static sampleFormat = (new Rendering.VertexDescription).appendPosition3D().appendNormalByte();

static merge = fn(mapA, mapB) {
	var map = new Map;
	map.merge(mapA);
	return map.merge(mapB);
};

static mean = fn(values) {
	return values.reduce(fn(sum,k,v){ return sum+v;},0) / values.count();
};

static dispatchCompute = fn(shader, fnName, threads) {
	if(threads <= 0)
		return;
	if(!shader.isActive(renderingContext))
		renderingContext.setShader(shader);
	renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, [fnName]);
	renderingContext.dispatchCompute((threads / GROUP_SIZE).ceil());
	renderingContext.barrier();
};

// --------------------------------------------------------------------------------

static T = new Type;
T._printableName := $ProgressiveSampleProjection;

T.dirty @(private) := true;

T.profiler @(private) := void;
T.statistics @(private,init) := Map;
T.getStatistics @(public) ::= fn() { 
	finalizeProfiling();
	return statistics; 
};

T.debugLevel @(private) := 0;
T.setDebugLevel @(public) ::= fn(Number v) { debugLevel = v; return this; };
T.getDebugLevel @(public) ::= fn() { return debugLevel; };

T.iterations @(private) := 10;
T.setIterations @(public) ::= fn(Number v) { iterations = v; return this; };

T.radius @(private) := 0.01;
T.setRadius @(public) ::= fn(Number v) { radius = v; return this; };
T.getRadius @(public) ::= fn() { return radius; };

T.targetQuality @(private) := 1.0;
T.setTargetQuality @(public) ::= fn(Number v) { targetQuality = v; return this; };
T.getTargetQuality @(public) ::= fn() { return targetQuality; };

T.maxResolution @(private) := 1024;
T.setResolution @(public) ::= fn(Number v) { if(maxResolution != v) dirty = true; maxResolution = v; return this; };
T.getResolution @(public) ::= fn() { return maxResolution; };

T.maxCount @(private) := 0;
T.setMaxCount @(public) ::= fn(Number v) { if(maxCount < v) dirty = true; maxCount = v; return this; };
T.getMaxCount @(public) ::= fn() { return maxCount; };

T.gridHashSize @(private) := 65536;
T.lastNode @(private) := void;
T.surface @(private) := void;

// ----------------------------

T.beginProfile @(private) ::= fn(name, level=0) {
	if(level > debugLevel)
		return;
	//if(!profiler)
	//	profiler = new Experiments.GPUProfiler;
	//if(debugLevel >= 4) Experiments.pushDebugGroup(name);
	//profiler.begin(name);
	//renderingContext.flush();
};

// ----------------------------

T.endProfile @(private) ::= fn(level=0) {
	if(level > debugLevel)
		return;
	//profiler.end();
	//renderingContext.flush();
	//if(debugLevel >= 4) Experiments.popDebugGroup();
};

// ----------------------------

T.finalizeProfiling @(private) ::= fn() {
	if(debugLevel <= 0)
		return;
	//statistics['profiling'] = profiler.getResults();
	profiler = void;
};

// ----------------------------

T.pushState @(private) ::= fn() {
	// store current rendering state
	frameContext.pushCamera();
	renderingContext.pushShader();
	renderingContext.pushFBO();
	renderingContext.pushViewport();
	renderingContext.pushAndSetScissor(new Rendering.ScissorParameters);
	renderingContext.pushDepthBuffer();
	renderingContext.pushColorBuffer();
	renderingContext.pushAndSetCullFace((new Rendering.CullFaceParameters()).disable());
	for(var i=0; i<6; ++i) renderingContext.pushTexture(i);	
	//if(debugLevel >= 4) Experiments.startCapture();
	beginProfile('Total', 1);
};

// ----------------------------

T.popState @(private) ::= fn() {
	// restore rendering state
	endProfile(1);
	renderingContext.clearDepth(1);
	frameContext.popCamera();
	renderingContext.popShader();
	renderingContext.popFBO();
	renderingContext.popViewport();
	renderingContext.popScissor();
	renderingContext.popDepthBuffer();
	renderingContext.popColorBuffer();
	renderingContext.popCullFace();
	for(var i=0; i<6; ++i) renderingContext.popTexture(i);
	for(var i=0; i<7; ++i) renderingContext.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, i);
	renderingContext.unbindBuffer(Rendering.TARGET_UNIFORM_BUFFER, 0);	
	//if(debugLevel >= 4) Experiments.endCapture();
};

// ----------------------------

T.createDolly := fn(MinSG.Node node) {
	var nodeCenter = node.getWorldBB().getCenter();
	var extent = node.getWorldBB().getBoundingSphereRadius() * 2;
	var bb = new Geometry.Box(new Geometry.Vec3(0,0,0), extent, extent, extent);
	var dolly = new MinSG.ListNode;
	dolly.setFixedBB(bb);
	dolly.setWorldOrigin(nodeCenter);
	
	var directions = [new Geometry.Vec3(-1,0,0), new Geometry.Vec3(0,-1,0), new Geometry.Vec3(0,0,-1)];
	foreach(directions as var dir) {
		var camera = new MinSG.CameraNodeOrtho();
		dolly += camera;
		camera.setRelOrigin(-dir.getNormalized() * bb.getExtentMax());
		camera.rotateToWorldDir(-dir.getNormalized());	
		
		var frustum = Geometry.calcEnclosingOrthoFrustum(bb, camera.getWorldToLocalMatrix() * dolly.getWorldTransformationMatrix());
		camera.setClippingPlanes(frustum.getLeft(), frustum.getRight(), frustum.getBottom(), frustum.getTop());
		camera.setNearFar(frustum.getNear(), frustum.getFar());
		camera.setViewport(new Geometry.Rect(0,0,maxResolution,maxResolution), false);
	}
	return dolly;
};

// ----------------------------

/**
 * Initialize shaders and resources 
 */
T.initialize @(public) ::= fn() {
	if(!dirty)
		return;
	dirty = false;
		
	beginProfile('Setup', 1);
	gridHashSize = 2*maxCount;
	
	// defines for shaders
	var defines = {
		'GROUP_SIZE' : GROUP_SIZE,
		'BLOCK_SIZE' : BLOCK_SIZE,
		'GRID_HASH_SIZE' : gridHashSize.toIntStr(),
	};
	
	// create shaders
	this.projector_shader := Rendering.Shader.createVertexFromFile(__DIR__ + "/../resources/shader/ProgressiveSampleProjection.sfn", merge(defines,{'INIT_PROJECTOR':1}));
	this.trace_shader := Rendering.Shader.createFromFile(__DIR__ + "/../resources/shader/ProgressiveSampleProjection.sfn", defines);
	this.compute_shader := Rendering.Shader.createComputeFromFile(__DIR__ + "/../resources/shader/ProgressiveSampleProjection.sfn", defines);
	
	// compile shaders
	renderingContext.pushShader();
	renderingContext.setShader(projector_shader);
	renderingContext.setShader(trace_shader);
	renderingContext.setShader(compute_shader);
	renderingContext.popShader();
	
	// create textures
	this.t_depth := Rendering.createDepthTexture(maxResolution, maxResolution);
	this.t_count := Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D, maxResolution, maxResolution, 1, Util.TypeConstant.UINT32, 1);
	
	// create FBOs
	this.renderFBO := new Rendering.FBO;
	this.renderFBO.attachDepthTexture(renderingContext, t_depth);
	this.renderFBO.attachColorTexture(renderingContext, t_count, 0);
	
	// create buffers
	this.paramBuffer := (new Rendering.BufferObject).allocate(4 * 4);
	this.gridBuffer := (new Rendering.BufferObject).allocate(gridHashSize * 4);
	this.offsetBuffer := (new Rendering.BufferObject).allocate(maxCount * 8);
	this.priorityBuffer := (new Rendering.BufferObject).allocate(2 * maxCount * 4);
	this.traceBuffer := (new Rendering.Mesh(sampleFormat, maxCount, 0)).setDrawPoints().setUseIndexData(false).allocateGLData().releaseLocalData();
			
	// create sorter
	this.sorter := new Sorter;
	sorter.setKeyType(Util.TypeConstant.UINT64);
	sorter.setBindingOffset(7);
	sorter.setWorkGroupSize(256);
	sorter.setMaxElements(maxCount);
	sorter.setRadixRange(0,32);
	sorter.setSortAscending(true);
	sorter.build();
	
	// minReducer
	this.minReducer := new Reducer;
	minReducer.setType(Util.TypeConstant.FLOAT);
	minReducer.setBindingOffset(7);
	minReducer.setWorkGroupSize(GROUP_SIZE);
	minReducer.setReduceFn("min(a,b)", "3.402823466e+38");
	minReducer.build();
	
	Rendering.checkGLError();
	endProfile(1);
};

// ----------------------------

T.createProjector ::= fn(size, radius) {
	// projector plane
	beginProfile('Projector', 1);

	var min_r = 2/maxResolution;
	var target_r = [radius/size, min_r].max();

	// generate 2d poisson disk samples
	var poisson = new PoissonSampler;
	poisson.setRadius(target_r);
	poisson.setResolution(maxResolution);
	poisson.initialize();
	var projector = poisson.generate();
	
	if(debugLevel >= 4) {
		var plane_r = MinSG.BlueSurfels.getMinimalVertexDistances(projector, projector.getVertexCount()).min() * 0.5;
		var plane_r_max = (1/(2*3.sqrt()*projector.getVertexCount())).sqrt();
		var quality = plane_r/plane_r_max;
		outln("  Projector");
		outln("    size ", size);
		outln("    min r ", min_r * 0.5 * size);
		outln("    target r ", target_r * size * 0.5);
		outln("    r ", plane_r * size);
		outln("    r_max ", plane_r_max * size);
		outln("    quality ", quality);
		outln("    count  ", projector.getVertexCount());
	}

	// project samples to depth buffer
	t_depth.clear(new Util.Color4f(0,0,0,0));
	renderingContext.setFBO(renderFBO);
	renderingContext.setViewport(0,0,maxResolution,maxResolution);
	renderingContext.setShader(projector_shader);
	renderingContext.setDepthBuffer(true, true, Rendering.Comparison.ALWAYS);
	renderingContext.setColorBuffer(false,false,false,false);
	frameContext.displayMesh(projector);
	endProfile(1);
};

// ----------------------------

/**
 * Render node from multiple directions and stores resulting pixels in a mesh
 */
T.sample @(public) ::= fn(MinSG.Node node) {
	statistics.clear();
		
	// camera
	var dolly = createDolly(node);
	var matrix_worldToImpostorRel = node.getWorldTransformationMatrix().inverse();
	
	if(node != lastNode) {
		surface = Utils.computeTotalSurface(node);
		lastNode = node;
	}
	var expectedCount = (surface/(radius * radius * 0.5 * 3.sqrt())).ceil();
	var dim = dolly.getBB().getExtentMax();
	var gridDim = (dim / radius).floor();
	var cellSize = dim / gridDim;
	var resultCount = 0;
	var minRadius = 3.4028237e+38;
	setMaxCount(Utils.nextPowOfTwo(expectedCount));
	
	if(debugLevel >= 4) {
		outln("PSP");
		outln("  surface ", surface);
		outln("  expectedCount ", expectedCount);	
		outln("  gridDim ", gridDim);
		outln("  cellSize ", cellSize);
	}
	
	initialize();
	var rc = renderingContext;
	var rp = (new MinSG.RenderParam).setFlags(MinSG.USE_WORLD_MATRIX).setRenderingLayers(PADrend.getRenderingLayers());
	pushState();
	
	createProjector(dim, radius*1.01);
		
	// create result buffer
	var resultBuffer = (new Rendering.Mesh(sampleFormat, maxCount, 0)).setDrawPoints().setUseIndexData(false).allocateGLData().releaseLocalData();	
	
	paramBuffer.clear();
	paramBuffer.upload([0,0,gridDim], 0, Util.TypeConstant.UINT32);
	paramBuffer.upload([radius], 12, Util.TypeConstant.FLOAT);
	
	traceBuffer.clear();
	resultBuffer.clear();
	rc.bindBuffer(paramBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, 0);
	rc.bindBuffer(traceBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, 1);
	rc.bindBuffer(offsetBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, 2);
	rc.bindBuffer(gridBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, 3);
	rc.bindBuffer(priorityBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, 4);
	rc.bindBuffer(resultBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, 5);
	
	var directions = Utils.createDirections(iterations);
	var quality = 0;
	var rounds = 0;
	foreach(directions as var round, var dir) {
		beginProfile('Round #' + (round+1), 2);
		
		dolly.rotateToWorldDir(dir);
		
		// ray trace samples
		beginProfile('Trace', 3);
		offsetBuffer.clear(0xffffffff);
		gridBuffer.clear(0xffffffff);
		priorityBuffer.clear();
		rc.setShader(trace_shader);	
		rc.setDepthBuffer(true, false, Rendering.Comparison.LESS);
		rc.setColorBuffer(true,true,true,true);
		var gridCam = MinSG.getChildNodes(dolly).front();
		var sg_matrix_modelToGrid = (
			(new Geometry.Matrix4x4).scale(gridDim,gridDim,gridDim) * // [0,1] -> [0,gridDim]
			(new Geometry.Matrix4x4).scale(0.5,0.5,0.5).translate(1,1,1) * // clipping -> [0,1]
			gridCam.getFrustum().getProjectionMatrix() * // camera -> clipping
			gridCam.getWorldTransformationMatrix().inverse() * // world -> camera
			node.getWorldTransformationMatrix() // model -> world
		);
		trace_shader.setUniform(rc, 'sg_matrix_modelToGrid', Rendering.Uniform.MATRIX_4X4F, [sg_matrix_modelToGrid]);
		compute_shader.setUniform(rc, 'sg_matrix_modelToGrid', Rendering.Uniform.MATRIX_4X4F, [sg_matrix_modelToGrid]);	
		foreach(MinSG.getChildNodes(dolly) as var i, var camera) {
			frameContext.setCamera(camera);
			var matrix_cameraToImpostorRel = matrix_worldToImpostorRel * camera.getWorldTransformationMatrix();
			rc.setGlobalUniform('sg_mrt_matrix_cameraToCustom', Rendering.Uniform.MATRIX_4X4F, [matrix_cameraToImpostorRel]);
			trace_shader.setUniform(rc, 'priority', Rendering.Uniform.INT, [3-i]);
			frameContext.displayNode(node, rp);
		}
		endProfile(3);
			
		beginProfile('Resolve Conflicts', 3);
		beginProfile('Sort', 4);
		sorter.sort(offsetBuffer, maxCount);
		endProfile(4);
		dispatchCompute(compute_shader, 'writeGrid', maxCount);
		dispatchCompute(compute_shader, 'resolveRestartConflicts', maxCount);
		dispatchCompute(compute_shader, 'validityCheck', maxCount);
		endProfile(3);
			
		beginProfile('Merge', 3);
		offsetBuffer.clear(0xffffffff);
		gridBuffer.clear(0xffffffff);
		dispatchCompute(compute_shader, 'buildResultOffsets', resultCount);
		beginProfile('Sort', 4);
		sorter.sort(offsetBuffer, resultCount);
		endProfile(4);
		dispatchCompute(compute_shader, 'writeGrid', resultCount);
		dispatchCompute(compute_shader, 'merge', maxCount);
		resultCount = paramBuffer.download(1, Util.TypeConstant.UINT32, 0).front();
		paramBuffer.upload([0], 4, Util.TypeConstant.UINT32);
		endProfile(3);
		
		endProfile(2);
		
		var r_max = (surface/(2*3.sqrt()*resultCount)).sqrt();
		quality = 0.5 * radius/r_max;
		++rounds;
		if(quality >= targetQuality)
			break;
	}
	
	// ---------------------------------------------------	
	popState();
	
	resultBuffer._resize(resultCount);
	
	statistics['rounds'] = rounds;
	
	if(resultCount <= 0)
		return void;
	
	if(debugLevel >= 4) {
		var r_max = (surface/(2*3.sqrt()*resultCount)).sqrt();
		var minDistances = MinSG.BlueSurfels.getMinimalVertexDistances(resultBuffer, resultCount);
		var r_min = minDistances.min() * 0.5;
		var r_mean = mean(minDistances) * 0.5;
		outln("  r_max: ", r_max);
		outln("  r_min: ", r_min);
		outln("  Quality: ", r_min/r_max);
		outln("  Mean Quality: ", r_mean/r_max);
	}
	
	return resultBuffer;
};

// --------------------------------------------------------------
// GUI

static SurfelGUI = Std.module("BlueSurfels/GUI/SurfelGUI");
SurfelGUI.registerSampler(T);
SurfelGUI.registerSamplerGUI(T, fn(sampler) {
	return [
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Resolution",
			GUI.RANGE : [0,12],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.RANGE_FN_BASE : 2,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('resolution', 1024, sampler->sampler.setResolution),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Debug Level",
			GUI.RANGE : [0,4],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('psp.debugLevel', 0, sampler->sampler.setDebugLevel),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Iterations",
			GUI.RANGE : [1,1000],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('psp.iterations', 10, sampler->sampler.setIterations),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Radius",
			GUI.RANGE : [-5,1],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.RANGE_FN_BASE : 10,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('psp.radius', 0.01, sampler->sampler.setRadius),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Target Quality",
			GUI.RANGE : [0,1],
			GUI.RANGE_STEP_SIZE : 0.01,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('psp.quality', 1.0, sampler->sampler.setTargetQuality),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
	];
});

return T;