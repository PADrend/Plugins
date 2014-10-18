/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static ConnectedComponent = new Type;
ConnectedComponent.triangles @(init) := Array;
ConnectedComponent.join ::= fn(ConnectedComponent other){
	if(other!=this){
		if(other.triangles.count()<this.triangles.count()){
			foreach( other.triangles as var triangle)
				triangle.connectedComponent = this;
			this.triangles.append( other.triangles );
			other.triangles = void;
		} else {
			foreach( this.triangles as var triangle)
				triangle.connectedComponent = other;
			other.triangles.append( this.triangles );
			this.triangles = void;
		}
	}
};
ConnectedComponent.addTriangle ::= fn(Triangle t){
	this.triangles += t;
	t.connectedComponent = this;
};

static Triangle = new Type;
Triangle.connectedComponent := void;
Triangle.triangleIndex := void;
Triangle.positions := void;
Triangle.indices := void;

Triangle._constructor ::= fn( Array _positions, Array _indices, Number _triangleIndex){
	this.positions = _positions;
	this.indices = _indices;
	this.triangleIndex = _triangleIndex;
};

Triangle.getVertices ::= fn(){
	var i = this.triangleIndex * 3;
	return [ this.positions[this.indices[i]], this.positions[this.indices[i+1]], this.positions[this.indices[i+2]] ];
};
Triangle.getIndices ::= fn(){
	var i = this.triangleIndex * 3;
	return [this.indices[i],this.indices[i+1],this.indices[i+2]];
};

static getConnectedComponents = fn( Array positions, Array indices, Geometry.Box bb, Number relDistance ){
	var distance = relDistance * bb.getDiameter();
	var searchSphere = new Geometry.Sphere( [0,0,0], distance );
	var octree = new Geometry.PointOctree(bb,distance,5);
	var triangles = [];
	for(var i=0; i<indices.count(); i+=3)
		triangles += new Triangle(positions,indices,i/3);
	var ccs = [];

	foreach( triangles as var i,var triangle){
		foreach( triangle.getVertices() as var pos ){
			searchSphere.setCenter( pos );
			foreach( octree.collectPointsWithinSphere( searchSphere ) as var point ){
				var otherTriangle = point.data;
				if(!triangle.connectedComponent){
					otherTriangle.connectedComponent.addTriangle(triangle);
				}else{
					otherTriangle.connectedComponent.join( triangle.connectedComponent );
				}
			}
		}
		if(!triangle.connectedComponent){
			var cc = new ConnectedComponent;
			cc.addTriangle( triangle );
			ccs += cc;
		}
		foreach( triangle.getVertices() as var pos )
			octree.insert( pos, triangle );
//		if( (i%100)==0 ) out(".",i);
	}
	ccs.filter( fn(cc){ return cc.triangles && !cc.triangles.empty(); });
//	print_r(ccs);
	return ccs;
};


return fn( Rendering.Mesh mesh , Number relDistance = 0.001 ){
	var indices = mesh._getIndices();
	var positions = [];
	var posAcc = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);
	var vertexCount = mesh.getVertexCount();
	for(var i=0; i<vertexCount; ++i)
		positions += posAcc.getPosition( i );
	var meshes = [];
	foreach( getConnectedComponents(positions,indices,mesh.getBoundingBox(),relDistance) as var cc){
		var indices2 = [];
		foreach( cc.triangles as var t)
			indices2.append( t.getIndices() );
		var mesh2 = mesh.clone();
		mesh2._setIndices(indices2);
		Rendering.eliminateUnusedVertices(mesh2);
		meshes += mesh2;
	}
	return meshes;
};
