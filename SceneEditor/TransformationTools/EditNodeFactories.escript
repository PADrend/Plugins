/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor/EditNodeFactories]
 ** Collection helper functions to create editNodes; meta nodes for direct interactions in the 3-d-space.
 **
 **/

static EditNodeTraits = module('./EditNodeTraits');
 
static EditNodeFactories = new Namespace;

//---------------------------------------------------------------------------------

/*!	Creates a 3-d-translation node. It provides the following methods:

	>	void Node.onTranslationStart()								(extendable MultiProcedure)
	>	void Node.onTranslate(Geometry.Vec3 worldTranslation)		(extendable MultiProcedure)
	>	void Node.onTranslationStop(Geometry.Vec3 worldTranslation)	(extendable MultiProcedure)
*/
EditNodeFactories.createTranslationEditNode := fn(){
	var container = new MinSG.ListNode;

	container.onTranslate := new MultiProcedure; // fn(Geometry.Vec3)
	container.onTranslationStart := new MultiProcedure; //fn(){...}
	container.onTranslationStop := new MultiProcedure; //fn(){Geometry.Vec3}

	var arrow = EditNodeFactories.getArrowMeshToXAxis();
	var ring = EditNodeFactories.getRingSegmentMesh();

	//			0 mesh	1 translationTrait					2 color						3 rotation
	foreach( [	[arrow,	EditNodeTraits.TranslatableAxisTrait,	new Util.Color4f(1,0,0,1.0),false],
				[arrow,	EditNodeTraits.TranslatableAxisTrait,	new Util.Color4f(0,1,0,1.0),new Geometry.Vec3(0,0,1)],
				[arrow,	EditNodeTraits.TranslatableAxisTrait,	new Util.Color4f(0,0,1,1.0),new Geometry.Vec3(0,-1,0)],
				[ring,	EditNodeTraits.TranslatablePlaneTrait,	new Util.Color4f(1,1,0,1.0),false],
				[ring,	EditNodeTraits.TranslatablePlaneTrait,	new Util.Color4f(0,1,1,1.0),new Geometry.Vec3(0,-1,0)],
				[ring,	EditNodeTraits.TranslatablePlaneTrait,	new Util.Color4f(1,0,1,1.0),new Geometry.Vec3(1,0,0)]
			]	as var properties){

		var n = new MinSG.GeometryNode( properties[0] );
		Traits.addTrait( n,EditNodeTraits.ColorTrait,properties[2] );
		Traits.addTrait( n,properties[1] );

		if(properties[3])
			n.rotateLocal_deg(90,properties[3]);

		n.onTranslate += fn(v){
			getParent().onTranslate(v);
		};
		n.onTranslationStart += fn(){
			this.pushColor(new Util.Color4f(2,2,2,1));
			getParent().onTranslationStart();
		};
		n.onTranslationStop += fn(v){
			this.popColor();
			getParent().onTranslationStop(v);
		};
		container+=n;
	}
	return container;
};

//---------------------------------------------------------------------------------
EditNodeFactories.createRotationEditNode := fn(){
	var container = new MinSG.ListNode;

	container.onRotate := new MultiProcedure; // fn(Number angle_deg, Geometry.Vec3 axis_ws, Geometry.Vec3 pivot_ws)
	container.onRotationStart := new MultiProcedure; //fn(){...}
	container.onRotationStop  := new MultiProcedure; // fn(Number angle_deg, Geometry.Vec3 axis_ws, Geometry.Vec3 pivot_ws)


	foreach( [	[new Util.Color4f(1,0,0,1),false],
				[new Util.Color4f(0,1,0,1),new Geometry.Vec3(1,0,0)],
				[new Util.Color4f(0,0,1,1),new Geometry.Vec3(0,1,0)]
			]	as var properties){

		var n = new MinSG.GeometryNode( EditNodeFactories.getRingMesh() );
		Traits.addTrait( n, EditNodeTraits.ColorTrait, properties[0] );
		Traits.addTrait( n, EditNodeTraits.RotatableTrait );
		if(properties[1])
			n.rotateLocal_deg(90,properties[1]);

		n.onRotate += fn(deg,axis){
			getParent().onRotate(deg,axis);
		};
		n.onRotationStart += fn(){
			this.pushColor(new Util.Color4f(2,2,2,1));
			getParent().onRotationStart();
		};
		n.onRotationStop += fn(deg,axis){
			this.popColor();
			getParent().onRotationStop(deg,axis);
		};
		container+=n;
	}


	return container;

};
//---------------------------------------------------------------------------------
/*!	Creates a 3-d-scaling node. It provides the following methods:

	>	void Node.onScale(Number scale, Geometry.Vec3 origin_ws)			(extendable MultiProcedure)
	>	void Node.onScalingStart()											(extendable MultiProcedure)
	>	void Node.onScalingStop(Number scale, Geometry.Vec3 origin_ws)		(extendable MultiProcedure)
	>	updateScalingBox(Box,Matrix)	Has to be called repeatedly to update the nodes layout.
*/
EditNodeFactories.createScaleEditNode := fn(){
	var container = new MinSG.ListNode;

	container.onScale := new MultiProcedure; // fn(Number scale, Geometry.Vec3 origin_ws)
	container.onScalingStart := new MultiProcedure; //fn(){...}
	container.onScalingStop  := new MultiProcedure; // fn(Number scale, Geometry.Vec3 origin_ws)

	var c1 = new Util.Color4f(0,0,1,1.0);
	var c2 = new Util.Color4f(1,0,0,1.0);
	//! (static)
	container.__NE_Scale_arrows := [
		[	0.5,	0.5,	1.0,	c1],
		[	0.5,	0.5,	0.0,	c1],
		[	0.5,	1.0,	0.5,	c1],
		[	0.5,	0.0,	0.5,	c1],
		[	1.0,	0.5,	0.5,	c1],
		[	0.0,	0.5,	0.5,	c1],

		[	0.0,	0.0,	0.0,	c2],
		[	0.0,	0.0,	1.0,	c2],
		[	0.0,	1.0,	0.0,	c2],
		[	0.0,	1.0,	1.0,	c2],
		[	1.0,	0.0,	0.0,	c2],
		[	1.0,	0.0,	1.0,	c2],
		[	1.0,	1.0,	0.0,	c2],
		[	1.0,	1.0,	1.0,	c2],

	];

	container.updateScalingBox := fn(Geometry.Box box,Geometry.Matrix4x4 worldMatrix){
		this.resetRelTransformation();
		var center_ws = worldMatrix.transformPosition(box.getCenter());
		this.setWorldOrigin(center_ws);

		var arrowScale = 0.5 * box.getExtentMax() * (worldMatrix*new Geometry.Vec4(1,0,0,0)).length();

		var children = MinSG.getChildNodes(this);
		foreach( this.__NE_Scale_arrows as var index,var arrowConfig){
			var child = children[index];
			child.resetRelTransformation();
			var childPos_ws = worldMatrix.transformPosition( new Geometry.Vec3(
						box.getMinX() + box.getExtentX()*arrowConfig[0],
						box.getMinY() + box.getExtentY()*arrowConfig[1],
						box.getMinZ() + box.getExtentZ()*arrowConfig[2]));
			child.setWorldOrigin( childPos_ws );

			child.rotateToWorldDir(center_ws-childPos_ws);
			child.rotateLocal_deg(90,0,1,0);
			child.scale(arrowScale);
		}
	};


	var arrow = EditNodeFactories.getSmallArrowMesh();

	foreach(container.__NE_Scale_arrows as var arrowConfig){

		var n = new MinSG.GeometryNode( arrow );
		Traits.addTrait( n,EditNodeTraits.ColorTrait, arrowConfig[3] );
		Traits.addTrait( n,EditNodeTraits.TranslatableAxisTrait );
		n.__NE_ScaleOrigin_ws @(private) := new Geometry.Vec3;
		n.__NE_ScaleInititalPos_ws @(private) := new Geometry.Vec3;

		n.onTranslationStart += fn(){
			this.pushColor(new Util.Color4f(2,2,2,1));
			var relPos = this.getRelPosition();

			this.__NE_ScaleOrigin_ws.setValue( this.relPosToWorldPos(-relPos) ); // get the opposite point of the scaling box
			this.__NE_ScaleInititalPos_ws.setValue( this.getWorldOrigin() );
			getParent().onScalingStart();
		};
		n.onTranslate += fn(v){
			var length = (this.__NE_ScaleInititalPos_ws-this.__NE_ScaleOrigin_ws).length();
			if(length>0){
				var s = (this.__NE_ScaleInititalPos_ws+v-this.__NE_ScaleOrigin_ws).length()/length;
				getParent().onScale(__NE_ScaleOrigin_ws,s);
			}
		};
		n.onTranslationStop += fn(v){
			this.popColor();
			var length = (this.__NE_ScaleInititalPos_ws-this.__NE_ScaleOrigin_ws).length();
			if(length>0){
				var s = (this.__NE_ScaleInititalPos_ws+v-this.__NE_ScaleOrigin_ws).length() / length;
				getParent().onScalingStop(__NE_ScaleOrigin_ws,s);
			}
		};

		container+=n;
	}

	return container;
};
//---------------------------------------------------------------------------------
//MA Snap node
/*!	Creates a 3-d-Snap node. It provides the following methods:

	>	void Node.onTranslationStart()								(extendable MultiProcedure)
	>	void Node.onTranslate(Geometry.Vec3 worldTranslation)		(extendable MultiProcedure)
	>	void Node.onTranslationStop(Geometry.Vec3 worldTranslation)	(extendable MultiProcedure)
*/
EditNodeFactories.createSnapEditNode := fn(){
	var container = new MinSG.ListNode;

	container.onTranslate := new MultiProcedure; // fn(Geometry.Vec3)
	container.onTranslationStart := new MultiProcedure; //fn(){...}
	container.onTranslationStop := new MultiProcedure; //fn(){Geometry.Vec3}

	var arrow = Rendering.MeshBuilder.createArrow(0.025, 1.0);
	var ring = EditNodeFactories.createRingSegmentMesh(0.0,360, 0.3, 0, 0.5);

    foreach( [	[arrow,	EditNodeTraits.TranslatableAxisTrait,	new Util.Color4f(1,0,0,0.5),new Geometry.Vec3(0,0,1)],
				[ring,	EditNodeTraits.TranslatablePlaneTrait,	new Util.Color4f(1,0,0,0.5),new Geometry.Vec3(1,0,0)]
			]	as var properties){
        var n = new MinSG.GeometryNode( properties[0]);
        n.rotateRel_deg(-90,properties[3]);
        n.moveRel(new Geometry.Vec3(0,1,0));
        Traits.addTrait( n,EditNodeTraits.ColorTrait,properties[2] );
        Traits.addTrait( n,properties[1] );

        //! \see TranslatablePlaneTrait
        n.onTranslationStart += fn(){
            this.pushColor(new Util.Color4f(2,2,2,1));
            getParent().onTranslationStart();
        };

        //! \see TranslatablePlaneTrait
        n.onTranslate += fn(v){
            getParent().onTranslate(v);
        };

        //! \see TranslatablePlaneTrait
        n.onTranslationStop += fn(v){
            this.popColor();
            getParent().onTranslationStop(v);
        };

        container+=n;
    };
	return container;

};

// --------------------------------------------------------------------------------

EditNodeFactories.createLineAxisMesh := fn(){
	var mb = new Rendering.MeshBuilder;
	mb.normal(new Geometry.Vec3(0,0,1));
	mb.color(new Util.Color4f(0.2,0,0,0.1)).position(new Geometry.Vec3(1000,0,0)).addVertex();
	mb.color(new Util.Color4f(1.0,0,0,0.2)).position(new Geometry.Vec3(0,0,0)).addVertex();
	mb.addVertex();
	mb.color(new Util.Color4f(0.2,0,0,0.1)).position(new Geometry.Vec3(-1000,0,0)).addVertex();

	mb.normal(new Geometry.Vec3(0,0,1));
	mb.color(new Util.Color4f(0,0.2,0,0.1)).position(new Geometry.Vec3(0,1000,0)).addVertex();
	mb.color(new Util.Color4f(0,1.0,0,0.2)).position(new Geometry.Vec3(0,0,0)).addVertex();
	mb.addVertex();
	mb.color(new Util.Color4f(0,0.2,0,0.1)).position(new Geometry.Vec3(0,-1000,0)).addVertex();
	
	mb.normal(new Geometry.Vec3(0,1,0));
	mb.color(new Util.Color4f(0,0,0.2,0.1)).position(new Geometry.Vec3(0,0,1000)).addVertex();
	mb.color(new Util.Color4f(0,0,1.0,0.2)).position(new Geometry.Vec3(0,0,0)).addVertex();
	mb.addVertex();
	mb.color(new Util.Color4f(0,0,0.2,0.1)).position(new Geometry.Vec3(0,0,-1000)).addVertex();

	var m = mb.buildMesh();
	m.setDrawLines();
	return m;
};

EditNodeFactories.createRingSegmentMesh  := fn(startDeg,endDeg,stepSize,minR,maxR){
//	if(!ringMesh){
//		ringMesh = Rendering.MeshBuilder.createRingSector(minR, maxR, 16, 90.0);
//		var backSide = ringMesh.clone();
//		Rendering.reverseMeshWinding(backSide) ;
//		ringMesh = Rendering.combineMeshes( [ringMesh,backSide] );
//	}
	var mb = new Rendering.MeshBuilder;
	mb.normal(new Geometry.Vec3(0,0,1));
	mb.color(new Util.Color4f(1,1,1,1));
	for(var a=startDeg;a<=endDeg;a+=stepSize){
		var p = new Geometry.Vec3(a.degToRad().cos(),a.degToRad().sin(),0);
		var idx = mb.position(p*minR).addVertex();
		mb.position(p*maxR).addVertex();
		if(a>0){
			mb.addQuad(idx-2,idx,idx+1,idx-1);
		}
	}
	// back side
	mb.normal(new Geometry.Vec3(0,0,-1));
	for(var a=startDeg;a<=endDeg;a+=stepSize){
		var p = new Geometry.Vec3(a.degToRad().cos(),a.degToRad().sin(),0);
		var idx = mb.position(p*minR).addVertex();
		mb.position(p*maxR).addVertex();
		if(a>0){
			mb.addQuad(idx-2,idx-1,idx+1,idx);
		}
	}
	return mb.buildMesh();
};


EditNodeFactories.getArrowMeshToXAxis  := fn(){
	if(!thisFn.isSet($mesh))
		thisFn.mesh := Rendering.MeshBuilder.createArrow(0.025, 1.0);
	return thisFn.mesh;
};

EditNodeFactories.getArrowMeshFromXAxis  := fn(){
	if(!thisFn.isSet($mesh)){
		var extr = new MeshCreation.Extruder;
		extr.closeExtrusion = true;
		extr.addProfileVertex(-1	,0		,0);
		extr.addProfileVertex(-1	,0.02	,0);
		extr.addProfileVertex(-0.2	,0.02	,0);
		extr.addProfileVertex(-0.2	,0.2	,0);
		extr.addProfileVertex(0,0.0,0);
		for(var i=0;i<360;i+=20){
			var r = new Geometry.SRT;
			r.rotateLocal_deg(i,new Geometry.Vec3(1,0,0));
			extr.addControlSRT(r);
		}
		thisFn.mesh := extr.buildMesh();
	}
	return thisFn.mesh;
};

EditNodeFactories.getCubeMesh  := fn(){
	if(!thisFn.isSet($mesh)){
		var mb = new Rendering.MeshBuilder;
		mb.addBox(new Geometry.Box(0.0, 0.0, 0.0, 1.0, 1.0, 1.0));
		thisFn.mesh := mb.buildMesh();
	}
	return thisFn.mesh;
};

EditNodeFactories.getSmallArrowMesh  := fn(){
	if(!thisFn.isSet($mesh))
		thisFn.mesh := Rendering.MeshBuilder.createArrow(0.025, 0.25);
	return thisFn.mesh;
};

EditNodeFactories.getRingSegmentMesh  := fn(){
	if(!thisFn.isSet($mesh)){
		thisFn.mesh := createRingSegmentMesh(0,90,5,0.2,0.5);
	}
	return thisFn.mesh;
};

EditNodeFactories.getRingMesh  := fn(){
	if(!thisFn.isSet($mesh)){
		thisFn.mesh := createRingSegmentMesh(0,360,5,0.4,0.5);
	}
	return thisFn.mesh;
};


return EditNodeFactories;

//---------------------------------------------------------------------------------

