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
/*!
	Various extension to the Geometry library.
*/
  
Geometry.Box.getRelPosition ::= fn(x,y,z){
	return this.getCorner(Geometry.CORNER_xyz)+new Geometry.Vec3(this.getExtentX()*x,this.getExtentY()*y,this.getExtentZ()*z);
};

static X_NORMAL = new Geometry.Vec3(1,0,0);
static Y_NORMAL = new Geometry.Vec3(0,1,0);
static Z_NORMAL = new Geometry.Vec3(0,0,1);

/*! @return Returns an array with intersections of this  box and a given @p line.
		The array has 0 or 2 entries.
	@note if only one intersection from the outside is required, look at Geometry/RayBoxIntersection
			this is also much more efficient.
*/
Geometry.Box.getLineIntersections ::= fn(Geometry.Line3 line){
	var xyz = this.getCorner(Geometry.CORNER_xyz);
	var XYZ = this.getCorner(Geometry.CORNER_XYZ);
	var minX = this.getMinX();
	var maxX = this.getMaxX();
	var minY = this.getMinY();
	var maxY = this.getMaxY();
	var minZ = this.getMinZ();
	var maxZ = this.getMaxZ();
	var intersectionPoints = [];
	var i;
	i = (new Geometry.Plane(xyz,X_NORMAL)).getIntersection( line );
	if(i && i.y()>=minY && i.y()<=maxY && i.z()>=minZ && i.z()<=maxZ )
		intersectionPoints += i;
	i = (new Geometry.Plane(XYZ,X_NORMAL)).getIntersection( line );
	if(i && i.y()>=minY && i.y()<=maxY && i.z()>=minZ && i.z()<=maxZ )
		intersectionPoints += i;
	
	i = (new Geometry.Plane(xyz,Y_NORMAL)).getIntersection( line );
	if(i && i.x()>=minX && i.x()<=maxX && i.z()>=minZ && i.z()<=maxZ )
		intersectionPoints += i;
	i = (new Geometry.Plane(XYZ,Y_NORMAL)).getIntersection( line );
	if(i && i.x()>=minX && i.x()<=maxX && i.z()>=minZ && i.z()<=maxZ )
		intersectionPoints += i;

	i = (new Geometry.Plane(xyz,Z_NORMAL)).getIntersection( line );
	if(i && i.x()>=minX && i.x()<=maxX && i.y()>=minY && i.y()<=maxY )
		intersectionPoints += i;
	i = (new Geometry.Plane(XYZ,Z_NORMAL)).getIntersection( line );
	if(i && i.x()>=minX && i.x()<=maxX && i.y()>=minY && i.y()<=maxY )
		intersectionPoints += i;
	
	if( intersectionPoints.empty() || intersectionPoints.count()==2){
		// default
	}else if( intersectionPoints.count() == 1){ // edge/corner hit
		intersectionPoints += intersectionPoints.back().clone();
	}else { // diagonal? degenerated case
		do{
			var minDistance;
			var minIndex;
			// search closest points
			foreach(intersectionPoints as var index,var p){
				foreach(intersectionPoints as var index2,var p2){
					if(index2!=index){
						var d = p.distance(p2);
						if(!minDistance || d<minDistance ){
							minDistance = d;
							minIndex = index;
						}
					}
				}
			}
			intersectionPoints.removeIndex(minIndex);
		}while(intersectionPoints.count()>2);
	}
	return intersectionPoints;	
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
	this.setValue(this.x().round(r),this.y().round(r),this.z().round(r));
	return this;
};
Geometry.Vec3.createOrthogonalVector ::= fn(){
	if(this.isZero()){
		Runtime.warn("Vec3.createOrthogonalVector: Input is null vector.");
		return new Geometry.Vec3(0,0,0);
	}
	var normal = this.getNormalized();
	var v1 = new Geometry.Vec3( normal.y(),normal.z(),normal.x());
	if(v1.dot(normal).abs()>0.6){
		v1 = new Geometry.Vec3( normal.z(),normal.x(),normal.y());
		if(v1.dot(normal).abs()>0.6){
			do{
				v1.setValue( Rand.uniform(-1,1),Rand.uniform(-1,1),Rand.uniform(-1,1) );
			}while( v1.isZero() || v1.normalize().dot(normal).abs()>0.6 );
		}
	}
	return normal.cross(v1).normalize();
};

return Geometry;
