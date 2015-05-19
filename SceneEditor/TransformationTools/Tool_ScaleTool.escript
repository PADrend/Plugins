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

//----------------------------------------------------------------------------
var Tool = new Type;

Traits.addTrait(Tool,ToolHelperTraits.GenericNodeTransformToolTrait);

Tool.localTransform @(init) := fn(){	return new Std.DataWrapper(false);	};

//! \see ToolHelperTraits.UIToolTrait
Tool.onToolInitOnce_static += fn(){
	var n = EditNodeFactories.createScaleEditNode();

	n.onScale += this->fn(origin_ws,scale){
		scale = [scale,0.1].max(); // prevent creation of too small nodes.
		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		foreach( this.getTransformedNodesOrigins() as var node,var origin){
			if(node.hasRelTransformationSRT()){
				node.setRelTransformation( origin.toSRT() );
			}else{
				node.setRelTransformation(origin);
			}
			node.setWorldOrigin( node.getWorldOrigin() - (node.getWorldOrigin()-origin_ws)*(1.0-scale)) ;
			node.scale(scale);
		}
//			out(scale);
	};

	//! \see ToolHelperTraits.NodeTransformationHandlerTrait
	n.onScalingStart += this->applyNodeTransformations;

	n.onScalingStop += this->fn(origin_ws,scale){
		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		this.applyNodeTransformations();
	};
	this.setMetaNode(n);
};

//! \see ToolHelperTraits.FrameListenerTrait
Tool.onFrame_static += fn(){
	var editNode = this.getMetaNode();
	//! \see ToolHelperTraits.NodeTransformationHandlerTrait
	var nodes = getTransformedNodes();
	if(nodes.empty())
		return;

	if(localTransform()){
		editNode.updateScalingBox(nodes[0].getBB(),nodes[0].getWorldTransformationMatrix());
	}else{
		editNode.updateScalingBox(MinSG.getCombinedWorldBB(nodes),new Geometry.Matrix4x4);
	}
};


//! \see ToolHelperTraits.ContextMenuProviderTrait
Tool.doCreateContextMenu ::= fn(){
	return [
	"*Scaling Tool*",
	{
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Local scaling",
		GUI.DATA_WRAPPER : localTransform,
		GUI.TOOLTIP : 	"----TranslationTool----\n"
						"When activated, the scaling is performed relative \n"
						"to the coordinate system of the first selected node; \n"
						"otherwise, the world coordinates are used."
	},'----'];
};



return Tool;
//----------------------------------------------------------------------------
