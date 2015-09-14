/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C)2015 Sascha Brandt <myeti@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static EditNodeFactories = module('SceneEditor/TransformationTools/EditNodeFactories');
static EditNodeTraits = module('SceneEditor/TransformationTools/EditNodeTraits');
static ToolHelperTraits = module('SceneEditor/TransformationTools/ToolHelperTraits');
static TransformationObserverTrait = Std.module('LibMinSGExt/Traits/TransformationObserverTrait');
static PathManagement = Std.module('Waypoints/PathManagement');

//---------------------------------------------------------------------------------

static NodeAnchors = Std.module('LibMinSGExt/NodeAnchors');

var Tool = new Type;

Tool.pathVisuNode @(private) := void;

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
	this.pathVisuNode = void;
};

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

static createPathMesh = fn(MinSG.PathNode pathNode) {
	var mb = new Rendering.MeshBuilder;
	mb.color(new Util.Color4f(0.9,0,0,0.5));
	foreach(pathNode.getWaypoints() as var wp) {
		mb.position(wp.getRelPosition());
		mb.addVertex();
	}
	var mesh = mb.buildMesh();
	mesh.setDrawLineStrip();
	return mesh;
};

static updatePathMesh = fn(MinSG.PathNode pathNode, Rendering.Mesh mesh, wpIndex = void) {
	if(mesh.getVertexCount() != pathNode.countChildren()) {
		mesh.swap(createPathMesh(pathNode));
		return;
	}
	var waypoints = pathNode.getWaypoints();
	var posAcc = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);
	if(wpIndex) {
		posAcc.setPosition(wpIndex, waypoints[wpIndex].getRelPosition());
	} else {
		var i = 0;
		foreach(waypoints as var wp) {
			posAcc.setPosition(i, wp.getRelPosition());
		}
	}
	mesh._markAsChanged();
	//mesh._upload();
	return;
};

Tool._updateWaypoint ::= fn(node, waypoint, wpIndex, metaRoot) {
	var waypointName = "" + wpIndex + " - " + waypoint.getTime();
	var location = waypoint.getRelTransformationSRT();

	PADrend.message("Creating waypoint: "+waypointName);

	var editNode = new MinSG.ListNode;
	metaRoot += editNode;

	var markerNode = new MinSG.GeometryNode(EditNodeFactories.getCubeMesh());
	markerNode.scale(0.2);
	editNode += markerNode;
	Std.Traits.addTrait( markerNode, EditNodeTraits.AnnotatableTrait);		//! \see EditNodeTraits.AnnotatableTrait
	markerNode.setAnnotation("["+waypointName+"]");					//! \see EditNodeTraits.AnnotatableTrait
	markerNode += this.mat_SRT;

	var ctxt = new ExtObject;
	ctxt.node := node;
	ctxt.waypoint := waypoint;
	ctxt.waypointIndex := wpIndex;
	ctxt.waypointName := waypointName;
	ctxt.editNode := editNode;
	ctxt.markerNode := markerNode;
	ctxt.pathVisuNode := this.pathVisuNode;

	var updateEditNode = [ctxt] => fn(ctxt, ...){
		if(ctxt.editNode.isDestroyed()){
			outln("~");
			return $REMOVE;
		}
		ctxt.editNode.setRelTransformation(this.getRelTransformationSRT());
		updatePathMesh(ctxt.node, ctxt.pathVisuNode.getMesh(), ctxt.waypointIndex);
	};
	(waypoint->updateEditNode)();

	Std.Traits.assureTrait(waypoint, TransformationObserverTrait);
	waypoint.onNodeTransformed += updateEditNode;

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
		ctxt.markerNode.setAnnotation("["+ctxt.waypointName+"]\n"+ctxt.initalRelPos );				//! \see EditNodeTraits.AnnotatableTrait
	};

	translatorNode.onTranslate += [ctxt] => this->fn(ctxt, worldTranslation){
		var relTranslation = this.roundTranslationVector(ctxt.editNode.worldDirToRelDir(worldTranslation),ctxt.editNode.getRelScaling());
		var newRelPos = (ctxt.initalRelPos + relTranslation).round(0.001);
		ctxt.editNode.setRelPosition( newRelPos );
		ctxt.axisMarkerNode.setRelTransformation( ctxt.editNode.getRelTransformationSRT());
		ctxt.markerNode.setAnnotation("["+ctxt.waypointName+"]\n"+newRelPos);				//! \see EditNodeTraits.AnnotatableTrait
	};

	translatorNode.onTranslationStop += [ctxt] => this->fn(ctxt, worldTranslation){
		var relTranslation = this.roundTranslationVector(ctxt.editNode.worldDirToRelDir(worldTranslation),ctxt.editNode.getRelScaling());
		var newRelPos = (ctxt.initalRelPos + relTranslation).round(0.001);

		var oldLocation = ctxt.waypoint.getRelTransformationSRT();
		var newLocation = oldLocation.clone();
		newLocation.setTranslation(newRelPos);

		static Command = Std.module('LibUtilExt/Command');
		PADrend.executeCommand({
			Command.DESCRIPTION : "Transform waypoint",
			Command.EXECUTE : 	[newLocation] => ctxt.waypoint->ctxt.waypoint.setRelTransformation ,
			Command.UNDO : 		[oldLocation.clone()] => ctxt.waypoint->ctxt.waypoint.setRelTransformation
		});
		MinSG.destroy(ctxt.axisMarkerNode);
	};
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

		ctxt.markerNode.setAnnotation("["+ctxt.waypointName+"]\n"+deg);				//! \see EditNodeTraits.AnnotatableTrait

	};
	rotationNode.onRotationStop += [ctxt] => fn(ctxt, deg,axis_ws){
		deg = deg.round(1.0);
		ctxt.editNode.setRelTransformation(ctxt.originalSRT);
		ctxt.editNode.rotateAroundWorldAxis_deg(deg,axis_ws);
		var newLocation = ctxt.editNode.getRelTransformationSRT();
		newLocation.setScale(1.0);
		static Command = Std.module('LibUtilExt/Command');
		PADrend.executeCommand({
			Command.DESCRIPTION : "Transform waypoint",
			Command.EXECUTE : 	[newLocation] => ctxt.waypoint->ctxt.waypoint.setRelTransformation ,
			Command.UNDO : 		[ctxt.originalSRT.clone()] => ctxt.waypoint->ctxt.waypoint.setRelTransformation
		});
		MinSG.destroy(ctxt.axisMarkerNode);

	};
};

//! \see ToolHelperTraits.NodeSelectionListenerTrait
Tool.onNodesSelected_static += fn(Array selectedNodes){
	this.cleanup();
	if(selectedNodes.count()!=1)
		return;
	var node = selectedNodes[0];
  if(!(node ---|> MinSG.PathNode))
    return;

	var waypoints = node.getWaypoints();
	if(waypoints.empty())
		return;

	var metaRoot = new MinSG.ListNode;
	this.setMetaNode(metaRoot);											//! \see ToolHelperTraits.MetaNodeContainerTrait
	this.enableMetaNode();												//! \see ToolHelperTraits.MetaNodeContainerTrait

	metaRoot.setRelTransformation( node.getWorldTransformationSRT() );

  // Create path
	this.pathVisuNode = new MinSG.GeometryNode(createPathMesh(node));
	metaRoot += pathVisuNode;

  var wpIndex = 0;
	foreach(waypoints as var waypoint){
		this._updateWaypoint(node, waypoint, wpIndex++, metaRoot);
	}
};

//! \see ToolHelperTraits.FrameListenerTrait
Tool.onFrame_static += fn(){
	// update editNodes ?
};

//! \see ToolHelperTraits.ContextMenuProviderTrait
Tool.doCreateContextMenu ::= fn(){
	var entries = ["*Waypoints*"];
	entries += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Create new PathNode",
		GUI.ON_CLICK : fn(){
			var path = new MinSG.PathNode;
			var parent = NodeEditor.getSelectedNode();
			if(!parent || !(parent ---|> MinSG.GroupNode))
				parent = PADrend.getCurrentScene();
			parent += path;
			path.createWaypoint(new Geometry.SRT, 0);
			NodeEditor.selectNode(path);
			gui.closeAllMenus();
		}
	};
	
	if(this.getSelectedNodes().count()!=1){ 					//! \see ToolHelperTraits.NodeSelectionListenerTrait
		entries += "Select single node!";
		entries += '----';
		return entries;
	}
	var node = this.getSelectedNodes()[0];
  if(!(node ---|> MinSG.PathNode)) {
    entries += "Select path node!";
		entries += '----';
		return entries;
  }
  var wpIndex = -1;
	foreach( node.getWaypoints() as var waypoint){
    var name = "" + (++wpIndex);

		entries += {
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : ("["+name+"]").fillUp(15," "),
			GUI.MENU : [waypoint,node] => fn(waypoint,node){
				var refreshGroup = new GUI.RefreshGroup;
				var entries = [
					"Time:",
					{
						GUI.TYPE : GUI.TYPE_NUMBER,
						GUI.DATA_PROVIDER : [waypoint] => fn(waypoint){
							return waypoint.getTime();
						},
						GUI.ON_DATA_CHANGED : [waypoint,refreshGroup] => fn(waypoint,refreshGroup, t){
							waypoint.setTime( t );
							refreshGroup.refresh(); // bug workaround
						},
						GUI.DATA_REFRESH_GROUP : refreshGroup,
					},
					"Position (local):",
					{
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.DATA_PROVIDER : [waypoint] => fn(waypoint){
							var pos = waypoint.getRelTransformationSRT().getTranslation();
							return toJSON( pos.toArray(),false);
						},
						GUI.ON_DATA_CHANGED : [waypoint,refreshGroup] => fn(waypoint,refreshGroup, t){
							var pos = new Geometry.Vec3( parseJSON(t) );
							waypoint.setRelTransformation( waypoint.getRelTransformationSRT().setTranslation(pos));
							refreshGroup.refresh(); // bug workaround
						},
						GUI.DATA_REFRESH_GROUP : refreshGroup,
					},
					{
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "Reset rotation",
						GUI.ON_CLICK : [waypoint] => fn(waypoint){
	            waypoint.setRelTransformation( waypoint.getRelTransformationSRT().resetRotation());
						}
					},
					{
						GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
						GUI.LABEL : "Delete",
						GUI.ON_CLICK : [waypoint,refreshGroup] => fn(waypoint,refreshGroup){
	            MinSG.destroy(waypoint);
							refreshGroup.refresh();
						},
						GUI.DATA_REFRESH_GROUP : refreshGroup,
					}
				];
				return entries;
			}
		};
	}
	entries +='----';
	entries += {
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "New Waypoint",
		GUI.MENU : [node] => this->fn(node){			
			var time = new Std.DataWrapper(node.getWaypoints().back().getTime()+1);
			var pos = new Std.DataWrapper("");
			return [
				"Time:",
				{
					GUI.TYPE : GUI.TYPE_NUMBER,
					GUI.DATA_WRAPPER : time,
				},
				/*"Position:",
				{
					GUI.TYPE : GUI.TYPE_TEXT,
					GUI.DATA_WRAPPER : pos,
				},*/
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Create",
					GUI.ON_CLICK : [node,time,pos] => this->fn(node,time,pos){
						var p = parseJSON(pos());
						if(p ---|> Array) {
							p = (new Geometry.SRT).setTranslation(new Geometry.Vec3( p ));
						} else {
							p = node.getPosition(time()); 
						}
						node.createWaypoint(p, time());
						gui.closeAllMenus();
						NodeEditor.selectNode(node);
					}
				},
			];
		},
	};
	entries += {
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "Recalculate Times",
		GUI.MENU : [node] => this->fn(node){
			var time = new Std.DataWrapper(node.getWaypoints().back().getTime());
			var byDist = Std.DataWrapper.createFromEntry(PADrend.configCache,'Waypoints.byDistance',false);
			var incDir = Std.DataWrapper.createFromEntry(PADrend.configCache,'Waypoints.includeDir',true);
			return [
				"Max. Time:",
				{
					GUI.TYPE : GUI.TYPE_NUMBER,
					GUI.DATA_WRAPPER : time,
				},
				{
					GUI.TYPE : GUI.TYPE_BOOL,
					GUI.LABEL : "By Distance",
					GUI.DATA_WRAPPER : byDist,
				},
				{
					GUI.TYPE : GUI.TYPE_BOOL,
					GUI.LABEL : "Include Direction",
					GUI.DATA_WRAPPER : incDir,
				},
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Update",
					GUI.ON_CLICK : [node,time,byDist,incDir] => this->fn(node,time,byDist,incDir){
						PathManagement.setTimecodesByDistance(node, 1, incDir());
						if(!byDist()) {
							var last = node.getWaypoints().back().getTime();
							PathManagement.setTimecodesByDistance(node, last/time(), incDir());
						}
						gui.closeAllMenus();
						NodeEditor.selectNode(node);
					}
				},
			];

		},
	};
	
	var loopingWrapper = DataWrapper.createFromFunctions(
	node->fn(){
		return this.isLooping();
	},
	node->fn(d){
		return this.setLooping(d).isLooping(); 
	}
);
	entries += {
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "looping",
		GUI.DATA_WRAPPER : loopingWrapper,
	};

	entries +='----';
	return entries;


};

return Tool;
//----------------------------------------------------------------------------
