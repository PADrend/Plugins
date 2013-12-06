/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2009 Jan Krems
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
//! Helper functions for creating various primitives


declareNamespace($MeshCreation);




// ----------------------------------------------------------------------
/*! Add a disk to the given meshBuilder. Use the @p transformation to control its size and appearance.
	Per default its center is (0,0,0) lying on the x,z-plane.
	\see MeshBuilder.createDiskSector(...) as alternative.
*/
MeshCreation.addDisk := fn(Rendering.MeshBuilder mb,numSegments = 16,Geometry.SRT transformation = new Geometry.SRT()){
	mb.normal( transformation.applyRotation(new Geometry.Vec3(0,1,0)) );
	mb.position( new Geometry.Vec3(0,0,0) );
	var firstIndex = mb.addVertex();
	
	var stepWidth = Math.PI*2/numSegments;

	var d = 0;
	for(var i=0;i<numSegments;++i){
		mb.position(transformation * new Geometry.Vec3(d.cos(),0,d.sin()));
		mb.addVertex();
		d+=stepWidth;
	}
	
	mb.addTriangle(firstIndex,firstIndex+1,firstIndex+numSegments);
	for(var i=1;i<numSegments;++i){
		mb.addTriangle(firstIndex,firstIndex+i+1,firstIndex+i);
	}

};



MeshCreation.testDisk := fn(){
	var mb = new Rendering.MeshBuilder();
	mb.color( new Util.Color4f(1,0,0,1) );
	MeshCreation.addDisk(mb);
	PADrend.getCurrentScene() += new MinSG.GeometryNode(mb.buildMesh());
};	

// ------------------

/*! Add a disk to the given meshBuilder. Use the @p transformation to control its size and appearance.
	Per default its center is (0,0,0) lying on the x,z-plane.
	\see MeshBuilder.createDiskSector(...) as alternative.
*/
MeshCreation.addGear := fn(Rendering.MeshBuilder mb,numSegments = 16,Geometry.SRT transformation = new Geometry.SRT()){
	numSegments = numSegments.round(2);
	
	mb.normal( transformation.applyRotation(new Geometry.Vec3(0,1,0)) );
	mb.position( new Geometry.Vec3(0,0,0) );
	var firstIndex = mb.addVertex();
	
	var stepWidth = Math.PI*2/numSegments;
	var stepWidth_a = stepWidth* 3/4;
	var stepWidth_b = stepWidth-stepWidth_a;
	
	
	var d = 0;
	for(var i=0;i<numSegments;++i){
		var s = (i%2==0) ? 1.05 : 0.95;
		mb.position(transformation * (new Geometry.Vec3(d.cos(),0,d.sin())*s));
		mb.addVertex();
		d+=stepWidth_a;		
		mb.position(transformation * (new Geometry.Vec3(d.cos(),0,d.sin())*s));
		mb.addVertex();
		d+=stepWidth_b;
	}
	
	mb.addTriangle(firstIndex,firstIndex+1,firstIndex+numSegments*2);
	for(var i=1;i<numSegments*2;++i){
		mb.addTriangle(firstIndex,firstIndex+i+1,firstIndex+i);
	}

};

MeshCreation.testGear := fn(){
	var mb = new Rendering.MeshBuilder();
	mb.color( new Util.Color4f(1,0,0,1) );
	MeshCreation.addGear(mb,32);
	PADrend.getCurrentScene() += new MinSG.GeometryNode(mb.buildMesh());
};	
