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


/*! Can be added to a GUI.Component object. Show a marker (an arbitrary component) 
	during the dragging of the component at the cursor's position.

	\param markerFactory 	(optional) fn(draggedComponent) -> GUI.Component
								Called to create the marker.
	
	Adds the following methods:
	
	*	Component|Void Component.getDraggingMarker()


	\note If you want to query the component under the cursor during dragging, you have to temporarily disable the marker.
		\code
			myComponent.onDrag += fn(evt){
				getDraggingMarker().setEnabled(false);
				var c = (gui.getComponentAtPos(gui.screenPosToGUIPos( [evt.x,evt.y] )));
				// ...
				
				getDraggingMarker().setEnabled(true);
			};
		\endcode
	
	\note Requires GUI.DraggableTrait
*/
static DraggableTrait = module('./DraggableTrait');

var t = new Traits.GenericTrait("GUI.DraggingMarkerTrait");

//! Get the active marker component or void.
t.attributes.getDraggingMarker ::= fn(){
	return isSet($_draggingMarker_marker) ? _draggingMarker_marker : void;	
};

t.onInit += fn(GUI.Component c, markerFactory = void){
	Traits.requireTrait(c,DraggableTrait);
	
	if(markerFactory)
		c._dragging_markerFactory := markerFactory;
	
	c.onStartDragging += fn(evt){
		var marker;
		this._draggingMarker_relPos := getAbsPosition() - gui.screenPosToGUIPos( [evt.x,evt.y] );

		if(isSet($_dragging_markerFactory) && _dragging_markerFactory){
			marker = gui.create( _dragging_markerFactory(this) );
		}else{
			marker = gui.create({
				GUI.TYPE : GUI.TYPE_CONTAINER,
				GUI.FLAGS : GUI.BACKGROUND,
				GUI.SIZE : [getWidth(),getHeight()]
			});
			marker.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
									gui._createRectShape(new Util.Color4ub(255,255,255,45),new Util.Color4ub(20,20,20,45),true)));
		}
		marker.setFlag( GUI.ALWAYS_ON_TOP );
		this._draggingMarker_marker := marker;


		gui.registerWindow( marker );
		marker.setPosition(getAbsPosition());

	};
	c.onStopDragging += fn(){
		var marker = _draggingMarker_marker;
		if(marker){
			gui.unregisterWindow( marker );
			gui.markForRemoval( marker );
			_draggingMarker_marker = void;
		}
	};
	c.onDrag += fn(evt){
		var marker = _draggingMarker_marker;
		if(marker){
			marker.setPosition( gui.screenPosToGUIPos( [evt.x,evt.y] ) + _draggingMarker_relPos );
		}
	};
};

GUI.DraggingMarkerTrait := t;

return t;
