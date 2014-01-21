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
/*! The Object performs repeated actions (once after each frame).
	The following members are added to the given Node:
			
	- node.addActionHandler(callback)	A yieldable callback called once after each frame.
*/
static trait = new Traits.GenericTrait('ObjectTraits/ActionPerformerTrait');

trait.onInit += fn(MinSG.Node node){

	node.addActionHandler := fn(handler){
		Util.registerExtension( 'PADrend_AfterFrame', handler);
	};
	
};

return trait;

