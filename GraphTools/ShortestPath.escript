/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/**
 * Run Dijkstra's algorithm on a directed graph to compute the shortest path
 * between the vertex @p source and the vertex @p target.
 * 
 * @param vertices Objects of a type with the 'GraphTools/Vertex' trait
 * @param source Source vertex in the graph. Also contained in @p vertices.
 * @param source Target vertex in the graph. Also contained in @p vertices.
 * @return Array containing vertices, including the source and the target.
 * If there is no path between source and target, an empty array is returned.
 */
return fn(Array vertices, source, target) {
	var VertexTrait = Std.require('GraphTools/Vertex');
	Traits.requireTrait(source, VertexTrait);
	Traits.requireTrait(target, VertexTrait);

	var previous = new Map;
	var infinity = 1.0e+20;
	var queue = new Util.UpdatableHeap;
	var queueElements = new Map;
	foreach(vertices as var vertex) {
		Traits.requireTrait(vertex, VertexTrait);

		// The distance is stored as the cost in the heap.
		queueElements[vertex] = queue.insert(vertex === source ? 0 : infinity,
											 vertex);
	}

	while(queue.size() > 0) {
		var u = queue.top().data();
		var distU = queue.top().getCost();
		queue.pop();
		queueElements.unset(u);

		// Stop here when the target has been found.
		if(u === target) {
			break;
		}

		if(distU == infinity) {
			break;
		}

		foreach(u.getOutgoingEdges() as var edge) {
			var v = edge.getEdgeHead();
			var distNew = distU + edge.getEdgeWeight();
			if(queueElements.containsKey(v) && 
			   distNew < queueElements[v].getCost()) {
				previous[v] = u;
				queue.update(queueElements[v], distNew);
			}
		}
	}
	var path = [];
	var u = target;
	while(previous.containsKey(u)) {
		path.pushFront(u);
		u = previous[u];
	}
	return path;
};
