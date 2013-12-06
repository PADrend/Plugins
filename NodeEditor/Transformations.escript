/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 David Maicher
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Transformations] NodeEditor/Transformations.escript
 **
 ** Module for the NodeEditor Plugin: Move and scale the current node
 **
 ** 2010-03-19 Claudius
 **
 ** \todo  IMPORTANT: When removing the old panel,replace all dependecies on 'currentNode' by actual node bindings!
 **/

declareNamespace($NodeEditor);

//! ---|> Plugin
NodeEditor.TransformationsTabPlugin := new Plugin({
		Plugin.NAME : 'NodeEditor/TransformationsTabPlugin',
		Plugin.DESCRIPTION : 'Add a tab to the NodeEditor to transform nodes.',
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['NodeEditor/GUI'],
		Plugin.EXTENSION_POINTS : [	]
});

var plugin = NodeEditor.TransformationsTabPlugin;

// some shortcuts
plugin.getSelectedNode := fn(){return NodeEditor.getSelectedNode();};
plugin.getSelectedNodes := fn(){return NodeEditor.getSelectedNodes();};

//! ---|> Plugin
plugin.init=fn(){

    this.backupCamera:=void;
    this.backupSRT:=void;
    this.currentNode:=void;

	registerExtension('NodeEditor_OnNodesSelected',this->fn(nodes) {
		this.stopMoving();
	});
	// ---------------------------------------------------------------------------------

	NodeEditor.addConfigTreeEntryProvider(MinSG.Node,fn( node,entry ){
		var b = gui.create({
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.ICON : "#TransformationSmall",
			GUI.FLAGS : GUI.FLAT_BUTTON,
			GUI.ICON_COLOR : node.hasMatrix() ? GUI.BLACK : new Util.Color4ub(128,128,128,128),
			GUI.WIDTH : 15,
			GUI.TOOLTIP : "Transformations",
			GUI.ON_CLICK : (fn(entry){
				entry.configure(new NodeEditor.Wrappers.NodeTransformationsWrapper(entry.getObject()));

			}).bindLastParams(entry)
		});
		entry.addOption(b);
	});


	NodeEditor.Wrappers.NodeTransformationsWrapper := new Type();
	var NodeTransformationsWrapper = NodeEditor.Wrappers.NodeTransformationsWrapper;

	//! (ctor)
	NodeTransformationsWrapper._constructor ::= fn(MinSG.Node node){	this._node := node;	};
	NodeTransformationsWrapper.getNode ::= fn(){	return _node;	};

	NodeEditor.getIcon += [NodeTransformationsWrapper,fn(nodeConfigurator){
		return {
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.ICON : "#NodesSmall",
			GUI.ICON_COLOR : (nodeConfigurator.getNode().countChildren()>0) ? NodeEditor.NODE_COLOR : NodeEditor.NODE_COLOR_PASSIVE
		};
	}];

	NodeEditor.registerConfigPanelProvider(NodeTransformationsWrapper,fn( transformationWrapper,panel ){
		var node = transformationWrapper.getNode();

		// this refreshGroup is updated every frame
		var displayRefreshGroup = new GUI.RefreshGroup();
		// this refreshGroup is only updated if the panel is not selected.
		// (automatic updates on external changes but still allowing editing with the text inputs)
		var manipulationRefreshGroup = new GUI.RefreshGroup();

		panel += "Transformations for node ["+NodeEditor.getString(node)+"]";
		panel++;
		panel += '----';
		panel++;
		panel += "*Information*";
		panel++;

		registerExtension('PADrend_AfterRendering', (fn(d,displayRefreshGroup,manipulationRefreshGroup,panel){
			if(!gui.isCurrentlyEnabled(panel))
				return Extension.REMOVE_EXTENSION;
			if(!panel.isSelected())
				manipulationRefreshGroup.refresh();
			displayRefreshGroup.refresh();
		}).bindLastParams(displayRefreshGroup,manipulationRefreshGroup,panel));
//
		panel++;
		panel += "SRT";
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.SIZE : [GUI.WIDTH_ABS, -30,0],
			GUI.DATA_PROVIDER : (fn(node){
				return node.hasSRT() ? node.getSRT().toString() : "The node has no SRT.";
			}).bindLastParams(node),
			GUI.DATA_REFRESH_GROUP : displayRefreshGroup,
			GUI.FLAGS : GUI.LOCKED,
			GUI.TOOLTIP : "The node's SRT (displayed only)"
		};
		panel++;
		panel += "Matrix";
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.SIZE : [GUI.WIDTH_ABS, -30,0],
			GUI.DATA_PROVIDER : (fn(node){
				return node.hasMatrix() ? node.getMatrix().toString() : "The node has no matrix.";
			}).bindLastParams(node),
			GUI.DATA_REFRESH_GROUP : displayRefreshGroup,
			GUI.FLAGS : GUI.LOCKED,
			GUI.TOOLTIP : "The node's local transformation matrix (displayed only)"
		};
		panel++;
		panel += "Local bounding box";
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.SIZE : [GUI.WIDTH_ABS, -30,0],
			GUI.DATA_PROVIDER : (fn(node){
				return node.getBB().toString();
			}).bindLastParams(node),
			GUI.DATA_REFRESH_GROUP : displayRefreshGroup,
			GUI.FLAGS : GUI.LOCKED,
			GUI.TOOLTIP : "The node's axis-aligned bounding box in local coordinates. (displayed only)"
		};
		panel++;
		panel += "Absolute bounding box";
		panel++;
		panel += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.SIZE : [GUI.WIDTH_ABS, -30,0],
			GUI.DATA_PROVIDER : (fn(node){
				return node.getWorldBB().toString();
			}).bindLastParams(node),
			GUI.DATA_REFRESH_GROUP : displayRefreshGroup,
			GUI.FLAGS : GUI.LOCKED,
			GUI.TOOLTIP : "The node's axis-aligned bounding box in global coordinates. (displayed only)"
		};
		panel++;
		// ------------------------------------------------------------------------------

		panel += '----';
		panel++;
		panel += "*Manipulation*";
//		panel += {
//			GUI.TYPE : GUI.TYPE_BUTTON,
//			GUI.ICON : "#RefreshSmall",
//			GUI.ICON_COLOR : GUI.BLACK,
//			GUI.ON_CLICK : manipulationRefreshGroup->manipulationRefreshGroup.refresh,
//			GUI.TOOLTIP : "Refresh the input components below.",
//			GUI.FLAGS : GUI.FLAT_BUTTON
//		};
		panel++;

		panel += {
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Move Node",
			GUI.TOOLTIP		:	"Move selected node with the cameraMover.",
			GUI.ON_CLICK	:	(fn(node) {
				if(NodeEditor.TransformationsTabPlugin.currentNode) {
					NodeEditor.TransformationsTabPlugin.stopMoving();
					setSwitch(false);
				} else {
					NodeEditor.TransformationsTabPlugin.startMoving(node);
					setSwitch(true);
				}
			}).bindLastParams(node)
		};
		panel += {
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Undo",
			GUI.ON_CLICK	:	fn() {
				NodeEditor.TransformationsTabPlugin.stopMoving();
				PADrend.undoCommand();
			}
		};
		panel += {
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Redo",
			GUI.ON_CLICK	:	fn() {
				NodeEditor.TransformationsTabPlugin.stopMoving();
				PADrend.redoCommand();
			}
		};
		panel++;


		panel += {
			GUI.TYPE			:	GUI.TYPE_TEXT,
			GUI.LABEL			:	"Scale",
			GUI.OPTIONS			:	[1.0, 0.1, 0.01],
			GUI.SIZE 			: 	[GUI.WIDTH_ABS, -30,0],
			GUI.DATA_REFRESH_GROUP : manipulationRefreshGroup,
			GUI.DATA_PROVIDER : (fn(node){
				return node.hasSRT() ? node.getSRT().getScale() : (node.getMatrix().transformDirection(1,0,0)).length();
			}).bindLastParams(node),
			GUI.ON_DATA_CHANGED :	NodeEditor.TransformationsTabPlugin -> (fn(data,node) {
				applySRT(node,node.getSRT().setScale(0 + data));
			}).bindLastParams(node)
		};
		panel++;

		panel += {
			GUI.TYPE			:	GUI.TYPE_TEXT,
			GUI.LABEL			:	"Translation",
			GUI.OPTIONS			:	["0, 0, 0"],
			GUI.SIZE 			: 	[GUI.WIDTH_ABS, -30,0],
			GUI.DATA_REFRESH_GROUP : manipulationRefreshGroup,
			GUI.DATA_PROVIDER : (fn(node){
				var p = node.getMatrix().transformPosition(0,0,0);
				return ""+p.getX()+","+p.getY()+","+p.getZ();
			}).bindLastParams(node),
			GUI.ON_DATA_CHANGED : NodeEditor.TransformationsTabPlugin -> (fn(data,node) {
				applySRT(node , node.getSRT().setTranslation(new Geometry.Vec3(parseJSON("["+data+"]"))));
			}).bindLastParams(node)
		};
		panel++;

		panel += {
			GUI.TYPE 			: 	GUI.TYPE_TEXT,
			GUI.LABEL			:	"Rotation",
			GUI.TOOLTIP			:	"Array of two arrays: [[dirX, dirY, dirZ], [upX, upY, upZ]]",
			GUI.OPTIONS			: [
				"[[ 0,  0,  1], [ 0,  1,  0]]",
				"[[ 1,  0,  0], [ 0,  1,  0]]",
				"[[ 0,  0, -1], [ 0,  1,  0]]",
				"[[-1,  0,  0], [ 0,  1,  0]]",
				"[[ 0,  1,  0], [ 0,  0, -1]]",
				"[[ 0, -1,  0], [ 0,  0,  1]]"
			],
			GUI.SIZE 			: [GUI.WIDTH_ABS, -30,0],
			GUI.DATA_REFRESH_GROUP : manipulationRefreshGroup,
			GUI.DATA_PROVIDER : (fn(node){
				var dir = node.hasSRT() ? node.getSRT().getDirVector() : node.getMatrix().transformDirection(0,0,1);
				var up = node.hasSRT() ? node.getSRT().getUpVector() : node.getMatrix().transformDirection(0,1,0);
				return toJSON([[dir.getX(), dir.getY(), dir.getZ()], [up.getX(), up.getY(), up.getZ()]], false);
			}).bindLastParams(node),
			GUI.ON_DATA_CHANGED	: NodeEditor.TransformationsTabPlugin -> (fn(data,node) {
				var d = parseJSON(data);
				var currentSRT = node.getSRT();
				var srt = new Geometry.SRT(currentSRT.getTranslation(),
										   new Geometry.Vec3(d[0][0], d[0][1], d[0][2]),
										   new Geometry.Vec3(d[1][0], d[1][1], d[1][2]),
										   currentSRT.getScale());
				applySRT(node , srt);
			}).bindLastParams(node)
		};
		panel++;
		panel += " ";
		panel++;
		panel += "Hint: Graphical transformation tools are available by [right mouse button] -> 'Transformations >>'";
	});

	// ---------------------------------------------------------------------------------

	return true;
};



plugin.applySRT := fn(MinSG.Node node,Geometry.SRT newSRT, oldSRT = void){
	if(!oldSRT){
		oldSRT = node.getSRT();
	}
	var cmd = new Command({
		Command.DESCRIPTION : "Transformation",
		Command.EXECUTE : fn(){ // execute
			if( this.newSRT && this.node)
				node.setSRT(newSRT);
		},
		Command.UNDO : fn(){ // undo
			if( this.oldSRT && this.node)
				node.setSRT(oldSRT);
			out("Undo\n");
		},
		Command.FLAGS : Command.FLAG_EXECUTE_LOCALLY|Command.FLAG_SEND_TO_SLAVES,
		$node : node,
		$oldSRT : oldSRT,
		$newSRT : newSRT.clone()
	});
	PADrend.executeCommand(cmd);
};


plugin.stopMoving:=fn(){
	if(!currentNode)
		return;
	out("Stop moving...\n");

	applySRT(currentNode,currentNode.getSRT(),backupSRT);
	backupSRT=void;
	currentNode = void;

	PADrend.getCameraMover().setDolly(backupCamera);
	backupCamera=void;
};

plugin.startMoving:=fn(MinSG.Node node){
	stopMoving();
	currentNode = node;

	out("Start moving...\n");

	backupCamera = PADrend.getCameraMover().getDolly();
	backupSRT = node.getSRT();

	PADrend.getCameraMover().setDolly(node);
};

return plugin;
// ------------------------------------------------------------------------------
