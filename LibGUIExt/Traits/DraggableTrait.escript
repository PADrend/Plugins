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

static MouseButtonListenerTrait = module('./MouseButtonListenerTrait');

/*! Can be added to a GUI.Component object. Makes the component draggable. 
	\param mouseButtons 	(optional) Array of usable mouse buttons (Util.UI.MOUSE_BUTTON_???)
							Default is [Util.UI.MOUSE_BUTTON_LEFT, Util.UI.MOUSE_BUTTON_RIGHT]
	Adds the following methods:
	
	*	void Component.onDrag(event)			(extendable Std.MultiProcedure)
	*	void Component.onDrop(event)			(extendable Std.MultiProcedure)
	*	void Component.onStartDragging(event)	(extendable Std.MultiProcedure)
	*	void Component.onStopDragging()			(extendable Std.MultiProcedure)
	*	void Component.stopDragging()
				Can be called stop the dragging process. onStopDragging() is called, but onDrop(...) is skipped.
	
	\note Adds the MouseButtonListenerTrait if not already present.
	\note the coordinates stored in the events are screenPositions (and not guiPositions)
*/
var t = new Std.Traits.GenericTrait("GUI.DraggableTrait");
t.attributes.onDrag @(init) := Std.MultiProcedure;				// fn(evt)
t.attributes.onDrop @(init) := Std.MultiProcedure;				// fn(evt)
t.attributes.onStartDragging @(init) := Std.MultiProcedure;		// fn(evt)
t.attributes.onStopDragging @(init) := Std.MultiProcedure;		// fn(){...}

//! call to end the dragging.
t.attributes.stopDragging ::= fn(){
	if(this.isSet($_dragging_active) && _dragging_active){
		_dragging_active = false;
		onStopDragging();
	}
	return this;
};

t.attributes._dragging_possibleButtons @(private) := void;

t.onInit += fn(GUI.Component c,Array mouseButtons = [Util.UI.MOUSE_BUTTON_LEFT, Util.UI.MOUSE_BUTTON_RIGHT] ){
	//! \see MouseButtonListenerTrait
	Std.Traits.assureTrait(c, MouseButtonListenerTrait);

	(c->fn(mouseButtons){ _dragging_possibleButtons = mouseButtons;	})(mouseButtons.clone());
	c.onMouseButton += fn(evt){
		if(!evt.pressed || !_dragging_possibleButtons.contains(evt.button))
			return $CONTINUE;
		
		this._dragging_button @(private) := evt.button;
		this._dragging_active @(private) := true;
		
		onStartDragging(evt);
		if(!_dragging_active) // onStartDragging may disable the dragging!
			return $CONTINUE; // event not handled
		
		// register global mouse button listener
		gui.onMouseButton += this->fn(evt){
			if(this.isDestroyed() || !_dragging_active)
				return $REMOVE;
			
			if(evt.button == _dragging_button){
				stopDragging();
							
				var evt2 = evt.clone();
				var screenPos = gui.guiPosToScreenPos( [evt2.x,evt2.y] );
				evt2.x = screenPos.x();
				evt2.y = screenPos.y();
				this.onDrop(evt2);
			}
		};

		gui.onMouseMove += this->fn(evt){
			if(this.isDestroyed() || !this._dragging_active)
				return $REMOVE;
			var evt2 = evt.clone();
			var screenPos = gui.guiPosToScreenPos( [evt2.x,evt2.y] );
			evt2.x = screenPos.x();
			evt2.y = screenPos.y();
			this.onDrag(evt2);
		};
		return $BREAK; // event handled
	};
};

GUI.DraggableTrait := t;

return t;
//----------------------------------------
