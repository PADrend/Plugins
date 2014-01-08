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


static trait = new MinSG.PersistentNodeTrait('ObjectTraits/RotationTrait');

trait.onInit += fn(MinSG.Node node){
	@(once) static AnimatedBaseTrait = Std.require('ObjectTraits/AnimatedBaseTrait');

	if(!Traits.queryTrait(node,AnimatedBaseTrait))
		Traits.addTrait(node,AnimatedBaseTrait);
	
	//! \see ObjectTraits/AnimatedBaseTrait
	node.animationInit += fn(time){
		outln("init");
		this._rotationStartingTime  := time;
		this._rotationInitialSRT  := this.getSRT();
	};
	//! \see ObjectTraits/AnimatedBaseTrait
	node.animationPlay += fn(time,lastTime){
//		outln("play");
//		var srt = this._rotationInitialSRT.clone();
		var srt = this.getSRT();
		srt.rotateLocal_deg( (time-lastTime)*this.rotationSpeed(),new Geometry.Vec3(0,1,0) );
		this.setSRT(srt);
	};
	//! \see ObjectTraits/AnimatedBaseTrait
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

