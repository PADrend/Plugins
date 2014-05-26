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

/*! Can be added to a GUI.Component object. The component's onMouseButton method is called
	if a mouse button is pressed or released over the component. The onMouseButton
	is initialized as GUI.ChainedEventHandler. Further functions can be added using '+='.
	The parameter of the onMouseButton is the event (ExtObject: $button, $pressed, $type, $x ,$y)
	\see GUI.ChainedEventHandler
	\code
		myComponent.onMouseButton += fn(evt){	print_r(evt._getAttributes());	return CONTINUE;	};
	\endcode
*/
GUI.MouseButtonListenerTrait := new Traits.GenericTrait("GUI.MouseButtonListenerTrait");

var t = GUI.MouseButtonListenerTrait;
t.attributes.onMouseButton @(init) := GUI.ChainedEventHandler;
t.onInit += fn(GUI.Component c){
	gui.enableMouseButtonListener(c);
};

return t;
