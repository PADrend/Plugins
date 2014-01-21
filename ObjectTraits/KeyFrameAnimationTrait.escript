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

/*! Animate an object according to key frames.
	The following members are added to the given Node:
			
	- node.animationSpeed 		DataWrapper( Number )
	- node.animationKeyFrames 	DataWrapper( { time->SRT|Vec3 } )
	
	\see ObjectTraits/AnimatedBaseTrait
	
	\todo support other interpolation methods.
	\todo visualize locations?
	\todo support position locations
*/
static trait = new MinSG.PersistentNodeTrait('ObjectTraits/KeyFrameAnimationTrait');

trait.onInit += fn(MinSG.Node node){
	node.animationSpeed :=  node.getNodeAttributeWrapper('animationSpeed', 1.0 );
	// time0 x0 y0 z0 | time1 x1 y1 y2 | ...
	// OR time0 x0 y0 z0 dx0 dy0 dz0 upx0 upy0 upz0 scale| ...
	var serializedKeyFrames =  node.getNodeAttributeWrapper('keyframes', "" );

	var keyFrames = new DataWrapper;
	
	{ // init existing key frames
		var m = new Map; // time -> SRT | Vec3
		foreach(serializedKeyFrames().split(',') as var singleKeyFrameString){
			var parts = singleKeyFrameString.split(' ');
			if(parts.count()==4){
				m[0+parts[0]] = new Geometry.Vec3( parts[1],parts[2],parts[3] );
			}else if(parts.count()==11){
				var pos =  new Geometry.Vec3( parts[1],parts[2],parts[3] );
				var dir =  new Geometry.Vec3( parts[4],parts[5],parts[6] );
				var up =  new Geometry.Vec3( parts[7],parts[8],parts[9] );
				m[0+parts[0]] = new Geometry.SRT(pos,dir,up, parts[10]);
			}else{
				Runtime.warn("KeyFrameAnimationTrait: unknown key frame format:"+s);
			}
		}
		keyFrames(m);
	}
	keyFrames.onDataChanged := [serializedKeyFrames] => fn(serializedKeyFrames, m){
		var parts = [];
		foreach(m as var time, var location){
			var parts2 = [time];
			if(location---|>Geometry.Vec3)
				parts2.append(location.toArray());
			else if(location---|>Geometry.SRT){
				parts2.append(location.getTranslation().toArray());
				parts2.append(location.getDirVector().toArray());
				parts2.append(location.getUpVector().toArray());
				parts2 += location.getScale();
			}
			parts += parts2.implode(" ");
		}
		serializedKeyFrames( parts.implode(',') );
	};
	node.animationKeyFrames := keyFrames;


	@(once) static AnimatedBaseTrait = Std.require('ObjectTraits/AnimatedBaseTrait');
	if(!Traits.queryTrait(node,AnimatedBaseTrait))
		Traits.addTrait(node,AnimatedBaseTrait);
	
	//! \see ObjectTraits/AnimatedBaseTrait
	node.onAnimationInit += fn(time){
		outln("onAnimationInit (KeyFrameAnimationTrait)");
		this._animationStartingTime  := time;
		this._animationInitialSRT  := this.getSRT();
	};
	//! \see ObjectTraits/AnimatedBaseTrait
	node.onAnimationPlay += fn(time,lastTime){
		if(this.animationKeyFrames().empty())
			return;
		var relTime = (time-_animationStartingTime)*this.animationSpeed();
		var prevLocation = this._animationInitialSRT;
		var nextLocation;
		var prevTime = 0;
		var nextTime = 0;
		foreach(this.animationKeyFrames() as nextTime, nextLocation){
			if(relTime<=nextTime)
				break;
			prevLocation = nextLocation;
			prevTime = nextTime;
		}
		if(prevLocation==nextLocation){
			if(prevLocation---|>Geometry.SRT){
				this.setSRT(prevLocation);
			}else{
				this.setRelPosition( prevLocation );
			}
		}else{ //! \todo mixed interpolation!
//			outln( relTime," ",prevTime," ",nextTime);
			
			var d = (prevTime==nextTime ? 0.0 : ((relTime-prevTime) / (nextTime-prevTime)) );
			if(prevLocation---|>Geometry.SRT){
				this.setSRT( new Geometry.SRT(prevLocation,nextLocation,d));
			}else{
				this.setRelPosition( prevLocation*d + nextLocation*(1-d) );
			}
		}

	};
	//! \see ObjectTraits/AnimatedBaseTrait
	node.onAnimationStop += fn(...){
		outln("stop");
		this.setSRT( this._animationInitialSRT );
	};
	
};

trait.allowRemoval();

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		var entries = [ "Key frames",
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
				GUI.RANGE : [0,60],
				GUI.LABEL : "speed",
				GUI.WIDTH : 200,
				GUI.DATA_WRAPPER : node.animationSpeed
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			'----'
		];
		foreach(node.animationKeyFrames() as var time,var location){
			entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
			entries += {
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.DATA_VALUE : time,
				GUI.ON_DATA_CHANGED : [refreshCallback,node.animationKeyFrames,time] => fn(refreshCallback,keyFrames,oldTime,newTime){
					var map = keyFrames().clone();
					var location = map[oldTime];
					if(location){
						map.unset(oldTime);
						map[newTime] = location;
						keyFrames(map);
					}
					refreshCallback();
				}
			};
			entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
			entries += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Update",
				GUI.WIDTH : 40,
				GUI.ON_CLICK : [node,node.animationKeyFrames,time] => fn(node,keyFrames,time){
					var map = keyFrames().clone();
					map[time] = node.getSRT();
					keyFrames(map);
				}
			};
			entries += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.WIDTH : 40,
				GUI.LABEL : "Apply",
				GUI.ON_CLICK : [node,node.animationKeyFrames,time] => fn(node,keyFrames,time){
					node.setSRT(keyFrames()[time]);
				}
			};
			entries += {
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.LABEL : "Delete",
				GUI.WIDTH : 40,
				GUI.ON_CLICK : [refreshCallback,node.animationKeyFrames,time] => fn(refreshCallback,keyFrames,time){
					var map = keyFrames().clone();
					map.unset(time);
					keyFrames(map);
					refreshCallback();
				}
			};
		}
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Add Keyframe",
			GUI.WIDTH : 120,
			GUI.ON_CLICK : [refreshCallback,node,node.animationKeyFrames] => fn(refreshCallback,node,keyFrames){
				var map = keyFrames().clone();
				var last = 0;
				foreach(map as var t, var location)
					last = t+1;
				map[last] = node.getSRT();
				keyFrames(map);
				refreshCallback();
			}
		};
		
		return entries;
	});
});

return trait;

