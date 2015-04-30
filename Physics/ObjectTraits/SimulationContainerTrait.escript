/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');

static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.GroupNode node){
	node.physics_simSpeed := node.getNodeAttributeWrapper('physics_speed', 1 );
	node.physics_gravityAttr := node.getNodeAttributeWrapper('physics_gravity', "0 -10 0" ); // text based representation
	node.physics_gravity := new Std.DataWrapper; // vec3 data
	node.physics_gravityAttr.onDataChanged += [node.physics_gravity] => fn(v3, s){
		v3( new Geometry.Vec3(s.split(" ")) );
	};
	node.physics_gravityAttr.forceRefresh();
	node.physics_gravity.onDataChanged += [node.physics_gravityAttr] => fn(text, v3){
		text( v3.toArray().implode(" ") );
	};

	var ctxt = module('../SimulationContext')._create(node, node.physics_gravity, node.physics_simSpeed);
    node.physics_getSimulationContext := [ctxt] => fn(ctxt){	return ctxt;	};
    
    node.physics_debugRendererEnabled := Std.DataWrapper.createFromFunctions( [node]=>fn(node){
		var Renderer = module('../PhysicsDebugRendererState');
		foreach(node.getStates() as var s)
			if(s.isA(Renderer))
				return true;
		return false;
	},[node]=>fn(node, b){
		var Renderer = module('../PhysicsDebugRendererState');
		foreach(node.getStates() as var s)
			if(s.isA(Renderer))
				node -= s;
		if(b)
			node += new Renderer;
	});
};

module.on('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		var ctxt = node.physics_getSimulationContext();
		return [
				{
						GUI.TYPE : GUI.TYPE_BOOL,
						GUI.DATA_WRAPPER :ctxt.simulationRunning,
						GUI.LABEL : "Active",
						GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				},
				{	GUI.TYPE : GUI.TYPE_NEXT_ROW },
				{
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.DATA_WRAPPER :node.physics_gravityAttr,
						GUI.LABEL : "Gravity",
						GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				},
				{	GUI.TYPE : GUI.TYPE_NEXT_ROW },
				{
						GUI.TYPE : GUI.TYPE_RANGE,
						GUI.DATA_WRAPPER :node.physics_simSpeed,
						GUI.RANGE : [0,2],
						GUI.RANGE_STEP_SIZE : 0.1,
						GUI.LABEL : "Simulation speed",
						GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
				},
				{	GUI.TYPE : GUI.TYPE_NEXT_ROW },
				{
						GUI.TYPE : GUI.TYPE_BOOL,
						GUI.DATA_WRAPPER :node.physics_debugRendererEnabled,
						GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
						GUI.LABEL : "Debug renderer",

				},
				{	GUI.TYPE : GUI.TYPE_NEXT_ROW }
		];
	});
});

return trait;
