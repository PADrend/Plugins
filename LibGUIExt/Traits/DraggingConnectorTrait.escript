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
 
/*! Can be added to a GUI.Component object having the GUI.DraggingMarkerTrait.
	Shows a connector between the dragged component and the dragging marker.
	Adds the following methods:
	
	*	Connector|Void Component.getDraggingConnector()

	Example:
		\code
			Std.Traits.addTrait(myComponent,GUI.DraggableTrait);
			Std.Traits.addTrait(myComponent,GUI.DraggingConnectorTrait);
		\endcode

	\note If you want to query the component under the cursor during dragging, you have to temporarily disable the connector.
		\code
			myComponent.onDrag += fn(evt){
				getDraggingMarker().setEnabled(false);
				getDraggingConnector().setEnabled(false);
				var c = (gui.getComponentAtPos(gui.screenPosToGUIPos( [evt.x,evt.y] )));
				// ...
				
				getDraggingMarker().setEnabled(true);
				getDraggingConnector().setEnabled(true);
			};
		\endcode
		
	Example for customizeing the connector:
	\code
		myComponent.onStartDragging += fn(evt){
			getDraggingConnector().addProperty(
				new GUI.ShapeProperty(GUI.PROPERTY_CONNECTOR_LINE_SHAPE,gui._createStraightLineShape(new Util.Color4f(0,0,1,0.3),3)));
		};
	\endcode

	\see Requires GUI.DraggingMarkerTrait
	\see GUI.DraggableTrait
*/
var t = new Std.Traits.GenericTrait("GUI.DraggingConnectorTrait");
static DraggingMarkerTrait = module('./DraggingMarkerTrait');

t.attributes.getDraggingConnector ::= fn(){
	return isSet($_draggingMarker_connector) ? _draggingMarker_connector : void;
};
t.onInit += fn(GUI.Component c){
	//! \see GUI.DraggingMarkerTrait
	Std.Traits.requireTrait(c,DraggingMarkerTrait);

	
	//! \see GUI.DraggableTrait
	c.onStartDragging += fn(evt){
		var connector = gui.createConnector();
		connector.setFlag( GUI.ALWAYS_ON_TOP );
		gui.registerWindow( connector );
		
		connector.setFirstComponent( this );
		connector.setSecondComponent( this.getDraggingMarker()); //! \see GUI.DraggingMarkerTrait
		
		this._draggingMarker_connector := connector;
	};
	//! \see GUI.DraggableTrait
	c.onStopDragging += fn(){
		var connector = _draggingMarker_connector;
		if(connector){
			gui.unregisterWindow( connector );
			gui.markForRemoval( connector );
			_draggingMarker_connector = void;
		}
	};
	//! \see GUI.DraggableTrait
	c.onDrag += fn(evt){
		var connector = _draggingMarker_connector;
		var marker = this.getDraggingMarker(); //! \see GUI.DraggingMarkerTrait
		if(connector&&marker){
			connector.invalidateLayout(); // this is required to update the connector
		
			// correct the direction if necessary.
			var left;
			var right;
			if(this.getDraggingMarker().getPosition().x() < this.getAbsPosition().x()){
				left = this.getDraggingMarker();
				right = this;
			}else{
				left = this;
				right = this.getDraggingMarker();
			}
			if(left != connector.getFirstComponent()){
				connector.setFirstComponent( left);
				connector.setSecondComponent( right);
			}
		}
	};
};

GUI.DraggingConnectorTrait := t;

return t;
