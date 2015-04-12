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

Tool.originSRT :=void; // store the origin srt of the editNode.

//! \see ToolHelperTraits.NodeSelectionListenerTrait
Tool.onNodesSelected_static += fn(Array selectedNodes){
	if(!selectedNodes.empty()){
		var box = MinSG.getCombinedWorldBB(selectedNodes);
		this.getMetaNode().setWorldOrigin(box.getCenter().setY(box.getMaxY()));
	}
};

//! \see ToolHelperTraits.UIToolTrait
Tool.onToolInitOnce_static += fn(){
	var n = EditNodeFactories.createSnapEditNode();

	//! \see EditNodeTraits.AdjustableProjSizeTrait
	Traits.addTrait( n, EditNodeTraits.AdjustableProjSizeTrait);

	//! \see EditNodeTraits.TranslatablePlaneTrait
	n.onTranslationStart += this->fn(){
		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		applyNodeTransformations();
		this.originSRT = this.getMetaNode().getRelTransformationSRT();
	};

	//! \see EditNodeTraits.TranslatablePlaneTrait
	n.onTranslate += this->fn(v){
		var n = this.getMetaNode();
		n.setRelTransformation(this.originSRT);
		n.moveRel(n.worldDirToRelDir(v));
		var pos = n.getWorldOrigin();
		var direction = (pos-new Geometry.Vec3(pos.getX(),pos.getY()+2,pos.getZ())).normalize();
		foreach( this.getTransformedNodesOrigins() as var node,var origin){
			var newMatrix = origin.clone().translate(node.worldDirToLocalDir(v));
			if(node.hasRelTransformationSRT()){
				node.setRelTransformation( newMatrix.toSRT() );
			}else{
				node.setRelTransformation(newMatrix);
			}
			this.snapSelectedNode(pos,direction, node);
		}

	};

	//! \see EditNodeTraits.TranslatablePlaneTrait
	n.onTranslationStop += this->fn(v){
		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		this.applyNodeTransformations();
	};

	this.setMetaNode(n);
};

//! \see ToolHelperTraits.FrameListenerTrait
Tool.onFrame_static += fn(){
	var editNode = this.getMetaNode();
	var s = editNode.getRelScaling();
	editNode.setRelScaling(s);
	editNode.adjustProjSize();
};

//Snap function
Tool.snapSelectedNode @(private) :=fn(Geometry.Vec3 pos, Geometry.Vec3 direction,  node){
	//! \see ToolHelperTraits.NodeTransformationHandlerTrait
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


return Tool;
