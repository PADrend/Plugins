/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2019 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static T = new Namespace;

static strToColor = fn(color) {
	color = color.trim();
	var c = new Util.Color4ub(0,0,0,255);
	if(!color.beginsWith("#") || color.length() < 7)
		return c;
	c.r(eval("0x" + color.substr(1,2) + ";"));
	c.g(eval("0x" + color.substr(3,2) + ";"));
	c.b(eval("0x" + color.substr(5,2) + ";"));
	return c;
};

T.plot := fn(data, markers=[]) {
	var root = new MinSG.ListNode;
	var vd = new Rendering.VertexDescription;
	vd.appendPosition3D();
	vd.appendColorRGBFloat();
	var minX = 1e+50;
	var maxX = -1e+50;
	var minY = 1e+50;
	var maxY = -1e+50;
	foreach(data.dataRows as var row){
		var mb = new Rendering.MeshBuilder(vd);
		mb.color(strToColor(row.color));
		var keys = [];
		foreach(row.data as var x, var y) {
			keys += x;
		}
		keys.sort();
		foreach(keys as var x) {
			var y = row.data[x];
			minX = [minX, x].min();
			maxX = [maxX, x].max();
			minY = [minY, y].min();
			maxY = [maxY, y].max();
			mb.position(new Geometry.Vec3(x, y, 0));
			mb.addVertex();
		}
		var mesh = mb.buildMesh();    
		mesh.setDrawLineStrip();
		var node = new MinSG.GeometryNode(mesh);
		root += node;
	}
	var xScale = 1/[maxX.abs(),minX.abs()].max();
	var yScale = 1/[maxY.abs(),minY.abs()].max();
	foreach(MinSG.getChildNodes(root) as var n) {
		Rendering.transformMesh(n.getMesh(), (new Geometry.Matrix4x4()).scale(xScale, yScale, 1));
	}
	foreach(markers as var m) {
		var mb = new Rendering.MeshBuilder(vd);
		mb.color(new Util.Color4f(0,0,0,1));
		
		mb.position(new Geometry.Vec3(0,m[1]*yScale,0)); mb.addVertex();
		mb.position(new Geometry.Vec3(m[0]*xScale,m[1]*yScale,0)); mb.addVertex();
		mb.position(new Geometry.Vec3(m[0]*xScale,0,0)); mb.addVertex();
		var mesh = mb.buildMesh();    
		mesh.setDrawLineStrip();
		var node = new MinSG.GeometryNode(mesh);
		root += node;
	}
	/*{ // create legend
		var mb = new Rendering.MeshBuilder(vd);
		mb.color(new Util.Color4f(0,0,0,1));
		mb.position(new Geometry.Vec3(0,0,0)); mb.addVertex();
		mb.position(new Geometry.Vec3(1,0,0)); mb.addVertex();
		mb.position(new Geometry.Vec3(0,0,0)); mb.addVertex();
		mb.position(new Geometry.Vec3(0,1,0)); mb.addVertex();
		var mesh = mb.buildMesh();    
		mesh.setDrawLines();
		var node = new MinSG.GeometryNode(mesh);
		root += node;
	}*/
	
	return root;
};

return T;