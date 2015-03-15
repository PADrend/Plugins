/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:SceneEditor/Selection]
 **
 ** Graphical tools to select Node(s) with different methods.
 **/

var plugin = new Plugin({
	Plugin.NAME : 'SceneEditor/Selection',
	Plugin.DESCRIPTION : 'Select Node(s) with different methods',
	Plugin.AUTHORS : "Mouns, Claudius",
	Plugin.OWNER : "All",
	Plugin.LICENSE : "Mozilla Public License, v. 2.0",
	Plugin.REQUIRES : ['NodeEditor','PADrend','PADrend/Picking'],
	Plugin.EXTENSION_POINTS : []
});


static TOOL_ID = 'SceneEditor_Selection';

// Variables
static selectionRect;
static selectionStartingPos;
static mode_selectOnIntersection = new Std.DataWrapper(true); 
static includeSemObj  = DataWrapper.createFromValue(false);

plugin.init @(override) := fn(){
	module.on('PADrend/gui',registerGUI);

	static revoce = new Std.MultiProcedure;
	PADrend.registerUITool(TOOL_ID)
			.registerActivationListener(fn(){
				revoce();
				revoce += Util.registerExtensionRevocably('PADrend_UIEvent', handleEvent);
			})
			.registerDeactivationListener(fn(){
				revoce();
				selectionStartingPos = void; // to disable a pending selection process
				selectionRect = void;
			});

	return true;
};

static registerGUI = fn(gui){
	
	static icons = [ '#SelectWindowCrossing','#SelectWindowInclude' ];

	static activeIcon = new Std.DataWrapper;
	mode_selectOnIntersection.onDataChanged += [activeIcon] => fn(activeIcon,b){
		activeIcon([{
			GUI.TYPE:GUI.TYPE_ICON,
			GUI.ICON : b ? icons[0] : icons[1],
			GUI.ICON_COLOR : false // explicitly use inherited color property
		}]);
	};
	mode_selectOnIntersection.forceRefresh();
	
	gui.register('PADrend_ToolsToolbar.20_selectionTool',[gui]=>fn(gui){
		return {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.PROPERTIES : module('PADrend/GUI/Style').TOOLBAR_BUTTON_PROPERTIES,
			GUI.HOVER_PROPERTIES : module('PADrend/GUI/Style').TOOLBAR_BUTTON_HOVER_PROPERTIES,
			GUI.LABEL : "",
			GUI.CONTENTS : activeIcon,
			GUI.ICON : mode_selectOnIntersection() ? icons[0] : icons[1], // initially, a valid icon is required to properly init the color properties
			GUI.ON_CLICK : fn(){	PADrend.setActiveUITool(TOOL_ID);	},
			GUI.ON_INIT : fn(...){
				var switchFun = [this]=>fn(button,b){
					if(button.isDestroyed())
						return $REMOVE;
					foreach(module('PADrend/GUI/Style').TOOLBAR_ACTIVE_BUTTON_PROPERTIES as var p)
						b ? button.addProperty(p) : button.removeProperty(p);
				};
				PADrend.accessUIToolConfigurator(TOOL_ID)
						.registerActivationListener( [true]=>switchFun )
						.registerDeactivationListener( [false]=>switchFun );
			},
			GUI.TOOLTIP :	"Drag mouse to select nodes in a rectangle.\n"
							"[L-click] select a single node.\n"
							"[Shift] add to selection modifier\n"
							"[Alt] remove from selection modifier\n"
							"[R-Click] for further options"
		};
	});

	gui.register('PADrend_UIToolConfig:'+TOOL_ID,[
		"*Selection Tool*",
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "incl. sem. obj.",
			GUI.DATA_WRAPPER : includeSemObj
		},
		{
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.LAYOUT : GUI.LAYOUT_FLOW,
			GUI.CONTENTS : [
				"Mode:",
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.ICON : '#SelectWindowCrossing',
					GUI.ON_CLICK : [true]=>mode_selectOnIntersection,
					GUI.TOOLTIP : "Also select nodes on the border of the selection window."
				},
				{
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.ICON : '#SelectWindowInclude',
					GUI.ON_CLICK : [false]=>mode_selectOnIntersection,
					GUI.TOOLTIP : "Only select nodes inside selection window."
				},
			],
			GUI.HEIGHT : 24
		}
	]);
	
};

static revoceDrawCallback = new Std.MultiProcedure;

static handleEvent = fn(evt){
	if(evt.type==Util.UI.EVENT_MOUSE_BUTTON && evt.button == Util.UI.MOUSE_BUTTON_LEFT){
		if(evt.pressed){
			revoceDrawCallback();
			revoceDrawCallback += Util.registerExtensionRevocably('PADrend_AfterRendering',fn(...){
				if(selectionRect){
					Rendering.enable2DMode(renderingContext);
					renderingContext.pushAndSetLighting(false);
					renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.ALWAYS);
					
					var blending = new Rendering.BlendingParameters;
					blending.enable();
					blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA, Rendering.BlendFunc.ONE);
					renderingContext.pushAndSetBlending(blending);
					renderingContext.applyChanges();
					Rendering.drawRect(renderingContext, selectionRect, new Util.Color4f(1,1,1,0.2));
					renderingContext.popBlending();
					Rendering.drawWireframeRect(renderingContext, selectionRect, new Util.Color4f(0,0,0,1));
		
					renderingContext.popDepthBuffer();
					renderingContext.popLighting();
					Rendering.disable2DMode(renderingContext);
				}
				if(!selectionStartingPos) // ... tool has been disabled while dragging.
					revoceDrawCallback();
			});
			selectionStartingPos = new Geometry.Vec2(evt.x,evt.y);
			var node = Util.requirePlugin('PADrend/Picking').pickNode( [evt.x,evt.y] );
			if(node){
				if(includeSemObj()){
					var semObj = module('LibMinSGExt/SemanticObject').getContainingSemanticObject(node);
					if(semObj)
						node = semObj;
				}
				if(PADrend.getEventContext().isShiftPressed())
					NodeEditor.addSelectedNode(node);
				else if(PADrend.getEventContext().isAltPressed())
					NodeEditor.unselectNode(node);
				else
					NodeEditor.selectNode(node);
			}
			return true;
		}else{
			if(selectionRect){
				revoceDrawCallback();
				var nodes = collectNodesInSelectionWindow(PADrend.getRootNode(),selectionRect, mode_selectOnIntersection());
				selectionStartingPos = false;
				selectionRect = false;

				var nodesWithSem = [];
				if(includeSemObj()){
					foreach(nodes as var node){
						var semObj = module('LibMinSGExt/SemanticObject').getContainingSemanticObject(node);
						if(semObj)
							nodesWithSem += semObj;
						else
							nodesWithSem += node;
					}
					nodes = nodesWithSem;
				}

				if(PADrend.getEventContext().isShiftPressed())
					NodeEditor.addSelectedNodes(nodes);
				else if(PADrend.getEventContext().isAltPressed())
					NodeEditor.unselectNodes(nodes);
				else
					NodeEditor.selectNodes(nodes);
			}
		}

		return true;
	}else if(evt.type==Util.UI.EVENT_MOUSE_MOTION){
		if(evt.buttonMask ==Util.UI.MASK_MOUSE_BUTTON_LEFT && selectionStartingPos){
			// drag selection Box
			var posNew = new Geometry.Vec2(evt.x,evt.y);
			selectionRect = new Geometry.Rect(selectionStartingPos.x(),selectionStartingPos.y(),0.0,2.0);
			selectionRect.include(posNew.x(), posNew.y());
			return true;
		}

	}else if(evt.type==Util.UI.EVENT_KEYBOARD){
		if(evt.key==Util.UI.KEY_SHIFTL){
			if(evt.pressed){
				@(once) static cursor = Util.loadBitmap(module('PADrend/GUI/Style').resourceFolder+"/MouseCursors/3dSceneCursor_plus.png");
				module('PADrend/gui').registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, cursor, 0, 0);
			}
			else
				module('PADrend/gui').registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, module('PADrend/GUI/Style').CURSOR_DEFAULT, 0, 0);
			return true;
		}else if(evt.key==Util.UI.KEY_ALTL){
			if(evt.pressed){
				@(once) static cursor = Util.loadBitmap(module('PADrend/GUI/Style').resourceFolder+"/MouseCursors/3dSceneCursor_minus.png");
				module('PADrend/gui').registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, cursor, 0, 0);
			}
			else
				module('PADrend/gui').registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, module('PADrend/GUI/Style').CURSOR_DEFAULT, 0, 0);
			return true;
		}
	}
	return false;
};

/**
*To collect all Geonodes, which they are in the selection frame.
*/
static collectNodesInSelectionWindow =fn(MinSG.Node root,Geometry.Rect screenRect,Bool selectOnIntersection){
/**
		   p4
	|------*-------|
	|              |
	|              |
  p1*              * p2
	|              |
	|              |
	|------*-------|
		   p3
*/
	var center = screenRect.getCenter();
	var w = screenRect.getWidth();
	var h = screenRect.getHeight();
	if(w==0||h==0)
		return [];

	//left
	var p1 = center.getX()-w/2;
	//right
	var p2 = center.getX()+w/2;
	//butten
	var p3 = (renderingContext.getWindowHeight()-center.getY())-h/2;
	//top
	var p4 = (renderingContext.getWindowHeight()-center.getY())+h/2;

	var cam = frameContext.getCamera();
	var frustum = cam.getFrustum();
	var camDummy = cam.clone();
	var angleBackup = camDummy.getAngles();
	var viewportBackup = camDummy.getViewport();

	camDummy.setAngles([
		getZoomedAngle(p1,angleBackup[0],angleBackup[1],viewportBackup.getWidth() ),
		getZoomedAngle(p2,angleBackup[0],angleBackup[1],viewportBackup.getWidth() ),
		getZoomedAngle(p3,angleBackup[2],angleBackup[3],viewportBackup.getHeight() ),
		getZoomedAngle(p4,angleBackup[2],angleBackup[3],viewportBackup.getHeight() )
	]);
	var frustumDummy = camDummy.getFrustum().setPosition(frustum.getPos(), frustum.getDir(), frustum.getUp());
	return MinSG.collectGeoNodesInFrustum(root, frustumDummy, selectOnIntersection);
};

static getZoomedAngle = fn( pos, origAngle1 , origAngle2, resolution){
	var p1 = origAngle1.degToRad().tan();
	var resX = origAngle2.degToRad().tan() - p1;
	return (p1+ resX*(pos/resolution) ).atan().radToDeg();
};

return plugin;
