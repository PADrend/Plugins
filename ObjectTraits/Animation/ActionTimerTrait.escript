/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myet@mail.uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

static sortActions = fn(array){
	return array.sort( fn(a,b){	return a[0]<b[0];	});
};

static executeAction = fn(node, entry) {
	[var time, var role, var actionFn, var params] = entry;
	if(role.empty())
		return;
	params = params.clone();
	for(var i=0; i<params.count(); ++i) {
		if(params[i] === '$TIME')
			params[i] = time;
	}
	//! \see ObjectTraits/NodeLinkTrait
	var nodes = node.getLinkedNodes( role );
	if(nodes.empty())
		PADrend.message("Could not find nodes with role: " + role);
	foreach(nodes as var target) {
		try{
			(target->target.getAttribute(actionFn))(params...);
		}catch(e){
			Runtime.warn(e);
		}
	}
};

trait.onInit += fn(MinSG.Node node){
	node.animationSpeed :=  node.getNodeAttributeWrapper('animationSpeed', 1.0 );
	node.loopAnimation :=  node.getNodeAttributeWrapper('loopAnimation', false );
	node._nextActionIndex := 0;
	// time0 x0 y0 z0 | time1 x1 y1 y2 | ...
	// OR time0 x0 y0 z0 dx0 dy0 dz0 upx0 upy0 upz0 scale| ...
	var serializedActions =  node.getNodeAttributeWrapper('actions', "[]" );
	

	var actions = new DataWrapper;

	{ // init existing key frames
		var arr = parseJSON(serializedActions()); // [time,role,fn,[params]]*
		actions( sortActions(arr) );
	}
	actions.onDataChanged := [serializedActions] => fn(serializedActions, arr){
		serializedActions( toJSON(arr) );
	};
	node._animationStartingTime := 0;
	node.animationActions := actions;
	node.testFn := fn() { outln("Test!"); };
	
	Traits.assureTrait(node,module('./_AnimatedBaseTrait'));

	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationInit += fn(time){
		//outln("onAnimationInit (ActionAnimationTrait)");
		this._animationStartingTime = time;
	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationPlay += fn(time,lastTime){
		if(this.animationActions().empty())
			return;
		var relTime = (time-_animationStartingTime)*this.animationSpeed();
		var relLastTime = (lastTime-_animationStartingTime)*this.animationSpeed();
		
		var finishTime = this.animationActions().back()[0];
		if(this.loopAnimation() && !this.animationActions().empty())
			relTime %= finishTime;
		if(this.loopAnimation() && !this.animationActions().empty())
			relLastTime %= finishTime;
		
		// find actions in interval [relLastTime, relTime]	
		// TODO: do a binary search
		var actions = [];
		foreach(this.animationActions() as var entry){
			var actionTime = entry[0];
			if(relTime < relLastTime) {// wrap around
				if(relTime >= actionTime || relLastTime < actionTime)
					actions += entry;
			} else {
				if(relTime < actionTime)
					break;
				if(relLastTime < actionTime)
					actions += entry;
			}
		}		
		sortActions(actions);
		
		foreach(actions as var entry) {
			executeAction(this, entry);
		}
	};
	//! \see ObjectTraits/Animation/_AnimatedBaseTrait
	node.onAnimationStop += fn(...){
		//outln("stop");
	};

};

trait.allowRemoval();
trait.onRemove += fn(node){
	node.animationActions([]);
};

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
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "loop",
				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				GUI.DATA_WRAPPER : node.loopAnimation
			},
			'----'
		];
		var steps = [];

		foreach(node.animationActions() as var index, var entry){
			[var time, var role, var actionFn, var params] = entry;
			var data = new ExtObject({
				$time : new DataWrapper(time),
				$role : new DataWrapper(role),
				$actionFn : new DataWrapper(actionFn),
				$params : new DataWrapper(toJSON(params, false)),
			});
			var updateEntry = [refreshCallback, node.animationActions,index,data] => fn(refreshCallback, actions,index,data,...) {
				var arr = actions().clone();// create new array to detect update
				var entry = arr[index].clone(); // create new array to detect update
				entry = [data.time(), data.role(), data.actionFn(), parseJSON(data.params())];
				arr[index] = entry;
				actions(sortActions(arr));
				refreshCallback();
			};
			data.time.onDataChanged += updateEntry;
			data.role.onDataChanged += updateEntry;
			data.actionFn.onDataChanged += updateEntry;
			data.params.onDataChanged += updateEntry;
			
			entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
			entries += {
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.TOOLTIP : "Time",
				GUI.DATA_WRAPPER : data.time,
				GUI.SIZE : [GUI.WIDTH_REL | GUI.HEIGHT_ABS,0.1,15 ],
			};
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.TOOLTIP : "Role",
				GUI.DATA_WRAPPER : data.role,
				GUI.SIZE : [GUI.WIDTH_REL | GUI.HEIGHT_ABS,0.2,15 ],
			};
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.TOOLTIP : "Function Name",
				GUI.DATA_WRAPPER : data.actionFn,
				GUI.SIZE : [GUI.WIDTH_REL | GUI.HEIGHT_ABS,0.3,15 ],
			};
			entries += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.TOOLTIP : "Function Parameters (JSON-Array)",
				GUI.DATA_WRAPPER : data.params,
				GUI.SIZE : [GUI.WIDTH_REL | GUI.HEIGHT_ABS,0.3,15 ],
			};
			entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
			entries += {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.WIDTH : 40,
				GUI.LABEL : "Test",
				GUI.ON_CLICK : [node,node.animationActions,index] => fn(node,actions,index){
					executeAction(node, actions()[index]);
				}
			};
			entries += {
				GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
				GUI.LABEL : "Delete",
				GUI.WIDTH : 40,
				GUI.ON_CLICK : [refreshCallback,node.animationActions,index] => fn(refreshCallback,actions,index){
					var arr = actions().clone(); // create new array to detect update
					arr.removeIndex(index);
					actions(sortActions(arr));
					refreshCallback();
				}
			};
		}
		entries += {	GUI.TYPE : GUI.TYPE_NEXT_ROW	};
		entries += {
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Add Action",
			GUI.WIDTH : 120,
			GUI.ON_CLICK : [refreshCallback,node,node.animationActions] => fn(refreshCallback,node,actions){

				var arr = actions().clone();
				arr += [ (arr.empty() ? 0 : arr.back()[0]+1), "self", "testFn", []];
				actions(sortActions(arr));
				refreshCallback();
			}
		};

		return entries;
	});
});

return trait;
