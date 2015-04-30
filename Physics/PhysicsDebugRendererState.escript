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

static SimulationContainerTrait =  module('./ObjectTraits/SimulationContainerTrait');

var T = new Type( MinSG.ScriptedState );

T._printableName ::= $PhysicsDebugRenderState;

T._constructor ::= fn(){
	this.setTempState(true);
};
T.doEnableState ::= fn(node,params){
	if(Std.Traits.queryTrait(node,SimulationContainerTrait)){
		node.physics_getSimulationContext().getPhysicsWorld().renderPhysicWorld(GLOBALS.renderingContext);
		return MinSG.STATE_SKIP_RENDERING;
	}else{
		outln("PhysicsDebugRenderState: Node has no SimulationContainerTrait!");
	}
	return MinSG.STATE_OK;
};

return T;
