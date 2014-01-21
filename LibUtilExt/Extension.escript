/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[LibUtilExt] Extension.escript
 ** Extension point management
 **/

// ---------------------------
// Extension

Util.EXTENSION_PRIORITY_LOW @(const) := -100;
Util.EXTENSION_PRIORITY_MEDIUM @(const) := 0;
Util.EXTENSION_PRIORITY_HIGH @(const) := 100;

Util.EXTENSION_REMOVE @(const) := $REMOVE;
Util.EXTENSION_BREAK_AND_REMOVE @(const) := $BREAK_AND_REMOVE;
Util.EXTENSION_BREAK @(const) := $BREAK;
Util.EXTENSION_CONTINUE @(const) := $CONTINUE;

Util.EXTPOINT_CHAINED @(const) := 1;
Util.EXTPOINT_THROW_EXCEPTION @(const) := 2;
Util.EXTPOINT_ONE_TIME @(const) := 4;
Util.EXTPOINT_DEPRECATED @(const) := 8;


Util.Extension := new Type;
GLOBALS.Extension := Util.Extension; //! \deprecated global alias
{
	var T = Util.Extension;
	T._printableName @(override) ::= $Extension;

	//! priority constants (aliases)
	T.LOW_PRIORITY ::= Util.EXTENSION_PRIORITY_LOW;
	T.MEDIUM_PRIORITY ::= Util.EXTENSION_PRIORITY_MEDIUM;
	T.HIGH_PRIORITY ::= Util.EXTENSION_PRIORITY_HIGH;

	//! Possible predefined results for an extension call:
	T.REMOVE ::= Util.EXTENSION_REMOVE; //!< continue and remove extension
	T.REMOVE_EXTENSION ::= Util.EXTENSION_REMOVE; // alias
	T.BREAK_AND_REMOVE ::= Util.EXTENSION_BREAK_AND_REMOVE; //!<  works only on chained ExtensionPoints!
	T.BREAK_AND_REMOVE_EXTENSION ::= Util.EXTENSION_BREAK_AND_REMOVE; // alias
	T.BREAK ::= Util.EXTENSION_BREAK; //!<  works only on chained ExtensionPoints!
	T.CONTINUE ::= Util.EXTENSION_CONTINUE;

	//! Members
	T.priority := 0;
	T.fun := void;
	T.yieldIterator := void;

	//! (ctor)
	T._constructor ::= fn( fun,priority ){
		this.fun = fun;
		this.priority = priority;
	};

	//! used for sorting
	T."<" ::= fn(other){
		return this.priority < other.priority;
	};

}

// ---------------------------
// ExtensionPoint

Util.ExtensionPoint := new Type;
GLOBALS.ExtensionPoint := Util.ExtensionPoint; //! \deprecated global alias
{
	var T = Util.ExtensionPoint;
	T._printableName @(override) ::= $ExtensionPoint;

	//! Flags

	/*! The extensions are handled as a 'chain of responsibility'; when the first extension returns true, Util.EXTENSION_BREAK or Util.EXTENSION_BREAK_AND_REMOVE, 
		the other extension are skipped. This can be used for ExtensionPoint that handle events. If the Event is consumed by an extension, this extension then returns true. */
	T.CHAINED ::= Util.EXTPOINT_CHAINED;  

	/*! If an extension throws an exception, the execution of the other extensions is stopped and the exception is re-thrown. */
	T.THROW_EXCEPTION ::= Util.EXTPOINT_THROW_EXCEPTION;  

	/*! The extensions are only executed once and then removed.	*/
	T.ONE_TIME ::= Util.EXTPOINT_ONE_TIME;

	/*! The extension point should no longer be used; when registering an extension, a warning is shown.	*/
	T.DEPRECATED ::= Util.EXTPOINT_DEPRECATED;

	//! (static)
	T._extensionPointsRegistry ::= new Map;

	//! (static) Create a new extensionPoint and store it in the singleton extensionPoint registry.
	T.create ::= fn(name,Number flags = 0) {
		var extPoint = new ExtensionPoint(flags);
		if(ExtensionPoint._extensionPointsRegistry[name]){
			Runtime.warn("Extension point '"+name+"' already exists.");
		}
			
		ExtensionPoint._extensionPointsRegistry[name] = extPoint;
		return extPoint;
	};

	//! (static)
	T.get ::= fn(name) {
		return ExtensionPoint._extensionPointsRegistry[name];
	};

	// ----------

	T.extensions @(private,init) := Array;
	T.chainOfResponsibility @(private) := false;
	T.deprecated @(private) := false;
	T.throwException @(private) := false;
	T.oneTime @(private) := false;
	T.needsSorting @(private) := false;

	//! (ctor)
	T._constructor ::= fn(flags = 0){
		chainOfResponsibility = (flags&CHAINED)>0;
		throwException = (flags&THROW_EXCEPTION)>0;
		oneTime = (flags&ONE_TIME)>0;
		deprecated = (flags&DEPRECATED)>0;
	};

	T._call ::= fn(caller,params...){
		return execute(params);
	};

	//! Execute the registered Extensions.
	T.execute ::= fn(params){
		if(needsSorting)
			this.extensions.rSort();
		
		var needsFiltering = false; // an extension has been disabled and needs to be removed
		var handledByChain = void; // if the extensionPoint is  a chain-of-resposibility, this is true if a responsible handler is found
		var exception;
		var extensions2 = this.extensions.clone(); // temporary copy
		foreach(extensions2 as var extension){
			var result;
			try{
				result = extension.yieldIterator ? extension.yieldIterator.next() :	(void->extension.fun)(params...);
			}catch(e){
				if(extension.yieldIterator.end())
					extension.yieldIterator = void;
					
				if( throwException ){
					exception = e;
					break; // skip all other extensions
				}else{
					Runtime.log(Runtime.LOG_ERROR,e);
				}
				continue;
			}
			
			if( result ---|> YieldIterator ){
				extension.yieldIterator = result.end() ? void : result; // valid yield iterator returned --> store in extension
				result = result.value();
			}
			
			if(!result || Util.EXTENSION_CONTINUE==result) { // void, false or EXTENSION_CONTINUE? --> keep extension and continue
				continue;
			}else if(Util.EXTENSION_REMOVE==result){ // EXTENSION_REMOVE --> exclude extension and continue
				extension.fun = void;
				needsFiltering = true;
				continue;
			}else if(chainOfResponsibility && (Util.EXTENSION_BREAK==result || true === result) ){ // (true or EXTENSION_BREAK) in chained mode --> skip others
				handledByChain = true;
				break;
			}else if(chainOfResponsibility && Util.EXTENSION_BREAK_AND_REMOVE==result){ // EXTENSION_BREAK_AND_REMOVE in chained mode --> exclude and skip others
				extension.fun = void;
				needsFiltering = true;
				handledByChain = true;
				break;
			}else{ // result is invalid
				Runtime.warn("Extension '"+extension.fun.toDbgString()+"' returned invalid result '"+result+"'" );
			}
		}
		if(oneTime){
			// keep the extensions added during the execution of this one, remove the rest.
			foreach(extensions2 as var extension) 
				extension.fun = void;
			needsFiltering = true;
		}

		if(needsFiltering)
			this.extensions.filter( fn(extension){return true & extension.fun; } );

		if(exception)
			throw exception;
		return handledByChain;
	};
	T.isDeprecated ::= fn(){	return deprecated;	};

	//! (internal)
	T.createExtension @(private) ::= fn(fun,[Number,Bool] priority = Util.EXTENSION_PRIORITY_MEDIUM) {
		if(priority---|>Bool){
			priority = priority ? Extension.HIGH_PRIORITY : Util.EXTENSION_PRIORITY_MEDIUM;
		}
		// plugins added later get a slightly lower priority to preserve the ordering inside of priority classes
		priority += 0.1-(extensions.count()*0.0001);

	//	out("",name,":",priority,"\n" );
		return new Extension(fun,priority);

	};

	T.registerExtension ::= fn(extOrFun,[Number,Bool] priority = Util.EXTENSION_PRIORITY_MEDIUM) {
		var extension = extOrFun---|>Extension ? extOrFun : createExtension(extOrFun,priority);
		this.extensions += extension;
		this.needsSorting = true;
		return extension;
	};

	T.registerConditionalExtension ::= fn(DataWrapper condition,extOrFun,[Number,Bool] priority = Util.EXTENSION_PRIORITY_MEDIUM) {
		var extension = extOrFun---|>Extension ? extOrFun : createExtension(extOrFun,priority);
		var conditionListener = [extension] => ( this->fn(extension,enabled){
			if(enabled){
				if(!extensions.contains(extension)){
					registerExtension(extension);
				}
			}else {
				removeExtension(extension);
			}
		});
		condition.onDataChanged += conditionListener;
		
		conditionListener(condition());
		return extension;
	};


	T.removeExtension ::= fn(extOrFun) {
		var fun = extOrFun---|>Extension ? extOrFun.fun : extOrFun;
		extensions.filter( [fun] => fn(fun,ext){ return ext.fun!=fun;	} );
	};

	//! Alias for registerExtension(fun)
	T."+=" ::= fn(fun){
		this.registerExtension(fun);
		return this;
	};
	//! Alias for removeExtension(fun)
	T."-=" ::= fn(fun){
		this.removeExtension(fun);
		return this;
	};
}
// ----------------------------


//! (public)
Util.registerExtension := fn(name, fun,[Number,Bool] priority = Util.EXTENSION_PRIORITY_MEDIUM) {
	var extensionPoint = ExtensionPoint.get(name);
	if(!extensionPoint){
		Runtime.warn("Unknown extension point: "+name);
		return;
	}
	if(extensionPoint.isDeprecated()){
		Runtime.warn("Extending deprecated extension point '"+name+"' with extension '"+fun.toDbgString()+"'.");
	}
	return extensionPoint.registerExtension(fun,priority);
};
GLOBALS.registerExtension := Util.registerExtension; //! \deprecated global alias

/*! (public) Register an extension at the extension point with @p name with the given @p priority.
	The extension is only active while the boolean DataWrapper @p condition is true. No runtime overhead
	is introduced for inactive extensions. 
	\see ExtensionPoint.registerConditionalExtension	*/
Util.registerConditionalExtension := fn(DataWrapper condition, name, fun,[Number,Bool] priority = Util.EXTENSION_PRIORITY_MEDIUM) {
	var extensionPoint = ExtensionPoint.get(name);
	if(!extensionPoint){
		Runtime.warn("Unknown extension point: "+name);
		return;
	}
	if(extensionPoint.isDeprecated()){
		Runtime.warn("Extending deprecated extension point '"+name+"' with extension '"+fun.toDbgString()+"'.");
	}
	return extensionPoint.registerConditionalExtension(condition,fun,priority);
};
GLOBALS.registerConditionalExtension := Util.registerConditionalExtension; //! \deprecated global alias

//! (public)
Util.removeExtension := fn(name, fun) {
	var extensionPoint = ExtensionPoint.get(name);
	if(!extensionPoint){
		Runtime.warn("Unknown extension point: "+name);
		return;
	}
	extensionPoint.removeExtension(fun);
};
GLOBALS.removeExtension := Util.removeExtension; //! \deprecated global alias


/*! (public) If the extensionPoint is a chainOfResponsibility, the execution is stopped after the
	first extension results true. Then true is returned.	*/
Util.executeExtensions := fn(name,params...) {
	var extensionPoint = ExtensionPoint.get(name);
	if(!extensionPoint){
		Runtime.warn("Unknown extension point: "+name);
		return;
	}
	
	return extensionPoint.execute(params);
};
GLOBALS.executeExtensions := Util.executeExtensions; //! \deprecated global alias


