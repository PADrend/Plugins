/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
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
declareNamespace($SceneEditor,$Selection);

//! ---|> Plugin
var plugin = new Plugin({
    Plugin.NAME : 'SceneEditor/Selection',
    Plugin.DESCRIPTION : 'Select Node(s) with different methods',
    Plugin.AUTHORS : "Mouns, Claudius",
    Plugin.OWNER : "All",
    Plugin.LICENSE : "Mozilla Public License, v. 2.0",
    Plugin.REQUIRES : ['NodeEditor','PADrend'],
    Plugin.EXTENSION_POINTS : []
});


// Variables
plugin.eventHandler :=void;
plugin.selectionWindow :=false;
plugin.selectionStart :=false;
plugin.window :=false;
plugin.crossing :=false;
plugin.path := __DIR__+"/../../../plugins/PADrend/resources/MouseCursors";
plugin.cursor_plus := Util.loadBitmap(__DIR__+"/../../../plugins/PADrend/resources/MouseCursors/3dSceneCursor_plus.png");
plugin.cursor_minus := Util.loadBitmap(__DIR__+"/../../../plugins/PADrend/resources/MouseCursors/3dSceneCursor_minus.png");
//plugin.cursor := gui.getStyleManager().getMouseCursor();

plugin.init @(override) := fn(){
    this.eventHandler = this->ex_UIEvent;
    registerExtension('PADrend_OnSceneSelected',this->NodeEditor.selectNode);
   	registerExtension('PADrend_Init',this->fn(){
		createUIToolEntries();
	});
	PADrend.registerUITool('SceneEditor_Window')
            .registerActivationListener(this->fn(){
                registerExtension('PADrend_UIEvent',eventHandler);
                this.window = true;
            })
            .registerDeactivationListener(this->fn(){
                removeExtension('PADrend_UIEvent',eventHandler);
                this.window = false;
            });
	 PADrend.registerUITool('SceneEditor_Crossing')
            .registerActivationListener(this->fn(){
                registerExtension('PADrend_UIEvent',eventHandler);
                this.crossing = true;
            })
            .registerDeactivationListener(this->fn(){
                removeExtension('PADrend_UIEvent',eventHandler);
                this.crossing = false;
            });

	return true;
};

//! Internal
/**
*To create and register the UITool entries.
*/
plugin.createUIToolEntries :=fn(){
    gui.registerComponentProvider('PADrend_ToolsToolbar.sceneEditor_Selection',{
        GUI.TYPE : GUI.TYPE_SELECT,
		GUI.WIDTH : 39,
		GUI.HEIGHT : 24,
		GUI.TOOLTIP : "With this tool node(s) can be selected / unselected through three different methods."+
		"\n-(Window) The node(s) being select / unselect should be completely in the selection window."+
		"\n-(Crossing) Just a part of the the node(s) being select / unselect should be in the selection window."+
		"\n- A node can be selected / unselected per pick the node."+
		"\n- New node(s) can be added to the selected node(s) through pressing 'Shift' simultaneously with any other"+
		"\n  selection methods were described above."+
		"\n- Node(s) can be subtracted from the selected node(s) through pressing 'Alt' simultaneously with any other"+
		"\n  selection methods were described above."+
		"\n- To unselect all selected nodes, click the mouse-right-button and click 'Unselect all'.",
		GUI.OPTIONS : [
            ['SceneEditor_Window',{GUI.TYPE:GUI.TYPE_ICON,GUI.ICON : '#SelectWindowInclude',GUI.ICON_COLOR:GUI.WHITE},{
                GUI.TYPE : GUI.TYPE_BUTTON,
                GUI.ICON : '#SelectWindowInclude',
                GUI.WIDTH : 24,
                GUI.TOOLTIP : "The node(s) being select / unselect should be completely in the selection window.",
                GUI.ON_CLICK : fn(){PADrend.setActiveUITool('SceneEditor_Window');},
                GUI.ON_INIT : fn(...){
					var swithFun = fn(b){
						if(isDestroyed())
							return $REMOVE;
						setSwitch(b);
					};
					PADrend.accessUIToolConfigurator('SceneEditor_Window')
							.registerActivationListener(this->(swithFun.bindFirstParams(true)))
							.registerDeactivationListener(this->(swithFun.bindFirstParams(false)));
				},

            }],
            ['SceneEditor_Crossing',{GUI.TYPE:GUI.TYPE_ICON,GUI.ICON : '#SelectWindowCrossing',GUI.ICON_COLOR:GUI.WHITE},{
                GUI.TYPE : GUI.TYPE_BUTTON,
                GUI.LABEL : "Crossing",
                GUI.ICON : '#SelectWindowCrossing',
                GUI.WIDTH : 24,
                GUI.TOOLTIP : "Just a part of the the node(s) being select / unselect should be in the selection window.",
                GUI.ON_CLICK : fn(){PADrend.setActiveUITool('SceneEditor_Crossing');	},
                GUI.ON_INIT : fn(...){
					var swithFun = fn(b){
						if(isDestroyed())
							return $REMOVE;
						setSwitch(b);
					};
					PADrend.accessUIToolConfigurator('SceneEditor_Crossing')
							.registerActivationListener(this->(swithFun.bindFirstParams(true)))
							.registerDeactivationListener(this->(swithFun.bindFirstParams(false)));
				},

            }],
		],

        GUI.ON_DATA_CHANGED : fn(tool){
            PADrend.setActiveUITool(tool);
        }
    });

    gui.registerComponentProvider('PADrend_SceneToolMenu.01_sceneEditor_Selection',fn(){
		return NodeEditor.getSelectedNodes().empty() ? [] : [{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Unselect all",
			GUI.TOOLTIP : "Unselect all selected Nodes",
			GUI.ON_CLICK : fn(){NodeEditor.selectNode(void);}
		}];
    });
};

//! [ext:SDLEvent]
plugin.ex_UIEvent := fn(evt){
    if(	evt.type==Util.UI.EVENT_MOUSE_BUTTON && evt.button == Util.UI.MOUSE_BUTTON_LEFT){
        if(evt.pressed){
            this.selectionStart = new Geometry.Vec2(evt.x,evt.y);
            var node = (new MinSG.RendRayCaster).queryNodeFromScreen(frameContext,PADrend.getRootNode(),new Geometry.Vec2(evt.x,evt.y),true);
            if(node){
                if(PADrend.getEventContext().isShiftPressed()){
                    NodeEditor.addSelectedNode(node);
                }
                else if(PADrend.getEventContext().isAltPressed())
                         NodeEditor.unselectNode(node);
                else{
                    NodeEditor.selectNode(node);
                }
            }
        }
        else if(!evt.pressed ){
            if(this.selectionWindow){
                var nodes = this.collectNodesInSelectionWindow((this.window? false:true));
                if(PADrend.getEventContext().isShiftPressed()){
                    NodeEditor.addSelectedNodes(nodes);
                }
                else if(PADrend.getEventContext().isAltPressed())
                        NodeEditor.unselectNodes(nodes);
                else{
                    NodeEditor.selectNodes(nodes);
                }
            }
            return true;
        }

        return true;
    }
    if(evt.type==Util.UI.EVENT_MOUSE_MOTION){
        if(evt.buttonMask ==Util.UI.MASK_MOUSE_BUTTON_LEFT && this.selectionStart){
            // drag selection Box
            var posNew = new Geometry.Vec2(evt.x,evt.y);
            this.selectionWindow = new Geometry.Rect(this.selectionStart.getX(),this.selectionStart.getY(),0.0,2.0);
            this.selectionWindow.include(posNew.getX(), posNew.getY());
            Rendering.enable2DMode(GLOBALS.renderingContext);
            this.drawIt();
            Rendering.disable2DMode(GLOBALS.renderingContext);
            return true;
        }

    }
    // To do
     if(evt.type==Util.UI.EVENT_KEYBOARD && evt.key==Util.UI.KEY_SHIFTL){
        if(evt.pressed)
            gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, this.cursor_plus, 0, 0);
        if(!evt.pressed)
           gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, Util.loadBitmap(this.path+"/3dSceneCursor.png"), 0, 0);
//            gui.getStyleManager().setMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT,this.cursor);
        return true;
    }
    if(evt.type==Util.UI.EVENT_KEYBOARD && evt.key==Util.UI.KEY_ALTL){
        if(evt.pressed)
            gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, this.cursor_minus, 0, 0);
        if(!evt.pressed)
           gui.registerMouseCursor(GUI.PROPERTY_MOUSECURSOR_DEFAULT, Util.loadBitmap(this.path+"/3dSceneCursor.png"), 0, 0);
        return true;
    }

	return false;
};

//! (Internal)
plugin.drawIt :=fn(){
    if(this.selectionWindow){
        var blending=new Rendering.BlendingParameters();
		blending.enable();
		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA, Rendering.BlendFunc.ONE);
		GLOBALS.renderingContext.pushAndSetBlending(blending);
		GLOBALS.renderingContext.pushAndSetLighting(false);
		GLOBALS.renderingContext.applyChanges();
        Rendering.drawRect(GLOBALS.renderingContext, this.selectionWindow, new Util.Color4f(1,1,1,0.2));
		GLOBALS.renderingContext.popLighting();
		GLOBALS.renderingContext.popBlending();
		Rendering.drawWireframeRect(GLOBALS.renderingContext, this.selectionWindow, new Util.Color4f(0,0,0,1));

    }

};

//! (Internal)
/**
*To collect all Geonodes, which they are in the selection frame.
*@param mode: If the selection with window or wit crossing (see the tool description)
*@return set of Geonodes
*/
plugin.collectNodesInSelectionWindow :=fn(mode){

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
    var center = this.selectionWindow.getCenter();
    var w = this.selectionWindow.getWidth();
    var h = this.selectionWindow.getHeight();

    //left
    var p1 = center.getX()-w/2;
    //right
    var p2 = center.getX()+w/2;
    //butten
    var p3 = (GLOBALS.renderingContext.getWindowHeight()-center.getY())-h/2;
    //top
    var p4 = (GLOBALS.renderingContext.getWindowHeight()-center.getY())+h/2;

    var cam = frameContext.getCamera();
    var frustum = cam.getFrustum();
    var camDummy = cam.clone();
    var angleBackup = camDummy.getAngles();
	var viewportBackup = camDummy.getViewport();
	var angles = angleBackup.clone();

    angles[0]=getZoomedAngle(p1,angleBackup[0],angleBackup[1],viewportBackup.getWidth() );
	angles[1]=getZoomedAngle(p2,angleBackup[0],angleBackup[1],viewportBackup.getWidth() );
	angles[2]=getZoomedAngle(p3,angleBackup[2],angleBackup[3],viewportBackup.getHeight() );
	angles[3]=getZoomedAngle(p4,angleBackup[2],angleBackup[3],viewportBackup.getHeight() );

	camDummy.setAngles(angles);
    var frsutumDummy = camDummy.getFrustum().setPosition(frustum.getPos(), frustum.getDir(), frustum.getUp());
    var nodes = MinSG.collectGeoNodesInFrustum(PADrend.getRootNode(), frsutumDummy, mode);
    this.selectionStart = false;
    this.selectionWindow = false;

	return nodes;

};

//! (Internal)
plugin.getZoomedAngle := fn( pos, origAngle1 , origAngle2, resolution){
    var p1 = origAngle1.degToRad().tan();
    var resX = origAngle2.degToRad().tan() - p1;
    return (p1+ resX*(pos/resolution) ).atan().radToDeg();
};

return plugin;

