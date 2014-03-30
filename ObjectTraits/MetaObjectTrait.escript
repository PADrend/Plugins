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
Renderer._printableName @(override) ::= "_MetaObjectRenderer(tmp)";

Renderer.nodes @(init) := Array;

//Renderer._constructor ::= fn()@(super(MinSG.FrameContext.APPROXIMATION_CHANNEL)){};
Renderer._constructor ::= fn()@(super("META_OBJECT_CHANNEL")){
	this.setTempState(true);

};
Renderer.displayNode := fn(node,params){
	this.nodes += node;
//	out("+");
};

Renderer.doEnableState @(override) ::= fn(node,params){ //node,params){
	if( !params.getFlag(MinSG.SHOW_META_OBJECTS) )
		return MinSG.STATE_SKIPPED;
	this.nodes.clear();
	return MinSG.STATE_OK;
};
Renderer.doDisableState  @(override) ::= fn(node,params){// node,params){
//	out(this.nodes.count()," ");
	params.setChannel( "META_OBJECT_CHANNEL" ); //DEFAULT_CHANNEL
	// push and set blending, depth test, and lighting
	// depth sort
	params.setFlag( MinSG.USE_WORLD_MATRIX);

	var blending=new Rendering.BlendingParameters;
	blending.enable();
//	blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
	blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
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
MetaNodeState._printableName @(override) ::= "_MetaNodeState(tmp)";
MetaNodeState._constructor ::= fn(){
	this.setTempState(true);

};

MetaNodeState.doEnableState ::= fn(node,params){
	if(params.getChannel()!="META_OBJECT_CHANNEL"){
//		out("a");//,params.getChannel());
		params.setFlag( MinSG.USE_WORLD_MATRIX);
		params.setChannel( "META_OBJECT_CHANNEL" );

		if(frameContext.displayNode(node,params)) // pass on to other channel
			return MinSG.STATE_SKIP_RENDERING;
		else{ // no (active) Renderer state
			if(!node.hasParent())
				return MinSG.STATE_OK;
			var sceneRoot = node;
			while(sceneRoot.getParent().hasParent())
				sceneRoot = sceneRoot.getParent();
			
			foreach(sceneRoot.getStates() as var s){
				if(s---|>Renderer) // renderer found (probably just disabled)
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
		return [	];
	});
});


return trait;
