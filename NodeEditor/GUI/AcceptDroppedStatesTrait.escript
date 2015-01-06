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

 
 var t = new Traits.GenericTrait("NodeEditor/GUI/AcceptDroppedStatesTrait");
 
 static COPY_STATES = 1;
 static MOVE_STATES = 2;
 t.MOVE_STATES :=  MOVE_STATES;
 t.COPY_STATES :=  COPY_STATES;
 
 t.transferDroppedStates := fn( source, target, Array states, actionType=COPY_STATES ){
	var exisitingStates = target.getStates();
	foreach(states as var state){
		if(!exisitingStates.contains(state)){
			target += state;
			if(source && MOVE_STATES == actionType)
				source -= state;
		}
	}
 };

 t.attributes.availableStateDropActions := t.MOVE_STATES | t.COPY_STATES;
 t.attributes.defaultStateDropActions := t.COPY_STATES;
 t.attributes.onStatesDropped @(init) := Std.MultiProcedure; // fn( source, [State*], MOVE_STATES||COPY_STATES, evt )
   
 return t;
