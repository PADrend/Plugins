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
 **	[Plugin:SceneEditor/TransformationTools/Tool_AnchorTool.escript]
 **/

declareNamespace($TransformationTools);

loadOnce(__DIR__+"/EditNodeTraits.escript");
loadOnce(__DIR__+"/EditNodeFactories.escript");
loadOnce(__DIR__+"/ToolHelperTraits.escript");


//---------------------------------------------------------------------------------


TransformationTools.AnchorTool := new Type;
{
	var T = TransformationTools.AnchorTool;

	//! \see TransformationTools.GenericNodeTransformToolTrait
	Traits.addTrait(T,TransformationTools.GenericNodeTransformToolTrait);


	//! \see TransformationTools.UIToolTrait
	T.onToolInitOnce_static += fn(){
	};

	//! \see TransformationTools.UIToolTrait
	T.onToolDeactivation_static += fn(){
		this.cleanup;
	};


	T.cleanup ::= fn(){
		this.onFrame.clear();												//! \see TransformationTools.FrameListenerTrait
		this.destroyMetaNode();												//! \see TransformationTools.MetaNodeContainerTrait
	};
		
	T.mat_Vec3 := (new MinSG.MaterialState).setAmbient(new Util.Color4f(0,0,1,0.5));
	T.mat_SRT := (new MinSG.MaterialState).setAmbient(new Util.Color4f(0,1,0,0.5));

	T.gridSizes @(private,const) ::= { // scaling -> grid size (used for rounding translations)
		0.0	:	0.0001,
		0.15 :	0.001,
		1.2 :	0.01,
		2.0 :	0.1,
		8.0 :	1.0
	};
	T.roundTranslationVector ::= fn(worldTranslation,editNodeScaling){
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
	
	
	//! \see TransformationTools.NodeSelectionListenerTrait
	T.onNodesSelected_static += fn(Array selectedNodes){
		this.cleanup();
		if(selectedNodes.count()!=1)
			return;
		var node = selectedNodes[0];
		
		var anchors = node.findAnchors();
		if(anchors.empty())
			return;

		var metaRoot = new MinSG.ListNode;
		this.setMetaNode(metaRoot);											//! \see TransformationTools.MetaNodeContainerTrait
		this.enableMetaNode();												//! \see TransformationTools.MetaNodeContainerTrait

		metaRoot.setRelTransformation( node.getWorldTransformationSRT() );
		
		foreach(anchors as var anchorName,var anchor){
			var location = anchor();
			if(!location)
				continue;

			PADrend.message("Creating anchorNode: "+anchorName);
		
			var editNode = new MinSG.ListNode;
			metaRoot += editNode;

			var markerNode = new MinSG.GeometryNode(EditNodes.getCubeMesh());
			markerNode.scale(0.2);
			editNode += markerNode;
			Traits.addTrait( markerNode, EditNodes.AnnotatableTrait);		//! \see EditNodes.AnnotatableTrait
			markerNode.setAnnotation("["+anchorName+"]");					//! \see EditNodes.AnnotatableTrait
			markerNode += (location---|>Geometry.Vec3) ? this.mat_Vec3 : this.mat_SRT;

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
				}else if(location---|>Geometry.Vec3){
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
			if(!node.getAnchor(anchorName)){ 
				// only the marker is visible -> smaller projected size required
				Traits.addTrait( editNode, EditNodes.AdjustableProjSizeTrait,10,30);	//! \see EditNodes.AdjustableProjSizeTrait
				//! \see TransformationTools.FrameListenerTrait
				this.onFrame += editNode->editNode.adjustProjSize; 						//! \see EditNodes.AdjustableProjSizeTrait
				continue;
			}

			Traits.addTrait( editNode, EditNodes.AdjustableProjSizeTrait);				//! \see EditNodes.AdjustableProjSizeTrait
			//! \see TransformationTools.FrameListenerTrait
			this.onFrame += editNode->editNode.adjustProjSize; 							//! \see EditNodes.AdjustableProjSizeTrait


			var translatorNode = EditNodes.createTranslationEditNode();
			editNode += translatorNode;
			
			translatorNode.onTranslationStart += [ctxt] => fn(ctxt){
				ctxt.initalRelPos := ctxt.editNode.getRelPosition().round(0.001);

				ctxt.axisMarkerNode := new MinSG.GeometryNode(EditNodes.createLineAxisMesh());
				ctxt.editNode.getParent() += ctxt.axisMarkerNode;
				ctxt.axisMarkerNode.setRelTransformation(ctxt.editNode.getRelTransformationSRT());
				ctxt.markerNode.setAnnotation("["+ctxt.anchorName+"]\n"+ctxt.initalRelPos );				//! \see EditNodes.AnnotatableTrait
			};
			
			translatorNode.onTranslate += [ctxt] => this->fn(ctxt, worldTranslation){
				var relTranslation = this.roundTranslationVector(ctxt.editNode.worldDirToRelDir(worldTranslation),ctxt.editNode.getRelScaling());
				var newRelPos = (ctxt.initalRelPos + relTranslation).round(0.001);
				ctxt.editNode.setRelPosition( newRelPos ); 
				ctxt.axisMarkerNode.setRelTransformation( ctxt.editNode.getRelTransformationSRT());
				ctxt.markerNode.setAnnotation("["+ctxt.anchorName+"]\n"+newRelPos);				//! \see EditNodes.AnnotatableTrait
			};

			translatorNode.onTranslationStop += [ctxt] => this->fn(ctxt, worldTranslation){
				var relTranslation = this.roundTranslationVector(ctxt.editNode.worldDirToRelDir(worldTranslation),ctxt.editNode.getRelScaling());
				var newRelPos = (ctxt.initalRelPos + relTranslation).round(0.001);
				
				var oldLocation = ctxt.anchor();
				var newLocation;
				
				if(oldLocation---|>Geometry.Vec3){
					newLocation =  newRelPos ;
				}else if(oldLocation---|>Geometry.SRT){
					newLocation = oldLocation.clone();
					newLocation.setTranslation(newRelPos);
				}
				PADrend.executeCommand({
					Command.DESCRIPTION : "Transform anchor",
					Command.EXECUTE : 	[newLocation] => ctxt.anchor ,
					Command.UNDO : 		[oldLocation.clone()] => ctxt.anchor
				});
				MinSG.destroy(ctxt.axisMarkerNode);
			};

			 if(! (location---|>Geometry.SRT)) // no rotation necessary-> continue
				continue;
			
			translatorNode.scale(0.5);
			
			var rotationNode = EditNodes.createRotationEditNode();
			
			editNode += rotationNode;

			rotationNode.onRotationStart += [ctxt] => fn(ctxt){
				ctxt.originalSRT := ctxt.editNode.getRelTransformationSRT();
				ctxt.axisMarkerNode := new MinSG.GeometryNode(EditNodes.createLineAxisMesh());
				ctxt.editNode.getParent() += ctxt.axisMarkerNode;
				ctxt.axisMarkerNode.setRelTransformation(ctxt.editNode.getRelTransformationSRT());				
			};
			rotationNode.onRotate += [ctxt] => fn(ctxt, deg,axis_ws){
				deg = deg.round(1.0);
				ctxt.editNode.setRelTransformation(ctxt.originalSRT);
				ctxt.editNode.rotateAroundWorldAxis_deg(deg,axis_ws);
				ctxt.axisMarkerNode.setRelTransformation( ctxt.editNode.getRelTransformationSRT());
		
				ctxt.markerNode.setAnnotation("["+ctxt.anchorName+"]\n"+deg);				//! \see EditNodes.AnnotatableTrait

			};
			rotationNode.onRotationStop += [ctxt] => fn(ctxt, deg,axis_ws){
				deg = deg.round(1.0);
				ctxt.editNode.setRelTransformation(ctxt.originalSRT);
				ctxt.editNode.rotateAroundWorldAxis_deg(deg,axis_ws);
				var newLocation = ctxt.editNode.getRelTransformationSRT();
				newLocation.setScale(1.0);
				
				PADrend.executeCommand({
					Command.DESCRIPTION : "Transform anchor",
					Command.EXECUTE : 	[newLocation] => ctxt.anchor ,
					Command.UNDO : 		[ctxt.originalSRT.clone()] => ctxt.anchor
				});
				MinSG.destroy(ctxt.axisMarkerNode);

			};
		}
	};

	//! \see TransformationTools.FrameListenerTrait
	T.onFrame_static += fn(){
		// update editNodes ?
	};
	
	//! \see TransformationTools.ContextMenuProviderTrait
	T.doCreateContextMenu ::= fn(){
		var entries = ["*Anchors*"];
		if(this.getSelectedNodes().count()!=1){ 					//! \see TransformationTools.NodeSelectionListenerTrait
			entries += "Select single node!";
			entries += '----';
			return entries;
		}
		var node = this.getSelectedNodes()[0];
		foreach(node.findAnchors() as var name,var anchor){
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
				
				var name = DataWrapper.createFromValue("anchor#"+node.findAnchors().count());
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
							var a = node.getAnchor(name());
							if(a && a()){
								Runtime.warn("Anchor '"+name()+"' overwritten.");
							}else{
								a = node.createAnchor(name());
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

}

//----------------------------------------------------------------------------
