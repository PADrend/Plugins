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

static META_OBJECT_LAYER = 4+1; // layer 2 (2^2)
 
static Renderer = new Type( MinSG.ScriptedNodeRendererState );
Renderer._printableName @(override) ::= "_MetaObjectRenderer(tmp)";

Renderer.nodes @(init) := Array;

//Renderer._constructor ::= fn()@(super(MinSG.FrameContext.APPROXIMATION_CHANNEL)){};
Renderer._constructor ::= fn()@(super("META_OBJECT_CHANNEL")){
	this.setTempState(true);
	this.setRenderingLayers( META_OBJECT_LAYER );

};
Renderer.displayNode := fn(node,params){
	this.nodes += node;
//	out("+");
};

Renderer.doEnableState @(override) ::= fn(node,params){ //node,params){
//	if( !params.getFlag(MinSG.SHOW_META_OBJECTS) )
//		return MinSG.STATE_SKIPPED;
	this.nodes.clear();
	return MinSG.STATE_OK;
};
Renderer.doDisableState  @(override) ::= fn(node,params){// node,params){
//	out(this.nodes.count()," ");
	params.setChannel( "META_OBJECT_CHANNEL" ); //DEFAULT_CHANNEL
	// push and set blending, depth test, and lighting
	// depth sort
	params.setFlag( MinSG.USE_WORLD_MATRIX);

	var blending = new Rendering.BlendingParameters;
	blending.enable();



	{	//  pass: no depth test
//		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
		renderingContext.pushAndSetBlending(blending);
		renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.ALWAYS);
		foreach(this.nodes as var node){
			node.display(frameContext,params);
		}
		renderingContext.popDepthBuffer();
		renderingContext.popBlending();
	}

	{	//  pass: normal depth test
		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
//		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
		renderingContext.pushAndSetBlending(blending);
		
		foreach(this.nodes as var node){
			node.display(frameContext,params);
		}
		renderingContext.popBlending();
	}

};

Util.registerExtension('NodeEditor_QueryAvailableStates',fn(map){
	map['[scripted] MetaNodeRenderer'] = fn(){return new Renderer;};
});


var MetaNodeState = new Type( MinSG.ScriptedState );
MetaNodeState._printableName @(override) ::= "_MetaNodeState(tmp)";
MetaNodeState._constructor ::= fn(){
	this.setTempState(true);
	this.setRenderingLayers( META_OBJECT_LAYER );
};

MetaNodeState.doEnableState ::= fn(node,params){
	if(params.getChannel()!="META_OBJECT_CHANNEL"){
//		out("a");//,params.getChannel());
		params.setFlag( MinSG.USE_WORLD_MATRIX);
		params.setChannel( "META_OBJECT_CHANNEL" );

		if(frameContext.displayNode(node,params)) // pass on to other channel
			return MinSG.STATE_SKIP_RENDERING;
//			return MinSG.STATE_OK;
		else{ // no (active) Renderer state
			if(!node.hasParent())
				return MinSG.STATE_OK;
			var sceneRoot = node;
			while(sceneRoot.getParent().hasParent())
				sceneRoot = sceneRoot.getParent();
			
			foreach(sceneRoot.getStates() as var s){
				if(s.isA(Renderer)) // renderer found (probably just disabled)
					break; 
			}else{ // no renderer found -> add one
				sceneRoot += new Renderer; 
			}
			
			return MinSG.STATE_OK;
		}
	}else{
		// set Material
//		out("b");//,params.getChannel());
		return MinSG.STATE_OK;
	}
};


static highlightState = new MetaNodeState;

// ----------------------------------

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.GeometryNode node){
	node += highlightState;
//	node.setRenderingLayers( META_OBJECT_LAYER );
};

trait.allowRemoval();
trait.onRemove += fn(node){
	outln("Remove state.");
	node.removeState(highlightState);
//	node.setRenderingLayers( 1 ); // layer 0 (2^0)
};

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);//,"MetaObject");
	registry.registerTraitConfigGUI(trait, fn(node,refreshCallback){
		return [	];
	});
});


return trait;
