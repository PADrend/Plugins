/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

return fn() {
	var tools = module('../InternalTools');

	var listNode = new MinSG.ListNode;
	module('LibMinSGExt/SemanticObject').markAsSemanticObject(listNode);
	Std.Traits.addTrait( listNode, Std.module('ObjectTraits/Misc/SplineTrait'));

	var points = [];

	points += listNode.spline_createControlPoint( new Geometry.Vec3(0,0,0) );
	points += listNode.spline_createControlPoint( new Geometry.Vec3(1,1,0) );
	points += listNode.spline_createControlPoint( new Geometry.Vec3(1.5,1,0) );
	points += listNode.spline_createControlPoint( new Geometry.Vec3(2,0,0) );

	listNode.spline_controlPoints(points);
	Std.Traits.addTrait( listNode, Std.module('ObjectTraits/Misc/SplineEditorTrait'));

	tools.registerNodeWithUniqueId(listNode,"Spline");
	
	PADrend.message("Added spline (with rendering layer #2)");
	return listNode;
};

