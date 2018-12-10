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

static NS = new Namespace;

// ------------------------------------------------------------

NS.accumulateStatistics @(public) := fn(statistics) {
  if(statistics.count() <= 1)
    return statistics.front();
  var accStats = new Map;
  foreach(statistics as var stat) {
    foreach(stat as var key, var value) {
      var aKey = key + ' (sum)';
      if(value.isA(Number)) {
        if(!accStats.containsKey(aKey))
          accStats[aKey] = 0;
        accStats[aKey] += value;
      }
    }
  }
  accStats['processed'] = statistics.count();
};

// ------------------------------------------------------------

NS.createSurfelsForNode @(public) := fn(node, sampler) {
  var statistics = new Map;
  var timer = new Util.Timer;
  Utils.removeSurfels(node);
  if(!sampler) {
    statistics['status'] = "failed";
    return statistics;
  }
  
  var surfels = sampler.sample(node);
  statistics.merge(sampler.getStatistics());
  
  if(!surfels) {
    statistics['status'] = "failed";
    return statistics;
  }
    
  // attach surfels to node
  var finalTimer = new Util.Timer;
	Utils.attachSurfels(node, surfels, statistics['packing']);  
  statistics['t_finalize'] = finalTimer.getSeconds();
  
  statistics['t_total'] = timer.getSeconds();
  statistics['status'] = "success";
  return statistics;
};

// ------------------------------------------------------------

NS.createSurfelsForNodes @(public) := fn(nodes, sampler) {
  progressBar.setDescription("Blue Surfels");
  progressBar.setSize(500, 32);
  progressBar.setToScreenCenter();
  progressBar.setMaxValue(nodes.count());
  progressBar.update(0);
  var statistics = [];

  foreach(nodes as var index, var node) {    
		progressBar.setDescription("Blue Surfels: Processing " + (index+1) + "/" + nodes.count());
    
    statistics += createSurfelsForNode(node, sampler);
    
    if(Utils.handleUserEvents())
      break;
      
    progressBar.update(index+1);
  }
  
  return statistics;
};

// ------------------------------------------------------------

NS.createSurfelsForLeafNodes @(public) := fn(Array rootNodes, sampler) {
  // Collect nodes
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
  return createSurfelsForNodes(nodeSet.toArray(), sampler);
};

// ------------------------------------------------------------

NS.createSurfelHierarchy @(public) := fn(Array rootNodes, sampler) {
  // Collect nodes
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
			
			todo += proto;
		});
	}
  return createSurfelsForNodes(nodeSet.toArray(), sampler);
};

// ------------------------------------------------------------

NS.recreateSurfelsForAllNodes @(public) := fn(Array rootNodes, sampler) {
  // Collect nodes
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
	var nodes = nodeSet.toArray();

  progressBar.setDescription("Blue Surfels");
  progressBar.setSize(500, 32);
  progressBar.setToScreenCenter();
  progressBar.setMaxValue(nodes.count());
  progressBar.update(0);
  var statistics = [];
  
  var oldTargetCount = sampler.getTargetCount();
  foreach(nodes as var index, var node) {    
		progressBar.setDescription("Blue Surfels: Processing " + (index+1) + "/" + nodes.count());
    
		var oldSurfels = Utils.locateSurfels(node);
		sampler.setTargetCount(oldSurfels.getVertexCount());
    statistics += createSurfelsForNode(node, sampler);
    
    if(Utils.handleUserEvents())
      break;
      
    progressBar.update(index+1);
  }
  sampler.setTargetCount(oldTargetCount);
  
  return statistics;
};

return NS;