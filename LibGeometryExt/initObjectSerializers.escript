/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*! Collection of serializers for various types from Geometry.	*/
var defaultRegistry = Std.module('Std/ObjectSerialization').defaultRegistry;

defaultRegistry.registerType(Geometry.Box,"Geometry.Box")
	.addDescriber(fn(ctxt,Geometry.Box obj,Map d){
		d['center'] = ctxt.createDescription(obj.getCenter());
		d['size'] = [ obj.getExtentX(),obj.getExtentY(),obj.getExtentZ() ];
	})
	.setFactory(fn(ctxt,Type actualType,Map d){
		return new Geometry.Box( ctxt.createObject(d['center']), d['size'][0],d['size'][1],d['size'][2]);
	});

defaultRegistry.registerType(Geometry.Matrix4x4,"Geometry.Matrix4x4")
	.addDescriber(fn(ctxt,Geometry.Matrix4x4 obj,Map d){	d['values'] = obj.toArray().implode(" ");	})
	.setFactory(fn(ctxt,Type actualType,Map d){
		return new Geometry.Matrix4x4( (d['values']---|>Array) ? d['values'] : d['values'].split(" ") );
	});

defaultRegistry.registerType(Geometry.Rect,"Geometry.Rect")
	.addDescriber(fn(ctxt,Geometry.Rect obj,Map d){
		d['values'] = [ obj.getX(),obj.getY(),obj.getWidth(),obj.getHeight() ].implode(" ");
	})
	.setFactory(fn(ctxt,Type actualType,Map d){
		var values = (d['values']---|>Array) ? d['values'] : d['values'].split(" ");
		return new Geometry.Rect( values[0],values[1],values[2],values[3] );
	});


defaultRegistry.registerType(Geometry.Sphere,"Geometry.Sphere")
	.addDescriber(fn(ctxt,Geometry.Sphere obj,Map d){
		d['center'] = ctxt.createDescription(obj.getCenter());
		d['radius'] = obj.getRadius();
	})
	.setFactory(fn(ctxt,Type actualType,Map d){
		return new Geometry.Sphere(ctxt.createObject( d['center']), d['radius']);
	});
	
defaultRegistry.registerType(Geometry.SRT,"Geometry.SRT")
	.addDescriber(fn(ctxt,Geometry.SRT obj,Map d){
		d['pos'] = ctxt.createDescription(obj.getTranslation());
		d['dir'] = ctxt.createDescription(obj.getDirVector());
		d['up'] = ctxt.createDescription(obj.getUpVector());
		d['scale'] = obj.getScale();
	})
	.setFactory(fn(ctxt,Type actualType,Map d){
		return new Geometry.SRT( ctxt.createObject(d['pos']), ctxt.createObject(d['dir']), 
								ctxt.createObject(d['up']),d['scale']);
	});

	
defaultRegistry.registerType(Geometry.Vec2,"Geometry.Vec2")
	.addDescriber(fn(ctxt,Geometry.Vec2 obj,Map d){ d['values'] = [obj.getX(),obj.getY()].implode(" ");	})
	.setFactory(fn(ctxt,Type actualType,Map d){
		var values = (d['values']---|>Array) ? d['values'] : d['values'].split(" ");
		return new Geometry.Vec2(values[0],values[1]);
	});

defaultRegistry.registerType(Geometry.Vec3,"Geometry.Vec3")
	.addDescriber(fn(ctxt,Geometry.Vec3 obj,Map d){ d['values'] = [obj.getX(),obj.getY(),obj.getZ()].implode(" ");	})
	.setFactory(fn(ctxt,Type actualType,Map d){
		return new Geometry.Vec3((d['values']---|>Array) ? d['values'] : d['values'].split(" "));
	});	

defaultRegistry.registerType(Geometry.Vec4,"Geometry.Vec4")
	.addDescriber(fn(ctxt,Geometry.Vec4 obj,Map d){ d['values'] = [obj.getX(),obj.getY(),obj.getZ(),obj.getW()].implode(" ");	})
	.setFactory(fn(ctxt,Type actualType,Map d){
		return new Geometry.Vec4((d['values']---|>Array) ? d['values'] : d['values'].split(" "));
	});


return true;
