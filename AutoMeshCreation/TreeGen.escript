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


MeshCreation.TreeGen :=  new Type;

var TreeGen = MeshCreation.TreeGen;


/*! Helper structure holding parameters for a branch */
// @{
static BranchData = new Type;
BranchData.initialSRT @(init) :=  Geometry.SRT;
BranchData.seg1 := 20; // number of steps
BranchData.seg2 := 5; // number of profile points (roundness of the branch)
BranchData.radius := 0.3; // initial radius
BranchData.bend := 0; // bending angle in degree
BranchData.b_incr := 0; // bending change per step
BranchData.b_incr2 := 0; // bending change change per step
BranchData.wind := 0; // winding angle in degree
BranchData.stretch := 1.0; // upward translation length per step
BranchData.stretch_fac := 1.0; // upward translation length change factor per step (stretch*=stretch_fac)
BranchData.scale_fac := 1.0; // scale factor per step (scale*=scale_fac)
BranchData.uScale := 1.0; // horizontal texture scale
BranchData.vScale := 10.0; // vertical texture scale
BranchData.branchingIndices @(init) :=  Array;
BranchData.level := 0;
BranchData.branchAngle := 90;
BranchData.onInit @(init) := Std.MultiProcedure; // called after the _extruder  and profile vertices have been set
BranchData.parent := void;
BranchData.parentIndex := void;


BranchData._extruder := void;

BranchData._constructor ::= fn( [BranchData,void] parent,Number index=0){
	this.parent = parent;
	this.level = parent ? parent.level+1 : 0;
	this.parentIndex = index;
};

// @}

		

TreeGen.executeBranchExtruder ::= fn(Rendering.MeshBuilder mb,BranchData d){
	@(once) static Extruder = Std.require('AutoMeshCreation/Extruder');
	
	var ext = new Extruder;
	ext.uScale = d.uScale;
	ext.vScale = d.vScale;

	{ // add profile
		ext.closeProfileShape=true;
		var incr = (2*Math.PI)/d.seg2;
		var ang = 0;
		var r = d.radius;
		for(var i=0;i<=d.seg2;i++){
			ext.addProfileVertex( new Geometry.Vec3(ang.cos(),0,ang.sin())*r );
			ang+=incr;
		}
	}
	
	d._extruder = ext;
	d.onInit();
	
	{  // create SRTs
		var bend = d.bend;
		var b_incr = d.b_incr;
		var b_incr2 = d.b_incr2;
		var wind = d.wind;
		var stretch = d.stretch;//Rand.normal(0.4,0.1);
		var stretch_fac = d.stretch_fac;
		var scale_fac = d.scale_fac;
		var srt = d.initialSRT.clone();

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
		srt.setScale(0);
		ext.addControlSRT(srt);

	}
	ext.addMesh(mb);
};
TreeGen.createBranchData ::= fn([BranchData,void] p=void,Number index = 0){
	if(p&&p.level>3)
		return void;
		
	
	var d = new BranchData(p,index);
	d.seg1 = 20;
	d.bend = Rand.normal(0.0,10.0/d.seg1);
	d.b_incr = Rand.normal(0.0,0.5);
	d.b_incr2 = Rand.normal(0.0,0.1);
	if( d.b_incr*d.b_incr2>0 ) d.b_incr2*=-1;
	d.wind = Rand.normal(0.0,180.0/d.seg1);
	d.stretch = Rand.normal(0.5,0.1);
	d.stretch_fac = Rand.uniform(0.97,0.94);
	d.scale_fac=0.9;
	d.branchingIndices = [8,8,10,10,13,13,17,20];
	d.branchAngle = Rand.normal(45,20);
	
	if(p){
		
		var srt = p._extruder.getControlSRT(index);
		if(!srt)
			return void;
		srt = srt.clone();
		srt.setRotation(srt.getRotation().rotateLocal_deg(Rand.uniform(0,360),[0,1,0]));
		srt.setRotation(srt.getRotation().rotateLocal_deg(d.branchAngle, [1,0,0]));
		d.initialSRT = srt;

		d.seg1 = p.seg1*0.5;
		d.bend = Rand.normal(0.0,90.0/d.seg1);
		d.radius = p.radius*0.7;
		d.b_incr = Rand.normal(0.0,0.9);
		d.stretch = d.stretch*0.5;
		d.branchAngle = Rand.normal(0,20);
	}else{
//		d.radius = 0.01;
	}
	if(d.level<2){
		d.onInit += fn(){
			var srt =  this.initialSRT;
			var scale = srt.getScale();
			if(scale==0)
				return;

			var t = new Geometry.Vec3(0, this.radius/scale,0);

			if(this.parent){
				var pSrt = this.parent._extruder.getControlSRT(this.parentIndex);
				if(pSrt)
					this._extruder.addControlSRT(pSrt);
				
				srt.translateLocal( t*0.2 );
			}
			
			
			srt.setScale( scale*1.1 );
			this._extruder.addControlSRT(srt);
			
			srt.setScale( scale );
			srt.translateLocal( t*0.3 );
			srt.setScale( scale*1.3 );
			this._extruder.addControlSRT(srt);
			
			srt.setScale( scale );
			srt.translateLocal( t*0.3 );
			srt.setScale( scale*1.1 );
			this._extruder.addControlSRT(srt);
			
			srt.setScale( scale );
			srt.translateLocal( t*0.2 );
			
		};
	}

	return d;
};

TreeGen.buildMesh ::= fn(){
	var mb = new Rendering.MeshBuilder;
	var branches = [ this.createBranchData() ];

	while(!branches.empty()){
		var d = branches.popBack();
		this.executeBranchExtruder(mb,d);

		foreach(d.branchingIndices as var index){
			var d2 = this.createBranchData(d,index);
			if(!d2)
				break;
			branches+=d2;
		}
	}

	var mesh = mb.buildMesh();
	Rendering.calculateNormals(mesh);
	return mesh;
};

//TreeGen.bonsai ::= fn(){
//	var tGen = new MeshCreation.TreeGen;
//	tGen.
//
//};


TreeGen.test ::= fn(){
	var t = clock();
	var tGen = new MeshCreation.TreeGen;
	var node = new MinSG.GeometryNode(tGen.buildMesh());
	node.moveRel( new Geometry.Vec3(thisFn.counter++ * 5,0,0) );
	node += (new MinSG.MaterialState)
				.setAmbient(new Util.Color4f(0.4,0.3,0.1,1.0))
				.setDiffuse(new Util.Color4f(0.5,0.4,0.3,1.0))
				.setSpecular(new Util.Color4f(0.5,0.5,0.5,1.0));
	PADrend.getCurrentScene() += node;
	out(clock()-t,"\n");
	return node;
};
TreeGen.test.counter :=  0;

GLOBALS.tree := TreeGen.test;

return TreeGen;