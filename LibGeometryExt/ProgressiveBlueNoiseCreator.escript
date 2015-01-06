/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

/** 
	Creates a series of distributed points. The goal of the distribution is to achive a blue noise distribution,
	maximizing the minimal distance between two adjacent points.
	
	\code
	var ProgressiveBlueNoiseCreator = Std.require('LibGeometryExt/ProgressiveBlueNoiseCreator');

	// simple example: create points inside a 3d box
	print_r( ProgressiveBlueNoiseCreator.createPointsInBox( new Geometry.Box(0,0,0,1,1,1),100 );
	
	// example: create 100 points inside a sphere
	print_r( (new ProgressiveBlueNoiseCreator( fn(){
			while(true){
				var p = new Geometry.Vec3( Rand.uniform(-1,1),Rand.uniform(-1,1),Rand.uniform(-1,1) );
				if( p.length()<=1.0 )
					return p;
			}
		})).createPositions( 100 ) );

	// example: create 100 points on a sphere
	print_r( (new ProgressiveBlueNoiseCreator( fn(){
			var p;
			do{
				p = new Geometry.Vec3( Rand.uniform(-1,1),Rand.uniform(-1,1),Rand.uniform(-1,1) );
			}while(p.isZero());
			return p.normalize();
		})).createPositions( 100 ) );
	\endcode

*/

static T = new Type;
T.tries @(private) := 0;
T.generatorFn @(private) := void;
T.octree @(private) := void;
T.points @(init,private) := Array;
T.bounds @(private) := void;

//! (static)
T.createPointsInBox ::= fn(Geometry.Box box, Number numPoints, Number tries = 200){
	return (new T( [box]=>fn(bb){return bb.getRelPosition(Rand.uniform(0,1),Rand.uniform(0,1),Rand.uniform(0,1));}, tries))
				.createPositions(numPoints);
};

T._constructor ::= fn(generatorFn, Number tries = 200){
	this.generatorFn = generatorFn;
	this.tries = tries;
};

T.createPositions ::= fn(Number count){
	var arr =[];
	for(;count>0;--count)
		arr += this.createPosition();
	return arr;
};

T.recreateOctree @(private) ::= fn(){
	var ot = new Geometry.PointOctree( this.bounds , bounds.getDiameter()*0.01,10  );
	foreach( this.points as var p)
		ot.insert( p, true );
	this.octree = ot;
};

T.createPosition ::= fn(){
	if(!this.bounds){
		var bb = new Geometry.Box;
		bb.invalidate();
		for(var i=this.tries; i>0; --i)
			bb.include( this.generatorFn() );
		bb.resizeRel(1.1);
		this.bounds = bb;
		recreateOctree();
	}

	var bestDistance = false;
	var bestCanditate = false;
	for(var i=this.tries; i>0; --i){
		var candidate = new Geometry.Vec3( this.generatorFn() );

		var closestPoints = this.octree.getClosestPoints(candidate,1);

		var candidateDistance = closestPoints.empty() ? false : candidate.distance(closestPoints[0].pos);

		if(!bestCanditate || !bestDistance || candidateDistance>bestDistance){
			bestCanditate = candidate;
			bestDistance = candidateDistance;
		}
	}
	this.points += bestCanditate;
	if(!this.bounds.contains(bestCanditate)){ // octree too small
//		outln("Recreating octree...");
		this.recreateOctree();
	}else{
		octree.insert(bestCanditate,true);
	}
	return bestCanditate;
};

return T;
