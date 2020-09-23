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
static Sorter = Std.module("Compute/Sorter");
static Compactor = Std.module("Compute/Compactor");
static Reducer = Std.module("Compute/Reducer");
static Mipmapper = Std.module("Compute/Mipmapper");

static Rasterizer = Std.module("BlueSurfels/Tools/Rasterizer");
static PeelingRasterizer = Std.module("BlueSurfels/Tools/PeelingRasterizer");

static GROUP_SIZE = 256;
static BLOCK_SIZE = GROUP_SIZE.sqrt();
static MAX_DIRECTIONS = 32;
static MAX_LEVEL = 8;
static BINDING_OFFSET = 4;

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

// --------------------------------------------------------------------------------

static T = new Type;
T._printableName := $GPUSampler;

T.dirty @(private) := true;

T.statistics @(private,init) := Map;
T.getStatistics @(public) ::= fn() {
	finalizeProfiling();
	return statistics;
};

T.profiler @(private) := void;
T.debugLevel @(private) := 0;
T.setDebugLevel @(public) ::= fn(Number v) { debugLevel = v; return this; };
T.getDebugLevel @(public) ::= fn() { return debugLevel; };

T.maxResolution @(private) := 512;
T.setResolution @(public) ::= fn(Number v) { if(maxResolution != v) dirty = true; maxResolution = v; return this; };
T.getResolution @(public) ::= fn() { return maxResolution; };

T.maxTargetCount @(private) := 10000;
T.setTargetCount @(public) ::= fn(Number v) { if(maxTargetCount < v) dirty = true; maxTargetCount = v; return this; };
T.getTargetCount @(public) ::= fn() { return maxTargetCount; };

T.globalSort @(private) := false;
T.setGlobalSort @(public) ::= fn(Bool v) { globalSort = v; return this; };
T.getGlobalSort @(public) ::= fn() { return globalSort; };

T.adaptiveRes @(private) := true;
T.setAdaptiveResolution @(public) ::= fn(Bool v) { adaptiveRes = v; return this; };
T.getAdaptiveResolution @(public) ::= fn() { return adaptiveRes; };

T.adaptiveSamples @(private) := false;
T.setAdaptiveSamples @(public) ::= fn(Bool v) {  if(adaptiveSamples != v) dirty = true; adaptiveSamples = v; return this; };
T.getAdaptiveSamples @(public) ::= fn() { return adaptiveSamples; };

T.geodesic @(private) := false;
T.setGeodesic @(public) ::= fn(Bool v) {  if(geodesic != v) dirty = true; geodesic = v; return this; };
T.getGeodesic @(public) ::= fn() { return geodesic; };

T.peelingLayers @(private) := 1;
T.setPeelingLayers @(public) ::= fn(Number v) { if(peelingLayers != v) dirty = true; peelingLayers = v; return this; };
T.getPeelingLayers @(public) ::= fn() { return peelingLayers; };

T.radiusFactor @(private) := 0.75;
T.setRadiusFactor @(public) ::= fn(Number v) { radiusFactor = v; return this; };
T.getRadiusFactor @(public) ::= fn() { return radiusFactor; };

T.autodetect @(private) := false;
T.setAutodetect @(public) ::= fn(Bool v) { autodetect = v; return this; };
T.getAutodetect @(public) ::= fn() { return autodetect; };

T.directions @(private,init) := fn() {
	return [
		new Geometry.Vec3( 1, 1, 1), new Geometry.Vec3(-1,-1,-1), new Geometry.Vec3( 1, 1,-1), new Geometry.Vec3(-1,-1, 1),
		new Geometry.Vec3( 1,-1, 1), new Geometry.Vec3(-1, 1,-1), new Geometry.Vec3( 1,-1,-1), new Geometry.Vec3(-1, 1, 1)
	]; 
};
T.setDirections @(public) ::= fn(Array dir) { dirty = true; directions = dir.clone(); return this; };
T.getDirections @(public) ::= fn() { return directions; };

// ----------------------------

T.beginProfile @(private) ::= fn(name, level=0) {
	if(level > debugLevel)
		return;
	//if(!profiler)
	//	profiler = new Experiments.GPUProfiler;
	if(debugLevel >= 4) Rendering.pushDebugGroup(name);
	//profiler.begin(name);
	//renderingContext.flush();
};

// ----------------------------

T.endProfile @(private) ::= fn(level=0) {
	if(level > debugLevel)
		return;
	//profiler.end();
	//renderingContext.flush();
	if(debugLevel >= 4) Rendering.popDebugGroup();
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
	renderingContext.pushScissor();
	renderingContext.pushDepthBuffer();
	renderingContext.pushColorBuffer();
	for(var i=0; i<6; ++i) renderingContext.pushTexture(i);
	if(debugLevel >= 4) Rendering.startCapture();
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
	for(var i=0; i<6; ++i) renderingContext.popTexture(i);
	for(var i=0; i<BINDING_OFFSET; ++i) renderingContext.unbindBuffer(Rendering.TARGET_SHADER_STORAGE_BUFFER, i);
	renderingContext.unbindBuffer(Rendering.TARGET_UNIFORM_BUFFER, 0);
	if(debugLevel >= 4) Rendering.endCapture();
};

// ----------------------------

/**
 * Initialize shaders and resources 
 */
T.initialize @(public) ::= fn() {
	profiler = void;
	if(!dirty)
		return true;
	dirty = false;
		
	beginProfile('Setup', 1);
	
	if(directions.count() * peelingLayers > MAX_DIRECTIONS) {
		outln("Warning: Maximum directions of ", MAX_DIRECTIONS, " exceeded.");
		return false;
	}
		
	// create shaders
	this.rasterizer := peelingLayers > 1 ? new PeelingRasterizer : new Rasterizer;
	this.rasterizer.setDirections(directions);
	this.rasterizer.setResolution(maxResolution);
	this.rasterizer.setMipMapping(true);
	if(peelingLayers > 1)
		this.rasterizer.setPeelLayers(peelingLayers);
	this.rasterizer.initialize();
	var layers = this.rasterizer.getTextureLayers();
	
	// defines for shaders
	var defines = {
		'BLOCK_SIZE' : BLOCK_SIZE,
		'GROUP_SIZE' : GROUP_SIZE,
		'LAYER_COUNT' : layers,
		'RESOLUTION' : maxResolution,
		'TARGET_COUNT' : maxTargetCount.toIntStr(),
	};
	
	if(adaptiveSamples)
		defines['WEIGHTED'] = 1;
	
	if(geodesic)
		defines['GEODESIC'] = 1;
	
	this.voronoi_shader := Rendering.Shader.createGeometryFromFile(__DIR__ + "/../resources/shader/GPUSampler.sfn", merge(defines, {'VORONOI_MODE':1}));
	this.poisson_shader := Rendering.Shader.createGeometryFromFile(__DIR__ + "/../resources/shader/GPUSampler.sfn", merge(defines, {'POISSON_MODE':1}));
	this.compute_shader := Rendering.Shader.createComputeFromFile(__DIR__ + "/../resources/shader/GPUSampler.sfn", defines);
	//this.max_shader := Rendering.Shader.createGeometryFromFile(__DIR__ + "/../resources/shader/GPUSampler.sfn", merge(defines, {'EXTRACT_MAX':1}));
	
	// compile shaders
	renderingContext.pushShader();
	renderingContext.setShader(voronoi_shader);
	renderingContext.setShader(poisson_shader);
	renderingContext.setShader(compute_shader);
	//renderingContext.setShader(max_shader);
	renderingContext.popShader();
	
	if(voronoi_shader.isInvalid() || poisson_shader.isInvalid() || compute_shader.isInvalid()) {
		outln("Warning: Invalid shaders.");
		return false;
	}
	
	// create textures
	// TODO: only use depth & color texture (& optionally normals) to reduce resources
	
	this.t_depth := void;
	this.t_color := void;
	this.t_position := void;
	this.t_normal := void;
		
	this.t_voronoiDist := Rendering.createDepthTexture(maxResolution, maxResolution, layers);
	this.t_poissonRad := Rendering.createDepthTexture(maxResolution, maxResolution, layers);
	this.t_voronoi := Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, maxResolution, maxResolution, layers, Util.TypeConstant.UINT32, 1);
	this.t_poisson := Rendering.createDataTexture(Rendering.Texture.TEXTURE_2D_ARRAY, maxResolution, maxResolution, layers, Util.TypeConstant.UINT32, 1);
	
	// allocate mipmaps	
	t_poissonRad.createMipmaps(renderingContext);
	t_voronoiDist.createMipmaps(renderingContext);
	t_voronoi.createMipmaps(renderingContext);
	t_poisson.createMipmaps(renderingContext);
			
	// create FBO
	this.sampleFBO := new Rendering.FBO;
		
	// create buffers
	this.paramBuffer := (new Rendering.BufferObject).allocate((8 + 2 * layers * 16) * 4); // 8 parameters + two 4x4 matrices for each camera
	
	this.validBlockBuffers := [];
	var maxBlockCount = (maxResolution/BLOCK_SIZE).ceil();
	var maxValidBlockCount = maxBlockCount*maxBlockCount*layers;
	for(var level=0; level<=(maxResolution.log(2)-BLOCK_SIZE.log(2)); ++level) {
		var blockCount = maxBlockCount / 2.pow(level);
		validBlockBuffers += (new Rendering.BufferObject).allocate(4*blockCount*blockCount*layers).clear();
	}
	
	// sample buffer
	var sampleFormat = (new Rendering.VertexDescription).appendUnsignedIntAttribute("source",1,false).appendFloatAttribute("dist");
	this.sampleMesh := (new Rendering.Mesh(sampleFormat, maxTargetCount*2, 0)).setDrawPoints().setUseIndexData(false).allocateGLData().releaseLocalData();
	
	// create sorter
	this.sorter := new Sorter;
	sorter.setKeyType(Util.TypeConstant.UINT64);
	sorter.setBindingOffset(BINDING_OFFSET);
	sorter.setWorkGroupSize(GROUP_SIZE);
	sorter.setMaxElements(2*maxTargetCount);
	sorter.setRadixRange(32,64);
	sorter.setSortAscending(false);
	sorter.build();
	
	// create compactor
	this.compactor := new Compactor;
	compactor.setKeyType(Util.TypeConstant.UINT64);
	compactor.setBindingOffset(BINDING_OFFSET);
	compactor.setWorkGroupSize(GROUP_SIZE);
	compactor.setMaxElements(2*maxTargetCount);
	compactor.build();
	
	this.validBlockCompactor := new Compactor;
	validBlockCompactor.setBindingOffset(BINDING_OFFSET);
	validBlockCompactor.setWorkGroupSize(GROUP_SIZE);
	validBlockCompactor.setMaxElements(maxValidBlockCount);
	validBlockCompactor.build();
	
	// minReducer
	this.minReducer := new Reducer;
	minReducer.setType(Util.TypeConstant.UINT64);
	minReducer.setBindingOffset(BINDING_OFFSET);
	minReducer.setWorkGroupSize(GROUP_SIZE);
	minReducer.setReduceFn("min(a,b)", "0xfffffffffffffffful");
	minReducer.build();
	
	// maxReducer
	this.maxReducer := new Reducer;
	maxReducer.setType(Util.TypeConstant.UINT64);
	maxReducer.setBindingOffset(BINDING_OFFSET);
	maxReducer.setWorkGroupSize(GROUP_SIZE);
	maxReducer.setReduceFn("max(a,b)", "0");
	maxReducer.build();
	
	// mipmapper
	this.mipmapper := new Mipmapper;
	mipmapper.layers = layers;
	mipmapper.textureCount = 3;
	mipmapper.build();
	
	endProfile(1);
	//Rendering.checkGLError();
	return true;
};

// ----------------------------

/**
 * Render node from multiple directions and stores resulting pixels in a mesh
 */
T.sample @(public) ::= fn(MinSG.Node node) {
	var rc = renderingContext;
	statistics.clear();
	[var resolution, var targetCount] = detectSettings(node);
	if(resolution < BLOCK_SIZE || targetCount < 10) {
		outln("Warning: Invalid object.");
		return void;
	}
	
	if(!initialize())
		return void;
	
	// ---------------------------------------------------
	
	// set up cameras	
	var cameras = rasterizer.placeCameras(node);
	var matrices = [];
	foreach(cameras as var camera) // local to camera
		matrices += camera.getWorldTransformationMatrix().inverse() * node.getWorldTransformationMatrix();
	foreach(cameras as var camera) // camera to clipping
		matrices += camera.getFrustum().getProjectionMatrix();
	
	// set up parameters
	var maxDist = node.getBB().getDiameter();
	var minDist = 0.5 * node.getBB().getExtentMin() / resolution;
	var maxRadius = maxDist;
	var minRadius = maxDist;
	var minLevel = (maxResolution/resolution).log(2);
	var maxLevel = [minLevel+MAX_LEVEL, resolution.log(2)-BLOCK_SIZE.log(2)].min();
	var layers = this.rasterizer.getTextureLayers();
	if(debugLevel >= 4) {
		outln();
		outln("minLevel ", minLevel);
		outln("maxLevel ", maxLevel);
		outln("maxDist ", maxDist);
		outln("minDist ", minDist);
		outln("resolution ", resolution);
		outln("targetCount ", targetCount);
	}
		
	// ---------------------------------------------------
	
	// push state
	pushState();
	beginProfile('Allocate', 1);
		
	// update buffers
	paramBuffer.upload([1,minLevel,resolution,0], 0, Util.TypeConstant.INT32);
	paramBuffer.upload([minRadius, maxRadius, minDist, maxDist], 16, Util.TypeConstant.FLOAT);
	paramBuffer.upload(matrices, 32);
	sampleMesh.clear();
	
	// bind buffers
	//rc.bindBuffer(paramBuffer, Rendering.TARGET_UNIFORM_BUFFER, 0);
	rc.bindBuffer(sampleMesh, Rendering.TARGET_SHADER_STORAGE_BUFFER, 0);
	rc.bindBuffer(paramBuffer, Rendering.TARGET_SHADER_STORAGE_BUFFER, 3);
	endProfile(1);
		
	// ---------------------------------------------------
			
	// render scene from multiple directions
	beginProfile('Render', 1);
	[t_depth, t_color, t_position, t_normal] = rasterizer.rasterize(node);
	mipmapper.generate(minLevel, maxLevel, t_position, t_normal, t_color);
	
	// bind textures
	rc.setTexture(0, t_position);
	rc.setTexture(1, t_normal);
	rc.setTexture(2, t_color);
	rc.setTexture(3, t_voronoi);
	rc.setTexture(4, t_voronoiDist);
	rc.setTexture(5, t_poisson);
		
	// update fbo
	rc.setFBO(sampleFBO);
	sampleFBO.attachDepthTexture(rc,t_voronoiDist,maxLevel);
	sampleFBO.attachColorTexture(rc,t_voronoi,0,maxLevel);
	t_voronoiDist.clear(new Util.Color4f(1,0,0,0));	
	t_voronoi.clear(new Util.Color4f(targetCount,0,0,0));
	t_poissonRad.clear(new Util.Color4f(0,0,0,0));
	endProfile(1);
			
	// mark valid blocks
	var validBlockCount = [];
	for(var level=0; level<minLevel; ++level)
		validBlockCount += 0;
		
	beginProfile('init', 1);
	var maxBlockCount = (maxResolution/BLOCK_SIZE).ceil();
	for(var level=minLevel; level<=maxLevel; ++level) {
		var blockCount = maxBlockCount / 2.pow(level);
		var count = blockCount*blockCount*layers;
		var res = maxResolution / 2.pow(level);
		paramBuffer.upload([1,level,res], 0, Util.TypeConstant.INT32);
		
		//beginProfile('init', 2);
		validBlockBuffers[level].clear();
		rc.bindBuffer(validBlockBuffers[level], Rendering.TARGET_SHADER_STORAGE_BUFFER, 1);
		dispatchCompute(compute_shader, 'markValid', count*GROUP_SIZE);
		validBlockCompactor.compact(validBlockBuffers[level], count);
		//endProfile(2);
		
		//beginProfile('download', 2);
		validBlockCount += validBlockCompactor.getCount();
		//endProfile(2);
	}
	
	var level = minLevel;
	var currentResolution = resolution;	
	if(adaptiveRes) {
		level = maxLevel;
		currentResolution = maxResolution/2.pow(level);
	}
	rc.setViewport(0,0,currentResolution,currentResolution);
	rc.setScissor(new Rendering.ScissorParameters(new Geometry.Rect(0,0,currentResolution, currentResolution)));
	rc.bindBuffer(validBlockBuffers[level], Rendering.TARGET_SHADER_STORAGE_BUFFER, 1);
	paramBuffer.upload([1,level,currentResolution], 0, Util.TypeConstant.INT32);
				
	// get random vertex
	//var start = getRandomVertex(MinSG.collectGeoNodes(node).front().getMesh());	
	compute_shader.setUniform(rc, 'initBlock', Rendering.Uniform.INT, [Rand.equilikely(0,validBlockCount[level]-1)]);
	//compute_shader.setUniform(rc, 'initBlock', Rendering.Uniform.INT, [validBlockCount[level]/2]);
	dispatchCompute(compute_shader, 'chooseFirstSample', GROUP_SIZE);
	endProfile(1);
	
	if(validBlockCount[level] <= 0) {
		popState();
		outln("Warning: Texture is empty.");
		return void;
	}
	if(debugLevel >= 4) {
		//outln("First Sample ", start);
		outln("Viewport ", currentResolution, "x", currentResolution);
		outln("Level ", level);
		outln("Valid Blocks: ");
		print_r(validBlockCount);
	}
	
	var round = 0;
	var sampleCount = 1;
	var insertCount = 0;
	var samplesPerLevel = [];
	for(var i=0; i<=maxLevel; ++i)
		samplesPerLevel += 0;
	
	// insert samples
	beginProfile('Sampling', 1);
	if(debugLevel>=2) statistics["samples_per_round"] = [];
	while(sampleCount < targetCount) {
		beginProfile('Sample Pass #' + round, 2);
		
		// compute voronoi
		beginProfile('Voronoi', 3);
		sampleFBO.attachDepthTexture(rc,t_voronoiDist,level);
		sampleFBO.attachColorTexture(rc,t_voronoi,0,level);
		rc.setDepthBuffer(true, true, Rendering.Comparison.LESS);
		rc.setColorBuffer(true, true, true, true);
		rc.setShader(voronoi_shader);
		frameContext.displayMesh(sampleMesh, samplesPerLevel[level], sampleCount-samplesPerLevel[level]);
		endProfile(3);
		
		// update max
		beginProfile('Extract', 3);
		dispatchCompute(compute_shader, 'updateMax', validBlockCount[level]*GROUP_SIZE);
		
		// fragment shader version of update max
		//rc.setDepthBuffer(true, false, Rendering.Comparison.LESS);
		//rc.setColorBuffer(false, false, false, false);
		//rc.setShader(max_shader);
		//Rendering.drawFullScreenRect(renderingContext);
		
		// get maximum radius
		maxReducer.reduce(sampleMesh, sampleCount, sampleCount);
		maxRadius = maxReducer.getValue(Util.TypeConstant.FLOAT, 1);
		paramBuffer.upload([radiusFactor*maxRadius], 24, Util.TypeConstant.FLOAT);
		
		// remove samples that are smaller than maxRadius * x%
		dispatchCompute(compute_shader, 'testRadius', sampleCount);		
		endProfile(3);
		
		// poisson sampling of new samples
		beginProfile('Poisson', 3);
		sampleFBO.attachDepthTexture(rc,t_poissonRad,level);
		sampleFBO.attachColorTexture(rc,t_poisson,0,level);
		rc.setDepthBuffer(true, true, Rendering.Comparison.GREATER);
		rc.setColorBuffer(true, true, true, true);
		rc.clearScreen(new Util.Color4f(0,0,0,0));
		rc.clearDepth(0);
		rc.setShader(poisson_shader);
		frameContext.displayMesh(sampleMesh, sampleCount, sampleCount);
				
		// remove samples that did not pass poisson test or are smaller than maxRadius * x%
		dispatchCompute(compute_shader, 'testSamples', sampleCount);
		endProfile(3);
		
		beginProfile('Sort', 3);
		sorter.sort(sampleMesh, void, sampleCount, sampleCount);
		dispatchCompute(compute_shader, 'findInsertCount', sampleCount);
		insertCount = paramBuffer.download(1, Util.TypeConstant.INT32, 3).front();
		minRadius = paramBuffer.download(1, Util.TypeConstant.FLOAT, 4).front();
		endProfile(3);
		
		// find minimum radius
		//minReducer.reduce(sampleMesh, insertCount, sampleCount);
		//minRadius = minReducer.getValue(Util.TypeConstant.FLOAT, 1);
		
		// update required resolution
		samplesPerLevel[level] = sampleCount;
		sampleCount += insertCount;
		
		if(adaptiveRes) {
			currentResolution = [[Utils.nextPowOfTwo(4 * maxDist / minRadius), maxResolution].min(), BLOCK_SIZE].max();	
			level = [minLevel, [maxLevel, (maxResolution/currentResolution).log(2)].min()].max();
			currentResolution = maxResolution/2.pow(level);
			rc.setViewport(0,0,currentResolution,currentResolution);
			rc.setScissor(new Rendering.ScissorParameters(new Geometry.Rect(0,0,currentResolution, currentResolution)));
			rc.bindBuffer(validBlockBuffers[level], Rendering.TARGET_SHADER_STORAGE_BUFFER, 1);
		}
		paramBuffer.upload([sampleCount,level,currentResolution], 0, Util.TypeConstant.INT32);
		paramBuffer.upload([maxRadius], 20, Util.TypeConstant.FLOAT);
		
		endProfile(2);
		
		if(debugLevel>=2) statistics["samples_per_round"] += sampleCount;
		if(insertCount <= 0 || minRadius <= 0)
			break;
		++round;
	}
	
	// TODO: new samples should have minimum radius - based on Lagae2008
	// TODO: predict number of rounds: reduce CPU-GPU communication, using indirect dispatch - only minor optimization
	// TODO: "sort indirect" set sort parameters from buffer - only minor optimization
	// TODO: use raster shader with "rings" for finding maximum
	// TODO: use depth buffer only for poisson sampling (write ids instead of depth)
	// TODO: use uniform radius for each round
	
	// optional final sort 
	if(globalSort) {
		beginProfile('Final Sort', 3);
		sorter.sort(sampleMesh, void, sampleCount);
		endProfile(3);
	}
	endProfile(1);
	
	// copy mesh
	beginProfile('Download', 1);
	
	// surfel mesh
	var surfelFormat = (new Rendering.VertexDescription).appendPosition3D().appendNormalByte().appendColorRGBAByte();
	var surfelMesh = (new Rendering.Mesh(surfelFormat, sampleCount, 0)).setDrawPoints().setUseIndexData(false).allocateGLData().releaseLocalData();
	rc.bindBuffer(surfelMesh, Rendering.TARGET_SHADER_STORAGE_BUFFER, 2);
	
	paramBuffer.upload([sampleCount], 0, Util.TypeConstant.INT32);
	dispatchCompute(compute_shader, 'copyMesh', sampleCount);
	
	// download surfelMesh
	surfelMesh._markAsChanged();
	//surfelMesh._swapVertexBuffer(new Rendering.BufferObject);
	endProfile(1);
		
	// restore state
	popState();
	
	// statistics
	statistics["rounds"] = round;
	statistics["samples"] = sampleCount;
	statistics["resolution"] = resolution;
	
	return surfelMesh;
};

// ----------------------------

T.detectSettings ::= fn(MinSG.Node node) {
	if(!autodetect)
		return [maxResolution, maxTargetCount];
	var s = node.getSRT().getScale();
	var w = node.getBB().getExtentX() * s;
	var h = node.getBB().getExtentY() * s;
	var d = node.getBB().getExtentZ() * s;
	var area = 4*Math.PI * (((w*h/4).pow(1.6)+(w*d/4).pow(1.6)+(h*d/4).pow(1.6)) / 3).pow(1/1.6);
	area = Utils.computeTotalSurface(node);
	var targetCount = [[MinSG.countTriangles(node), maxTargetCount].min(), 1].max();
	var r_max = (area/(2*3.sqrt()*targetCount)).sqrt();
	var resolution = r_max > 0 ? [Utils.nextPowOfTwo(node.getBB().getDiameter() / r_max), maxResolution].min() : 1;
	if(debugLevel >= 4) {
		outln("Est. Surface: ", area);
		outln("r_max: ", r_max);
		outln("Target Count: ", targetCount);
		outln("Resolution: ", resolution);
	}
	return [maxResolution, targetCount];
};

T.createDebugNode ::= fn(MinSG.Node node) {
	var cameras = rasterizer.placeCameras(node);
	var sphere = new Geometry.Sphere(node.getWorldBB().getCenter(), node.getWorldBB().getBoundingSphereRadius());
	var format = (new Rendering.VertexDescription).appendPosition3D().appendColorRGBAByte();
	var sphereMesh = Rendering.createWireSphere(format, sphere, 32);
	return new MinSG.GeometryNode(sphereMesh);
};

// --------------------------------------------------------------
// GUI

static SurfelGUI = Std.module("BlueSurfels/GUI/SurfelGUI");
SurfelGUI.registerSampler(T);
SurfelGUI.registerSamplerGUI(T, fn(sampler) {
	return [
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Directions",
			GUI.RANGE : [1,MAX_DIRECTIONS],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('gpusampler.directions', 16, [sampler] => fn(sampler, count) {
				sampler.setDirections(Utils.createDirections(count));
			}),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Peeling Layers",
			GUI.RANGE : [1,MAX_DIRECTIONS],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('gpusampler.peeling', 1, [sampler] => fn(sampler, count) {
				sampler.setPeelingLayers(count);
			}),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Resolution",
			GUI.RANGE : [0,11],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.RANGE_FN_BASE : 2,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('resolution', 512, sampler->sampler.setResolution),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Debug Level",
			GUI.RANGE : [0,4],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('gpusampler.debugLevel', 0, sampler->sampler.setDebugLevel),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Target Surfels",
			GUI.RANGE : [1,6],
			GUI.RANGE_STEP_SIZE : 1,
			GUI.RANGE_FN_BASE : 10,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('targetCount', 10000, sampler->sampler.setTargetCount),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Radius Factor",
			GUI.RANGE : [0,0.9],
			GUI.RANGE_STEP_SIZE : 0.05,
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('gpusampler.radiusFactor', 0.75, sampler->sampler.setRadiusFactor),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Autodetect",
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('gpusampler.autodetect', false, sampler->sampler.setAutodetect),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Final Sort",
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('gpusampler.sortGlobal', false, sampler->sampler.setGlobalSort),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Adaptive Resolution",
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('gpusampler.adaptiveRes', true, sampler->sampler.setAdaptiveResolution),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Adaptive Samples",
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('gpusampler.adaptiveSamples', false, sampler->sampler.setAdaptiveSamples),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Geodesic",
			GUI.DATA_WRAPPER : SurfelGUI.createConfigWrapper('gpusampler.geodesic', false, sampler->sampler.setGeodesic),
			GUI.SIZE : [GUI.WIDTH_FILL_ABS, 5, 0],
		},
		{ GUI.TYPE : GUI.TYPE_NEXT_ROW },
	];
});

return T;