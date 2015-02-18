/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014-2015 Claudius J�hn <claudius@uni-paderborn.de>
 * Copyright (C) 2014-2015 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

 /*! A GroupNode becomes a container for a s spline curve (cubic bezier).
	The splie's control points are saved with the node as node attribute.
	Adds the following public members:
	
	- spline_controlPoints 						DataWrapper for ControlPoints*
												Extend to update the spline.
	- spline_createControlPoint(SRT|Vec3) -> ControlPoint 	Factory for control points; 
												manually add to spline_controlPoints.
	- spline_calcPositions(stepSize for t) -> { t -> Vec3 }
 
	- spline_calcLocation(t) -> SRT|Vec3
	- spline_calcLocationByLength(t) -> SRT|Vec3
	- spline_calcLength() -> Number
 
	\note Auxiliary Traits (like the SplineEditTrait) may add child nodes to the group node.
		No persistant "normal" child node should be addded to the node.
 */

static NumberKeyMap = module('LibUtilExt/NumberKeyMap'); 
var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

static Point = new Type;
Point.location := void; // SRT | Vec3
Point.data := void; // mixed
Point.getPosition ::= fn(){
	return this.location.isA(Geometry.Vec3) ? this.location : this.location.getTranslation();
};


trait.onInit += fn( MinSG.GroupNode node){
	var distancesMapWrapper = new Std.DataWrapper;
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
	node.spline_controlPoints.onDataChanged += [distancesMapWrapper,serializedSplineControlpoints]=>fn(distancesMapWrapper,serializedSplineControlpoints,  Array points){
		distancesMapWrapper( void );
		var serializedPoints = [];
		foreach(points as var point)
			serializedPoints += point.location.toArray();
//		outln(toJSON(serializedPoints,false));
		serializedSplineControlpoints(toJSON(serializedPoints,false));
	};

	node.spline_calcPositions := fn(Number stepSize){
		var splineCurvePoints = new NumberKeyMap;

		var points = this.spline_controlPoints();
		if((points.size()-4) % 3 != 0){
			Runtime.warn("Ivalid number of points" );
		}else{
			var t = 0;
			for(var index = 0; index < points.size()-1; index +=3){
				var p0 = points[index].getPosition();
				var p1 = points[index+1].getPosition();
				var p2 = points[index+2].getPosition();
				var p3 = points[index+3].getPosition();
				for(var i = 0; i< 0.99995; i+=stepSize)
					splineCurvePoints[t+i] = Geometry.interpolateCubicBezier(p0,p1,p2,p3, i);
				++t;
			}
			if(!points.empty())
				splineCurvePoints[t] = points.back().getPosition();
//			print_r(splineCurvePoints);
		}
		return splineCurvePoints; // t -> position
	};

	node.spline_calcLocation := fn(Number t){
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

	static updateDistanceMap = fn(distancesMapWrapper,splineNode){
		if(!distancesMapWrapper()){
			var distancesMap = new NumberKeyMap; // length -> splineValue_t
			var distance = 0;
			var lastPoint;
			foreach(splineNode.spline_calcPositions(0.01) as var t, var position){
				distance += lastPoint ? lastPoint.distance(position) : 0;
				lastPoint = position;
				distancesMap.insert(distance, t);
			}
			distancesMapWrapper(distancesMap);
		}
	};
	node.spline_calcLength := [distancesMapWrapper]=>fn(distancesMapWrapper){
		updateDistanceMap(distancesMapWrapper,this);
		return distancesMapWrapper().getMaxKey();
	};

	node.spline_calcLocationByLength := [distancesMapWrapper]=>fn(distancesMapWrapper, Number length){
		updateDistanceMap(distancesMapWrapper,this);
		[var lEntry,var rEntry] = distancesMapWrapper().getNeighbors(length);
		var t;
		if( !lEntry || lEntry[0]==rEntry[0] ){
			t = rEntry[1];
		}else if( !rEntry ){
			t = lEntry[1];
		}else{
			t = lEntry[1] + (rEntry[1]-lEntry[1]) * (length-lEntry[0]) / (rEntry[0]-lEntry[0]);
		}
		return this.spline_calcLocation(t);

	};

};

trait.allowRemoval();

return trait;
