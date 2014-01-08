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


/*

An AnimatorTrait adds the following interface:

- animationCallbacks (MultiProcedure)



*/

static AnimationHandler = new Type;
AnimationHandler.subject := void;
AnimationHandler.currentMode := void;
AnimationHandler.lastTime := void;
AnimationHandler._constructor ::= fn(_subject){
	this.subject = _subject;
};
AnimationHandler._call ::= fn(caller,mode,time=0){
	switch(mode){
	case 'play':
		if(this.currentMode!=mode){
			this.subject.animationInit(time);
			this.currentMode = mode;
			this.lastTime = time;
		}
		this.subject.animationPlay(time,this.lastTime);
		this.lastTime = time;
		break;
	case 'stop':
		if(this.currentMode!=mode){
			this.subject.animationStop(time,this.lastTime);
			this.currentMode = mode;
			this.lastTime = time;
		}
	case 'pause':
		break;
	default:
		Runtime.warn("Unknown mode: "+mode);
	}
	

};



static trait = new MinSG.PersistentNodeTrait('ObjectTraits/RotationTrait');

trait.onInit += fn(MinSG.Node node){

	// --> AnimationBaseTrait

	@(once) static NodeLinkTrait = Std.require('ObjectTraits/NodeLinkTrait');
	@(once) static AnimatorBaseTrait = Std.require('ObjectTraits/AnimatorBaseTrait');

	if(!Traits.queryTrait(node,NodeLinkTrait))
		Traits.addTrait(node,NodeLinkTrait);
	
	var handler = new AnimationHandler(node);
//	node->fn(mode,Number t=0){
////		this.
//		this.animate(mode,t);
//	};


	var connectTo = [node,handler] => fn(node,handler, [MinSG.Node,void] animatorNode){
		outln(" Connecting ",node," to ",animatorNode);
		if(node.isSet($__myAnimatorNode) && node.__myAnimatorNode){
			node.__myAnimatorNode.animationCallbacks.accessFunctions().removeValue(handler); //! \see ObjectTraits/AnimatorBaseTrait
			handler( "stop" );
		}

		node.__myAnimatorNode := animatorNode;

		if(animatorNode){
			if(!Traits.queryTrait(animatorNode,AnimatorBaseTrait))
				Traits.addTrait(animatorNode,AnimatorBaseTrait);
				
			animatorNode.animationCallbacks += handler;	//! \see ObjectTraits/AnimatorBaseTrait
		}
	};

	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesLinked += [connectTo] => fn(connectTo, role,Array nodes,Array parameters){
		if(role=="animator"){
			connectTo(nodes[0]);
			if(nodes.count()!=1){
				Runtime.warn("AnimationBaseTrait: only one AnimatorNode allowed.");
			}
		}
	};
	
	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesUnlinked += [connectTo] => fn(connectTo, role,Array nodes,Array parameters){
		if(role=="animator")
			connectTo( void );
	};
	
	var exisitingLinks = node.getNodeLinks("animator");
	if(!exisitingLinks.empty()){
		connectTo(exisitingLinks[0][0][0]);
		if(exisitingLinks.count()!=1||exisitingLinks[0][0].count()!=1){
			Runtime.warn("AnimationBaseTrait: only one AnimatorNode allowed.");
			print_r(exisitingLinks);
		}
	}
		
		
	node.animationPlay := new MultiProcedure;
	node.animationInit := new MultiProcedure;
	node.animationStop := new MultiProcedure;
	// <---
	
	node.animationInit += fn(time){
		outln("init");
		this._rotationStartingTime  := time;
		this._rotationInitialSRT  := this.getSRT();
	};
	node.animationPlay += fn(time,lastTime){
//		outln("play");
//		var srt = this._rotationInitialSRT.clone();
		var srt = this.getSRT();
		srt.rotateLocal_deg( (time-lastTime)*this.rotationSpeed(),new Geometry.Vec3(0,1,0) );
		this.setSRT(srt);
	};
	node.animationStop += fn(...){
		outln("stop");
		this.setSRT( this._rotationInitialSRT );
	};
	node.rotationSpeed := new DataWrapper(  node.getNodeAttribute("rotationSpeed"); );
	if(!node.rotationSpeed())
		node.rotationSpeed(90.0);
	node.rotationSpeed.onDataChanged += [node] => fn(node,speed){
		node.setNodeAttribute("rotationSpeed",speed);
	};
};

trait.allowRemoval();

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [ "Rotation",
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
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [-3600,3600],
				GUI.LABEL : "deg/sek",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.rotationSpeed
			},	
		];
	});
});

return trait;

