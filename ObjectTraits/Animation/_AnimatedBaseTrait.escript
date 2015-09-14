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


/*! The AnimatedBaseTrait is a helper trait for animation traits.
	It handles the registration with a linked animator node.
	The following members are added to the given Node:
			
	- node.onAnimationInit 	MultiProcedure(time)
	- node.onAnimationPlay 	MultiProcedure(time,lastTime)
	- node.onAnimationStop	MultiProcedure(time)
	
	\note adds the ObjectTraits/NodeLinkTrait to the given node.
	\note adds the ObjectTraits/Helper/AnimatorBaseTrait to a node linked with the "animator" role.
*/
static AnimationHandler = new Type;
AnimationHandler.subject := void;
AnimationHandler.currentMode := void;
AnimationHandler.lastTime := void;
AnimationHandler.lastClock := void;
AnimationHandler._constructor ::= fn(_subject){
	this.subject = _subject;
};



AnimationHandler._call ::= fn(caller,mode,time=0){
	if(!subject || !subject.isSet($onAnimationPlay))
		return;
	switch(mode){
	case 'play':
		if(this.currentMode!=mode){
			this.subject.onAnimationInit(time);
			this.currentMode = mode;
			this.lastTime = time;
			this.lastClock = PADrend.getSyncClock();
		}
		if(!subject.isActive())
			return;
			
		var camera = PADrend.getActiveCamera();
		var distSqr = 0;
		var maxDistSqr = this.subject.animCullDist()*this.subject.animCullDist();
		var minDistSqr = this.subject.animCullDistMin()*this.subject.animCullDistMin();
	
		if(maxDistSqr > 0 || minDistSqr > 0)
			distSqr = this.subject.getWorldPosition().distanceSquared(camera.getWorldPosition());
	
		if(maxDistSqr > 0 && distSqr > maxDistSqr )
			return;
			
		if(minDistSqr > 0 && distSqr > minDistSqr
			&& (PADrend.getSyncClock() - this.lastClock) < ((distSqr-minDistSqr)/(maxDistSqr-minDistSqr)) )
			return;
						
		if(this.subject.animFrustumCulling() 
			&& camera.testBoxFrustumIntersection(this.subject.getWorldBB()) == Geometry.Frustum.OUTSIDE 
			&& ((this.subject.animFrustumCullingRate() <= 0) || (PADrend.getSyncClock() - this.lastClock < this.subject.animFrustumCullingRate())) )
			return;
			
		this.subject.onAnimationPlay(time,this.lastTime);
		this.lastTime = time;
		this.lastClock = PADrend.getSyncClock();
		
		break;
	case 'stop':
		if(this.currentMode!=mode){
			this.subject.onAnimationStop(time,this.lastTime);
			this.currentMode = mode;
			this.lastTime = time;
			this.lastClock = PADrend.getSyncClock();
		}
	case 'pause':
		break;
	default:
		Runtime.warn("Unknown mode: "+mode);
	}
};

static trait = new Std.Traits.GenericTrait(module.getId());

trait.onInit += fn(MinSG.Node node){

	@(once) static AnimatorBaseTrait = module('./_AnimatorBaseTrait');

	Traits.assureTrait(node,module('../Basic/NodeLinkTrait'));
	
	var handler = new AnimationHandler(node);


	var connectTo = [node,handler] => fn(node,handler, [MinSG.Node,void] animatorNode){
		//outln(" Connecting ",node," to ",animatorNode);
		if(node.isSet($__myAnimatorNode) && node.__myAnimatorNode){
			node.__myAnimatorNode.animationCallbacks.accessFunctions().removeValue(handler); //! \see ObjectTraits/Helper/AnimatorBaseTrait
			handler( "stop" );
		}

		node.__myAnimatorNode := animatorNode;

		if(animatorNode){
			Traits.assureTrait(animatorNode,AnimatorBaseTrait);
				
			animatorNode.animationCallbacks += handler;	//! \see ObjectTraits/Helper/AnimatorBaseTrait
		}
	};

	//! \see ObjectTraits/NodeLinkTrait
	node.availableLinkRoleNames += "animator";
	
	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesLinked += [connectTo] => fn(connectTo, role,Array nodes){
		if(role=="animator"){
			connectTo(nodes[0]);
			if(nodes.count()!=1){
				Runtime.warn("AnimationBaseTrait: only one AnimatorNode allowed.");
			}
		}
	};
	
	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesUnlinked += [connectTo] => fn(connectTo, role,Array nodes){
		if(role=="animator")
			connectTo( void );
	};
	
	var exisitingLinks = node.getLinkedNodes("animator");
	if(!exisitingLinks.empty()){
		connectTo(exisitingLinks.front());
		if(exisitingLinks.count()!=1){
			Runtime.warn("AnimationBaseTrait: only one AnimatorNode allowed.");
			print_r(exisitingLinks);
		}
	}
		
		
	node.onAnimationPlay := new MultiProcedure;
	node.onAnimationInit := new MultiProcedure;
	node.onAnimationStop := new MultiProcedure;
	
	node.animFrustumCulling := node.getNodeAttributeWrapper("animFrustumCulling", false);
	node.animFrustumCullingRate := node.getNodeAttributeWrapper("animFrustumCullingRate", 0);
	node.animCullDist := node.getNodeAttributeWrapper("animCullDist", 0);
	node.animCullDistMin := node.getNodeAttributeWrapper("animCullDistMin", 0);
};

trait.allowRemoval();
trait.onRemove := fn(node){
	node.onAnimationStop(0);
	node.onAnimationStop.clear();
	node.onAnimationPlay.clear();
	node.onAnimationInit.clear();
};

return trait;

