/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
// MeshBuilder extension

Rendering.MeshBuilder.addBox ::= fn(Geometry.Box box){
	var i=this.getNextIndex();
	
	var normals = [new Geometry.Vec3(0,0,-1), new Geometry.Vec3(1,0,0), new Geometry.Vec3(0,0,1), new Geometry.Vec3(-1,0,0), new Geometry.Vec3(0,1,0), new Geometry.Vec3(0,-1,0)];
	var sideCorners = [ [6,4,5,7], [7,5,1,3], [3,1,0,2], [2,0,4,6] , [2,6,7,3], [0,1,5,4] ];
	var uvIndices = [ [0,1], [1,2], [0,1], [1,2], [0,2], [0,2] ]; // x=0, y=1, z=2
	
	foreach( sideCorners  as var sideNr,var side){
		this.normal(normals[sideNr]);
		foreach(side as var cornerId){
			var corner = box.getCorner(cornerId);
			var cornerArr = corner.toArray();
			this.position(corner);
			this.texCoord0(new Geometry.Vec2(cornerArr[uvIndices[sideNr][0]], cornerArr[uvIndices[sideNr][1]]));
			this.addVertex();
		}
		this.addQuad(i,i+1,i+2,i+3);
		i+=4;
	}
	return this;
};



return true;
