/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static ProgressBar = Std.module('Tools/ProgressBar');
static Utils = Std.module("BlueSurfels/Utils");
static progressBar = new ProgressBar;

static T = new Type(ExtObject);

T.getConfig := fn() {
	return new ExtObject({
		$samplerName : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.sampler','ProgressiveSampler'),
		$scannerName : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.scanner','RasterScanner'),
		$seed : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.seed', 0),
		$debug : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.debug', false),
		$directionPresetName : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.directions', 'cube'),
		$resolution : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.resolution', 512),
		$targetCount : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.targetCount', 10000),
		$samplesPerRound : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.samplesPerRound', 200),
		$sampleResolution : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.sampleResolution', 512),
		$maxRounds : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.maxRounds', 1000),
		$mitchellK : Std.DataWrapper.createFromEntry(PADrend.configCache,'BlueSurfels.mitchellK', 1),
	});
};

// -------------------------------
// sampler
T.sampler @(private, init) := MinSG.BlueSurfels.ProgressiveSampler;
T.setSampler @(public) ::= fn(value) {
  sampler = value;
  return this;
};
T.setTargetCount @(public) ::= fn(value) { sampler.setTargetCount(value); };
T.setMaxAbsSurfels @(public) ::= fn(value) { sampler.setTargetCount(value); }; // deprecated
T.setMaxRelSurfels @(public) ::= fn(value) { }; // deprecated

// -------------------------------
// scanner
T.scanner @(private, init) := Std.module('BlueSurfels/Scanners/RasterScanner');
T.setScanner @(public) ::= fn(value) {
  scanner = value;
  return this;
};

// -------------------------------
// statistics
T.statistics @(private, init) := Map;
T.getStatistics @(public) ::= fn() {
  if(sampler)
    statistics.merge(sampler.getStatistics());
  if(scanner)
    statistics.merge(scanner.getStatistics());
  return statistics;
};

// -------------------------------

// -------------------------------

T.createSurfelsForNode @(public) ::= fn(node, limit=false) {
  var timer = new Util.Timer;
  
  var initialSamples = scanner.scanSurface(node);
  if(!initialSamples) 
    return;  
			
	var maxSurfelCount = sampler.getTargetCount();
	if(limit)
		sampler.setTargetCount([maxSurfelCount, MinSG.countTriangles(node)].min());
		
  var surfels = sampler.sampleSurfels(initialSamples);
	sampler.setTargetCount(maxSurfelCount);
	
  if(!surfels)
    return;
		
  // calculate median distance
  var medianTimer = new Util.Timer;
	var medianCount = [[100, surfels.getVertexCount()].min(), surfels.getVertexCount() * 0.1].max();
  var median = MinSG.BlueSurfels.getMedianOfNthClosestNeighbours(surfels,medianCount,2);
	var surface = medianCount * median * median;
  statistics['t_median'] = medianTimer.getSeconds();
  statistics['t_total'] = timer.getSeconds();
  statistics['median'] = median;
  statistics['surface'] = surface;
  
  // attach surfels to node
	Utils.attachSurfels(node, surfels, surface);
};

T.createSurfelsForLeafNodes @(public) ::= fn(Array rootNodes) {
  var timer = new Util.Timer;
  
	var nodeSet = new Set;
	foreach(rootNodes as var root) {
		root.traverse([nodeSet] => this->fn(todo, node) {
			var proto = node.getPrototype();
			if(!proto)
				proto = node;
			
			if(proto.isClosed()) {
				todo += proto;
				return $BREAK_TRAVERSAL;
			}
			
			if(proto ---|> MinSG.GeometryNode)
				todo += proto;
		});
	}
	var todoList = nodeSet.toArray();
	
	progressBar.setDescription("Blue Surfels");
	progressBar.setSize(500, 32);
	progressBar.setToScreenCenter();
	progressBar.setMaxValue(nodeSet.count());
	progressBar.update(0);
	
	var config = getConfig();
	
	var maxSurfelCount = sampler.getTargetCount();
	var count = 0;
	foreach(todoList as var node) {
		progressBar.setDescription("Blue Surfels: Processing " + (++count) + "/" + todoList.count());
		
		var directions = Utils.getDirectionsFromPreset(config.directionPresetName());
		//var size = Utils.getMinProjTriangleSize(node, directions);
		//var resolution = [[Utils.nextPowOfTwo(size > 0 ? (1/size).ceil() : 1), 4].max(), 2048].min();
		//var surfelCount = Utils.computeVisibleTriangles(node, directions, resolution);
		//surfelCount = [[surfelCount, 4].max(), maxSurfelCount].min();
		var surfelCount = [MinSG.countTriangles(node), maxSurfelCount].min();
		
		//scanner.setResolution(resolution);
		sampler.setTargetCount(surfelCount);
		createSurfelsForNode(node);
		
		if(Utils.handleUserEvents()) {
			statistics['status'] = "aborted";
			break;
		}
		progressBar.update(count);
	}
	
  statistics['t_total'] = timer.getSeconds();
	statistics['status'] = "finished";
	print_r(statistics);
};

T.createSurfelHierarchy @(public) ::= fn(Array rootNodes) {
  var timer = new Util.Timer;
	var config = getConfig();	
	var maxSurfelCount = sampler.getTargetCount();
  
	var innerNodes = new Set;
	var leafNodes = new Set;
	foreach(rootNodes as var root) {
		root.traverse([innerNodes, leafNodes] => this->fn(innerNodes, leafNodes, node) {
			var proto = node.getPrototype();
			if(!proto)
				proto = node;
			
			if(proto.isClosed() || proto ---|> MinSG.GeometryNode) {
				// leaf node
				leafNodes += proto;
				return $BREAK_TRAVERSAL;
			}
			
			innerNodes += proto;
		});
	}
	innerNodes = innerNodes.toArray();
	leafNodes = leafNodes.toArray();
		
	progressBar.setDescription("Blue Surfels");
	progressBar.setSize(500, 32);
	progressBar.setToScreenCenter();
	progressBar.setMaxValue(leafNodes.count());
	progressBar.update(0);
	 
	// annotate all leaf nodes with their intended surfel count	
	var count = 0;
	foreach(leafNodes as var node) {
		progressBar.setDescription("Blue Surfels: Compute leaf surfel count " + (++count) + "/" + leafNodes.count());
		
		var directions = Utils.getDirectionsFromPreset(config.directionPresetName());
		var size = Utils.getMinProjTriangleSize(node, directions);
		var resolution = [[Utils.nextPowOfTwo(size > 0 ? (1/size).ceil() : 1), 4].max(), 2048].min();
		var surfelCount = Utils.computeVisibleTriangles(node, directions, resolution);
		surfelCount = [[surfelCount, 4].max(), maxSurfelCount].min();
		var surface = Utils.estimateVisibleSurface(node, directions, resolution);
		node.setNodeAttribute('$cs$targetSurfels', surfelCount);		
		
		if(Utils.handleUserEvents()) {
			statistics['status'] = "aborted";
			break;
		}
		progressBar.update(count);
	}
};


T.recreateSurfelsForAllNodes @(public) ::= fn(Array rootNodes) {
  var timer = new Util.Timer;
  
	var nodeSet = new Set;
	foreach(rootNodes as var root) {
		root.traverse([nodeSet] => this->fn(todo, node) {
			var proto = node.getPrototype();
			if(!proto)
				proto = node;
			
			var surfels = Utils.locateSurfels(proto);
			if(surfels)
				todo += proto;
		});
	}
	var todoList = nodeSet.toArray();
	
	progressBar.setDescription("Blue Surfels");
	progressBar.setSize(500, 32);
	progressBar.setToScreenCenter();
	progressBar.setMaxValue(nodeSet.count());
	progressBar.update(0);
	
	var config = getConfig();
	
	var maxSurfelCount = sampler.getTargetCount();
	var count = 0;
	var directions = Utils.getDirectionsFromPreset(config.directionPresetName());
	var totalCount =  todoList.count();
	
	foreach(todoList as var node) {
		progressBar.setDescription("Blue Surfels: Processing " + (++count) + "/" + todoList.count());
		
		var oldSurfels = Utils.locateSurfels(node);
		var surfelCount = oldSurfels.getVertexCount();
		sampler.setTargetCount(surfelCount);
		createSurfelsForNode(node);
		
		if(Utils.handleUserEvents()) {
			statistics['status'] = "aborted";
			break;
		}
		progressBar.update(count);
	}
	
  statistics['t_total'] = timer.getSeconds();
  statistics['processed'] = totalCount;
	statistics['status'] = "finished";
	print_r(statistics);
	Util.saveFile("./stats/benchmark_surfels.json", toJSON(statistics));
};

return T;