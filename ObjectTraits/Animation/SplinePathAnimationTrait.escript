/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2015 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.Node node){
	static roleName = "splineNode";
	node.spline_splineNode := new DataWrapper;
	node.animationSpeed := node.getNodeAttributeWrapper('spline_animationSpeed', 1 );
	node.repeatAnimation := node.getNodeAttributeWrapper('spline_repeatAnimation', false );
	node.distanceOffset := node.getNodeAttributeWrapper('spline_distanceOffset', 0 );
	//! \see ObjectTraits/NodeLinkTrait
	Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));

	{	// spline node connection

		//! \see ObjectTraits/NodeLinkTrait
		node.availableLinkRoleNames += roleName;

		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesLinked += fn(role,Array nodes){
			if(role==roleName){
				this.spline_splineNode(nodes.empty() ? void : nodes.back());
				this.setRelOrigin(this.spline_splineNode().getRelOrigin());
			}
		};
		// connect to existing links
		//! \see ObjectTraits/NodeLinkTrait
		if(!node.getLinkedNodes(roleName).empty()){
            node.spline_splineNode( node.getLinkedNodes(roleName).back() );
            node.setRelOrigin(node.spline_splineNode().getRelOrigin());
		}

		//! \see ObjectTraits/NodeLinkTrait
		node.onNodesUnlinked += fn(role,Array nodes){
			if(role==roleName)
				this.spline_splineNode(void);
		};
	}

	Traits.assureTrait(node,module('./_AnimatedBaseTrait'));

	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationInit += fn(time){
		outln("onAnimationInit (SplinePathAnimationTrait)");
	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationPlay += fn(time,lastTime){
//		var mb = new Rendering.MeshBuilder;
//		mb.color(new Util.Color4f(0,1,0,0.4));
//		mb.addSphere( new Geometry.Sphere([0,0,0],0.3),10,2 );
//		var posMesh = mb.buildMesh();
		if(this.spline_splineNode()){
			var splineLength = this.spline_splineNode().spline_calcLength();
			var currentDistance = this.repeatAnimation() ?
				(this.animationSpeed() * time) % splineLength :
				(this.animationSpeed() * time).clamp(0,splineLength);
			var transacormation = this.spline_splineNode().spline_calcLocationByLength(currentDistance + this.distanceOffset());
//			var n = new MinSG.GeometryNode(posMesh);
//			n.setRelOrigin(transacormation);
//			this.spline_splineNode()+=n;
			if(transacormation.isA(Geometry.Vec3))
				this.setWorldOrigin(this.spline_splineNode().localPosToWorldPos(transacormation));
			else{
				transacormation.setTranslation(this.spline_splineNode().localPosToWorldPos(transacormation.getTranslation()));
				this.setSRT(transacormation);
			}

		}else outln("No spline node selected!");
	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationStop += fn(...){
		outln("onAnimationStop (SplinePathAnimationTrait)");
		this.setRelOrigin(this.spline_splineNode().getRelOrigin());
	};
};

trait.allowRemoval();

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [1,10],
				GUI.LABEL : "m/sek",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.animationSpeed
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : " dist. offset",
				GUI.WIDTH : 150,
				GUI.DATA_WRAPPER : node.distanceOffset
			},
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Rep. anim.",
				GUI.DATA_WRAPPER : node.repeatAnimation
			}
		];
	});
});

return trait;

