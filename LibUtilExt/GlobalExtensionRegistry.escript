/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

 //! Global registry for ExtensionPoints
 
static ExtensionPoint = module('./ExtensionPoint');
 
static _extensionPointsRegistry = new Map;

static N = new Namespace;

//! (static) Create a new extensionPoint and store it in the singleton extensionPoint registry.
N.createExtensionPoint := fn(name,Number flags = 0) {
	var extPoint = new ExtensionPoint(flags);
	if( _extensionPointsRegistry[name] ){
		Runtime.warn("Extension point '"+name+"' already exists.");
	}
		
	_extensionPointsRegistry[name] = extPoint;
	return extPoint;
};

N.get := fn(name) {
	return _extensionPointsRegistry[name];
};
 
N.registerExtension := fn(name, fun,[Number,Bool] priority = Util.EXTENSION_PRIORITY_MEDIUM) {
	var extensionPoint = N.get(name);
	if(!extensionPoint){
		Runtime.warn("Unknown extension point: "+name);
		return;
	}
	if(extensionPoint.isDeprecated())
		Runtime.warn("Extending deprecated extension point '"+name+"' with extension '"+fun.toDbgString()+"'.");
	return extensionPoint.registerExtension(fun,priority);
};

N.registerExtensionRevocably := fn( name, fun, p...) {
	N.registerExtension( name, fun, p...);
	return [name,fun] => fn(name,fun){
		N.removeExtension( name, fun );
		return $REMOVE;
	};
};

N.removeExtension := fn(name, fun) {
	var extensionPoint = N.get(name);
	if(!extensionPoint){
		Runtime.warn("Unknown extension point: "+name);
		return;
	}
	extensionPoint.removeExtension(fun);
};

/*! (public) If the extensionPoint is a chainOfResponsibility, the execution is stopped after the
	first extension results true. Then true is returned.	*/
N.executeExtensions := fn(name,params...) {
	var extensionPoint = N.get(name);
	if(!extensionPoint){
		Runtime.warn("Unknown extension point: "+name);
		return;
	}
	return extensionPoint.execute(params);
};

Util.registerExtensionRevocably := N.registerExtensionRevocably; //! \deprecated alias
GLOBALS.registerExtension := N.registerExtension; //! \deprecated alias
Util.registerExtension := N.registerExtension; //! \deprecated alias
GLOBALS.removeExtension := N.removeExtension; //! \deprecated alias
Util.removeExtension := N.removeExtension; //! \deprecated alias
GLOBALS.executeExtensions := N.executeExtensions; //! \deprecated alias
Util.executeExtensions := N.executeExtensions; //! \deprecated alias

return N;

