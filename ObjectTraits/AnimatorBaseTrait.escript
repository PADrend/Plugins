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

/*! The AnimatorBaseTrait is a helper trait used for Animator Traits.
	It adds the following members:
	- animationCallbacks: a MultiProcedure where animated nodes can register their animation handler \see AnimatedBaseTrait
	
	\note the specific animator trait is responsible for repeatedly calling the animationCallbacks.
*/


/* \todo
     stop before saving
*/


static trait = new MinSG.PersistentNodeTrait('ObjectTraits/AnimatorBaseTrait');

trait.onInit += fn(MinSG.Node node){
	node.animationCallbacks := new MultiProcedure;
	
	Util.registerExtension( 'PADrend_AfterFrame', node->fn(...){
		if(this.isDestroyed())
			return $REMOVE;
		this.animationCallbacks("play",PADrend.getSyncClock());
	});
	
};


return trait;

