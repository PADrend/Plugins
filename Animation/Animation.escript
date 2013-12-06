/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/AnimationPlugin/Animation.escript
 ** 2011-04 Claudius
 **
 ** Animation namespace definition and generic stuff...
 **
 **/

GLOBALS.Animation := new Namespace();

// used for copy and paste
Animation.animationClipboard := void; 

// Registry for creatable Types of Animations:   Name(=short name) -> Type
Animation.constructableAnimationTypes := new Map();

Animation.loadAnimation := fn(filename){
	var s = Util.loadFile(filename);
	var obj = PADrend.deserialize(s);
	if(! (obj---|>Animation.AnimationBase) )
		Runtime.exception("Could not load Animation.");
	return obj;
};

Animation.saveAnimation := fn(filename,Animation.AnimationBase animation){
	return Util.saveFile(filename,PADrend.serialize(animation));
};