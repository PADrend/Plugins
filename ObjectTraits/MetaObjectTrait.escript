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


static Renderer = new Type( MinSG.ScriptedNodeRendererState );
Renderer.nodes @(init) := Array;

//Renderer._constructor ::= fn()@(super(MinSG.FrameContext.APPROXIMATION_CHANNEL)){};
Renderer._constructor ::= fn()@(super("META_OBJECT_CHANNEL")){};
Renderer.displayNode := fn(node,params){
	this.nodes += node;
//	out("+");
};

Renderer.doEnableState @(override) ::= fn(...){ //node,params){
	this.nodes.clear();
	return MinSG.STATE_OK;
};
Renderer.doDisableState  @(override) ::= fn(node,params){// node,params){
	out(this.nodes.count()," ");
	params.setChannel( "META_OBJECT_CHANNEL" ); //DEFAULT_CHANNEL
	// push and set blending, depth test, and lighting
	// depth sort

	var blending=new Rendering.BlendingParameters;
	blending.enable();
	blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
	renderingContext.pushAndSetBlending(blending);
	
	renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.ALWAYS);
	foreach(this.nodes as var node){
		node.display(frameContext,params);
	}
	renderingContext.popDepthBuffer();
	renderingContext.popBlending();
};

Util.registerExtension('NodeEditor_QueryAvailableStates',fn(map){
	map['_MetaNodeRenderer'] = fn(){return new Renderer;};
});


var MetaNodeState = new Type( MinSG.ScriptedState );

MetaNodeState.doEnableState ::= fn(node,params){
//	if(params.getFlag(MinSG.BOUNDING_BOXES))
//		return MinSG.STATE_OK;
	if(params.getChannel()!="META_OBJECT_CHANNEL"){
//		out("a");//,params.getChannel());
		params.setFlag( MinSG.USE_WORLD_MATRIX);
		params.setChannel( "META_OBJECT_CHANNEL" );

		
		if(frameContext.displayNode(node,params)) // pass on to other channel
			return MinSG.STATE_SKIP_RENDERING;
		else
			return MinSG.STATE_OK;
	}else{
		// set Material
//		out("b");//,params.getChannel());
		return MinSG.STATE_OK;
	}
};


static highlightState = new MetaNodeState;




//static highlightState = new MinSG.GroupState;

//	{	// add lighting
//		var defaultLight = new MinSG.LightNode(MinSG.LightNode.DIRECTIONAL);
//		defaultLight.setAmbientLightColor(new Util.Color4f(0.2,0.2,0.2,1))
//					.setDiffuseLightColor(new Util.Color4f(0,0,0,0))
//					.setSpecularLightColor(new Util.Color4f(0,0,0,0));
//	
//		highlightState.addState(new MinSG.LightingState(defaultLight));
//	}
//	
//	{	// add blending
//		var blending = new Rendering.BlendingParameters;
//		blending.enable();
//		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
//		var s = new MinSG.BlendingState;
//		s.setParameters(blending);
//		highlightState.addState( s );
//	}
//	
////	{	// depth test
////		var S = new Type( MinSG.ScriptedState );
////		S.doEnableState ::= fn(node,params){
////			renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.LESS);
////			return MinSG.STATE_OK;
////		};
////		S.doDisableState ::= fn(node,params){
////			renderingContext.popDepthBuffer();
////		};
////		highlightState.addState( new S );
////	}
//	

// ----------------------------------

static trait = new MinSG.PersistentNodeTrait('ObjectTraits/MetaObjectTrait');

trait.onInit += fn(MinSG.GeometryNode node){
	node += highlightState;
};

trait.allowRemoval();
trait.onRemove += fn(node){
	outln("Remove state.");
	node.removeState(highlightState);
};

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);//,"MetaObject");
	registry.registerTraitConfigGUI(trait, fn(node,refreshCallback){
		return [ "MetaObjectTrait",
			{
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.FLAGS : GUI.FLAT_BUTTON,
				GUI.TOOLTIP : "Remove trait",
				GUI.LABEL : "-",
				GUI.WIDTH : 20,
				GUI.ON_CLICK : [node,refreshCallback] => fn(node,refreshCallback){
					if(Traits.queryTrait(node,trait))
						Traits.removeTrait(node,trait);
					refreshCallback();
				}
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},

//			{
//				GUI.TYPE : GUI.TYPE_RANGE,
//				GUI.RANGE : [-3,2],
//				GUI.RANGE_FN_BASE : 10,
//				GUI.LABEL : "X",
//				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
//				GUI.DATA_WRAPPER : node.dimX
//			},

		];
	});
});


return trait;