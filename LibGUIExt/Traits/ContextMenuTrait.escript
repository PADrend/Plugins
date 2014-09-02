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

static MouseButtonListenerTrait = Std.require('LibGUIExt/Traits/MouseButtonListenerTrait');

/*! Adds a configurable right-click menu to the component.
	\param menu width 	(optional) the context menu's width.

	Adds the following public attributes:
	
	*	void Component.contextMenuProvider		
				An array that can contain:
					- ComponentIds (Strings) (using the component as context)
					- functions returning an array of entry descriptions
					- an array of entry descriptions


	\see MouseButtonListenerTrait
	\code
		Traits.addTrait(myComponent, Std.require('LibUtilExt/Traits/ContextMenuTrait'),300); // context menu with 300px width

		// add registered menu entries
		myComponent.contextMenuProvider += "MyPlugin_SomeMenuName";
	
		// add menu entries as array
		myComponent.contextMenuProvider += [ "someEntry" , "someOtherEntry" ];
	
		// add provider function
		myComponent.contextMenuProvider += fn(){	return [ "someEntry","someOtherEntry"]; };
	\endcode
*/
var t = new Traits.GenericTrait("GUI.ContextMenuTrait"); 

t.attributes.contextMenuProvider @(init) := Array;
t.onInit += fn(GUI.Component c,Number menuWidth = 150){
	Traits.assureTrait(c, MouseButtonListenerTrait);
	
	//! \see MouseButtonListenerTrait
	c.onMouseButton += [menuWidth] => fn(menuWidth, buttonEvent){
		if(buttonEvent.button == Util.UI.MOUSE_BUTTON_RIGHT && buttonEvent.pressed) {
			var absPos = new Geometry.Vec2(buttonEvent.x, buttonEvent.y);
			var entries = [];
			foreach(this.contextMenuProvider as var p)
				entries.append( gui.createComponents({
										GUI.TYPE : GUI.TYPE_MENU_ENTRIES,
										GUI.PROVIDER : p,
										GUI.WIDTH : menuWidth}));
														
			gui.openMenu(absPos, entries, menuWidth);
			return $BREAK;
		}
		return $CONTINUE;
	};
};

return t;
