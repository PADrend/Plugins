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

//! Trait that extends a Type to represent a directed edge in a graph.
var DirectedEdgeTrait = new Traits.GenericTrait('GraphTools.DirectedEdge');

DirectedEdgeTrait.attributes.edgeTail @(private) := void;
DirectedEdgeTrait.attributes.edgeHead @(private) := void;
DirectedEdgeTrait.attributes.edgeWeight @(private) := 1;

DirectedEdgeTrait.attributes.connectVertices ::= fn(tail, head) {
	this.setEdgeTail(tail);
	tail.addOutgoingEdge(this);
	this.setEdgeHead(head);
	head.addIncomingEdge(this);
};
DirectedEdgeTrait.attributes.getEdgeTail ::= fn() {
	return this.edgeTail;
};
DirectedEdgeTrait.attributes.getEdgeHead ::= fn() {
	return this.edgeHead;
};
DirectedEdgeTrait.attributes.getEdgeWeight ::= fn() {
	return this.edgeWeight;
};
DirectedEdgeTrait.attributes.setEdgeTail ::= fn(tail) {
	Traits.requireTrait(tail, Std.require('GraphTools/Vertex'));
	this.edgeTail = tail;
};
DirectedEdgeTrait.attributes.setEdgeHead ::= fn(head) {
	Traits.requireTrait(head, Std.require('GraphTools/Vertex'));
	this.edgeHead = head;
};
DirectedEdgeTrait.attributes.setEdgeWeight ::= fn(Number weight) {
	this.edgeWeight = weight;
};

DirectedEdgeTrait.onInit += fn(Type type) {
};

return DirectedEdgeTrait;
