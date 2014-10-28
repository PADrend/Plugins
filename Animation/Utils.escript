/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2014 Claudius Jähn <claudius@uni-paderborn.de>
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

static NS = new Namespace;

// used for copy and paste
NS.animationClipboard := void; 

// Registry for creatable Types of Animations:   Name(=short name) -> Type
NS.constructableAnimationTypes := new Map();

NS.loadAnimation := fn(filename){
	var s = Util.loadFile(filename);
	var obj = PADrend.deserialize(s);
	if(! obj.isA(module('./Animations/AnimationBase') ))
		Runtime.exception("Could not load Animation.");
	return obj;
};

NS.saveAnimation := fn(filename,animation){
	assert(animation.isA(module('./Animations/AnimationBase')));
	return Util.saveFile(filename,PADrend.serialize(animation));
};
return NS;
