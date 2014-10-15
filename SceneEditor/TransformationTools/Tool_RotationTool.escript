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

//---------------------------------------------------------------------------------
static NodeAnchors = Std.require('LibMinSGExt/NodeAnchors');

static _updatePivot = fn(MinSG.Node node, [Geometry.Vec3,false] pivot){
	var newPivot = pivot ? pivot.toArray() : false;
	var oldPivot = node.isSet( $__rotationPivot) ? node.__rotationPivot : false;
	if(newPivot!=oldPivot){
		var fun = fn(node,pivot){
			node.__rotationPivot := pivot;
			NodeEditor.selectNodes( NodeEditor.getSelectedNodes() );
		};
		static Command = Std.require('LibUtilExt/Command');
		PADrend.executeCommand({
			Command.DESCRIPTION : "Transform pivot",
			Command.EXECUTE : 	[node,newPivot]=>fun,
			Command.UNDO : 		[node,oldPivot]=>fun
		});
	}
};

static _findPivot = fn(MinSG.Node node){
	if(node.isSet( $__rotationPivot) && node.__rotationPivot)
		return new Geometry.Vec3(node.__rotationPivot);
	var anchor = NodeAnchors.findAnchor(node,'pivot');
	if( anchor ){
		if(anchor().isA(Geometry.SRT))
			return anchor().getTranslation();
		if(anchor().isA(Geometry.Vec3))
			return anchor().clone();
	}
	if( node.isInstance() )
		return _findPivot(node.getPrototype());
	return new Geometry.Vec3;
};

var Tool = new Type;

//! \see ToolHelperTraits.GenericNodeTransformToolTrait
Traits.addTrait(Tool,ToolHelperTraits.GenericNodeTransformToolTrait);

Tool.pivot_ws @(init) := fn(){	return DataWrapper.createFromValue(void);	};
Tool.editNode @(private) := void;
Tool.stepSize @(private,init) := fn(){	return DataWrapper.createFromValue(1);	};
Tool.localTransform @(init) := fn(){	return DataWrapper.createFromValue(true);	};

//! (internal) Call to store the current pivot at the node if necessary.
Tool.storePivotAtNode ::= fn(){
	//! \see ToolHelperTraits.NodeTransformationHandlerTrait
	var nodes = getTransformedNodes();
	if(nodes.count()==1 && pivot_ws()){
		var localPivot = nodes[0].worldPosToLocalPos(pivot_ws());
		_updatePivot( nodes[0], localPivot );
	}
};

//! \see ToolHelperTraits.UIToolTrait
Tool.onToolInitOnce_static += fn(){
	var metaRoot = new MinSG.ListNode;
	this.setMetaNode(metaRoot);

	// ----------

	this.editNode = new MinSG.ListNode;
	metaRoot += editNode;

	//! \see EditNodeTraits.AdjustableProjSizeTrait
	Traits.addTrait( editNode, EditNodeTraits.AdjustableProjSizeTrait);

	//! \see ToolHelperTraits.FrameListenerTrait
	this.onFrame += editNode->editNode.adjustProjSize; //! \see EditNodeTraits.AdjustableProjSizeTrait

	//! \see EditNodeTraits.AnnotatableTrait
	Traits.addTrait( editNode, EditNodeTraits.AnnotatableTrait);

	// ----------

	var axisMarkerNode = new MinSG.GeometryNode(EditNodeFactories.createLineAxisMesh());
	metaRoot += axisMarkerNode;
	axisMarkerNode.deactivate();

	// ----------

	var pivotEditNode = EditNodeFactories.createTranslationEditNode();
	editNode += pivotEditNode;
	pivotEditNode.scale(0.5);

	pivotEditNode.onTranslationStart += [axisMarkerNode] => this->fn(axisMarkerNode){
		this.initialPivot_ws @(private) := pivot_ws().clone();
		axisMarkerNode.activate();
		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		var freePivot = getTransformedNodes().count()>1;
		if(freePivot)
			this.editNode.setAnnotation("Free Pivot");
		else
			this.editNode.setAnnotation("Bound Pivot");
	};
	pivotEditNode.onTranslate += this->fn(v){
		this.pivot_ws(new Geometry.Vec3( initialPivot_ws + v) );
	};
	pivotEditNode.onTranslationStop += [axisMarkerNode] => this->fn(axisMarkerNode,v){
		axisMarkerNode.deactivate();
		this.initialPivot_ws = void;
		this.storePivotAtNode();
		this.editNode.hideAnnotation();
	};

	// ----------
	var rotationNode = EditNodeFactories.createRotationEditNode();
	editNode += rotationNode;

	//! \see ToolHelperTraits.NodeTransformationHandlerTrait
	rotationNode.onRotationStart += this->applyNodeTransformations;
	rotationNode.onRotate += this->fn(deg,axis_ws){
		deg = deg.round(this.stepSize());

		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		foreach( this.getTransformedNodesOrigins() as var node,var origin){
			if(node.hasRelTransformationSRT()){
				node.setRelTransformation( origin.toSRT() );
			}else{
				node.setRelTransformation(origin);
			}				
			node.rotateAroundWorldAxis_deg(deg,axis_ws);
		}
		//! \see EditNodeTraits.AnnotatableTrait
		var dir = axis_ws.getDirection();
		editNode.setAnnotation("Rotate: "+deg+" ("+dir.x().round(0.01)+","+dir.y().round(0.01)+","+dir.z().round(0.01)+")");
	};
	rotationNode.onRotationStop += this->fn(...){
		this.applyNodeTransformations();				//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		editNode.hideAnnotation();						//! \see EditNodeTraits.AnnotatableTrait
	};
};

//! \see ToolHelperTraits.NodeSelectionListenerTrait
Tool.onNodesSelected_static += fn(Array selectedNodes){
	// reset pivot
	if(!selectedNodes.empty()){
		pivot_ws( selectedNodes[0].localPosToWorldPos( _findPivot(selectedNodes[0]) ) );
	}
//		if(selectedNodes.count()==1){
//		}else if(!selectedNodes.empty()){
		// ...
//			pivot_ws( new Geometry.Vec3(selectedNodes[0].getWorldOrigin() ) );
//		}
};

//! \see ToolHelperTraits.FrameListenerTrait
Tool.onFrame_static += fn(){
	//! \see ToolHelperTraits.NodeTransformationHandlerTrait
	var nodes = getTransformedNodes();
	if(nodes.empty())
		return;

	var metaRootNode = this.getMetaNode();

	if(localTransform()){
		var wm = nodes[0].getWorldTransformationMatrix();
		metaRootNode.setRelTransformation(new Geometry.SRT(wm.transformPosition(0,0,0),wm.transformDirection(0,0,-1),wm.transformDirection(0,1,0),1.0));
	}else{
		metaRootNode.resetRelTransformation();
	}
	metaRootNode.setWorldOrigin(pivot_ws());
};


//! \see ToolHelperTraits.ContextMenuProviderTrait
Tool.doCreateContextMenu ::= fn(){
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
		GUI.LABEL : "Pivot",
		GUI.MENU : this->fn(){
			// proxy
			var refreshGroup = new GUI.RefreshGroup;
			var bakePivot = [];

			//! \see ToolHelperTraits.NodeTransformationHandlerTrait
			if(getTransformedNodes().count()==1 && getTransformedNodes()[0]---|>MinSG.ListNode){
				bakePivot += {
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Bake pivot",
					GUI.TOOLTIP : "Move node so that the pivot is at 0,0,0\n while preserving the children's positions.",
					GUI.ON_CLICK : this->fn(){
						//! \see ToolHelperTraits.NodeTransformationHandlerTrait
						var node = this.getTransformedNodes()[0];
						if(!(node---|>MinSG.ListNode))
							return;
						var pivot = _findPivot(node);
						if(pivot.length()==0){
							PADrend.message("Baking pivot skipped.");
							return;
						}

						var nodes = [node];
						var before = [node.getWorldOrigin()];
						var after = [ node.localPosToWorldPos(pivot)];
						foreach(MinSG.getChildNodes(node) as var c){
							nodes += c;
							before += c.getWorldOrigin();
							after += c.getWorldOrigin();
						}
						var fun = fn(){
							PADrend.message("Baking pivot...");
							var nodes = this[0];
							var positions = this[1];
							var pivot = this[2];
							foreach(nodes as var i,var node)
								node.setWorldOrigin(positions[i]);
							_updatePivot( nodes[0],pivot );
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
						//! \see ToolHelperTraits.NodeTransformationHandlerTrait
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
						//! \see ToolHelperTraits.NodeTransformationHandlerTrait
						var nodes = getTransformedNodes();
						var arr = nodes[0].worldPosToLocalPos(pivot_ws()).toArray();
						var bb = nodes[0].getBB();
						arr[0] = bb.getExtentX() > 0 ? ( (arr[0] - bb.getMinX()) / bb.getExtentX() ) : 0.0;
						arr[1] = bb.getExtentY() > 0 ? ( (arr[1] - bb.getMinY()) / bb.getExtentY() ) : 0.0;
						arr[2] = bb.getExtentZ() > 0 ? ( (arr[2] - bb.getMinZ()) / bb.getExtentZ() ) : 0.0;
						return toJSON(arr.map(fn(key,value){return value.round(0.0001);}),false);
					},
					GUI.ON_DATA_CHANGED : this->fn(t){
						//! \see ToolHelperTraits.NodeTransformationHandlerTrait
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
				},
				{
					GUI.TYPE : GUI.TYPE_MENU,
					GUI.LABEL : "From anchor",
					GUI.MENU_WIDTH : 200,
					GUI.MENU_PROVIDER : [this] => fn(tool){
						var entries = ["*Anchors*"];
						foreach( tool.getTransformedNodes() as var node){
							foreach( NodeAnchors.findAnchors(node) as var anchorName,var anchor ){
								entries += {
									GUI.TYPE : GUI.TYPE_BUTTON,
									GUI.LABEL : anchorName + "@" + node,
									GUI.ON_CLICK : [tool,node,anchorName] => fn(tool,node,anchorName){
										var anchor = NodeAnchors.findAnchor(node,anchorName)();
										tool.pivot_ws(  node.localPosToWorldPos( anchor.isA(Geometry.SRT)?anchor.getTranslation() : anchor ) );
									}
								};
							}
						}
						tool.storePivotAtNode();
						return entries;
						
					}
				},					
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Store as anchor",
					GUI.TOOLTIP : "Store current pivot as 'pivot'-anchor.",
					GUI.ON_CLICK : [this] => fn(tool){
						foreach( tool.getTransformedNodes() as var node)
							NodeAnchors.createAnchor( node,'pivot', node.worldPosToLocalPos(tool.pivot_ws()) );							
					}
				},
				
				bakePivot...];
		}
	},
	{
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "Rotate",
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
					GUI.ON_DATA_CHANGED : [arr[1],value] => this->fn(localAxis,dataWrapper, value){
						this.applyNodeTransformations();                        //! \see ToolHelperTraits.NodeTransformationHandlerTrait
						foreach( this.getTransformedNodes() as var node)		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
							node.rotateLocal_deg(value,localAxis);
						this.applyNodeTransformations();                        //! \see ToolHelperTraits.NodeTransformationHandlerTrait
						outln("Rotated about the local Axis (",localAxis,")",value," deg.");
						dataWrapper(0);
					}
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
					GUI.ON_DATA_CHANGED : [arr[1],value] => this->fn(localAxis,dataWrapper, value){
						this.applyNodeTransformations();                        //! \see ToolHelperTraits.NodeTransformationHandlerTrait
						foreach( this.getTransformedNodes() as var node){		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
							var worldAxis = node.localDirToWorldDir(localAxis);
							node.rotateLocal_deg(value,worldAxis);
						}
						this.applyNodeTransformations();                        //! \see ToolHelperTraits.NodeTransformationHandlerTrait
						outln("Rotated about the world Axis (",localAxis,")",value," deg.");
						dataWrapper(0);
					}
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
			this.applyNodeTransformations();						//! \see ToolHelperTraits.NodeTransformationHandlerTrait
			foreach( this.getTransformedNodes() as var node)		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
				node.setRelTransformation(node.getRelTransformationSRT().resetRotation());
			this.applyNodeTransformations();						//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		},
		GUI.OPTIONS : [1,5,15,45,0.1,0.01]
	},

	'----'];
};

return Tool;
//----------------------------------------------------------------------------
