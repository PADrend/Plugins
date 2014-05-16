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
/****
 **	[Plugin:SceneEditor/TransformationTools/Tool_SnapTool.escript]
 **/

declareNamespace($TransformationTools);

loadOnce(__DIR__+"/EditNodeTraits.escript");
loadOnce(__DIR__+"/EditNodeFactories.escript");
loadOnce(__DIR__+"/ToolHelperTraits.escript");

//----------------------------------------------------------------------------
// MA_snap


TransformationTools.SnapTool := new Type;
{
	var T = TransformationTools.SnapTool;
	Traits.addTrait(T,TransformationTools.GenericNodeTransformToolTrait);

    T.originSRT :=void; // store the origin srt of the editNode.

    //! \see TransformationTools.NodeSelectionListenerTrait
	T.onNodesSelected_static += fn(Array selectedNodes){
		if(!selectedNodes.empty()){
			var box = MinSG.getCombinedWorldBB(selectedNodes);
			this.getMetaNode().setWorldPosition(box.getCenter().setY(box.getMaxY()));
		}
    };

	//! \see TransformationTools.UIToolTrait
	T.onToolInitOnce_static += fn(){
		var n = EditNodes.createSnapEditNode();

		//! \see EditNodes.AdjustableProjSizeTrait
		Traits.addTrait( n, EditNodes.AdjustableProjSizeTrait);

        //! \see EditNodes.TranslatablePlaneTrait
        n.onTranslationStart += this->fn(){
			//! \see TransformationTools.NodeTransformationHandlerTrait
			applyNodeTransformations();
            this.originSRT = this.getMetaNode().getSRT();
        };

        //! \see EditNodes.TranslatablePlaneTrait
		n.onTranslate += this->fn(v){
		    var n = this.getMetaNode();
            n.setSRT(this.originSRT);
            n.moveRel(n.worldDirToRelDir(v));
            var pos = n.getWorldPosition();
            var direction = (pos-new Geometry.Vec3(pos.getX(),pos.getY()+2,pos.getZ())).normalize();
			foreach( this.getTransformedNodesOrigins() as var node,var origin){
				var newMatrix = origin.clone().translate(node.worldDirToLocalDir(v));
				if(node.hasSRT()){
					node.setSRT( newMatrix.toSRT() );
				}else{
					node.setMatrix(newMatrix);
				}					
				this.snapSelectedNode(pos,direction, node);
			}

        };

        //! \see EditNodes.TranslatablePlaneTrait
		n.onTranslationStop += this->fn(v){
			//! \see TransformationTools.NodeTransformationHandlerTrait
			this.applyNodeTransformations();
		};

		this.setMetaNode(n);
	};

	//! \see TransformationTools.FrameListenerTrait
	T.onFrame_static += fn(){
        var editNode = this.getMetaNode();
        var s = editNode.getScale();
        editNode.setScale(s);
        editNode.adjustProjSize();
	};

	//Snap function
	T.snapSelectedNode @(private) :=fn(Geometry.Vec3 pos, Geometry.Vec3 direction,  node){
        //! \see TransformationTools.NodeTransformationHandlerTrait
		var nodes = getTransformedNodes();
		if(nodes.empty())
			return;
        var editNode = this.getMetaNode();
        var bb=node.getWorldBB();
        var editNodeBB = editNode.getWorldBB();
        var worldBottomCenter= new Geometry.Vec3(bb.getCenter().getX(),(bb.getCenter().getY()-bb.getExtentY()),bb.getCenter().getZ() );
        var editNodeBottomCenter= new Geometry.Vec3(editNodeBB.getCenter().getX(),(editNodeBB.getCenter().getY()-editNodeBB.getExtentY()),editNodeBB.getCenter().getZ() );
//        var vec = new Geometry.Vec3(worldBottomCenter.getX(),pos.getY(),worldBottomCenter.getZ());
        var vec = new Geometry.Vec3(worldBottomCenter.getX(),editNodeBottomCenter.getY(),worldBottomCenter.getZ());
        node.moveLocal(node.worldDirToLocalDir(vec-worldBottomCenter));
        foreach(nodes as var node)
            node.deactivate();
        var distance = MinSG.calcNodeToSceneDistance(frameContext,PADrend.getCurrentScene(),node,direction,32,0,false);
        foreach(nodes as var node)
            node.activate();

        if(!distance){
            var point = new Geometry.Vec3(worldBottomCenter.getX(),PADrend.getCurrentScene().getWorldBB().getMinY(),worldBottomCenter.getZ());
            node.setRelPosition(node.worldPosToRelPos(point));
        }
        else
            node.moveLocal(node.worldDirToLocalDir(direction*distance));

    };

}
//----------------------------------------------------------------------------


TransformationTools.SnapTool2 := new Type;
{
	var T = TransformationTools.SnapTool2;
	Traits.addTrait(T,TransformationTools.GenericNodeTransformToolTrait);

	T.handleIndividualNodes @(init) := fn(){	return DataWrapper.createFromValue(true);	};
	T.startPos @(private) := void;	// position of the metaNode in worldCoordinates when start dragging or void
	T.rayCaster @(init,private) := MinSG.RendRayCaster;
	T.castSegmentScaling @(private) := 1.0; // influences the length of the casting segments 

	T.nodeMarkerNode @(private) := 	void;	// a geometry node with a "cast segment" for each dragged node
	T.nodeRays @(private,init) := Map;  // node -> cast segment (Segment3)

	// ------------------------------
	T.getSnappingNormal @(private) := fn(){	return PADrend.getWorldUpVector(); };

	T.getNodeWorldAnchor @(private) := fn(node){ // this might also return a predefined anchor point stored as node attribute
		var snapNormal = this.getSnappingNormal();
		return node.getWorldBB().getRelPosition(	0.5-snapNormal.x()*0.5,
													0.5-snapNormal.y()*0.5,
													0.5-snapNormal.z()*0.5);
	};

	//! \see TransformationTools.NodeSelectionListenerTrait
	T.onNodesSelected_static += fn(nodes){
		this.nodeMarkerNode.deactivate();
		if(nodes.empty()){
			return;
		}
		// initial placement 
	
		var snapNormal = this.getSnappingNormal();
		//! \see TransformationTools.MetaNodeContainerTrait
		this.getMetaNode().setWorldPosition( this.getNodeWorldAnchor(nodes[0]) );

		this.refreshRelNodePositions(nodes);
	};

	T.onDraggingStart := fn(evt){
		this.applyNodeTransformations();					//! \see TransformationTools.NodeTransformationHandlerTrait

		// deactivate nodes
		var nodes = this.getTransformedNodes();
		foreach(nodes as var node)
			node.deactivate();

		var scene = PADrend.getCurrentScene();
	
		// check if metaObjects (e.g. lights or similar nodes) are visible.
		rayCaster.renderingLayers( Util.requirePlugin('PADrend/EventLoop').getRenderingLayers() );
	
		this.startPos = rayCaster.queryIntersectionFromScreen(frameContext,scene,new Geometry.Vec2(evt.x,evt.y));
		if(!this.startPos)
			this.startPos = PADrend.getCurrentSceneGroundPlane().getIntersection( frameContext.calcWorldRayOnScreenPos(evt.x,evt.y) );

		// activate nodes
		foreach(nodes as var node)
			node.activate();

		this.refreshRelNodePositions(nodes); // if individual
	};
	T.onDragging := fn(evt){
		var nodes = this.getTransformedNodes();				//! \see TransformationTools.NodeTransformationHandlerTrait
		if(nodes.empty()||!this.startPos)
			return;

		// deactivate nodes
		foreach(nodes as var node)
			node.deactivate();

		var scene = PADrend.getCurrentScene();
		var newPos = this.rayCaster.queryIntersectionFromScreen(frameContext,scene,new Geometry.Vec2(evt.x,evt.y));
		if(!newPos)
			newPos = PADrend.getCurrentSceneGroundPlane().getIntersection( frameContext.calcWorldRayOnScreenPos(evt.x,evt.y) );
		if(!newPos){
			// activate nodes
			foreach(nodes as var node)
				node.activate();
			return;
		}


		var metaNode = this.getMetaNode();				//! \see TransformationTools.MetaNodeContainerTrait
		metaNode.setWorldPosition(newPos);

		if(nodes.count()==1){
			var node = nodes[0];
			var nodeAnchorOffset = node.getWorldPosition() - this.getNodeWorldAnchor(node);
			node.setWorldPosition( newPos + nodeAnchorOffset  );
		}else{ // if individual
			var sceneGround = PADrend.getCurrentSceneGroundPlane();
			
			var sceneMinY = scene.getWorldBB().getMinY();
			foreach(this.nodeRays as var node,var segment){
				var intersection = this.rayCaster.queryIntersection(frameContext,scene,
												metaNode.localPosToWorldPos(segment.getFirstPoint()),
												metaNode.localPosToWorldPos(segment.getSecondPoint()));
				if(!intersection){
					intersection = metaNode.localPosToWorldPos(segment.getSecondPoint());
					if( sceneGround.planeTest( intersection )<0 )
						intersection = sceneGround.getProjection(intersection);
				}
				var nodeAnchorOffset = node.getWorldPosition() - this.getNodeWorldAnchor(node);
				node.setWorldPosition( intersection + nodeAnchorOffset  );
			}
		}

		this.startPos = newPos;

		// activate nodes
		foreach(nodes as var node)
			node.activate();


	};

	//! \see TransformationTools.UIToolTrait
	T.onToolInitOnce_static += fn(){
		var metaRootNode = new MinSG.ListNode;
		this.setMetaNode(metaRootNode);	//! \see TransformationTools.MetaNodeContainerTrait
		// -------

		var n = new MinSG.GeometryNode(EditNodes.getArrowMeshFromXAxis());
		metaRootNode += n;

		//! \see NodeSelectionListenerTrait.UIToolTrait		
		this.onNodesSelected += [n] => fn(arrowNode, ...){
			// rotate arrow to point downwards
			arrowNode.setSRT(new Geometry.SRT( new Geometry.Vec3(0,0,0),
												PADrend.getWorldFrontVector(),
												PADrend.getWorldUpVector()  ));
			arrowNode.rotateLocal_deg(-90,0,0,1);
		};

		//! \see EditNodes.AdjustableProjSizeTrait
		Traits.addTrait( n, EditNodes.AdjustableProjSizeTrait,50,80);

		//! \see TransformationTools.FrameListenerTrait
		this.onFrame += [n] => fn(arrowNode){
			arrowNode.adjustProjSize(); //! \see EditNodes.AdjustableProjSizeTrait
			this.castSegmentScaling = arrowNode.getScale();
		};

		//! \see EditNodes.ColorTrait
		Traits.addTrait(n,EditNodes.ColorTrait);
		n.setColor(new Util.Color4f(2,0,0,0.5));

		//! \see EditNodes.DraggableTrait
		Traits.addTrait(n,EditNodes.DraggableTrait);

		//! \see EditNodes.DraggableTrait
		n.onDraggingStart += fn(evt){
			this.pushColor(new Util.Color4f(2,2,2,1));	//! \see EditNodes.ColorTrait
		};
		n.onDraggingStart += this->this.onDraggingStart;

		//! \see EditNodes.DraggableTrait
		n.onDragging += this->onDragging;

		//! \see EditNodes.DraggableTrait
		n.onDraggingStop += fn(tool){
			this.popColor();								//! \see EditNodes.ColorTrait
			tool.applyNodeTransformations();				//! \see TransformationTools.NodeTransformationHandlerTrait
		}.bindLastParams(this);

		// --------
		this.nodeMarkerNode = new MinSG.GeometryNode;
		metaRootNode += nodeMarkerNode;

	};
	
	/*!	Calculate the transformed nodes' positions relative to the tool's meta node.
		The positions are stored in nodeRays and the nodeMarkerNode's mesh is updated.
		This is repeatedly called when the selection changes or while dragging is performed
	*/
	T.refreshRelNodePositions ::= fn(nodes){ // relative to startPos

		//! \see TransformationTools.MetaNodeContainerTrait
		var metaNode = this.getMetaNode();

		this.nodeRays.clear();

//		var castSegmentScaling = 1.0; // influences the length of the casting segments 
		var snapNormal = this.getSnappingNormal();
		var plane = new Geometry.Plane(snapNormal,0);

		foreach(nodes as var node){
			var relPos = metaNode.worldPosToLocalPos( this.getNodeWorldAnchor(node) );
			var projectedPoint = plane.getProjection( relPos );
			this.nodeRays[node] = new Geometry.Segment3(
											projectedPoint + snapNormal*(this.castSegmentScaling*0.95),
											projectedPoint - snapNormal*(this.castSegmentScaling*10));
		}


		{	// update marker node
			var mb = new Rendering.MeshBuilder;
			mb.normal(new Geometry.Vec3(0,0,1));

			var c1 = new Util.Color4f(0,0,2,0.3);
			var c2 = new Util.Color4f(0.5,0,0,0.1);

			foreach(nodeRays as var segment){
				mb.color(c1).position( segment.getFirstPoint() ).addVertex();
				mb.color(c2).position( segment.getSecondPoint() ).addVertex();
			}

			var mesh = mb.buildMesh();
			mesh.setDrawLines();
			this.nodeMarkerNode.setMesh(mesh);
			this.nodeMarkerNode.activate();
		}
	};

}

