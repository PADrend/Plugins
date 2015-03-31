/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/

 * Copyright (C) 2014-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var AutomatedTest = Std.module('Tests/AutomatedTest');

var tests = [];

static getRandomVector = fn(v){
	return new Geometry.Vec3(Rand.uniform(-v,v),Rand.uniform(-v,v),Rand.uniform(-v,v));
};

// -----------------------------------------------------------------------------------------------

tests += new AutomatedTest( "Geometry.Vec3.createOrthogonalVector",fn(){
	var vectors = [ new Geometry.Vec3(27,27,27) ];
	for(var i=0;i<100;++i){
		var v = getRandomVector(100);
		if(!v.isZero())
			vectors += v;
	}
	foreach(vectors as var v){
		if( (v.createOrthogonalVector().dot(v).abs()>0.0001 ))
			return false;
	}
	return true;
});


tests += new AutomatedTest( "Geometry.Box.getLineIntersections",fn(){
	for(var i=0;i<30;++i){
		var box = new Geometry.Box( getRandomVector(20), Rand.uniform(0.1,100),Rand.uniform(0.1,100),Rand.uniform(0.1,100) );
		var maxBox = box.clone().resizeRel(1.01);
		var minBox = box.clone().resizeRel(0.01);
		for(var j=0;j<100; ++j){
			var line = new Geometry.Line3( getRandomVector(3), getRandomVector(1).normalize() );
			var intersections = box.getLineIntersections(line);
			if(!intersections.empty()){
				assert(intersections.count()==2);
				[var p1,var p2] = intersections;
				if(!maxBox.contains(p1) || !maxBox.contains(p2) || minBox.contains(p1) ||minBox.contains(p1) || line.distance(p1)>0.001 || line.distance(p2)>0.001)
					return false;
			}
		}
	}
	return true;
});


tests += new AutomatedTest( "Geometry.ProgressiveBlueNoiseCreator",fn(){
	var ProgressiveBlueNoiseCreator = Std.module('LibGeometryExt/ProgressiveBlueNoiseCreator');

	var ok = true;
	// simple example: create points inside a 3d box
	var box =  new Geometry.Box(0,0,0,1,1,1);
	var points = ProgressiveBlueNoiseCreator.createPointsInBox( new Geometry.Box(0,0,0,1,1,1),100 );
	ok &= points.count()==100;
	foreach(points as var p)
		ok &= box.contains( p );

	//! \todo it qould be nice to also check the distribution's quality.	
	return ok;
});

// -----------------------------------------------------------------------------------------------

return tests;
