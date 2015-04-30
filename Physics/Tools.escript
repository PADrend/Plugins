/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Mouns R. Husan Almarrani
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var NS = new Namespace;

NS.assureSimulationContextAtSceneRoot := fn(MinSG.Node node){
	// 1. Find scene
	var scene;
	@(once) static SceneMarkerTrait = module('LibMinSGExt/Traits/SceneMarkerTrait');
	for(var n = node; n; n=n.getParent())
		if( Std.Traits.queryTrait(n, SceneMarkerTrait) )
			scene = n;
	
	if(!scene)
		Runtime.exception("assureSimulationContextAtSceneRoot: no scene root found.");
	
	Std.Traits.assureTrait(scene,module('./ObjectTraits/SimulationContainerTrait'));
	return scene.physics_getSimulationContext();
};

NS.queryResposibleSimulationContext := fn(MinSG.Node node){
	@(once) static SimulationContainerTrait = module('./ObjectTraits/SimulationContainerTrait');
	for(; node; node=node.getParent())
		if( Std.Traits.queryTrait(node, SimulationContainerTrait) )
			return node.physics_getSimulationContext();
	return void;
};

return NS;
