/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
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


static Point = new Type;
Point.location := void; // SRT | Vec3
Point.data := void; // mixed
Point.getPosition ::= fn(){
	return this.location.isA(Geometry.Vec3) ? this.location : this.location.getTranslation();
};


trait.onInit += fn( MinSG.GroupNode node){
	var serializedSplineControlpoints =  node.getNodeAttributeWrapper('spline_controlpoints', "[]" );
	node.spline_controlPoints := new Std.DataWrapper; // [ Vec3* ]

	node.spline_createControlPoint := fn([Geometry.Vec3,Geometry.SRT] location){
		var p = new Point;
		p.location := location.clone();
		return p;
	};
	
	if(!serializedSplineControlpoints().empty()){
		var initialPoints = [];
		foreach(parseJSON(serializedSplineControlpoints()) as var pointArr){
			if(pointArr.count()==3){
				initialPoints += node.spline_createControlPoint( new Geometry.Vec3(pointArr) );
			}else{
				initialPoints += node.spline_createControlPoint( new Geometry.SRT(pointArr) );
			}
		}
		node.spline_controlPoints(initialPoints);
	}
	node.spline_controlPoints.onDataChanged += [serializedSplineControlpoints]=>fn(serializedSplineControlpoints,  Array points){
		var serializedPoints = [];
		foreach(points as var point)
			serializedPoints += point.location.toArray();
//		outln(toJSON(serializedPoints,false));
		serializedSplineControlpoints(toJSON(serializedPoints,false));
	};

	
	node.spline_createSplinePoints := fn(Number stepSize){
		var points = this.spline_controlPoints();
		if((points.size()-4) % 3 == 0){
			var splineCurePoints = [];
			for(var index = 0; index < points.size()-1; index +=3){
				var p0 = points[index].getPosition();
				var p1 = points[index+1].getPosition();
				var p2 = points[index+2].getPosition();
				var p3 = points[index+3].getPosition();
				for(var i = 0; i<=1.00001; i+=stepSize)
					splineCurePoints += Geometry.interpolateCubicBezier(p0,p1,p2,p3, i);

			}
			return splineCurePoints;
		}
		else{
			Runtime.warn("No. of points is not 7 divisible!" );
			return [];
		}

	};
	
	node.spline_calculateTransformation := fn(Number t){
		var points = this.spline_controlPoints();
		
		if(points.empty())
			return new Geometry.Vec3;
		var index = t.floor()*3;
//		outln("#",t,"\t",index,"\t",points.count()-3);

		if(index<0)
			return points[0].location.clone();
		if(index>=points.count()-3)
			return points.back().location.clone();
			
		
		var p0 = points[index];
		var p1 = points[index+1];
		var p2 = points[index+2];
		var p3 = points[index+3];

		var pos = Geometry.interpolateCubicBezier(p0.getPosition(),p1.getPosition(),p2.getPosition(),p3.getPosition(), t%1.0);
		if(p0.location.isA(Geometry.SRT)&&p3.location.isA(Geometry.SRT) ){
//			outln("##",p0.location,"\t",p3.location,"\t",t%1.0);

			var interpolatedSRT = new Geometry.SRT;// (p0.location,p3.location,t%1.0);
			interpolatedSRT.setTranslation(pos);
			interpolatedSRT.setRotation( Geometry.Quaternion.slerp( new Geometry.Quaternion(p0.location.getRotation()), new Geometry.Quaternion(p3.location.getRotation()), t%1.0) );
			
			return interpolatedSRT;
		}else{
			return pos;
		}
		
	};

};

trait.allowRemoval();

return trait;
