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

static T = new Type;

T._printableName @(override) ::= $SimulationContext;
T.gravity := void;
T.simulationSpeed := void;
T.simulationRunning @(init) := Std.DataWrapper;

T.simulationRootNode @(private) := void;
T.physicsWorld @(private) := void;



T._constructor @(private) ::= fn(MinSG.GroupNode simRootNode, Std.DataWrapper gravity, Std.DataWrapper  speed){
	this.simulationSpeed = speed;
	this.gravity = gravity;
	
	this.physicsWorld = MinSG.Physics.createBulletWorld();
	this.physicsWorld.createGroundPlane(PADrend.getCurrentSceneGroundPlane() ); //! \todo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    this.physicsWorld.initNodeObserver(simRootNode);
    
	gravity.onDataChanged	+= this.physicsWorld -> this.physicsWorld.setGravity;
	gravity.forceRefresh();

	this.simulationRootNode = simRootNode;

    // search and init physic nodes....
	foreach( module('./ObjectTraits/PhysicTrait')._collectPhysicNodes( simRootNode )  as var n)
		n.physic_simulationCtxt( this );

	this.simulationRunning.onDataChanged += [new Std.MultiProcedure] => this->fn(revoce,b){
		revoce();
		if(b){
			revoce += Util.registerExtensionRevocably('PADrend_AfterFrame', [new Std.DataWrapper(PADrend.getSyncClock())] => this->fn(lastTime){
				var now = PADrend.getSyncClock();
				var delta = (now-lastTime()) * this.simulationSpeed();
				if(delta>0)
					this.physicsWorld.stepSimulation(delta);
				lastTime( now );
			});
		}
	};
};
T._create ::= fn(p...){
	return new T(p...);
};

T.getPhysicsWorld ::= fn(){	return this.physicsWorld;	};

// -----------------------------------------------------------------------------------------------------

return T;
