/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] AutoMeshCreation/Extruder.escript
 ** 2010-07 Claudius Spielerei...
 **/

/*! Extrudes a (profile) line segment.
	Copies a profile line to all positions given by control SRTs and connects them to a surface.
	Can be used to create tubes, donuts, bend branches, glasses, bottles ...
	\todo add support for normals
	*/
	
declareNamespace($MeshCreation);

MeshCreation.Extruder := new Type(ExtObject) ;

var Extruder = MeshCreation.Extruder;

Extruder.profileShape @(private,init) := Array;
Extruder.constrolSRTs @(private,init) := Array;
Extruder.closeProfileShape:=false;
Extruder.closeExtrusion:=false;
Extruder.uScale:=1.0;
Extruder.vScale:=1.0;


Extruder.addProfileVertex ::= fn(pointParams...){
	profileShape += new Geometry.Vec3(pointParams...);
};

Extruder.addControlSRT ::= fn(srtParams...){
	constrolSRTs += new Geometry.SRT(srtParams...);
};

Extruder.getControlSRT ::= fn(index){
	return constrolSRTs[index];
};

Extruder.buildMesh ::= fn(){
	var mb = new Rendering.MeshBuilder;
	addMesh(mb);
	var mesh = mb.buildMesh();
	Rendering.calculateNormals(mesh);
	return mesh;
};

Extruder.addMesh ::= fn(Rendering.MeshBuilder mb){
	var numBasePoints = profileShape.count();
	var pointLoopLimit = closeProfileShape?numBasePoints : numBasePoints-1;
	var uIncr = uScale/pointLoopLimit;
	var vIncr = vScale/constrolSRTs.count();

	var initialIndex = mb.getNextIndex();

	var u=0;
	var v=0;
	
	mb.setTransformation(constrolSRTs[0]);
	// add initial points
	foreach(profileShape as var bp){
		mb.position(bp).texCoord0( new Geometry.Vec2(u,v) ).addVertex();
		u+=uIncr;
	}
	var index;
	for(var i=1;i<constrolSRTs.count();++i){
		index = mb.getNextIndex();
		v+=vIncr;

		// add points
		u=0;
		mb.setTransformation(constrolSRTs[i]);
		foreach(profileShape as var bp){
//			ctxt.addVertex( srt*bp,u,v );
			mb.position(bp).texCoord0( new Geometry.Vec2(u,v) ).addVertex();
			u+=uIncr;
		}

		// build quads
		for(var j=0;j<pointLoopLimit;++j){
			mb.addQuad(index+j, index+(j+1)%numBasePoints, index+(j+1)%numBasePoints-numBasePoints, index+j-numBasePoints);
		}
	}
	// connect last points to initial points
	if(closeExtrusion){
		// build quads
		for(var j=0;j<pointLoopLimit;++j){
			mb.addQuad(initialIndex+j, initialIndex+(j+1)%numBasePoints, index+(j+1)%numBasePoints, index+j);
		}
	}
};





