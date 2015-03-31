/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 
static ContextMenuTrait = module('./ContextMenuTrait');

/*! Adds context menu entries for storing the component's rectangle (position and dimension) in a data wrapper.
	Initially, the position and dimension is adjusted to the position in the data wrapper.
	
	\param Std.DataWrapper	The Std.DataWrapper should contain an Array with [x,y,width,height].

	Adds no public attributes. Adds the ContextMenuTrait if not already present.
	
	\code
		Std.Traits.addTrait(myWindow, Std.module('LibMinSGExt/Traits/StorableRectTrait'), Std.DataWrapper.createFromEntry(someConfig,"someKey",[100,100,320,200]);
	\endcode

*/
GUI.StorableRectTrait := new Std.Traits.GenericTrait("GUI.StorableRectTrait"); 

var t = GUI.StorableRectTrait;
t.onInit += fn(GUI.Component component,Std.DataWrapper rectWrapper){
	if(!Std.Traits.queryTrait(component, ContextMenuTrait))
		Std.Traits.addTrait(component, ContextMenuTrait,200);
	
	
	//! \see GUI.ContextMenuTrait
	component.contextMenuProvider += [component,rectWrapper] => fn(component,rectWrapper){
		return [
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Store component's size and position",
			GUI.TOOLTIP : "Store component's size and position",
			GUI.ON_CLICK : [component,rectWrapper] => fn(component,rectWrapper){
				rectWrapper([component.getPosition().x(),component.getPosition().y(),component.getWidth(),component.getHeight()]);		
				gui.closeAllMenus();
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Reset component's size and position.",
			GUI.TOOLTIP : "Reset the component's size and position to the stored values.",
			GUI.ON_CLICK : [component,rectWrapper] => fn(component,rectWrapper){
				var r = rectWrapper();
				component.setPosition(r[0],r[1]);
				component.setSize(r[2],r[3]);
				gui.closeAllMenus();
			}
		}];			
	};

	var r = rectWrapper();
	component.setPosition(r[0],r[1]);
	component.setSize(r[2],r[3]);
};

return t;
