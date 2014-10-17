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
	- node.animationKeyFrames 	DataWrapper( [ time,SRT|Vec3]* } )
	
	\see ObjectTraits/Animation/_AnimatedBaseTrait
	
	\todo support other interpolation methods.
	\todo visualize locations?
	\todo support position locations
*/
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

	
static simpleSmootTime = fn(relTime,smoothness){
	if(smoothness == 0||relTime<0||relTime>=1.0){
		return relTime;
	}else{
		//! \see http://en.wikipedia.org/wiki/Smoothstep
		var s = relTime*relTime*(3.0-2.0*relTime);
		return smoothness * s + (1.0-smoothness) * relTime;
	}
};

static sortKeyFrames = fn(array){
	return array.sort( fn(a,b){	return a[0]<b[0];	});
};

trait.onInit += fn(MinSG.Node node){
	node.animationSpeed :=  node.getNodeAttributeWrapper('animationSpeed', 1.0 );
	// time0 x0 y0 z0 | time1 x1 y1 y2 | ...
	// OR time0 x0 y0 z0 dx0 dy0 dz0 upx0 upy0 upz0 scale| ...
	var serializedKeyFrames =  node.getNodeAttributeWrapper('keyframes', "" );
	node.keyFrame_smoothFactor :=  node.getNodeAttributeWrapper('keyframes_smoothFactor', 0 );

	var keyFrames = new DataWrapper;
	
	{ // init existing key frames
		var arr = []; // [time,SRT | Vec3]*
		foreach(serializedKeyFrames().split(',') as var singleKeyFrameString){
			var parts = singleKeyFrameString.split(' ');
			var entry = [];
			entry += 0+parts[0]; // time
			if(parts.count()==4){
				entry += new Geometry.Vec3( parts[1],parts[2],parts[3] );
			}else if(parts.count()==11){
				var pos =  new Geometry.Vec3( parts[1],parts[2],parts[3] );
				var dir =  new Geometry.Vec3( parts[4],parts[5],parts[6] );
				var up =  new Geometry.Vec3( parts[7],parts[8],parts[9] );
				entry += new Geometry.SRT(pos,dir,up, parts[10]);
			}else{
				Runtime.warn("KeyFrameAnimationTrait: unknown key frame format:"+s);
			}
			arr += entry;
		}
		keyFrames( sortKeyFrames(arr) );
	}
	keyFrames.onDataChanged := [serializedKeyFrames] => fn(serializedKeyFrames, arr){
		var parts = [];
		foreach(arr as var entry){
			[var time, var location] = entry;
			
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


	Traits.assureTrait(node,module('./_AnimatedBaseTrait'));
	
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationInit += fn(time){
		outln("onAnimationInit (KeyFrameAnimationTrait)");
		this._animationStartingTime  := time;
//////		this._animationInitialSRT  := (this.animationKeyFrames()[0]---|> Geometry.SRT) ? this.animationKeyFrames()[0] : this.getRelTransformationSRT();
		this._animationInitialSRT  := this.getRelTransformationSRT();
	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationPlay += fn(time,lastTime){
		if(this.animationKeyFrames().empty())
			return;
		var relTime = (time-_animationStartingTime)*this.animationSpeed();
		var prevLocation = this._animationInitialSRT;
		var nextLocation;
		var prevTime = 0;
		var nextTime = 0;
		foreach(this.animationKeyFrames() as var entry){
			[nextTime, nextLocation] = entry;
			if(relTime<=nextTime)
				break;
			prevLocation = nextLocation;
			prevTime = nextTime;
		}
		if(prevLocation==nextLocation){
			if(prevLocation---|>Geometry.SRT){
				this.setRelTransformation(prevLocation);
			}else{
				this.setRelPosition( prevLocation );
			}
		}else{ //! \todo mixed interpolation!
//			outln( relTime," ",prevTime," ",nextTime);
			
			var d = (prevTime==nextTime ? 0.0 : simpleSmootTime((relTime-prevTime) / (nextTime-prevTime),this.keyFrame_smoothFactor()) );
			if(prevLocation---|>Geometry.SRT){
				this.setRelTransformation( new Geometry.SRT(prevLocation,nextLocation,d));
			}else{
				this.setRelPosition( prevLocation*d + nextLocation*(1-d) );
			}
		}

	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationStop += fn(...){
		outln("stop");
		if(this.isSet($_animationInitialSRT) && this._animationInitialSRT)
			this.setRelTransformation( this._animationInitialSRT );
	};
	
};

trait.allowRemoval();

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		var entries = [
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0,60],
				GUI.LABEL : "speed",
				GUI.RANGE_STEP_SIZE : 0.1,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.animationSpeed
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.RANGE : [0,1],
				GUI.LABEL : "smoothness",
				GUI.RANGE_STEP_SIZE : 0.1,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.keyFrame_smoothFactor
			},	
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
			'----'
		];
		var steps = [];
		
		foreach(node.animationKeyFrames() as var index, var entry){
			[var time,var location] = entry;
			entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
			entries += {
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.DATA_VALUE : time,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.ON_DATA_CHANGED : [refreshCallback,node.animationKeyFrames,index] => fn(refreshCallback,keyFrames,index,newTime){
					var arr = keyFrames().clone();
					var entry = arr[index];
					entry[0] = newTime;
					keyFrames(sortKeyFrames(arr));

					refreshCallback();
				}
			};
			entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
			entries += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Update",
				GUI.WIDTH : 40,
				GUI.ON_CLICK : [node,node.animationKeyFrames,index] => fn(node,keyFrames,index){
					var arr = keyFrames().clone();
					var entry = arr[index];
					entry[1] = node.getRelTransformationSRT();
					keyFrames(sortKeyFrames(arr));

				}
			};
			entries += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.WIDTH : 40,
				GUI.LABEL : "Apply",
				GUI.ON_CLICK : [node,node.animationKeyFrames,index] => fn(node,keyFrames,index){
					node.setRelTransformation(keyFrames()[index][1]);
				}
			};
			entries += {
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.LABEL : "Delete",
				GUI.WIDTH : 40,
				GUI.ON_CLICK : [refreshCallback,node.animationKeyFrames,index] => fn(refreshCallback,keyFrames,index){

					var arr = keyFrames().clone();
					arr.removeIndex(index);
					keyFrames(sortKeyFrames(arr));
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

				var arr = keyFrames().clone();
				arr += [ (arr.empty() ? 0 : arr.back()[0]+1), node.getRelTransformationSRT()];
				keyFrames(sortKeyFrames(arr));
				refreshCallback();
			}
		};
		
		return entries;
	});
});

return trait;

