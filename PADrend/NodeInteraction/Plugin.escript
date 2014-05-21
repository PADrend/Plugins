/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/NodeInteraction/Plugin.escript
 **/
 
/** Example:
 * @code
		// make a GeometryNode draggable
		var n = someGeometryNode;
		out("The selected node can now be dragged around.\n");
		// simply add an onClick function
		n.onClick := fn(evt){
			out("Huhu!!! Drag me around!\n");
			registerExtension('PADrend_UIEvent',this->fn(evt){
				if(evt.type==Util.UI.EVENT_MOUSE_BUTTON && !evt.pressed){
					out("This is a nice place. I think I will stay here.\n");
					return Extension.REMOVE_EXTENSION;
				}else if(evt.type == Util.UI.EVENT_MOUSE_MOTION){
					this.moveRel(new Geometry.Vec3(evt.deltaX, 0, evt.deltaY) * 0.02);
				}
				return Extension.CONTINUE;
			});
		};
 * @endcode
 */

var plugin = new Plugin({
		Plugin.NAME : 'PADrend/NodeInteraction',
		Plugin.DESCRIPTION : "*EXPERIMENTAL* Basic functionality to interact with objects in the scene;\n should e.g. be used by the transformation EditNodes of the NodeEditor ",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend'],
		Plugin.EXTENSION_POINTS : []
});

	
// -------------------

static metaObjectRoot;
static objPicker;
static highlightState;

plugin.init @(override) := fn(){
	registerExtension('PADrend_Init',this->ex_Init,Extension.HIGH_PRIORITY);
	registerExtension('PADrend_UIEvent',this->ex_UIEvent);
	registerExtension('PADrend_AfterRenderingPass',this->ex_AfterRenderingPass);
	
	return true;
};

//! [ext:PADrend_Init]
plugin.ex_Init := fn(){
	metaObjectRoot = new MinSG.ListNode;
	metaObjectRoot.name := "PADrend.NodeInteraction.metaObjectRoot";
	
	PADrend.getRootNode().addChild(metaObjectRoot);
	
	objPicker  = new MinSG.RendRayCaster;
		
	// --------
	highlightState = new MinSG.GroupState;

	{	// add lighting
		var defaultLight = new MinSG.LightNode(MinSG.LightNode.DIRECTIONAL);
		defaultLight.setAmbientLightColor(new Util.Color4f(0.2,0.2,0.2,1))
					.setDiffuseLightColor(new Util.Color4f(0,0,0,0))
					.setSpecularLightColor(new Util.Color4f(0,0,0,0));
	
		highlightState.addState(new MinSG.LightingState(defaultLight));
	}
	
	{	// add blending
		var blending = new Rendering.BlendingParameters;
		blending.enable();
		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
		var s = new MinSG.BlendingState;
		s.setParameters(blending);
		highlightState.addState( s );
	}
	
	{	// depth test
		var S = new Type( MinSG.ScriptedState );
		S.doEnableState ::= fn(node,params){
			renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.LESS);
			return MinSG.STATE_OK;
		};
		S.doDisableState ::= fn(node,params){
			renderingContext.popDepthBuffer();
		};
		highlightState.addState( new S );
	}
	metaObjectRoot += highlightState;
};


//! [ext:PADrend_AfterRenderingPass]
plugin.ex_AfterRenderingPass := fn(...){
	if(metaObjectRoot.countChildren()==0)
		return;
	
	highlightState.activate();

	metaObjectRoot.display(GLOBALS.frameContext, MinSG.USE_WORLD_MATRIX);
	highlightState.deactivate();
};

//!	[ext:UIEvent]
plugin.ex_UIEvent:=fn(evt){
	if( evt.type==Util.UI.EVENT_MOUSE_BUTTON && evt.button == Util.UI.MOUSE_BUTTON_LEFT && evt.pressed){
		var node = pickNodeFromScreen(evt.x,evt.y,true);
		
		if(node){
			if(node.isSet($onClick))
				node.onClick(evt);
		}
	}
	return Extension.CONTINUE;
};

plugin.addMetaNode := fn(MinSG.Node n){
	metaObjectRoot.addChild(n);
};

plugin.removeMetaNode := fn(MinSG.Node n){
	metaObjectRoot.removeChild(n);
};
plugin.pickNodeFromScreen := fn(Number screenX,Number screenY,Bool includeMetaObjects=false){
	// if metaObjects (e.g. lights or similar nodes) are visible, allow interaction.
	objPicker.renderingLayers( Util.requirePlugin('PADrend/EventLoop').getRenderingLayers() );

	var node;
	if(includeMetaObjects){
		// try first to pick a metaObject (= nodes located below the metaObjectRoot)
		node = objPicker.queryNodeFromScreen(GLOBALS.frameContext,metaObjectRoot,new Geometry.Vec2(screenX,screenY),true);
	
		// otherwise a pick node from the scene
		if(!node)
			node = objPicker.queryNodeFromScreen(GLOBALS.frameContext,PADrend.getRootNode(),new Geometry.Vec2(screenX,screenY),true);
	}else{
		metaObjectRoot.deactivate();
		node = objPicker.queryNodeFromScreen(GLOBALS.frameContext,PADrend.getRootNode(),new Geometry.Vec2(screenX,screenY),true);
		metaObjectRoot.activate();
	}
	return node;
};


// alias
PADrend.NodeInteraction := plugin;

return plugin;
// ------------------------------------------------------------------------------
