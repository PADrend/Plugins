/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


/*! Marks the component as refreshable.
	\param childDescription	(optional)	if set, on refresh, the children are destroyed and recreated using the description.
	
	Adds the following public attributes:
	- refresh()		Destroy the container's old children and re-create them. 
					\note Must be overwritten by the user if no childDescription is passed as trait parameter.

	Offers the following helper functions:
	- refreshContainer( GUI.Component c ) 	Search a refreshable enclosing container of c (or c itself) and refresh it.
					If no refreshable container is found, the function returns without notice. 
*/
static t = new Traits.GenericTrait("GUI.RefreshableContainerTrait"); 

t.refreshContainer := fn( GUI.Component c ){
	for( ; c; c=c.getParentComponent() ){
		if( Traits.queryTrait(c, t) ){
			c.refresh();
			break;
		}
	}
};


t.attributes.refresh := fn(){Runtime.exception("This method is not implemented.");};	// Std.ABSTRACT_METHOD;
	
t.onInit += fn(GUI.Container container, contentDescription = void){
	if(void!==contentDescription){
		container.refresh := [contentDescription] => fn(contentDescription){
			if(this.isDestroyed()){
				return $REMOVE;
			}else{
				this.destroyContents();
				foreach( gui.createComponents(contentDescription) as var c)
					this += c;
			}
		};
	}
};

return t;
