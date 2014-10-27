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

static EditNodeFactories = module('./EditNodeFactories');
static EditNodeTraits = module('./EditNodeTraits');
static ToolHelperTraits = module('./ToolHelperTraits');

var Tool = new Type;

Traits.addTrait(Tool,ToolHelperTraits.GenericNodeTransformToolTrait);

Tool.handleIndividualNodes @(init) := fn(){	return DataWrapper.createFromValue(true);	};
Tool.startPos @(private) := void;	// position of the metaNode in worldCoordinates when start dragging or void
Tool.castSegmentScaling @(private) := 1.0; // influences the length of the casting segments 

Tool.nodeMarkerNode @(private) := 	void;	// a geometry node with a "cast segment" for each dragged node
Tool.nodeRays @(private,init) := Map;  // node -> cast segment (Segment3)

// ------------------------------
Tool.getSnappingNormal @(private) := fn(){	return PADrend.getWorldUpVector(); };

Tool.getNodeWorldAnchor @(private) := fn(node){ // this might also return a predefined anchor point stored as node attribute
	var snapNormal = this.getSnappingNormal();
	return node.getWorldBB().getRelPosition(	0.5-snapNormal.x()*0.5,
												0.5-snapNormal.y()*0.5,
												0.5-snapNormal.z()*0.5);
};

//! \see ToolHelperTraits.NodeSelectionListenerTrait
Tool.onNodesSelected_static += fn(nodes){
	this.nodeMarkerNode.deactivate();
	if(nodes.empty()){
		return;
	}
	// initial placement 

	var snapNormal = this.getSnappingNormal();
	//! \see ToolHelperTraits.MetaNodeContainerTrait
	this.getMetaNode().setWorldOrigin( this.getNodeWorldAnchor(nodes[0]) );

	this.refreshRelNodePositions(nodes);
};

Tool.onDraggingStart := fn(evt){
	this.applyNodeTransformations();					//! \see ToolHelperTraits.NodeTransformationHandlerTrait

	// deactivate nodes
	var nodes = this.getTransformedNodes();
	foreach(nodes as var node)
		node.deactivate();


	this.startPos = Util.requirePlugin('PADrend/Picking').queryIntersection( [evt.x,evt.y] );
	if(!this.startPos)
		this.startPos = PADrend.getCurrentSceneGroundPlane().getIntersection( Util.requirePlugin('PADrend/Picking').getPickingRay( [evt.x,evt.y] ) );

	// activate nodes
	foreach(nodes as var node)
		node.activate();

	this.refreshRelNodePositions(nodes); // if individual
};
static getRayCaster = fn(){
	static caster;
	@(once)	caster = new (Std.require('LibMinSGExt/RendRayCaster'));
	return caster;
};
Tool.onDragging := fn(evt){
	var nodes = this.getTransformedNodes();				//! \see ToolHelperTraits.NodeTransformationHandlerTrait
	if(nodes.empty()||!this.startPos)
		return;

	// deactivate nodes
	foreach(nodes as var node)
		node.deactivate();

	var newPos = Util.requirePlugin('PADrend/Picking').queryIntersection( [evt.x,evt.y] );
	if(!newPos)
		newPos = PADrend.getCurrentSceneGroundPlane().getIntersection(  Util.requirePlugin('PADrend/Picking').getPickingRay( [evt.x,evt.y] ) );
	if(!newPos){
		// activate nodes
		foreach(nodes as var node)
			node.activate();
		return;
	}


	var metaNode = this.getMetaNode();				//! \see ToolHelperTraits.MetaNodeContainerTrait
	metaNode.setWorldOrigin(newPos);

	if(nodes.count()==1){
		var node = nodes[0];
		var nodeAnchorOffset = node.getWorldOrigin() - this.getNodeWorldAnchor(node);
		node.setWorldOrigin( newPos + nodeAnchorOffset  );
	}else{ // if individual
		var sceneGround = PADrend.getCurrentSceneGroundPlane();
		
		var scene = PADrend.getCurrentScene();

		var sceneMinY = scene.getWorldBB().getMinY();
		
		foreach(this.nodeRays as var node,var segment){
			var intersection = getRayCaster().queryIntersection(frameContext,scene,
											metaNode.localPosToWorldPos(segment.getFirstPoint()),
											metaNode.localPosToWorldPos(segment.getSecondPoint()));
			if(!intersection){
				intersection = metaNode.localPosToWorldPos(segment.getSecondPoint());
				if( sceneGround.planeTest( intersection )<0 )
					intersection = sceneGround.getProjection(intersection);
			}
			var nodeAnchorOffset = node.getWorldOrigin() - this.getNodeWorldAnchor(node);
			node.setWorldOrigin( intersection + nodeAnchorOffset  );
		}
	}

	this.startPos = newPos;

	// activate nodes
	foreach(nodes as var node)
		node.activate();


};

//! \see ToolHelperTraits.UIToolTrait
Tool.onToolInitOnce_static += fn(){
	var metaRootNode = new MinSG.ListNode;
	this.setMetaNode(metaRootNode);	//! \see ToolHelperTraits.MetaNodeContainerTrait
	// -------

	var n = new MinSG.GeometryNode(EditNodeFactories.getArrowMeshFromXAxis());
	metaRootNode += n;

	//! \see NodeSelectionListenerTrait.UIToolTrait		
	this.onNodesSelected += [n] => fn(arrowNode, ...){
		// rotate arrow to point downwards
		arrowNode.setRelTransformation(new Geometry.SRT( new Geometry.Vec3(0,0,0),
											PADrend.getWorldFrontVector(),
											PADrend.getWorldUpVector()  ));
		arrowNode.rotateLocal_deg(-90,0,0,1);
	};

	//! \see EditNodeTraits.AdjustableProjSizeTrait
	Traits.addTrait( n, EditNodeTraits.AdjustableProjSizeTrait,50,80);

	//! \see ToolHelperTraits.FrameListenerTrait
	this.onFrame += [n] => fn(arrowNode){
		arrowNode.adjustProjSize(); //! \see EditNodeTraits.AdjustableProjSizeTrait
		this.castSegmentScaling = arrowNode.getRelScaling();
	};

	//! \see EditNodeTraits.ColorTrait
	Traits.addTrait(n,EditNodeTraits.ColorTrait);
	n.setColor(new Util.Color4f(2,0,0,0.5));

	//! \see EditNodeTraits.DraggableTrait
	Traits.addTrait(n,EditNodeTraits.DraggableTrait);

	//! \see EditNodeTraits.DraggableTrait
	n.onDraggingStart += fn(evt){
		this.pushColor(new Util.Color4f(2,2,2,1));	//! \see EditNodeTraits.ColorTrait
	};
	n.onDraggingStart += this->this.onDraggingStart;

	//! \see EditNodeTraits.DraggableTrait
	n.onDragging += this->onDragging;

	//! \see EditNodeTraits.DraggableTrait
	n.onDraggingStop += [this] => fn(tool){
		this.popColor();								//! \see EditNodeTraits.ColorTrait
		tool.applyNodeTransformations();				//! \see ToolHelperTraits.NodeTransformationHandlerTrait
	};

	// --------
	this.nodeMarkerNode = new MinSG.GeometryNode;
	metaRootNode += nodeMarkerNode;

};

/*!	Calculate the transformed nodes' positions relative to the tool's meta node.
	The positions are stored in nodeRays and the nodeMarkerNode's mesh is updated.
	This is repeatedly called when the selection changes or while dragging is performed
*/
Tool.refreshRelNodePositions ::= fn(nodes){ // relative to startPos

	//! \see ToolHelperTraits.MetaNodeContainerTrait
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

return Tool;
