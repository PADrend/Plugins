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

static NodeAnchors = Std.module('LibMinSGExt/NodeAnchors');

var Tool = new Type;

//! \see ToolHelperTraits.GenericNodeTransformToolTrait
Traits.addTrait(Tool,ToolHelperTraits.GenericNodeTransformToolTrait);


//! \see ToolHelperTraits.UIToolTrait
Tool.onToolInitOnce_static += fn(){
};

//! \see ToolHelperTraits.UIToolTrait
Tool.onToolDeactivation_static += fn(){
	this.cleanup;
};


Tool.cleanup ::= fn(){
	this.onFrame.clear();												//! \see ToolHelperTraits.FrameListenerTrait
	this.destroyMetaNode();												//! \see ToolHelperTraits.MetaNodeContainerTrait
};
	
Tool.mat_Vec3 := (new MinSG.MaterialState).setAmbient(new Util.Color4f(0,0,1,0.5));
Tool.mat_SRT := (new MinSG.MaterialState).setAmbient(new Util.Color4f(0,1,0,0.5));

Tool.gridSizes @(private,const) ::= { // scaling -> grid size (used for rounding translations)
	0.0	:	0.0001,
	0.15 :	0.001,
	1.2 :	0.01,
	2.0 :	0.1,
	8.0 :	1.0
};
Tool.roundTranslationVector ::= fn(worldTranslation,editNodeScaling){
	worldTranslation = worldTranslation.clone();
	var snap = 1;
	foreach(this.gridSizes as var scaling, var grid){
		if(scaling>editNodeScaling)
			break;
		snap = grid;
	}
	if(worldTranslation.x()!=0)
		worldTranslation.x(worldTranslation.x().round(snap));
	if(worldTranslation.y()!=0)
		worldTranslation.y(worldTranslation.y().round(snap));
	if(worldTranslation.z()!=0)
		worldTranslation.z(worldTranslation.z().round(snap));
	return worldTranslation;
};


//! \see ToolHelperTraits.NodeSelectionListenerTrait
Tool.onNodesSelected_static += fn(Array selectedNodes){
	this.cleanup();
	if(selectedNodes.count()!=1)
		return;
	var node = selectedNodes[0];
	
	var anchors = NodeAnchors.findAnchors(node);
	if(anchors.empty())
		return;

	var metaRoot = new MinSG.ListNode;
	this.setMetaNode(metaRoot);											//! \see ToolHelperTraits.MetaNodeContainerTrait
	this.enableMetaNode();												//! \see ToolHelperTraits.MetaNodeContainerTrait

	metaRoot.setRelTransformation( node.getWorldTransformationSRT() );
	
	foreach(anchors as var anchorName,var anchor){
		var location = anchor();
		if(!location)
			continue;

		PADrend.message("Creating anchorNode: "+anchorName);
	
		var editNode = new MinSG.ListNode;
		metaRoot += editNode;

		var markerNode = new MinSG.GeometryNode(EditNodeFactories.getCubeMesh());
		markerNode.scale(0.2);
		editNode += markerNode;
		Std.Traits.addTrait( markerNode, EditNodeTraits.AnnotatableTrait);		//! \see EditNodeTraits.AnnotatableTrait
		markerNode.setAnnotation("["+anchorName+"]");					//! \see EditNodeTraits.AnnotatableTrait
		markerNode += (location.isA(Geometry.Vec3)) ? this.mat_Vec3 : this.mat_SRT;

		var ctxt = new ExtObject;
		ctxt.node := node;
		ctxt.anchor := anchor;
		ctxt.anchorName := anchorName;
		ctxt.editNode := editNode;
		ctxt.markerNode := markerNode;

		var updateEditNode = [editNode] => fn(editNode, location){
			if(editNode.isDestroyed()){
				outln("~");
				return $REMOVE;
			}
			if(!location){
				editNode.deactivate();
			}else if(location.isA(Geometry.Vec3)){
				editNode.activate();
				editNode.setRelPosition(location);
			}else{
				editNode.activate();
				editNode.setRelTransformation(location);
			}
		};
		updateEditNode(location);
		anchor.onDataChanged += updateEditNode;
	
		// anchor is defined in prototype -> just show, but do not edit.
		if(!NodeAnchors.getAnchor(node,anchorName)){ 
			// only the marker is visible -> smaller projected size required
			Std.Traits.addTrait( editNode, EditNodeTraits.AdjustableProjSizeTrait,10,30);	//! \see EditNodeTraits.AdjustableProjSizeTrait
			//! \see ToolHelperTraits.FrameListenerTrait
			this.onFrame += editNode->editNode.adjustProjSize; 						//! \see EditNodeTraits.AdjustableProjSizeTrait
			continue;
		}

		Std.Traits.addTrait( editNode, EditNodeTraits.AdjustableProjSizeTrait);				//! \see EditNodeTraits.AdjustableProjSizeTrait
		//! \see ToolHelperTraits.FrameListenerTrait
		this.onFrame += editNode->editNode.adjustProjSize; 							//! \see EditNodeTraits.AdjustableProjSizeTrait


		var translatorNode = EditNodeFactories.createTranslationEditNode();
		editNode += translatorNode;
		
		translatorNode.onTranslationStart += [ctxt] => fn(ctxt){
			ctxt.initalRelPos := ctxt.editNode.getRelPosition().round(0.001);

			ctxt.axisMarkerNode := new MinSG.GeometryNode(EditNodeFactories.createLineAxisMesh());
			ctxt.editNode.getParent() += ctxt.axisMarkerNode;
			ctxt.axisMarkerNode.setRelTransformation(ctxt.editNode.getRelTransformationSRT());
			ctxt.markerNode.setAnnotation("["+ctxt.anchorName+"]\n"+ctxt.initalRelPos );				//! \see EditNodeTraits.AnnotatableTrait
		};
		
		translatorNode.onTranslate += [ctxt] => this->fn(ctxt, worldTranslation){
			var relTranslation = this.roundTranslationVector(ctxt.editNode.worldDirToRelDir(worldTranslation),ctxt.editNode.getRelScaling());
			var newRelPos = (ctxt.initalRelPos + relTranslation).round(0.001);
			ctxt.editNode.setRelPosition( newRelPos ); 
			ctxt.axisMarkerNode.setRelTransformation( ctxt.editNode.getRelTransformationSRT());
			ctxt.markerNode.setAnnotation("["+ctxt.anchorName+"]\n"+newRelPos);				//! \see EditNodeTraits.AnnotatableTrait
		};

		translatorNode.onTranslationStop += [ctxt] => this->fn(ctxt, worldTranslation){
			var relTranslation = this.roundTranslationVector(ctxt.editNode.worldDirToRelDir(worldTranslation),ctxt.editNode.getRelScaling());
			var newRelPos = (ctxt.initalRelPos + relTranslation).round(0.001);
			
			var oldLocation = ctxt.anchor();
			var newLocation;
			
			if(oldLocation.isA(Geometry.Vec3)){
				newLocation =  newRelPos ;
			}else if(oldLocation.isA(Geometry.SRT)){
				newLocation = oldLocation.clone();
				newLocation.setTranslation(newRelPos);
			}
			static Command = Std.module('LibUtilExt/Command');
			PADrend.executeCommand({
				Command.DESCRIPTION : "Transform anchor",
				Command.EXECUTE : 	[newLocation] => ctxt.anchor ,
				Command.UNDO : 		[oldLocation.clone()] => ctxt.anchor
			});
			MinSG.destroy(ctxt.axisMarkerNode);
		};

		 if(! (location.isA(Geometry.SRT))) // no rotation necessary-> continue
			continue;
		
		translatorNode.scale(0.5);
		
		var rotationNode = EditNodeFactories.createRotationEditNode();
		
		editNode += rotationNode;

		rotationNode.onRotationStart += [ctxt] => fn(ctxt){
			ctxt.originalSRT := ctxt.editNode.getRelTransformationSRT();
			ctxt.axisMarkerNode := new MinSG.GeometryNode(EditNodeFactories.createLineAxisMesh());
			ctxt.editNode.getParent() += ctxt.axisMarkerNode;
			ctxt.axisMarkerNode.setRelTransformation(ctxt.editNode.getRelTransformationSRT());				
		};
		rotationNode.onRotate += [ctxt] => fn(ctxt, deg,axis_ws){
			deg = deg.round(1.0);
			ctxt.editNode.setRelTransformation(ctxt.originalSRT);
			ctxt.editNode.rotateAroundWorldAxis_deg(deg,axis_ws);
			ctxt.axisMarkerNode.setRelTransformation( ctxt.editNode.getRelTransformationSRT());
	
			ctxt.markerNode.setAnnotation("["+ctxt.anchorName+"]\n"+deg);				//! \see EditNodeTraits.AnnotatableTrait

		};
		rotationNode.onRotationStop += [ctxt] => fn(ctxt, deg,axis_ws){
			deg = deg.round(1.0);
			ctxt.editNode.setRelTransformation(ctxt.originalSRT);
			ctxt.editNode.rotateAroundWorldAxis_deg(deg,axis_ws);
			var newLocation = ctxt.editNode.getRelTransformationSRT();
			newLocation.setScale(1.0);
			static Command = Std.module('LibUtilExt/Command');
			PADrend.executeCommand({
				Command.DESCRIPTION : "Transform anchor",
				Command.EXECUTE : 	[newLocation] => ctxt.anchor ,
				Command.UNDO : 		[ctxt.originalSRT.clone()] => ctxt.anchor
			});
			MinSG.destroy(ctxt.axisMarkerNode);

		};
	}
};

//! \see ToolHelperTraits.FrameListenerTrait
Tool.onFrame_static += fn(){
	// update editNodes ?
};

//! \see ToolHelperTraits.ContextMenuProviderTrait
Tool.doCreateContextMenu ::= fn(){
	var entries = ["*Anchors*"];
	if(this.getSelectedNodes().count()!=1){ 					//! \see ToolHelperTraits.NodeSelectionListenerTrait
		entries += "Select single node!";
		entries += '----';
		return entries;
	}
	var node = this.getSelectedNodes()[0];
	foreach( NodeAnchors.findAnchors(node) as var name,var anchor){
		if(!anchor())
			continue;
		if(!node.getAnchor(name)){
			entries += {
				GUI.TYPE : GUI.TYPE_LABEL,
				GUI.LABEL : "["+ name+"] @prototype",
				GUI.TOOLTIP : "[" + name + "] : "+anchor()
			};
			continue;
		}
		entries += {
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : ("["+name+"]").fillUp(15," "),
			GUI.MENU : [anchor,node] => fn(anchor,node){
				var refreshGroup = new GUI.RefreshGroup;
				var entries = [
					"Position (local):",
					{
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.DATA_PROVIDER : [anchor] => fn(anchor){
							var pos = (anchor() ---|> Geometry.SRT) ? anchor().getTranslation() : anchor();
							return toJSON( pos.toArray(),false);
						},
						GUI.ON_DATA_CHANGED : [anchor,refreshGroup] => fn(anchor,refreshGroup, t){
							var pos = new Geometry.Vec3( parseJSON(t) );
							anchor( (anchor() ---|> Geometry.SRT) ? anchor().clone().setTranslation(pos) : pos);
							refreshGroup.refresh(); // bug workaround
						},
						GUI.DATA_REFRESH_GROUP : refreshGroup,
					},
					"Position (relative to bb):",
					{
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.DATA_PROVIDER : [anchor,node] => fn(anchor,node){
							var pos = (anchor() ---|> Geometry.SRT) ? anchor().getTranslation() : anchor();
							var arr = pos.toArray();
							var bb = node.getBB();
							arr[0] = bb.getExtentX() > 0 ? ( (arr[0] - bb.getMinX()) / bb.getExtentX() ) : 0.0;
							arr[1] = bb.getExtentY() > 0 ? ( (arr[1] - bb.getMinY()) / bb.getExtentY() ) : 0.0;
							arr[2] = bb.getExtentZ() > 0 ? ( (arr[2] - bb.getMinZ()) / bb.getExtentZ() ) : 0.0;
							return toJSON(arr.map(fn(key,value){return value.round(0.0001);}),false);
						},
						GUI.ON_DATA_CHANGED : [anchor,node,refreshGroup] => fn(anchor,node,refreshGroup, t){
							var arr = parseJSON(t);
							var pos = node.getBB().getRelPosition(arr[0],arr[1],arr[2]);
							anchor( (anchor() ---|> Geometry.SRT) ? anchor().clone().setTranslation(pos) : pos);
							refreshGroup.refresh(); // bug workaround
						},
						GUI.DATA_REFRESH_GROUP : refreshGroup,
						GUI.OPTIONS : [ "[0.5,0.5,0.5]",
							"[0.5,0,0.5]","[0.5,1,0.5]",
							"[0.5,0.5,0]","[0.5,0.5,1]",
							"[0,0.5,0.5]","[1,0.5,0.5]",

						]
					}
				];
				
				if(anchor() ---|> Geometry.SRT){
					entries += {
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Reset rotation",
						GUI.ON_CLICK : [anchor] => fn(anchor){
							anchor( anchor().clone().resetRotation() );
						}
					};
				}
				entries += {
					GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
					GUI.LABEL : "Delete",
					GUI.ON_CLICK : [anchor] => fn(anchor){
						anchor( false );
						NodeEditor.selectNodes(NodeEditor.getSelectedNodes());
						gui.closeAllMenus();
					}
				};
				return entries;
			}
		};
	}
	entries +='----';
	entries += {
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "New Anchor",
		GUI.MENU : [node] => fn(node){
			
			var name = DataWrapper.createFromValue("anchor#"+NodeAnchors.findAnchors(node).count());
			var dir = DataWrapper.createFromValue(false);
			return [
				"Anchor name:",
				{
					GUI.TYPE : GUI.TYPE_TEXT,
					GUI.DATA_WRAPPER : name
				},
				{
					GUI.TYPE : GUI.TYPE_BOOL,
					GUI.DATA_WRAPPER : dir,
					GUI.LABEL : "Include direction"
				},
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Create",
					GUI.ON_CLICK : [node,name,dir] => fn(node,name,dir){
						var a = NodeAnchors.getAnchor(node,name());
						if(a && a()){
							Runtime.warn("Anchor '"+name()+"' overwritten.");
						}else{
							a = NodeAnchors.createAnchor(node,name());
						}
						a( dir() ? new Geometry.SRT : new Geometry.Vec3 );
						NodeEditor.selectNodes(NodeEditor.getSelectedNodes());
						gui.closeAllMenus();
					}
				},
			];
			
		},
	};
	
	entries +='----';
	return entries;

	
};

return Tool;
//----------------------------------------------------------------------------
