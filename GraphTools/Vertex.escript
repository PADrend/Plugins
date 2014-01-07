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

//! Trait that extends a Type to represent a vertex in a graph.
var VertexTrait = new Traits.GenericTrait('GraphTools.Vertex'); 

VertexTrait.attributes.vertexIncomingEdges @(private, init) := Array;
VertexTrait.attributes.vertexOutgoingEdges @(private, init) := Array;

VertexTrait.attributes.addIncomingEdge ::= fn(edge) {
	Traits.requireTrait(edge, Std.require('GraphTools/DirectedEdge'));
	this.vertexIncomingEdges += edge;
};
VertexTrait.attributes.addOutgoingEdge ::= fn(edge) {
	Traits.requireTrait(edge, Std.require('GraphTools/DirectedEdge'));
	this.vertexOutgoingEdges += edge;
};
VertexTrait.attributes.getDirectPredecessors ::= fn() {
	var Set = Std.require('Std/Set');
	var predecessors = new Set;
	foreach(this.vertexIncomingEdges as var edge) {
		predecessors += edge.getEdgeTail();
	}
	return predecessors;
};
VertexTrait.attributes.getDirectSuccessors ::= fn() {
	var Set = Std.require('Std/Set');
	var successors = new Set;
	foreach(this.vertexOutgoingEdges as var edge) {
		successors += edge.getEdgeHead();
	}
	return successors;
};
VertexTrait.attributes.getIncomingEdges ::= fn() {
	return this.vertexIncomingEdges;
};
VertexTrait.attributes.getOutgoingEdges ::= fn() {
	return this.vertexOutgoingEdges;
};

VertexTrait.onInit += fn(Type type) {
};

return VertexTrait;
