/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] Util/Listener.escript
 **
 **  Notifier(or Listener) support.
 **/

 // static
GLOBALS.Notifier := new Type;

Notifier.listener := void;

//! (ctor)
Notifier._constructor ::= fn(){
	this.listener = new Map;
};

Notifier.add ::= fn(type,l){
    if(!this.listener[type]){
        this.listener[type]=[];
    }
    this.listener[type].pushBack(l);
};

Notifier.remove ::= fn(type,l){
    if(!this.listener[type])
        return;
    this.listener[type].removeIndex(this.listener[type].indexOf(l));
};

Notifier.clear ::= fn(type){
    if(!this.listener[type])
        return;
    this.listener[type].clear();
};

/*! Calls each listener registered for the given _type_.
	If a listener returns false (exactly the value false, not void) it is removed. */
Notifier.notify ::= fn(type,data = void){
    var listener = this.listener[type];
    if(listener){
		var toRemove = [];
        foreach(listener as var l){
			var result = l(type,data);
			if( result===false )
				toRemove += l;
        }
        foreach(toRemove as var l){
			this.remove(type,l);
        }
    }
};


// global listener
GLOBALS.Listener := new Notifier;
return Listener;
