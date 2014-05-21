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
/****
 **	[PADrend] LibGUIExt/ComponentTraits.escript
 **
 ** Collection of traits that can be used for 
 **/

loadOnce(__DIR__"/GUI_Utils.escript"); // for GUI.ChainedEventHandler

/*! Binds the component's background color (and optionally border color) to a DataWarpper.
	\param bgColor		A DataWrapper with an Array of four floats representing the background color.
	\param lineColor	(optional)	A DataWrapper with an Array of four floats representing the line color.
	
	Adds no public methods to the component.
	
	\note Internally uses a RectShape. For this to be visibile, the component's GUI.BORDER-flag
		has to be enabled!
*/
GUI.AdjustableBackgroundColorTrait := new Traits.GenericTrait("GUI.AdjustableBackgroundColorTrait"); 
{
	var t = GUI.AdjustableBackgroundColorTrait;
	
	t.attributes._backgroundProperty @(private) := void;
	t.attributes._bgColor @(private) := GUI.NO_COLOR;
	t.attributes._lineColor @(private) := GUI.NO_COLOR;
	t.attributes._refreshBGColor @(private) := fn(){
		this._backgroundProperty.setShape(gui._createRectShape(_bgColor, _lineColor, true));
	};
	
	t.onInit += fn(GUI.Component component,DataWrapper bgColor,[DataWrapper,void] lineColor=void){
		component._backgroundProperty := new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,GUI.NULL_SHAPE);
		component.addProperty(component._backgroundProperty);
		
		bgColor.onDataChanged += component->fn(values){
			if(this.isDestroyed())
				return $REMOVE;
			this._bgColor = new Util.Color4f(values);
			this._refreshBGColor();
		};
		bgColor.forceRefresh();
		if(lineColor){
			lineColor.onDataChanged += component->fn(values){
				if(this.isDestroyed())
					return $REMOVE;
				this._lineColor = new Util.Color4f(values);
				this._refreshBGColor();
			};
			lineColor.forceRefresh();
		}
	};
}


/*! Adds a configurable right-click menu to the component.
	\param menu width 	(optional) the context menu's width.

	Adds the following public attributes:
	
	*	void Component.contextMenuProvider		
				An array that can contain:
					- ComponentIds (Strings) (using the component as context)
					- functions returning an array of entry descriptions
					- an array of entry descriptions


	\see GUI.MouseButtonListenerTrait
	\code
		Traits.addTrait(myComponent,GUI.ContextMenuTrait,300); // context menu with 300px width

		// add registered menu entries
		myComponent.contextMenuProvider += "MyPlugin_SomeMenuName";
	
		// add menu entries as array
		myComponent.contextMenuProvider += [ "someEntry" , "someOtherEntry" ];
	
		// add provider function
		myComponent.contextMenuProvider += fn(){	return [ "someEntry","someOtherEntry"]; };
	\endcode
*/
GUI.ContextMenuTrait := new Traits.GenericTrait("GUI.ContextMenuTrait"); 
{
	var t = GUI.ContextMenuTrait;
	t.attributes.contextMenuProvider @(init) := Array;
	t.onInit += fn(GUI.Component c,Number menuWidth = 150){
		if(!Traits.queryTrait(c,GUI.MouseButtonListenerTrait))
			Traits.addTrait(c,GUI.MouseButtonListenerTrait);
		
		//! \see GUI.MouseButtonListenerTrait
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
}


/*! Can be added to a GUI.Component object. Makes the component draggable. 
	\param mouseButtons 	(optional) Array of usable mouse buttons (Util.UI.MOUSE_BUTTON_???)
							Default is [Util.UI.MOUSE_BUTTON_LEFT, Util.UI.MOUSE_BUTTON_RIGHT]
	Adds the following methods:
	
	*	void Component.onDrag(event)			(extendable MultiProcedure)
	*	void Component.onDrop(event)			(extendable MultiProcedure)
	*	void Component.onStartDragging(event)	(extendable MultiProcedure)
	*	void Component.onStopDragging()			(extendable MultiProcedure)
	*	void Component.stopDragging()
				Can be called stop the dragging process. onStopDragging() is called, but onDrop(...) is skipped.
	
	\note Adds the GUI.MouseButtonListenerTrait if not already present.
*/
GUI.DraggableTrait := new Traits.GenericTrait("GUI.DraggableTrait");
{
	var t = GUI.DraggableTrait;
	t.attributes.onDrag @(init) := MultiProcedure;				// fn(evt)
	t.attributes.onDrop @(init) := MultiProcedure;				// fn(evt)
	t.attributes.onStartDragging @(init) := MultiProcedure;		// fn(evt)
	t.attributes.onStopDragging @(init) := MultiProcedure;		// fn(){...}
	
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
		//! \see GUI.MouseButtonListenerTrait
		if(!Traits.queryTrait(c,GUI.MouseButtonListenerTrait))
			Traits.addTrait(c,GUI.MouseButtonListenerTrait);
	
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
					onDrop(evt);
				}
			};

			gui.onMouseMove += this->fn(evt){
				if(this.isDestroyed() || !_dragging_active)
					return $REMOVE;
				onDrag(evt);
			};
			return $BREAK; // event handled
		};
	};
}

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
				var c = (gui.getComponentAtPos(new Geometry.Vec2(evt.x,evt.y)));
				// ...
				
				getDraggingMarker().setEnabled(true);
			};
		\endcode
	
	\note Requires GUI.DraggableTrait
*/
GUI.DraggingMarkerTrait := new Traits.GenericTrait("GUI.DraggingMarkerTrait");
{
	var t = GUI.DraggingMarkerTrait;
	
	//! Get the active marker component or void.
	t.attributes.getDraggingMarker ::= fn(){
		return isSet($_draggingMarker_marker) ? _draggingMarker_marker : void;	
	};
	
	t.onInit += fn(GUI.Component c, markerFactory = void){
		Traits.requireTrait(c,GUI.DraggableTrait);
		
		if(markerFactory)
			c._dragging_markerFactory := markerFactory;
		
		c.onStartDragging += fn(evt){
			var marker;
			this._draggingMarker_relPos := getAbsPosition() - new Geometry.Vec2(evt.x,evt.y);

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
				marker.setPosition(evt.x+_draggingMarker_relPos.getX(),evt.y+_draggingMarker_relPos.getY());
			}
		};
	};
}

/*! Can be added to a GUI.Component object having the GUI.DraggingMarkerTrait.
	Shows a connector between the dragged component and the dragging marker.
	Adds the following methods:
	
	*	Connector|Void Component.getDraggingConnector()

	Example:
		\code
			Traits.addTrait(myComponent,GUI.DraggableTrait);
			Traits.addTrait(myComponent,GUI.DraggingConnectorTrait);
		\endcode

	\note If you want to query the component under the cursor during dragging, you have to temporarily disable the connector.
		\code
			myComponent.onDrag += fn(evt){
				getDraggingMarker().setEnabled(false);
				getDraggingConnector().setEnabled(false);
				var c = (gui.getComponentAtPos(new Geometry.Vec2(evt.x,evt.y)));
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
GUI.DraggingConnectorTrait := new Traits.GenericTrait("GUI.DraggingConnectorTrait");
{
	var t = GUI.DraggingConnectorTrait;
	
	t.attributes.getDraggingConnector ::= fn(){
		return isSet($_draggingMarker_connector) ? _draggingMarker_connector : void;
	};
	t.onInit += fn(GUI.Component c){
		//! \see GUI.DraggingMarkerTrait
		Traits.requireTrait(c,GUI.DraggingMarkerTrait);
	
		
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
}

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
{
	var t = GUI.MouseButtonListenerTrait;
	t.attributes.onMouseButton @(init) := GUI.ChainedEventHandler;
	t.onInit += fn(GUI.Component c){
		gui.enableMouseButtonListener(c);
	};
}

/*! Adds context menu entries for storing the component's rectangle (position and dimension) in a data wrapper.
	Initially, the position and dimension is adjusted to the position in the data wrapper.
	
	\param DataWrapper	The DataWrapper should contain an Array with [x,y,width,height].

	Adds no public attributes. Adds the GUI.ContextMenuTrait if not already present.
	
	\code
		Traits.addTrait(myWindow,GUI.StorableRectTrait, DataWrapper.createFromConfig(someConfig,"someKey",[100,100,320,200]);
	\endcode

*/
GUI.StorableRectTrait := new Traits.GenericTrait("GUI.StorableRectTrait"); 
{
	var t = GUI.StorableRectTrait;
	t.onInit += fn(GUI.Component component,DataWrapper rectWrapper){
		if(!Traits.queryTrait(component,GUI.ContextMenuTrait))
			Traits.addTrait(component,GUI.ContextMenuTrait,200);
		
		
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
}
//----------------------------------------
