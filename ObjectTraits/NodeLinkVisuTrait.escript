/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*!
    

    Links
		...

	Properties
		linkNames

*/

static hsv2rgb = fn(Number h,Number s, Number v){
    var hh = h.clamp( 0,360 ) / 60.0;

	var i = hh.floor();
    var ff = hh - i;
    var p = v * (1.0 - s);
    var q = v * (1.0 - (s * ff));
    var t = v * (1.0 - (s * (1.0 - ff)));

    switch( i ) {
    case 0:
        return new Util.Color4f( v,t,p );
    case 1:
        return new Util.Color4f( q,v,p );
    case 2:
        return new Util.Color4f( p,v,t );
    case 3:
        return new Util.Color4f( p,q,v );
    case 4:
        return new Util.Color4f( t,p,v );
    case 5:
    default:
        return new Util.Color4f( v,p,q );
    }
};
Util.hsv2rgb := hsv2rgb;

// ---------------------------------------
static META_OBJECT_LAYER = 4; // layer 2 (2^2)

static COLOR1 = new Util.Color4f(0.0,1.0,0.0,1.0);
static COLOR2 = new Util.Color4f(0.0,0.0,0.0,0.1);

static LinkState = new Type( MinSG.ScriptedState );
LinkState.linkedNodes @(init) := Array;
LinkState.mesh := void;
LinkState._constructor ::= fn(Array linkedNodes,Array colors){
	this.setTempState(true);
	this.linkedNodes.append(linkedNodes);
	var mb = new Rendering.MeshBuilder;
	foreach(linkedNodes as var i,var node){
//		mb.color(COLOR1);
		mb.color(colors[i]);
		mb.addVertex();
		mb.color(COLOR2);
		mb.addVertex();
	}
	var mesh = mb.buildMesh();
	mesh.setDrawLines();
	mesh.setUseIndexData(false);
	this.mesh = mesh;
	
	this.setRenderingLayers( META_OBJECT_LAYER );
};

LinkState.doEnableState ::= fn(node,params){
	return MinSG.STATE_OK;
};
LinkState.doDisableState ::= fn(node,params){
//	if( !params.getFlag(MinSG.SHOW_META_OBJECTS) )
//		return MinSG.STATE_SKIPPED;
	
	var sourcePos = node.getWorldBB().getCenter();
	var posAcc = Rendering.PositionAttributeAccessor.create(this.mesh, Rendering.VertexAttributeIds.POSITION);

	var i=0;
	foreach(this.linkedNodes as var targetNode){
		posAcc.setPosition(i++,sourcePos);
		posAcc.setPosition(i++,targetNode.getWorldBB().getCenter());
	}
	this.mesh._markAsChanged();


	var blending=new Rendering.BlendingParameters;
	blending.enable();
	blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
//	blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
	renderingContext.pushAndSetBlending(blending);
	
	renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );

	renderingContext.pushLine();
	renderingContext.setLineWidth(2.0);

	renderingContext.pushAndSetColorMaterial();

	renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.ALWAYS);
	renderingContext.displayMesh(this.mesh);
	renderingContext.popDepthBuffer();

	renderingContext.pushAndSetDepthBuffer(true, false, Rendering.Comparison.LESS);
	renderingContext.setLineWidth(6.0);
	renderingContext.displayMesh(this.mesh);
	renderingContext.popDepthBuffer();

	
	renderingContext.popMaterial();
	renderingContext.popLine();
	renderingContext.popMatrix_modelToCamera();

	renderingContext.popBlending();
	
	return MinSG.STATE_OK;
};


static trait = new (Std.require('LibMinSGExt/Traits/PersistentNodeTrait'))('ObjectTraits/NodeLinkVisuTrait');

trait.onInit += fn(MinSG.Node node){

	node.__NodeLinkTrait_revoce := new (Std.require('Std/MultiProcedure'));
	
	//! \see ObjectTraits/NodeLinkTrait
    @(once) static NodeLinkTrait = Std.require('ObjectTraits/NodeLinkTrait');
	if(!Traits.queryTrait(node,NodeLinkTrait))
		Traits.addTrait(node,NodeLinkTrait);

	static linkedNodeState = new MinSG.MaterialState;
	linkedNodeState.setTempState(true);
	


	static update = [node]=>fn(node,...){
		node.__NodeLinkTrait_revoce();
		
		var nodes = [];
		var colors = [];
		//! \see ObjectTraits/NodeLinkTrait
		foreach( node.accessLinkedNodes() as var linkContainer){
			if(linkContainer.role==="transform")
				continue;
			var r = linkContainer.role.trim();
			var seed = 41729;
			for(var i=0;i<r.length();++i)
				seed = (seed*2)^ord(r[i]);

			var color = hsv2rgb( (new Math.RandomNumberGenerator(seed)).uniform(0,360).round(15),1,1 );
			foreach(linkContainer.nodes as var linkedNode){
				nodes += linkedNode;
				colors += color;
			}
		}
		if(!nodes.empty()){
			var sourceState = new LinkState(nodes,colors);	
			node.__NodeLinkTrait_revoce += Std.addRevocably( node, sourceState);
		}
	};

	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesLinked += update;
	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesUnlinked += update;

	update();

};

trait.allowRemoval();

trait.onRemove += fn(node){
	node.__NodeLinkTrait_revoce();
};

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
		];
	});
});

return trait;

