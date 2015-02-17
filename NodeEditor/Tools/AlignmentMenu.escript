/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


gui.registerComponentProvider('NodeEditor_NodeToolsMenu.alignment',fn(Array nodes){
	return nodes.empty() ? [] : [
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Alignment",
			GUI.MENU : 'NodeEditor_AlignmentMenu',
			GUI.MENU_WIDTH : 150,
			GUI.TOOLTIP: "Align nodes..."
		}
	];
});

/*
	Same origin
	snap origin to plane
	snap center to plane
	same center
	
	
	BoundingBoxCenter
	BoundingBoxLimit 
	Origin
	
	align rotation

*/

static NodeTransformationLogger = {


static T = new Type;

T.initialTransformations @(private,init) := Map;
T.nodes @(private) := Array;

T._constructor ::= fn(Array nodes_){
	this.nodes = nodes_.clone();
	this.init();
};

T.apply ::= fn([Map,void] relTransformations=void){
	@(once) static Command = Std.require('LibUtilExt/Command');
	
	if(!relTransformations){
		relTransformations = new Map;
		foreach( this.nodes as var node)
			relTransformations[node] = node.getRelTransformationSRT();
	}
	
	var cmd = new Command({
		Command.DESCRIPTION : "Transform nodes",
		Command.EXECUTE : [relTransformations]=>fn(relTransformations){
			foreach(relTransformations as var node, var t)
				node.setRelTransformation(t);
		},
		Command.UNDO : [initialTransformations]=>fn(relTransformations){
			foreach(relTransformations as var node, var t){
//				outln(t.getTranslation());
//				outln(node,"..",node.getRelOrigin());
				node.setRelTransformation(t);
//				outln(node,"..",node.getRelOrigin(),"\n");
			}
			outln("Undo...");
		},
		Command.FLAGS : Command.FLAG_EXECUTE_LOCALLY|Command.FLAG_SEND_TO_SLAVES,
	});
	PADrend.executeCommand(cmd);
};

T.init ::= fn(){
	foreach(this.nodes as var node)
		this.initialTransformations[node] = node.getRelTransformationSRT();	
};
//
////! (static)
//T.setWorldTransformations ::= fn(Map nodesToWorldTransformation){
//	var nodes = [];
//	foreach(nodesToWorldTransformation )
//	var logger
//	
//};
T;
};

static ALIGN_ORIGIN = 0;
static ALIGN_BB_CENTER = 1;
static ALIGN_BB_LOWER_CENTER = 2;
static getOffset_OriginToSnap = fn(MinSG.Node node, Number mode){
	switch(mode){
		case ALIGN_BB_CENTER:
			return node.localDirToWorldDir( node.getBoundingBox().getRelPosition(0.5,0.5,0.5) );
		case ALIGN_BB_LOWER_CENTER:
			return node.localDirToWorldDir( node.getBoundingBox().getRelPosition(0.5,0.0,0.5) );
		default:
			return new Geometry.Vec3(0,0,0);
	}
};

// ----------------------------------------------------------
gui.registerComponentProvider('NodeEditor_AlignmentMenu.alignment',fn(){
	@(once) static snapMode = Std.DataWrapper.createFromEntry(PADrend.configCache, "NodeEditor.alignmentMode", ALIGN_ORIGIN);
	return [
		'*Alignment*',
		{
			GUI.TYPE : GUI.TYPE_SELECT,
			GUI.DATA_WRAPPER : snapMode,
			GUI.OPTIONS : [
				[ALIGN_ORIGIN, "Origin", "Origin", "Align the nodes' local origins (0,0,0)"],
				[ALIGN_BB_CENTER, "BB center", "BB center", "Align the centers of the bounding boxes"],
				[ALIGN_BB_LOWER_CENTER, "BB lower center",  "BB lower center",  "Align the lower centers of the bounding boxes"],
			]
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Common position",
			GUI.TOOLTIP : "Move all selected nodes to the position\nof the first selected node.",
			GUI.ON_CLICK:fn(){
				var nodes = NodeEditor.getSelectedNodes().clone();
				if(nodes.count()>1){
					var node = nodes.popFront();
					var logger = new NodeTransformationLogger(nodes);
					var worldSnap = node.getWorldOrigin()+getOffset_OriginToSnap(node,snapMode());
					foreach(nodes as var node){
						node.setWorldOrigin( worldSnap - getOffset_OriginToSnap(node,snapMode()));
					}
					logger.apply();
				}
				PADrend.message("Nodes moved ("+nodes.count()+")");
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Place on line",
			GUI.TOOLTIP : "Move all selected nodes on to the line between \nthe first and last selected nodes.",
			GUI.ON_CLICK:fn(){
				var nodes = NodeEditor.getSelectedNodes().clone();
				if(nodes.count()>2){
					var node1 = nodes.popFront();
					var node2 = nodes.popBack();
					var logger = new NodeTransformationLogger(nodes);
					var pos1 = node1.getWorldOrigin()+getOffset_OriginToSnap(node1,snapMode());
					var pos2 = node2.getWorldOrigin()+getOffset_OriginToSnap(node2,snapMode());
					var line = new Geometry.Line3(pos1, (pos2-pos1).normalize());
					foreach(nodes as var node){
						var offset = getOffset_OriginToSnap(node,snapMode());
						node.setWorldOrigin( line.getClosestPoint( node.getWorldOrigin() + offset ) - offset );
					}
					logger.apply();
					PADrend.message("Nodes moved ("+nodes.count()+")");
				}
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Distribute on line",
			GUI.TOOLTIP : "Move all selected nodes on to the line between \nthe first and last selected nodes.",
			GUI.ON_CLICK:fn(){
				var nodes = NodeEditor.getSelectedNodes().clone();
				if(nodes.count()>2){
					var node1 = nodes.popFront();
					var node2 = nodes.popBack();
					var logger = new NodeTransformationLogger(nodes);
					var pos1 = node1.getWorldOrigin()+getOffset_OriginToSnap(node1,snapMode());
					var pos2 = node2.getWorldOrigin()+getOffset_OriginToSnap(node2,snapMode());
					
					nodes.sort( [pos1]=>fn(p, n1,n2){
						return (n1.getWorldOrigin()+getOffset_OriginToSnap(n1,snapMode())).distance(p) > (n2.getWorldOrigin()+getOffset_OriginToSnap(n2,snapMode())).distance(p);
					});
					
					var l = 1 /  (nodes.count()+1);
					foreach(nodes as var index, var node){
						var l = (index+1) / (nodes.count()+1);
						node.setWorldOrigin( pos1 * l + pos2 * (1-l) + getOffset_OriginToSnap(node,snapMode()) );
					}
					logger.apply();
					PADrend.message("Nodes moved ("+nodes.count()+")");
				}
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Common world rotation",
			GUI.TOOLTIP : "Apply the rotation of the \nfirst selected node to all selected nodes.",
			GUI.ON_CLICK:fn(){
				var nodes = NodeEditor.getSelectedNodes().clone();
				if(nodes.count()>1){
					var node = nodes.popFront();
					var srt = node.getWorldTransformationSRT();
					var worldDir = srt.getDirVector();
					var worldUp = srt.getUpVector();
					var logger = new NodeTransformationLogger(nodes);
					
					foreach(nodes as var node){
						var worldAnchor = node.getWorldOrigin()+getOffset_OriginToSnap(node,snapMode());
						node.setWorldTransformation( node.getWorldTransformationSRT().setRotation(worldDir,worldUp) );
						
						var movedAnchor = node.getWorldOrigin()+getOffset_OriginToSnap(node,snapMode());
						node.moveLocal( node.worldDirToLocalDir(worldAnchor-movedAnchor) );
					}
					logger.apply();
					PADrend.message("Nodes moved ("+nodes.count()+")");
				}
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Common world scaling",
			GUI.TOOLTIP : "Apply the scaling of the \nfirst selected node to all selected nodes.",
			GUI.ON_CLICK:fn(){
				var nodes = NodeEditor.getSelectedNodes().clone();
				if(nodes.count()>1){
					var node = nodes.popFront();
					var srt = node.getWorldTransformationSRT();
					var scaling = srt.getScale();
					var logger = new NodeTransformationLogger(nodes);
					
					foreach(nodes as var node){
						var worldAnchor = node.getWorldOrigin()+getOffset_OriginToSnap(node,snapMode());
						node.setWorldTransformation( node.getWorldTransformationSRT().setScale(scaling) );
						var movedAnchor = node.getWorldOrigin()+getOffset_OriginToSnap(node,snapMode());
						node.moveLocal( node.worldDirToLocalDir(worldAnchor-movedAnchor) );
					}
					logger.apply();
					PADrend.message("Nodes scaled ("+nodes.count()+")");
				}
			}
		},
	];
});
