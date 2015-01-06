/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

PADrend.Serialization := new Plugin({
		Plugin.NAME : 'PADrend/Serialization',
		Plugin.DESCRIPTION : "De-/serialization of Objects",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend'],
		Plugin.EXTENSION_POINTS : []
});

// -------------------

PADrend.Serialization.typeRegistry @(private) := void;

PADrend.Serialization.init @(override) := fn(){
	Std.require('LibUtilExt/initObjectSerializers');
	Std.require('LibGeometryExt/initObjectSerializers');

	this.typeRegistry = new  ObjectSerialization.TypeRegistry;
	
	// -----
	// MinSG
	
	PADrend.Serialization.registerType( MinSG.Node, "MinSG.Node")
		.enableIdentityTracking()
		.addDescriber( fn(ctxt,MinSG.Node obj,Map d){
			var id = PADrend.getSceneManager().getNameOfRegisteredNode(obj);
			d['id'] = id;
			if(!id){
				Runtime.warn("Can't serialize unnamed node.");
			}
		})
		.setFactory( fn(ctxt,Type obj,Map d){
			var node = PADrend.getSceneManager().getRegisteredNode(d['id']);
			if(!node){
				Runtime.warn("Can't find node with id '"+d['id']+"'");
			}
			return node;
		});

	return true;
};

//! (internal)
PADrend.Serialization.createContext @(private) := fn(){
	return (new ObjectSerialization.Context( this.typeRegistry ));
};

//! description ---> obj
PADrend.Serialization.createFromDescription := fn(Map objDescription){
	return createContext().createObject(objDescription);
};

//! string ---> obj
PADrend.Serialization.deserialize := fn(String s){
	return createContext().createFromString(s);
};

//! obj ---> description
PADrend.Serialization.describeObject := fn(obj){
	return createContext().createDescription(obj);
};

//! obj ---> description
PADrend.Serialization.getTypeHandler := fn(nameOrType){
	return typeRegistry.getTypeHandler(nameOrType);
};

PADrend.Serialization.registerType := fn(Type type, String name){
	return typeRegistry.registerType(type,name);
};

//! obj ---> string
PADrend.Serialization.serialize := fn(obj){
	return createContext().serialize(obj);
};

// --------------------
// Aliases

PADrend.deserialize := PADrend.Serialization -> PADrend.Serialization.deserialize;
PADrend.serialize := PADrend.Serialization -> PADrend.Serialization.serialize;

// --------------------


return PADrend.Serialization;
// ------------------------------------------------------------------------------
