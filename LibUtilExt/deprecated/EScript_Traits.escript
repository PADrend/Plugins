/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **		LibUtilExt/EScript_Traits.escript
 **
 **		This file contains the EScript Trait extension. It will eventually be
 **		transferred to the EScript repository (Claudius 2012-10-16)
 **/
declareNamespace($Traits);

/*!
	\todo
		- add test cases
		- improve documentation (including examples)
		- add support for info(...)

		
			THIS IS STILL EXPERIMENTAL!!!!!
*/

//------------------

//! (internal)
Traits._accessObjTraitRegistry := fn(obj,createIfNotExist = false){
	if(!obj.isSetLocally($__traits)){
		if(!createIfNotExist)
			return void;
		obj---|>Type ?
			(obj.__traits @(private) ::= new Map) :
			(obj.__traits @(private) := new Map);
	}
	return (obj->fn(){ return __traits;})(); // access private attribute
};

/*! Add a trait to the given object.
	The additional parameters are passed to the trait's init method. */
Traits.addTrait := fn(obj,Traits.Trait trait,params...){
	var name = trait.getName();

	var registry = Traits._accessObjTraitRegistry(obj,true);
	if(registry[name] && !trait.multipleUsesAllowed){
		Runtime.exception("Adding a trait to an Object twice.\nObject:"+obj.toDbgString()+"\nTrait:"+name);
	}
	(trait->trait.init)(obj,params...);
	if(trait.multipleUsesAllowed){
		if(!registry[name])
			registry[name] = [];
		registry[name] += trait;
	
	}else{
		registry[name] = trait;
	}
};


/*! Add a trait to the given object. The trait is identified by its name.
	\note The trait's name must correspond to the EScript attribute structure beginning with GLOBALS. 
			e.g. "Traits.SingletonTrait" --> GLOBALS.Traits.SingletonTrait	*/
Traits.addTraitByName := fn(obj,String traitName,params...){
	(Traits->Traits.addTrait)(obj,Traits.getTraitByName(traitName),params...);
};

Traits.getTraitByName := fn(String traitName){
	var nameParts = traitName.split('.');
	var traitSearch = GLOBALS;
	foreach(nameParts as var p){
		traitSearch = traitSearch.getAttribute(p);
		if(!traitSearch)
			Runtime.exception("Unknown node trait '"+traitName+"'");
	}
	return traitSearch;

};

/*! Checks if the given object has a trait stored locally (and not by inheritance).*/
Traits.queryLocalTrait := fn(obj,traitOrTraitName){
	var registry = _accessObjTraitRegistry(obj,false);
	return registry ? 
					registry[traitOrTraitName---|>Traits.Trait ? traitOrTraitName.getName():traitOrTraitName] :
					false;
};

/*! Checks if the given object has a trait (the trait may be inherited).*/
Traits.queryTrait := fn(obj,traitOrTraitName){
	var traitName = traitOrTraitName---|>Traits.Trait ? traitOrTraitName.getName():traitOrTraitName;
	while(obj){
		var reg = Traits._accessObjTraitRegistry(obj,false);
		if(reg && reg[traitName])
			return reg[traitName];
		obj = obj---|>Type ? obj.getBaseType() : obj.getType();
	}
	return false;
};

/*! Collects all traits of an object (including inherited traits).*/
Traits.queryTraits := fn(obj){
	var traits = _accessObjTraitRegistry(obj,false);
	traits = traits ? traits.clone() : new Map;
	for(var t = (obj---|>Type ? obj.getBaseType() : obj.getType()); t ; t = t.getBaseType()){
		var traits2 = _accessObjTraitRegistry(t,false);
		if(traits2)
			traits.merge(traits2);
	}
	return traits;
};

/*! Throws an exception if the given object does not have the given trait. */
Traits.requireTrait := fn(obj,traitOrTraitName){
	if(!Traits.queryTrait(obj,traitOrTraitName))
		Runtime.exception("Required trait not found\nObject:"+obj.toDbgString()+"\nTrait:"+traitOrTraitName);
};

// ---------------------------
/*! Baseclass for all Trait implementations.
	\note When creating a new Trait, you should consider using
		GenericTrait instead of this base class.	*/
Traits.Trait := new Type;
Traits.Trait._printableName @(override) ::= $Trait;
Traits.Trait._traitName @(private) := void;

//! If true, the Trait can be added multiple times to the same object.
Traits.Trait.multipleUsesAllowed := false;

/*! If a name is given, it is used to identify the trait. 
	Multiple traits offering the same behavior (with different implementations) 
	may provide the same name.	*/
Traits.Trait._constructor ::= fn(name = void){
	if(name){
		_traitName = name;
		this._printableName @(override) := name;
	}
};

Traits.Trait.allowMultipleUses ::= 		fn(){	return this.setMultipleUsesAllowed(true);	};
Traits.Trait.getMultipleUsesAllowed ::= fn(){	return multipleUsesAllowed;	};
Traits.Trait.getName ::=				fn(){	return _traitName ? _traitName : toString();	};
Traits.Trait.setMultipleUsesAllowed ::= fn(Bool b){	multipleUsesAllowed = b; 	return this;	};

//! ---o
Traits.Trait.init ::= fn(...){	Runtime.exception("This method is not implemented. Implement in subtype, or do not call!");	};


// ---------------------------

/*! GenericTrait ---|> Trait
	A GenericTrait offers:
	- attributes (including properties like @(private,init,...) that are added to the object(or type).
	- an onInit-method that is called on initialization.
	\note If you want to restrict the type of object to which the trait can be added,
		add an corresponding constraint to the onInit-method.
*/
Traits.GenericTrait := new Type(Traits.Trait);
Traits.GenericTrait._printableName @(override) ::= $GenericTrait;

Traits.GenericTrait.attributes @(init,public,const) := fn(){	return new Type;	};
//! ---o
Traits.GenericTrait.onInit @(init,public,const) := MultiProcedure;

//! ---|> Trait
Traits.GenericTrait.init @(const,override) ::= fn(obj,params...){
	// init attributes
	if(obj---|>Type){// set attribute directly
		foreach(attributes._getAttributes() as var name,var value){
			var attrProperties = attributes.getAttributeProperties(name);
			if(obj.isSetLocally(name) && (attrProperties&EScript.ATTR_OVERRIDE_BIT) == 0){
				Runtime.warn("GenericTrait overwrites existing attribute: "+obj+"."+name);
			}
			obj.setAttribute(name,value,attrProperties);
		}
	}else{
		// set attributes, but convert type-attribute and initialize the attributes marked with 'init'.
		foreach(attributes._getAttributes() as var name,var value){
			var attrProperties = attributes.getAttributeProperties(name);
			if(obj.isSetLocally(name) && (attrProperties&EScript.ATTR_OVERRIDE_BIT) == 0){
				Runtime.warn("GenericTrait overwrites existing attribute: "+obj+"."+name);
			}
			// silently convert type-attributes to object-attributes
			if((attrProperties&EScript.ATTR_TYPE_ATTR_BIT)>0){
				attrProperties^=EScript.ATTR_TYPE_ATTR_BIT;
			}
			if((attrProperties&EScript.ATTR_INIT_BIT)>0){
				if(value---|>Type){
					value = new value;
				}else{
					value = value();
				}
			}
			obj.setAttribute(name,value,attrProperties);
		}
	}
	
	// call onInit(type,params...)
	this.onInit(obj,params...);
};


// ----------

//
// ---------------------------------------
