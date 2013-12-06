/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] AutoMeshCreation/TreeGen.escript
 ** 2010-07 Claudius Spielerei...
 **/

declareNamespace($MeshCreation);
loadOnce(__DIR__+"/Extruder.escript");

MeshCreation.TreeGen := new Type;

var TreeGen = MeshCreation.TreeGen;


/*! Helper structure holding parameters for a branch */
// @{
TreeGen.BranchData:=new Type();
TreeGen.BranchData.initialSRT @(init) := Geometry.SRT;
TreeGen.BranchData.seg1:=20; // number of steps
TreeGen.BranchData.seg2:=5; // number of profile points (roundness of the branch)
TreeGen.BranchData.r:=0.3; // initial radius
TreeGen.BranchData.bend:=0; // bending angle in degree
TreeGen.BranchData.b_incr:=0; // bending change per step
TreeGen.BranchData.b_incr2:=0; // bending change change per step
TreeGen.BranchData.wind:=0; // winding angle in degree
TreeGen.BranchData.stretch:=1.0; // upward translation length per step
TreeGen.BranchData.stretch_fac:=1.0; // upward translation length change factor per step (stretch*=stretch_fac)
TreeGen.BranchData.scale_fac:=1.0; // scale factor per step (scale*=scale_fac)
TreeGen.BranchData.uScale:=1.0; // horizontal texture scale
TreeGen.BranchData.vScale:=10.0; // vertical texture scale
TreeGen.BranchData.branchingIndices @(init) := Array;
TreeGen.BranchData.level:=0;
TreeGen.BranchData.branchAngle:=90;
// @}

TreeGen.createBranchExtruder ::= fn(MeshCreation.TreeGen.BranchData d){
	var ext = new MeshCreation.Extruder();
	ext.uScale=d.uScale;
	ext.vScale=d.vScale;

	{ // add profile
//		ext.closeProfileShape=true;
		var incr=(2*Math.PI)/d.seg2;
		var ang=0;
		var r=d.r;
		for(var i=0;i<=d.seg2;i++){
			ext.addProfileVertex( new Geometry.Vec3(ang.cos(),0,ang.sin())*r );
			ang+=incr;
		}
	}

	{  // create SRTs
		var bend=d.bend;
		var b_incr=d.b_incr;
		var b_incr2=d.b_incr2;
		var wind=d.wind;
		var stretch=d.stretch;//Rand.normal(0.4,0.1);
		var stretch_fac=d.stretch_fac;
		var scale_fac=d.scale_fac;
		var srt=d.initialSRT.clone();

		ext.addControlSRT(srt.clone());
		for(var i=0; i<d.seg1; ++i ){
			srt.rotateLocal_deg(bend,new Geometry.Vec3(1,0,0));
			bend+=b_incr;
			b_incr+=b_incr2;

			srt.rotateLocal_deg(wind,new Geometry.Vec3(0,1,0));

			srt.translateLocal( new Geometry.Vec3(0,stretch,0)/srt.getScale() );
			stretch*=stretch_fac;

			srt.scale(scale_fac);
			ext.addControlSRT(srt.clone());
		}
	}
	return ext;
};
TreeGen.createRandBranchData ::= fn(){
	var d=new BranchData();
	d.seg1=20;
	d.bend=Rand.normal(0.0,10.0/d.seg1);
	d.b_incr=Rand.normal(0.0,0.5);
	d.b_incr2=Rand.normal(0.0,0.1);
	if( d.b_incr*d.b_incr2>0 ) d.b_incr2*=-1;
	d.wind=Rand.normal(0.0,180.0/d.seg1);
	d.stretch=Rand.normal(0.5,0.1);
	d.stretch_fac=Rand.uniform(0.97,0.94);
	d.scale_fac=0.9;
	d.initialSRT=new Geometry.SRT(new Geometry.Vec3(0,0,0),new Geometry.Vec3(0,0,1),new Geometry.Vec3(0,1,0));
	d.initialSRT.setRotation(d.initialSRT.getRotation().rotateLocal_deg(Rand.uniform(0,360.0),new Geometry.Vec3(0,1,0)));
	d.branchingIndices=[5,5,7,7,10,10,14];
	d.branchAngle=Rand.normal(45,20);
	return d;
};

TreeGen.buildMesh ::= fn(){
	var d=createRandBranchData();
	var branches=[d];
	d.bend*=0.3;
	d.b_incr*=0.3;
	d.seg1=15;
	d.seg2=8;
	d.bend=Rand.normal(0.0,90.0/d.seg1);
	if( d.bend*d.b_incr>0 ) d.b_incr*=-1;

	var mb = new Rendering.MeshBuilder();
	
	while(!branches.empty()){
		var d=branches.popBack();
		var ext=createBranchExtruder(d);

		ext.addMesh(mb);
//		out(d.level," ");
		if(d.level>4) continue;

		foreach(d.branchingIndices as var index){
			var d2=createRandBranchData();
			var srt=ext.getControlSRT(index);
			if(!srt)
				break;
			srt=srt.clone();
			srt.setRotation(srt.getRotation().rotateLocal_deg(Rand.uniform(0,360),new Geometry.Vec3(0,1,0)));
			srt.setRotation(srt.getRotation().rotateLocal_deg(d2.branchAngle,new Geometry.Vec3(1,0,0)));
			d2.initialSRT = srt;

			d2.seg1 = d.seg1*0.7;
			d2.bend=Rand.normal(0.0,90.0/d2.seg1);
			d2.r=d.r*0.7;
//			d2.bend = -d.bend*8;
//			d2.b_incr=d.b_incr*2;
			d2.b_incr=Rand.normal(0.0,0.9);
			d2.stretch=d.stretch*0.5;
			d2.level=d.level+1;
			d2.branchAngle=Rand.normal(0,20);
			branches+=d2;
		}
	}



	var mesh = mb.buildMesh();
	Rendering.calculateNormals(mesh);
	return mesh;
};

GLOBALS.tree:=fn(){
	var t = clock();
	var tGen = new MeshCreation.TreeGen();
	var node = new MinSG.GeometryNode(tGen.buildMesh());
	node.moveRel( new Geometry.Vec3(thisFn.counter++ * 5,0,0) );
	node += (new MinSG.MaterialState())
				.setAmbient(new Util.Color4f(0.4,0.3,0.1,1.0))
				.setDiffuse(new Util.Color4f(0.5,0.4,0.3,1.0))
				.setSpecular(new Util.Color4f(0.5,0.5,0.5,1.0));
	PADrend.getCurrentScene() += node;
	out(clock()-t,"\n");
	return node;
};
tree.counter := 0;
