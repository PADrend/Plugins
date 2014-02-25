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
 **	[Plugin:SceneEditor/TransformationTools/Tool_RotationTool.escript]
 **/

declareNamespace($TransformationTools);

loadOnce(__DIR__+"/EditNodeTraits.escript");
loadOnce(__DIR__+"/EditNodeFactories.escript");
loadOnce(__DIR__+"/ToolHelperTraits.escript");


//---------------------------------------------------------------------------------


declareNamespace($TransformationTools,$PivotHandling);

TransformationTools.PivotHandling.storePivotAtNode := fn([Geometry.Vec3,false] pivot,MinSG.Node node){

	var newPivot = pivot ? toJSON(pivot.toArray(),false) : false;
	var oldPivot = node.findNodeAttribute('NodeEdit.Pivot');
	if(newPivot==oldPivot)
		return;

	var fun = fn(){
		var node = this[0];
		var pivot = this[1];
		if(pivot){
			node.setNodeAttribute('NodeEdit.Pivot',pivot);
		}else{
			node.unsetNodeAttribute('NodeEdit.Pivot');
		}
		NodeEditor.selectNodes( NodeEditor.getSelectedNodes() );
	};
	PADrend.executeCommand({
		Command.DESCRIPTION : "Transform pivot",
		Command.EXECUTE : 	[node,newPivot]->fun,
		Command.UNDO : 		[node,oldPivot]->fun
	});
};

TransformationTools.PivotHandling.getPivot := fn(MinSG.Node node){
	var attr = node.findNodeAttribute('NodeEdit.Pivot');
	return attr ? new Geometry.Vec3(parseJSON(attr)) : new Geometry.Vec3;
};

TransformationTools.RotationTool := new Type;
{
	var T = TransformationTools.RotationTool;

	//! \see TransformationTools.GenericNodeTransformToolTrait
	Traits.addTrait(T,TransformationTools.GenericNodeTransformToolTrait);

	T.pivot_ws @(private,init) := fn(){	return DataWrapper.createFromValue(void);	};
	T.editNode @(private) := void;
	T.stepSize @(private,init) := fn(){	return DataWrapper.createFromValue(1);	};
	T.localTransform @(init) := fn(){	return DataWrapper.createFromValue(true);	};

	//! (internal) Call to store the current pivot at the node if necessary.
	T.storePivotAtNode @(private) ::= fn(){
		//! \see TransformationTools.NodeTransformationHandlerTrait
		var nodes = getTransformedNodes();
		if(nodes.count()==1 && pivot_ws()){
			var localPivot = nodes[0].worldPosToLocalPos(pivot_ws());
			TransformationTools.PivotHandling.storePivotAtNode( localPivot,nodes[0] );
		}
	};

	//! \see TransformationTools.UIToolTrait
	T.onToolInitOnce_static += fn(){
		var metaRoot = new MinSG.ListNode;
		this.setMetaNode(metaRoot);

		// ----------

		this.editNode = new MinSG.ListNode;
		metaRoot += editNode;

		//! \see EditNodes.AdjustableProjSizeTrait
		Traits.addTrait( editNode, EditNodes.AdjustableProjSizeTrait);

		//! \see TransformationTools.FrameListenerTrait
		this.onFrame += editNode->editNode.adjustProjSize; //! \see EditNodes.AdjustableProjSizeTrait

		//! \see EditNodes.AnnotatableTrait
		Traits.addTrait( editNode, EditNodes.AnnotatableTrait);

		// ----------

		var axisMarkerNode = new MinSG.GeometryNode(EditNodes.createLineAxisMesh());
		metaRoot += axisMarkerNode;
		axisMarkerNode.deactivate();

		// ----------

		var pivotEditNode = EditNodes.createTranslationEditNode();
		editNode += pivotEditNode;
		pivotEditNode.scale(0.5);

		pivotEditNode.onTranslationStart += this->fn(axisMarkerNode){
			this.initialPivot_ws @(private) := pivot_ws().clone();
			axisMarkerNode.activate();
			//! \see TransformationTools.NodeTransformationHandlerTrait
			var freePivot = getTransformedNodes().count()>1;
			if(freePivot)
				this.editNode.setAnnotation("Free Pivot");
			else
				this.editNode.setAnnotation("Bound Pivot");
		}.bindLastParams(axisMarkerNode);
		pivotEditNode.onTranslate += this->fn(v){
			this.pivot_ws(new Geometry.Vec3( initialPivot_ws + v) );
		};
		pivotEditNode.onTranslationStop += this->fn(v,axisMarkerNode){
			axisMarkerNode.deactivate();
			this.initialPivot_ws = void;
			this.storePivotAtNode();
			this.editNode.hideAnnotation();
		}.bindLastParams(axisMarkerNode);

		// ----------
		var rotationNode = EditNodes.createRotationEditNode();
		editNode += rotationNode;

		//! \see TransformationTools.NodeTransformationHandlerTrait
		rotationNode.onRotationStart += this->applyNodeTransformations;
		rotationNode.onRotate += this->fn(deg,axis_ws){
			deg = deg.round(this.stepSize());

			//! \see TransformationTools.NodeTransformationHandlerTrait
			foreach( this.getTransformedNodesOrigins() as var node,var origin){
				if(node.hasSRT()){
					node.setSRT( origin.toSRT() );
				}else{
					node.setMatrix(origin);
				}				
				node.rotateAroundWorldAxis_deg(deg,axis_ws);
			}
			//! \see EditNodes.AnnotatableTrait
			var dir = axis_ws.getDirection();
			editNode.setAnnotation("Rotate: "+deg+" ("+dir.x().round(0.01)+","+dir.y().round(0.01)+","+dir.z().round(0.01)+")");
		};
		rotationNode.onRotationStop += this->fn(...){
			this.applyNodeTransformations();				//! \see TransformationTools.NodeTransformationHandlerTrait
			editNode.hideAnnotation();						//! \see EditNodes.AnnotatableTrait
		};
	};

	//! \see TransformationTools.NodeSelectionListenerTrait
	T.onNodesSelected_static += fn(Array selectedNodes){
		// reset pivot
		if(!selectedNodes.empty()){
			pivot_ws( selectedNodes[0].localPosToWorldPos( TransformationTools.PivotHandling.getPivot(selectedNodes[0]) ) );
		}
//		if(selectedNodes.count()==1){
//		}else if(!selectedNodes.empty()){
			// ...
//			pivot_ws( new Geometry.Vec3(selectedNodes[0].getWorldPosition() ) );
//		}
	};

	//! \see TransformationTools.FrameListenerTrait
	T.onFrame_static += fn(){
		//! \see TransformationTools.NodeTransformationHandlerTrait
		var nodes = getTransformedNodes();
		if(nodes.empty())
			return;

		var metaRootNode = this.getMetaNode();

		if(localTransform()){
			var wm = nodes[0].getWorldMatrix();
			metaRootNode.setSRT(new Geometry.SRT(wm.transformPosition(0,0,0),wm.transformDirection(0,0,-1),wm.transformDirection(0,1,0),1.0));
		}else{
			metaRootNode.reset();
		}
		metaRootNode.setWorldPosition(pivot_ws());
	};


	//! \see TransformationTools.ContextMenuProviderTrait
	T.doCreateContextMenu ::= fn(){
		// apply to transformation

		return [
		"*Rotation Tool*",
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Local rotation",
			GUI.DATA_WRAPPER : localTransform,
			GUI.TOOLTIP : 	"When activated, the rotation is performed relative \n"
							"to the coordinate system of the first selected node; \n"
							"otherwise, the world coordinates are used."
		},


		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Pivot >",
			GUI.MENU : this->fn(){
				// proxy
				var refreshGroup = new GUI.RefreshGroup;
				var bakePivot = [];

				//! \see TransformationTools.NodeTransformationHandlerTrait
				if(getTransformedNodes().count()==1 && getTransformedNodes()[0]---|>MinSG.ListNode){
					bakePivot += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Bake pivot",
						GUI.TOOLTIP : "Move node so that the pivot is at 0,0,0\n while preserving the children's positions.",
						GUI.ON_CLICK : this->fn(){
							//! \see TransformationTools.NodeTransformationHandlerTrait
							var node = this.getTransformedNodes()[0];
							if(!(node---|>MinSG.ListNode))
								return;
							var pivot = TransformationTools.PivotHandling.getPivot(node);
							if(pivot.length()==0){
								PADrend.message("Baking pivot skipped.");
								return;
							}

							var nodes = [node];
							var before = [node.getWorldPosition()];
							var after = [ node.localPosToWorldPos(pivot)];
							foreach(MinSG.getChildNodes(node) as var c){
								nodes += c;
								before += c.getWorldPosition();
								after += c.getWorldPosition();
							}
							var fun = fn(){
								PADrend.message("Baking pivot...");
								var nodes = this[0];
								var positions = this[1];
								var pivot = this[2];
								foreach(nodes as var i,var node)
									node.setWorldPosition(positions[i]);
								TransformationTools.PivotHandling.storePivotAtNode( pivot,nodes[0] );
							};
							PADrend.executeCommand({
								Command.DESCRIPTION : "Bake pivot",
								Command.EXECUTE : 	[nodes,after,false]->fun,
								Command.UNDO : 		[nodes,before,pivot.clone()]->fun
							});

						}
					};
				}

				return [
					"Pivot local:",
					{
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.DATA_PROVIDER : this->fn(){
							//! \see TransformationTools.NodeTransformationHandlerTrait
							var nodes = getTransformedNodes();
							var arr = nodes[0].worldPosToLocalPos(pivot_ws()).toArray();
							return toJSON(arr.map(fn(key,value){return value.round(0.0001);}),false);
						},
						GUI.ON_DATA_CHANGED : this->fn(t){
							pivot_ws( nodes[0].localPosToWorldPos(new Geometry.Vec3( parseJSON(t))) );
							storePivotAtNode();
						},
						GUI.DATA_REFRESH_GROUP : refreshGroup,
					},
					"Pivot rel bb:",
					{
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.DATA_PROVIDER : this->fn(){
							//! \see TransformationTools.NodeTransformationHandlerTrait
							var nodes = getTransformedNodes();
							var arr = nodes[0].worldPosToLocalPos(pivot_ws()).toArray();
							var bb = nodes[0].getBB();
							arr[0] = bb.getExtentX() > 0 ? ( (arr[0] - bb.getMinX()) / bb.getExtentX() ) : 0.0;
							arr[1] = bb.getExtentY() > 0 ? ( (arr[1] - bb.getMinY()) / bb.getExtentY() ) : 0.0;
							arr[2] = bb.getExtentZ() > 0 ? ( (arr[2] - bb.getMinZ()) / bb.getExtentZ() ) : 0.0;
							return toJSON(arr.map(fn(key,value){return value.round(0.0001);}),false);
						},
						GUI.ON_DATA_CHANGED : this->fn(t){
							//! \see TransformationTools.NodeTransformationHandlerTrait
							var nodes = getTransformedNodes();

							var bb = nodes[0].getBB();
							var arr = parseJSON(t);

							pivot_ws( nodes[0].localPosToWorldPos(new Geometry.Vec3(
								bb.getMinX() + arr[0] * bb.getExtentX(),
								bb.getMinY() + arr[1] * bb.getExtentY(),
								bb.getMinZ() + arr[2] * bb.getExtentZ()
							)) );
							storePivotAtNode();
						},
						GUI.DATA_REFRESH_GROUP : refreshGroup,
						GUI.OPTIONS : [ "[0.5,0.5,0.5]",
							"[0.5,0,0.5]","[0.5,1,0.5]",
							"[0.5,0.5,0]","[0.5,0.5,1]",
							"[0,0.5,0.5]","[1,0.5,0.5]",

						]
					},bakePivot...];
			}
		},
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Rotate >",
			GUI.MENU : this->fn(){
                var value = DataWrapper.createFromValue(0);
				var refreshGroup = new GUI.RefreshGroup;

                var localContainer = gui.create({
                    GUI.TYPE : GUI.TYPE_CONTAINER,
                    GUI.WIDTH : 250,
                    GUI.LAYOUT :GUI.LAYOUT_TIGHT_FLOW,
                });
                foreach([ ["X-Axis:",new Geometry.Vec3(1,0,0)], ["Y-Axis:",new Geometry.Vec3(0,1,0)], ["Z-Axis:",new Geometry.Vec3(0,0,1)]]
						as var arr){
					localContainer+= arr[0];
					localContainer+={
						GUI.TYPE : GUI.TYPE_NUMBER,
						GUI.WIDTH : 40,
						GUI.DATA_WRAPPER: value,
						GUI.ON_DATA_CHANGED : this->fn(value,localAxis,dataWrapper){
							this.applyNodeTransformations();                        //! \see TransformationTools.NodeTransformationHandlerTrait
							foreach( this.getTransformedNodes() as var node)		//! \see TransformationTools.NodeTransformationHandlerTrait
								node.rotateLocal_deg(value,localAxis);
							this.applyNodeTransformations();                        //! \see TransformationTools.NodeTransformationHandlerTrait
							outln("Rotated about the local Axis (",localAxis,")",value," deg.");
							dataWrapper(0);
						}.bindLastParams(arr[1],value)
					};
				}
                var worldContainer = gui.create({
                    GUI.TYPE : GUI.TYPE_CONTAINER,
                    GUI.WIDTH : 250,
                    GUI.LAYOUT :GUI.LAYOUT_TIGHT_FLOW,
                });
                foreach([ ["X-Axis:",new Geometry.Vec3(1,0,0)], ["Y-Axis:",new Geometry.Vec3(0,1,0)], ["Z-Axis:",new Geometry.Vec3(0,0,1)]]
						as var arr){
					worldContainer+= arr[0];
					worldContainer+={
						GUI.TYPE : GUI.TYPE_NUMBER,
						GUI.WIDTH : 40,
						GUI.DATA_WRAPPER: value,
						GUI.ON_DATA_CHANGED : this->fn(value,localAxis,dataWrapper){
							this.applyNodeTransformations();                        //! \see TransformationTools.NodeTransformationHandlerTrait
							foreach( this.getTransformedNodes() as var node){		//! \see TransformationTools.NodeTransformationHandlerTrait
								var worldAxis = node.localDirToWorldDir(localAxis);
								node.rotateLocal_deg(value,worldAxis);
							}
							this.applyNodeTransformations();                        //! \see TransformationTools.NodeTransformationHandlerTrait
							outln("Rotated about the world Axis (",localAxis,")",value," deg.");
							dataWrapper(0);
						}.bindLastParams(arr[1],value)
					};
				}
				return ["Local Rotation",localContainer,"World Rotation",worldContainer];
            },

		},
		{
			GUI.TYPE : GUI.TYPE_NUMBER,
			GUI.LABEL : "Step size",
			GUI.DATA_WRAPPER : stepSize,
			GUI.OPTIONS : [1,5,15,45,0.1,0.01]
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Reset local rotations",
			GUI.ON_CLICK : this->fn(){
				this.applyNodeTransformations();						//! \see TransformationTools.NodeTransformationHandlerTrait
				foreach( this.getTransformedNodes() as var node)		//! \see TransformationTools.NodeTransformationHandlerTrait
					node.setSRT(node.getSRT().resetRotation());
				this.applyNodeTransformations();						//! \see TransformationTools.NodeTransformationHandlerTrait
			},
			GUI.DATA_WRAPPER : stepSize,
			GUI.OPTIONS : [1,5,15,45,0.1,0.01]
		},

		'----'];
	};

}

//----------------------------------------------------------------------------
