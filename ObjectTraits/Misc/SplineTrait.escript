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


var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());


trait.onInit += fn( MinSG.GroupNode node){
	var serializedSplineControlpoints =  node.getNodeAttributeWrapper('spline_controlpoints', "" );
	node.spline_controlPoints := new Std.DataWrapper; // [ Vec3* ]

	{
		var temp = [];
		foreach(serializedSplineControlpoints().split(" ") as var point){
			var part = point.split(",");
			temp += new Geometry.Vec3(part[0], part[1], part[2]);
		}
		node.spline_controlPoints(temp);
	}
	node.spline_controlPoints.onDataChanged += [serializedSplineControlpoints]=>fn(serializedSplineControlpoints,  Array points){
		var temp = [];
		foreach(points as var point){
			temp += (point.toArray()).implode(",");
		};
		serializedSplineControlpoints(temp.implode(" "));
	};

	node.spline_createSplinePoints := fn(Number stepSize){
		var points = this.spline_controlPoints();
		if((points.size()-4) % 3 == 0){
			var splineCurePoints = [];
			for(var index = 0; index < points.size()-1; index +=3){
				for(var i = 0; i<=1; i+=stepSize)
					splineCurePoints += Geometry.interpolateCubicBezier(points[index], points[index+1], points[index+2], points[index+3], i);

			}
			return splineCurePoints;
		}
		else{
			Runtime.warn("No. of points is not 7 divisible!" );
			return [];
		}

	};

};

trait.allowRemoval();

return trait;
