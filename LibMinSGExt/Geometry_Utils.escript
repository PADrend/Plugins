/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[LibMinSGEct] Util/Geometry_Utils.escript
 **/
 
Geometry.Box.getRelPosition ::= fn(x,y,z){
	return this.getCorner(Geometry.CORNER_xyz)+new Geometry.Vec3(this.getExtentX()*x,this.getExtentY()*y,this.getExtentZ()*z);
};


/**
 * Evaluates the polynom determined by the given _points_ at position _x_ in time O(#points).
 * @param points Array of Geometry.Vec2 points.
 *        x value
 * @return p(x)
 *
 * @see http://en.wikipedia.org/wiki/Neville%27s_algorithm
 * @see http://jsxgraph.uni-bayreuth.de/wiki/index.php/Interpolation:_Neville%27s_algorithm
 */
Geometry.interpolate2dPolynom:=fn(Array points,Number x){
    var n=points.count();
    var values=[[],[]];

    foreach(points as var p){
        values[0]+=p.getY();
        values[1]+=0;
    }
    var j=0;
	for (var i=1; i<n; i++){
		j=i%2;
		var j_prev=(i-1)%2;
		for (var k=0; k < (n-i); k++){
		    var x1 = points[k].getX();
		    var x2 = points[k+i].getX();
		    var y1 = values[j_prev][k];
		    var y2 = values[j_prev][k+1];

			values[j][k] = (y1*(x-x2) - y2*(x-x1)) / (x1 - x2);
		}
	}
	return values[j][0];
};

/*! Evaluate a cubic Bezier curve defined by 4 points p0..3 at the given position t.
	\param p0,p1,p2,p3 may be Numbers or a Point Geometry.Vec2/3/4
	\param 0 <= t <= 1.0 
	\see http://de.wikipedia.org/wiki/B%C3%A9zierkurve
*/
Geometry.interpolateCubicBezier := fn(p0,p1,p2,p3,t){
	var ti=1-t;
	return p0*(ti*ti*ti) + p1*(3*t*ti*ti) + p2*(3*t*t*ti) + p3*(t*t*t);
};


//---------
// Vec3 extensions

Geometry.Vec3.round ::= fn(Number r=1){
	var xValue = this.x().round(r);
	var yValue = this.y().round(r);
	var zValue = this.z().round(r);
	this.x( xValue==0 ? 0 : xValue );
	this.y( yValue==0 ? 0 : yValue );
	this.z( zValue==0 ? 0 : zValue );
	return this;
};
