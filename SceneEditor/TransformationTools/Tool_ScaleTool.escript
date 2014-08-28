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
 **	[Plugin:SceneEditor/TransformationTools/Tool_ScaleTool.escript]
 **/

declareNamespace($TransformationTools);

loadOnce(__DIR__+"/EditNodeTraits.escript");
loadOnce(__DIR__+"/EditNodeFactories.escript");
loadOnce(__DIR__+"/ToolHelperTraits.escript");

//----------------------------------------------------------------------------
// scale

TransformationTools.ScaleTool := new Type;
{
	var T = TransformationTools.ScaleTool;
	Traits.addTrait(T,TransformationTools.GenericNodeTransformToolTrait);

	T.localTransform @(init) := fn(){	return DataWrapper.createFromValue(false);	};

	//! \see TransformationTools.UIToolTrait
	T.onToolInitOnce_static += fn(){
		var n = EditNodes.createScaleEditNode();

		n.onScale += this->fn(origin_ws,scale){
			scale = [scale,0.1].max(); // prevent creation of too small nodes.
			//! \see TransformationTools.NodeTransformationHandlerTrait
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

		//! \see TransformationTools.NodeTransformationHandlerTrait
		n.onScalingStart += this->applyNodeTransformations;

		n.onScalingStop += this->fn(origin_ws,scale){
			//! \see TransformationTools.NodeTransformationHandlerTrait
			this.applyNodeTransformations();
		};
		this.setMetaNode(n);
	};

	//! \see TransformationTools.FrameListenerTrait
	T.onFrame_static += fn(){
		var editNode = this.getMetaNode();
		//! \see TransformationTools.NodeTransformationHandlerTrait
		var nodes = getTransformedNodes();
		if(nodes.empty())
			return;

		if(localTransform()){
			editNode.updateScalingBox(nodes[0].getBB(),nodes[0].getWorldTransformationMatrix());
		}else{
			editNode.updateScalingBox(MinSG.getCombinedWorldBB(nodes),new Geometry.Matrix4x4);
		}
	};


	//! \see TransformationTools.ContextMenuProviderTrait
	T.doCreateContextMenu ::= fn(){
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
}
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
			this.getMetaNode().setWorldOrigin(box.getCenter().setY(box.getMaxY()));
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
            this.originSRT = this.getMetaNode().getRelTransformationSRT();
        };

        //! \see EditNodes.TranslatablePlaneTrait
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
        var s = editNode.getRelScaling();
        editNode.setRelScaling(s);
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
