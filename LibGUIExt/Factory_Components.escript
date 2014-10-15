/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[LibGUIExt] Factory_Components.escript
 **/
loadOnce(__DIR__+"/GUI_Utils.escript");
loadOnce(__DIR__+"/FactoryConstants.escript");


/*! Creates a gui component.
	The result is depending on the type of @p entry:
	- GUI.Component: the Component itself
	- "----": A horizontal delimiter
	- String: A label with that string (if it begins end ends with "*", the label is formatted as a headline)
	- Map: A description of the component. \see _createComponentFromDescription(...)	*/
GUI.GUI_Manager.create ::= fn(entry,entryWidth=false,insideMenu=false){
    if(entry ---|> GUI.Component){
        return entry;
    }else if(entry---|>Map){
    	return _createComponentFromDescription(entry,entryWidth,insideMenu);
    } else if(entry === GUI.H_DELIMITER){ // }else  if(entry---|>Identifier){ \todo
    	return this.createDelimiter();
    }else if(entry === GUI.NEXT_COLUMN){
    	return this._createPanelNextColumn(0);
    }else if(entry === GUI.NEXT_ROW){
    	return this._createPanelNextRow(0);
    } else if(entry=='----'){
//       return this.createLabel(entryWidth,1,"",GUI.RAISED_BORDER);
       return this.createDelimiter();
    } else {
        var text=entry.toString();
        if(text.beginsWith('*') && text.endsWith('*')){
        	text=entry.substr(1,-1);
        	if(insideMenu){
				var label=entryWidth ? this.createLabel(entryWidth,15,text,GUI.BACKGROUND) : this.createLabel(text) ;
				label.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,GUI.BUTTON_SHAPE_TOP));
				label.setTextStyle (GUI.TEXT_ALIGN_CENTER|GUI.TEXT_ALIGN_MIDDLE);
				return label;
        	}else{
				return this.createHeader(text);
        	}
        }
        else
            return this.createLabel(entry);
    }
};
GUI.GUI_Manager.createComponent ::= GUI.GUI_Manager.create; // alias

/*! Creates a gui component from a description.
	\note This function is normally not called directly, but implicitly by gui.create(...)

	--------------------------
	General attributes:


		GUI.COLOR : 	(optional) Util.Color4f text color
		GUI.CONTENTS : 	(optional) [ components* ] An array of components to be added as children to
						the component.
						\note Use only for components where children can be added (Container, Panel, 
							Button, Window, ...). For other components, the behavior is undefined!
		GUI.CONTEXT_MENU_PROVIDER : (optional) a function returning an array of menu entries.
						The function is called and the menu is opened if the right mouse button is pressed
						on the component.
						\note does not work together with ON_MOUSE_BUTTON
						\note might eventually be changed to react on real-clicks (and not presses)
		GUI.CONTEXT_MENU_WIDTH : (optional) The width of the menu (see CONTEXT_MENU_PROVIDER)
		GUI.FLAGS : 	(optional) additional flags set on the created component
		GUI.FONT : 		(optional) GUI.Font or a name of a font (e.g. GUI.FONT_ID_DEFAULT,GUI.FONT_ID_HEADING)
		GUI.HEIGHT :  	(optional) component's initial height (normally, use SIZE instead)

		GUI.LABEL : 	(optional) label text (not supported by all components)
		GUI.ON_INIT : 		(optional) function which is called on the newly created component after creation with
									the description map as parameter.
		GUI.ON_MOUSE_BUTTON:(optional) Function which is called when a mouse button is pressed or released.
						Signature:   $CONTINUE|$BREAK|$CONTINUE_AND_REMOVE|$BREAK_AND_REMOVE|Void fn(ExtObject evt)
						The parameter contains $button,$pressed,$position,$absPosition.
						e.g. open a menu on a right click:
						GUI.ON_MOUSE_BUTTON : fn(evt){
							if(evt.button != Util.UI.MOUSE_BUTTON_RIGHT){  // only handle right mouse button
								return $CONTINUE;
							}else if(!evt.pressed){ // open menu on button release
								gui.openMenu(evt.absPosition,[ ...menuEntries... ] );
							}
							return $BREAK;
						}
						\note adds the MouseButtonListenerTrait trait.
						\note see GUI.ChainedEventHandler
						
		GUI.POSITION :	(optional) component's position
						Geometry.Vec2(x,y)		Fixed position relative to parent
						or
						[x,y]					Fixed position relative to parent
						or
						[flags, x, y]
						e.g. [GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 0,0]
							align at bottom center
						\note should not be used inside a Panel (use a Container instead)
		GUI.PROPERTIES : (optional) Array of properties added to the component

		GUI.SIZE : 		(optional) component's size
						Geometry.Vec2(width,height)
						or
						[width, height]
						or
						[flags, width, height]
						Flags:
							WIDTH_REL 		Width is given relative to the parents width
												(e.g. 0.5 is 50% of parent's width)
							or WIDTH_ABS 	If positive, the the given value is the component's width.
												If negative, the given value is added to the parent's width
												(e.g. -10 is 10 pixel less width than parent)
							or WIDTH_CHILDREN_REL	Width is given relative to the content's width (always >=1.0)
												(e.g. 1.1 is 110% of the children's width)
							or WIDTH_CHILDREN_ABS	Width is given relative to the content's width (always >=0)
												(e.g. 10 is 10 pixels more than the children's width)
							or WIDTH_FILL_ABS	Stretch the component up to the given number of pixels to the parent's right border.
												(e.g. 27 -> 27 pixels from the component's right border to the parent's right border)
							or WIDTH_FILL_REL	see WIDTH_FILL_ABS but relative

							HEIGHT_REL 		Width is given relative to the parents height
												(e.g. 0.5 is 50% of parent's height)
							or HEIGHT_ABS 	If positive, the the given value is the component's height.
												If negative, the given value is added to the parent's height
												(e.g. -10 is 10 pixel less height than parent)
							or HEIGHT_CHILDREN_REL	Width is given relative to the content's height (always >=1.0)
												(e.g. 1.1 is 110% of the children's height)
							or HEIGHT_CHILDREN_ABS	Width is given relative to the content's height (always >=0)
												(e.g. 10 is 10 pixels mor than the children's height)
							or HEIGHT_FILL_ABS	see WIDTH_FILL_ABS
							or HEIGHT_FILL_REL	see WIDTH_FILL_ABS

						e.g. [GUI.WIDTH_REL|GUI.HEIGHT_ABS , 0.5 ,50 ] 50% of parent's width, 50 px height
						or
						GUI.SIZE_MAXIMIZE		equivalent to [GUI.WIDTH_REL|GUI.HEIGHT_REL, 1.0, 1.0 ]
						or
						GUI.SIZE_MINIMIZE		equivalent to [GUI.WIDTH_CHILDREN_ABS|GUI.HEIGHT_CHILDREN_ABS, 0, 0 ]
						\note should not be used for components inside a Panel (use a Container instead)
		GUI.TOOLTIP : 	(optional) tooltip-text
		GUI.WIDTH :  	(optional) initial component's width (normally, use SIZE instead)

		--------
		Drag and Drop
		
		GUI.DRAGGING_ENABLED : (optional) if true, the component can be dragged using the following propteries.
						\note adds the GUI.DraggableTrait to the component.
		
		
		GUI.DRAGGING_BUTTONS : (optional) Array of Util.UI mouse button constants.
						If set, these buttons will be accepted for dragging.
						Default is [Util.UI.MOUSE_BUTTON_LEFT, Util.UI.MOUSE_BUTTON_RIGHT]
						\note needs GUI.DRAGGING_ENABLED

		GUI.DRAGGING_MARKER : (optional) true or a function for creating a drag marker component fn(Component) -> Component
						If true, the default marker is used.
						\see GUI.DraggingMarkerTrait for details.
						\note needs GUI.DRAGGING_ENABLED
		GUI.DRAGGING_CONNECTOR : (optional) If true, a dragging connector is used.
						\see GUI.DraggingConnectorTrait for details.
						\note needs GUI.DRAGGING_MARKER
						\note needs GUI.DRAGGING_ENABLED
		GUI.ON_DRAG : (optional) Function which is called when the mouse is moved while a button is pressed.
						The parameter is the mouse motion event.
						e.g. : simple button which can be moved inside the parent component (if it is not auto-layouted)
						{ 	GUI.TYPE : GUI.TYPE_BUTTON,	GUI.LABEL : "Drag me!",
							GUI.DRAGGING_ENABLED : true,
							GUI.ON_DRAG : fn(evt){
								this.setPosition(this.getPosition() + new Geometry.Vec2(evt.deltaX, evt.deltaY));
								return true;
						}}
						\note needs GUI.DRAGGING_ENABLED
		GUI.ON_DROP : (optional) Function which is called when a component is dropped after dragging.
						The parameter is the mouse motion event.
						\note needs GUI.DRAGGING_ENABLED
		GUI.ON_START_DRAGGING : (optional) Function which is called when a component is started dragging.
						The parameter is the mouse button event.
						\note To prevent the dragging, call stopDragging().
						\note needs GUI.DRAGGING_ENABLED
		GUI.ON_STOP_DRAGGING : (optional) Parameter less function which is called when a component is stopped dragging.
						\note this function is always called eventually after a dragging started while ON_DROP may be skipped.
						\note needs GUI.DRAGGING_ENABLED

	--------------------------
	Attributes for all input-types

	There are several possibilities for setting the value:

		GUI.DATA_VALUE : 		initial value
		GUI.ON_DATA_CHANGED : 	(optional) function that is executed whenever the value changed.

	OR (to directly connect the input to an attribute)

		GUI.DATA_OBJECT : 		Connected Object
		GUI.DATA_ATTRIBUTE : 		Connected Object's attribute name or id
		GUI.DATA_REFRESH_GROUP : (optional) GUI.RefreshGroup
						The component's data can be refreshed by refreshGroup.refresh() and
						all compontents in the same refreshGroup which are connected to the same attribute are synced automatically

	OR give a function that provides the data

		GUI.DATA_PROVIDER			function that returns the initial value and is called when the 'refresh'-function is called (which is
									automatically created if an DATA_PROVIDER is given).
		GUI.DATA_REFRESH_GROUP		(optional) if an RefreshGroup is given, the component's 'refresh'-function is registered.
		GUI.ON_DATA_CHANGED 		(optional) same functionality as in the other case


	OR connect to a data wrapper
		GUI.DATA_WRAPPER			An instance of DataWrapper (see DataWrapper.escript)
		GUI.DATA_REFRESH_GROUP		(optional) if an RefreshGroup is given, the component's 'refresh'-function is registered.
		GUI.ON_DATA_CHANGED 		(optional) same functionality as in the other case

		example to connect a slider to a config value:

			var myVariable = DataWrapper.createFromConfig( someConfigManager,'keyOfConfigValue', 1.0 ); // use this wrapper wherever you use the config value.
			//...
			panel += {
				GUI.TYPE  : GUI.TYPE_RANGE,
				GUI.LABEL : "My Variable",
				GUI.RANGE : [0,10],
				GUI.DATA_WRAPPER : myVariable
			};
	--------------------------
	Type specific attributes

	Button
		GUI.TYPE :				GUI.TYPE_BUTTON
		GUI.ON_CLICK : 			onClick-function
		GUI.ICON:  				(optional) name, filename of an icon or an GUI.Icon/Image object.
		GUI.ICON_COLOR:  		(optional) base color of the icon (default is WHITE)
		GUI.BUTTON_SHAPE : 		(optional) a GUI.AbstractShape used for the button
		GUI.TEXT_ALIGNMENT : 	(optional) alignment of the text e.g. (GUI.TEXT_ALIGN_LEFT | GUI.TEXT_ALIGN_MIDDLE) or (GUI.TEXT_ALIGN_CENTER | GUI.TEXT_ALIGN_BOTTOM)

	Button for critical actions (requiering an additional click)
		GUI.TYPE : 				GUI.TYPE_CRITICAL_BUTTON
		GUI.REQUEST_MESSAGE : 	(optional) The text of the message appearing after the click. Per
									default, the LABEL of the button is used.
		All other attribute correspond to those of a normal button.

	Bit (input)
		(checkbox bound to a single bit. Only in combination with GUI.DATA_OBJECT & GUI.DATA_ATTRIBUTE.)
		GUI.TYPE :				GUI.TYPE_BIT
		GUI.DATA_BIT : 			Number (bitmask for the bound bit)

	Checkbox (input)
		GUI.TYPE :				GUI.TYPE_BOOL

	Collapsible container		An container consisting of a header and a content area. The header contains a +/- button
								to collapse or open the content area. 
								- The content area's components are destroyed when the container is collapsed and created on demand.
								- The specified SIZE of the component refers to the header -- per default its width fills
									the parent's width and the height is adjusted by the header's content.
								- The header and the content area both have a flow-layout.
		GUI.TYPE				GUI.TYPE_COLLAPSIBLE_CONTAINER
		GUI.LABEL				The label in the container's header
		or
		GUI.HEADER				A components description for components in the header.
		GUI.COLLAPSED			(optional) Bool or a DataWrapper 
		GUI.CONTENTS			the contents

	ColorSelector (input)
		GUI.TYPE :				GUI.TYPE_COLOR

	Container
		GUI.TYPE :				GUI.TYPE_CONTAINER Simple container
		GUI.LAYOUT :			(optional) Content layouter: e.g. GUI.LAYOUT_FLOW, GUI.LAYOUT_TIGHT_FLOW or e.g. "(new GUI.FlowLayouter()).setMargin(2).setPadding(15)"
		GUI.CONTENTS : 			(optional) [ components* ] or 'componentId' or factoryFunction
									Array of child components

	Combobox (input)
		GUI.TYPE :				GUI.TYPE_TEXT
		GUI.OPTIONS : 			[ options* ]
		or
		GUI.OPTIONS_PROVIDER : 	function returning an array of options

	Dropdown (input)
		GUI.TYPE :				GUI.TYPE_SELECT
		GUI.OPTIONS : 			[ [optionValue,optionText(,optionSelectedText(,optionTooltip)) ]* ]

	File (input)
		GUI.TYPE :				GUI.TYPE_FILE
		GUI.ENDINGS : 			(optional) Array. E. g.  ['.jpg','.bmp']
		GUI.DIR : 				(optional) initial folder

	Folder (input)
		GUI.TYPE :				GUI.TYPE_FOLDER
		GUI.ENDINGS : 			Array. E. g.  ['.jpg','.bmp']
		GUI.DIR : 				(optional) initial folder

	Icon (or image)
		GUI.TYPE :				TYPE_ICON
		GUI.ICON : 				name, filename of an icon or an GUI.Icon/Image object.
		GUI.ICON_COLOR :  		(optional) base color of the icon (default is WHITE)
	Label
		GUI.TYPE :				TYPE_LABEL
		GUI.LABEL : 			text
		GUI.TEXT_ALIGNMENT : 	(optional) alignment of the text e.g. (GUI.TEXT_ALIGN_LEFT | GUI.TEXT_ALIGN_MIDDLE) or (GUI.TEXT_ALIGN_CENTER | GUI.TEXT_ALIGN_BOTTOM)
		GUI.DATA_WRAPPER : 		(optional) DataWrapper specifying dynamic text.

	ListView (input)
		GUI.TYPE :				GUI.TYPE_LIST
		GUI.OPTIONS : 			[ option* ]
								One option may be:
									- A component (or component description)
									- An array [optionValue, optionComponentDescription]
		GUI.LIST_ENTRY_HEIGHT : 	(optional) height of the entries.
		GUI.FLAGS : 			(optional)
								This component supports the following additional flags:
									GUI.AT_LEAST_ONE_MARKING, AT_MOST_ONE_MARKING

	Menu
		GUI.TYPE :				GUI.TYPE_MENU
		GUI.MENU_WIDTH : 		(optional) width of the menu (default 100)
		GUI.ICON:  				(optional) name, filename of an icon or an GUI.Icon/Image object.
		GUI.ICON_COLOR:  		(optional) base color of the icon (default is WHITE)
		GUI.MENU_CONTEXT : 		(optional) an arbitrary object (except void) given as parameter to all provider functions 
								called to create the menu entries. 
								If this value is set, all providers HAVE to accept a parameter!

		GUI.MENU : 				an registered menu's id, or an array, or a callback fn( [context] ) -> Array


	Next column marker in Panel
		GUI.TYPE :				GUI.TYPE_NEXT_COLUMN
		GUI.SPACING :				(optional) skipped space

	Next row marker in Panel
		GUI.TYPE :				GUI.TYPE_NEXT_ROW
		GUI.SPACING :			(optional) skipped space

	Panel (A container with scrollbars and flow layout)
		GUI.TYPE :				GUI.TYPE_PANEL
		GUI.CONTENTS : 			(optional) [ components* ]
								Array of child components,
		GUI.PANEL_MARGIN :		(optional) distance of the components from the border (only for auto layout)
		GUI.PANEL_PADDING :		(optional) distance between components (only for auto layout)

	RadioButtonSet (input)
		GUI.TYPE :				GUI.TYPE_RADIO
		GUI.OPTIONS : 			[ [optionValue,optionText]* ]

	Slider (input)
		GUI.TYPE :				GUI.TYPE_RANGE
		GUI.RANGE : 			[ min,max ]
		GUI.RANGE_STEPS : 		(optional) numSteps
		GUI.RANGE_STEP_SIZE : 	(optional) automatically set numSteps according to step size and range.
		GUI.RANGE_FN 			(optional) function mapping the slider step to the real number value. E.g. fn(v){ return (10).pow(v); }
		GUI.RANGE_INV_FN 		(optional) function mapping a number value to a step on the slider. E.g. fn(v){ return (v).log(10); }
		GUI.RANGE_FN_BASE :		(optional) Single number that is used to set default functions for mapping and inverse mapping.
								The mapping function will be set to fn(v) { return (@p base).pow(v); }
								The inverse mapping function will be set to fn(v) { return (v).log(@c base); }
								This overrides GUI.RANGE_FN and GUI.RANGE_INV_FN.
		GUI.OPTIONS				[ option* ] default values

	Tab
		GUI.TYPE : 				TYPE_TAB
		GUI.LABEL : 			tab's title
		GUI.TAB_CONTENT : 		the Container containing the tab's content

	Tabblad or TabbedPanel
		GUI.TYPE : 				TYPE_TABBED_PANEL
								Example for adding a tab:
								var tabbedPanel = gui.create({	GUI.TYPE : GUI.TYPE_TABBED_PANEL });
								tabbedPanel.addTab("Tab Title",{
									GUI.TYPE : GUI.TYPE_CONTAINER,
									GUI.SIZE : GUI.SIZE_MAXIMIZE,
									GUI.LAYOUT : GUI.LAYOUT_FLOW,
									GUI.CONTENTS : ["Some Text..."]
								},"Some optional tooltip");

	Textarea (input)
		GUI.TYPE :				GUI.TYPE_MULTILINE_TEXT

	Textfield (input)
		GUI.TYPE :				GUI.TYPE_TEXT

	Textfield for a number (input)
		GUI.TYPE :				GUI.TYPE_NUMBER
		GUI.OPTIONS : 			[ options* ]
		or
		GUI.OPTIONS_PROVIDER : 	function returning an array of options

	TreeView
		GUI.TYPE :				GUI.TYPE_TREE
		GUI.OPTIONS : 			[ option* ]

	TreeView SubGroup
		GUI.TYPE :				GUI.TYPE_TREE_GROUP
								\note to create an initially collapsed entry, add GUI.FLAGS : GUI.COLLAPSED_ENTRY
		GUI.LABEL :				The label of the entry
		GUI.OPTIONS : 			[ option* ]
								\note if no label is given, the first option is the representative of the group
		or
		GUI.OPTIONS_PROVIDER : 	function returning an array of options

	Window
		GUI.TYPE :				GUI.TYPE_WINDOW
		GUI.ON_WINDOW_CLOSED	(optional) Handler called after the window has been closed.
*/

GUI.GUI_Manager._createComponentFromDescription @(private) ::= fn(Map description,width = false,insideMenu=false){

	var component = void; 			//< main component
	var inputComponent = void; 		//< the input (sub-)component
	var skipAddingContents = void;	//< if true, the componentFactory itself handles the CONTENTS part of the description
	// -------------------
	// preparations (? temporary ?)

	// add dataWrapper's options
	if( description[GUI.DATA_WRAPPER] && description[GUI.DATA_WRAPPER].hasOptions() ){
		description[GUI.OPTIONS_PROVIDER] = description[GUI.DATA_WRAPPER] -> fn(){	return getOptions();	};
	}

	// set initial options (even if optionProvider is not supported explicitly)
	if( description[GUI.OPTIONS_PROVIDER] && 
			description[GUI.TYPE] != GUI.TYPE_TREE_GROUP ){ // unfortunate special case: options for a closed tree group should only be be created on demand.
		description[GUI.OPTIONS] = description[GUI.OPTIONS_PROVIDER]();
	}

	// -------------------
	// I. create component
	{
		// prepare factory input
		var input = new ExtObject();
		input.description := description;
		input.insideMenu := insideMenu;

		// component's label
		var label = description[GUI.LABEL];
		if(!label)
			label = description['name']; // (deprecated)
		input.label := label;

		 // component size
		input.height := description[GUI.HEIGHT] ? description[GUI.HEIGHT] : 15;
		input.width := description[GUI.WIDTH] ? description[GUI.WIDTH] : width;

		// component type
		var type = description[GUI.TYPE];
		if(!type){ // if no type is given, try to identify the type by the given entries
			if( description[GUI.ON_CLICK] ){
				type = GUI.TYPE_BUTTON;
			} else if( description['input'] ){ // (deprecated)
				type = description['input'];
			} else if( description[GUI.MENU] ){
				type = GUI.TYPE_MENU;
			}else if( input.label ){
				type = GUI.TYPE_LABEL;
			}
		}

		var factory = _componentFactories[type];
		if(factory){
			var result = new ExtObject();
			result.component := void;
			result.inputComponent := void;
			result.skipAddingContents := false;
			(this->factory)(input,result);
			component = result.component;
			inputComponent = result.inputComponent;
			skipAddingContents = result.skipAddingContents;
		}
		// unknown type
		else {
			component = this.createLabel("[???]");
		}
	}

	// ---------------
	// II. finalization
	{
		// init the input component
		if(inputComponent){

			// create the proper DataWrapper
			var dataWrapper;
			// Connect to attribute? obj.attr
			var obj = description[ GUI.DATA_OBJECT ];
			var id = description[ GUI.DATA_ATTRIBUTE ];
			if(obj&&id){
				dataWrapper = DataWrapper.createFromAttribute(obj,id);
			} // data provider - function?
			else if(var dataProvider = description[GUI.DATA_PROVIDER]){
				dataWrapper = DataWrapper.createFromFunctions( dataProvider );
			} // data wrapper?
			else if(var _dataWrapper = description[GUI.DATA_WRAPPER]){
				dataWrapper = _dataWrapper;
			} // single value?
			else if(description.containsKey(GUI.DATA_VALUE)){
				dataWrapper = DataWrapper.createFromValue(description[GUI.DATA_VALUE]);
			}else{ // no data given?
				dataWrapper = DataWrapper.createFromValue( inputComponent.getData() );
			}
			if(!inputComponent.setData){
				print_r(description);
			}

			// init
			inputComponent.setData( dataWrapper() );

			// If the inputComponent is changed (e.g. by user input) update the dataWrapper.
			inputComponent.addDataChangedListener( dataWrapper->dataWrapper.set );

			// add user defined dataChanged listener
			if(var onDataChanged = description[GUI.ON_DATA_CHANGED]){
				inputComponent.addDataChangedListener( onDataChanged );
			}

			// If the data is changed, update the inputComponent.
			dataWrapper.onDataChanged += inputComponent->fn(data){
				if(isDestroyed()){
					return MultiProcedure.REMOVE;
				}
				setData(data);
			};

			if(component!=inputComponent){
				component.setData := dataWrapper->dataWrapper.set;
				component.getData := dataWrapper->dataWrapper.get;
			}

			// connect to a refresh group
			if(var refreshGroup = description[ GUI.DATA_REFRESH_GROUP ]){
				refreshGroup += dataWrapper->dataWrapper.refresh;
				dataWrapper.onDataChanged += refreshGroup->fn(data){ refresh();	};
			}

		}else{ // non-input component (label, container, ...)
			var dataWrapper = description[GUI.DATA_WRAPPER];
			if(dataWrapper){
				// If the data is changed, update the component's label.
				dataWrapper.onDataChanged += component->fn(data){
					if(this.isDestroyed())
						return MultiProcedure.REMOVE;
					this.setText(data);
				};
				component.setText(dataWrapper());
			}
		}

		// set optional flags
		if(description[GUI.FLAGS]){
			component.setFlag(description[GUI.FLAGS],true);
			if( (description[GUI.FLAGS]&GUI.LOCKED)>0  && inputComponent){
				inputComponent.setLocked(true);
			}
		}

		// position and size
		if( description[GUI.SIZE] || description[GUI.POSITION] ){
			var size =  description.get(GUI.SIZE,false);
			var sizeFlags = 0;

			if(size){
				if(size ---|> Geometry.Vec2){
					component.setWidth(size.x());
					component.setHeight(size.y());
				}else if(size.count()==2){
					size = new Geometry.Vec2(size[0],size[1]);
					component.setWidth(size.x());
					component.setHeight(size.y());
				}else if(size.count()==3){
					sizeFlags = size[0];
					size = new Geometry.Vec2(size[1],size[2]);
				}else{
					Runtime.warn("Invalid value fot GUI.SIZE: '"+size+"'");
				}
			}else{
				size = new Geometry.Vec2(0,0);
			}

			var pos =  description.get(GUI.POSITION,false);
			var posFlags = 0;

			if(pos){
				if(pos ---|> Geometry.Vec2){
					component.setPosition(pos);
				}else if(pos.count()==2){
					pos = new Geometry.Vec2(pos[0],pos[1]);
					component.setPosition(pos);
				}else if(pos.count()==3){
					posFlags = pos[0];
					pos = new Geometry.Vec2(pos[1],pos[2]);
				}else{
					Runtime.warn("Invalid value fot GUI.POSITION: '"+pos+"'");
				}
			}else{
				pos = new Geometry.Vec2(0,0);
			}

			var flags = sizeFlags|posFlags;
			if(flags>0)
				component.setExtLayout( flags, pos, size);
		}

		// context menu
		if( description[GUI.CONTEXT_MENU_PROVIDER]){
			//! \see ContextMenuTrait
			@(once) static ContextMenuTrait = Std.require('LibGUIExt/Traits/ContextMenuTrait');
			if(!Traits.queryTrait(component, ContextMenuTrait))
				Traits.addTrait(component, ContextMenuTrait,description.get(GUI.CONTEXT_MENU_WIDTH,150));
			component.contextMenuProvider += description[GUI.CONTEXT_MENU_PROVIDER];
			
			@(once) static triangle = this._createTriangleAtCornerShape(GUI.BLACK,5);
			component.addComponentHoverProperty(new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_ADDITIONAL_BACKGROUND_SHAPE,triangle),1,false);
		}
		
		// mouse button listener
		if( description[GUI.ON_MOUSE_BUTTON]){
			//! \see MouseButtonListenerTrait
			@(once) static MouseButtonListenerTrait = Std.require('LibGUIExt/Traits/MouseButtonListenerTrait');
			if(!Traits.queryTrait(component, MouseButtonListenerTrait))
				Traits.addTrait(component, MouseButtonListenerTrait);
			component.onMouseButton += description[GUI.ON_MOUSE_BUTTON];
		}
			
		// drag and drop
		if( description[GUI.DRAGGING_ENABLED] ){
			static DraggableTrait;
			static DraggingMarkerTrait;
			static DraggingConnectorTrait;
			@(once){
				DraggableTrait = Std.require('LibGUIExt/Traits/DraggableTrait');
				DraggingMarkerTrait = Std.require('LibGUIExt/Traits/DraggingMarkerTrait');
				DraggingConnectorTrait = Std.require('LibGUIExt/Traits/DraggingConnectorTrait');
			}

			//! \see GUI.DraggableTrait
			if(!Traits.queryTrait(component,DraggableTrait)){
				if(description[GUI.DRAGGING_BUTTONS])
					Traits.addTrait(component,DraggableTrait, description[GUI.DRAGGING_BUTTONS] );
				else
					Traits.addTrait(component,DraggableTrait);
			}
			if(description[GUI.DRAGGING_MARKER]){
				if(description[GUI.DRAGGING_MARKER]===true)
					Traits.addTrait(component, DraggingMarkerTrait); // use default
				else
					Traits.addTrait(component, DraggingMarkerTrait, description[GUI.DRAGGING_MARKER] );
				if(description[GUI.DRAGGING_CONNECTOR]){
					Traits.addTrait(component, DraggingConnectorTrait);
				}
			}
			if(description[GUI.ON_DRAG])
				component.onDrag += description[GUI.ON_DRAG];
			if(description[GUI.ON_DROP])
				component.onDrop += description[GUI.ON_DROP];
			if(description[GUI.ON_START_DRAGGING])
				component.onStartDragging += description[GUI.ON_START_DRAGGING];
			if(description[GUI.ON_STOP_DRAGGING])
				component.onStopDragging += description[GUI.ON_STOP_DRAGGING];
		}
		
		// ----

		// set optional tooltip
		if( description[GUI.TOOLTIP] )
			component.setTooltip(description[GUI.TOOLTIP]);

		// set optional font
		if( description[GUI.FONT] ){
//			component.setFont(description[GUI.FONT]);
			component.addProperty(new GUI.FontProperty(GUI.PROPERTY_DEFAULT_FONT,getFont(description[GUI.FONT])));
		}

		// set optional font color
		if( description[GUI.COLOR] ){
			component.setColor(description[GUI.COLOR]);
		}

		// set optional properties
		if( description[GUI.PROPERTIES] ){
			foreach(description[GUI.PROPERTIES] as var property)
				component.addProperty(property);
		}
		

		// call optional init function
		if( description[GUI.ON_INIT] ){
			(component->description[GUI.ON_INIT])(description);
		}

		// optional contents (children)
		{
			var contents = description[GUI.CONTENTS];
			if( contents ){
				if(!skipAddingContents ){
					foreach( this.createComponents({
									GUI.TYPE : insideMenu ? GUI.TYPE_MENU_ENTRIES : GUI.TYPE_COMPONENTS,
									GUI.PROVIDER : contents }) as var c)
						component+=c;
				}
				if(contents.isA(String))// for debugging
					component._componentId := contents;
			}
		}

		if(gui._destructionMonitor){
			var s = component.toString();
			if(description[GUI.LABEL])
				s+=" '"+description[GUI.LABEL]+"'";
			component.__destructionMarker := gui._destructionMonitor.createMarker(s);
		}
	}
	return component;
};

//! (internal)
GUI.GUI_Manager._componentFactories ::= {

	// bit
	GUI.TYPE_BIT : fn(input,result){
		result.component = this.createCheckbox(input.label);
		// result.inputComponent is intentionally left as void, as
		// for bits it should not additionally be bound to an attribute later on
		var bit = input.description[GUI.DATA_BIT];
		var obj = input.description[GUI.DATA_OBJECT];
		var attr = input.description[GUI.DATA_ATTRIBUTE];
		result.component.setData( (obj.getAttribute(attr)&bit)>0 );
		result.component._attr := attr;
		result.component._bit := bit;
		result.component._obj := obj;
		result.component.addDataChangedListener( fn(data){
			var value = _obj.getAttribute(_attr);
			_obj.assignAttribute(_attr, data ? (value|_bit) : value-(value&_bit) );
		});
	},

	// bool
	GUI.TYPE_BOOL : fn(input,result){
		result.component = this.createCheckbox(input.label);
		result.inputComponent = result.component;
	},

	// button
	GUI.TYPE_BUTTON : fn(input,result){
		var flags = input.description.get(GUI.FLAGS,0);
		if( (flags&GUI.LOCKED)>0 ){
			var d = input.description.clone();
			d[GUI.ON_CLICK] = void;
			d[GUI.TYPE] = GUI.TYPE_LABEL;
			d[GUI.COLOR] = new Util.Color4f(0.5,0.5,0.5,0.5);
			result.component = this.create( d );
			return;
		}
			
		var button = this.createButton(input.width?input.width:100,input.height,input.label);
		var onClick = input.description[GUI.ON_CLICK];
		if(onClick)
			button.addOnClickHandler(onClick);

		// set other layout if button is inside menu
		if(input.insideMenu){
			button.setFlag(GUI.FLAT_BUTTON,true);
			button.setTextStyle (GUI.TEXT_ALIGN_LEFT|GUI.TEXT_ALIGN_MIDDLE);
		}
		if(input.description[GUI.TEXT_ALIGNMENT]){
			button.setTextStyle(input.description[GUI.TEXT_ALIGNMENT]);
		}

		if(input.description[GUI.ICON]) {

			var icon = gui.getIcon(input.description[GUI.ICON]);

			if(icon ---|> GUI.Component){
				button.setText('');
				button += icon;
//				button.setFlag(GUI.FLAT_BUTTON,true);

				if(!input.width){
//					icon.setPosition(3,0);
//					button.setWidth(icon.getWidth()+6);
					button.setWidth(icon.getWidth());
				}
				if(!input.height || icon.getHeight()>input.height )
					button.setHeight(icon.getHeight());

				if(input.description[GUI.ICON_COLOR])
					button.addProperty(new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR,
										new Util.Color4ub( input.description[GUI.ICON_COLOR])));

				// if no tooltip is given, use the label as tooltip
				if(input.label && !input.label.empty() && !input.description[GUI.TOOLTIP]){
					button.setTooltip(input.label);
				}

			}else{
				if(!input.label || input.label.empty())
					button.setText(input.description[GUI.ICON]);
			}

		}
		if(input.description[GUI.BUTTON_SHAPE]){
			button.setButtonShape(input.description[GUI.BUTTON_SHAPE]);
		}
		result.component = button;
	},
	
	// collapsible container
	GUI.TYPE_COLLAPSIBLE_CONTAINER : fn(input,result){
		// create header
		var containerSize = [GUI.HEIGHT_CHILDREN_ABS,0,4];

		var headerSize = [0,0,0];
		if(input.width) {
			containerSize[0] |= GUI.WIDTH_CHILDREN_ABS;
			containerSize[1] = 4;
			headerSize[0] |= GUI.WIDTH_ABS;
			headerSize[1] = input.width-4;
		}else{
			containerSize[0] |= GUI.WIDTH_FILL_ABS;
			containerSize[1] = 2;
			headerSize[0] |= GUI.WIDTH_FILL_ABS;
			headerSize[1] = 4;
		}
		if(input.height) {
			headerSize[0] |= GUI.HEIGHT_ABS;
			headerSize[2] = input.height;
		}else{
			headerSize[0] |= GUI.HEIGHT_CHILDREN_ABS;
			headerSize[2] = 2;
		}
		
		var container = this.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.SIZE : 	containerSize,
			GUI.FLAGS : GUI.BACKGROUND,
			GUI.LAYOUT : GUI.LAYOUT_FLOW
		});
		container.addProperty(new GUI.UseShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,GUI.PROPERTY_TEXTFIELD_SHAPE)); //! \todo Temporary to create a nice border
		
		var collapsed = input.description.get(GUI.COLLAPSED,false);
		if(! (collapsed---|>DataWrapper))
			collapsed = DataWrapper.createFromValue(collapsed);
		

		var header = this.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.SIZE : 	headerSize,
//			GUI.FLAGS : GUI.BORDER,
			GUI.LAYOUT : GUI.LAYOUT_FLOW
		});

		// add button
		var button = this.create({
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "+",
			GUI.SIZE :  [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , 15,15 ], // \todo the button's size should be adjustable
			GUI.ON_CLICK : [collapsed] => fn(collapsed){ collapsed(!collapsed());	},
			GUI.FLAGS : GUI.FLAT_BUTTON
		});
		header += button;
		
		if(input.label)
			header += input.label;
		if(input.description[GUI.HEADER]){
			foreach( this.createComponents(input.description[GUI.HEADER]) as var c)
				header+=c;
		}
		container += header;

		collapsed.onDataChanged += [this,container,input.description[GUI.CONTENTS],button] => fn(gui,container,content,button, b){
			if(container.isDestroyed())
				return $REMOVE;
			// clear
			for(var c=container.getFirstChild().getNext();c;c=c.getNext())
				gui.markForRemoval(c);
			if(b){
				button.setText("+");
			}else{
				button.setText("-");
				container++;
				container += '----';
				container++;
				foreach(gui.createComponents(content) as var c)
					container += c;
			}
		};		

		container.refreshContents := collapsed->collapsed.forceRefresh; // refreshable contents trait??????
		
		if(!collapsed())
			collapsed.forceRefresh();

		result.skipAddingContents = true;
		result.component = container;
	},

	// color selector
	GUI.TYPE_COLOR : fn(input,result){
		result.component = this.createColorSelector();
		if(input.label)
			result.component.setText(input.label);
		result.inputComponent = result.component;
	},

	// container
	GUI.TYPE_CONTAINER : fn(input,result){
		var p = this.createContainer(input.width?input.width:0,input.height);
		if((input.description.get(GUI.FLAGS,0)&GUI.AUTO_LAYOUT) > 0){ // deprecated!
			p.addLayouter(new GUI.FlowLayouter());
		}
		var layouter = input.description[GUI.LAYOUT];
		if(layouter){
			p.addLayouter(layouter);
		}
		result.component = p;
	},

	// critical button
	GUI.TYPE_CRITICAL_BUTTON : fn(input,result){
		var description2 = input.description.clone();
		description2[GUI.TYPE] = GUI.TYPE_BUTTON;
		description2[GUI.ON_CLICK] = (fn(message,action){
			gui.openMenu(getAbsPosition()-new Geometry.Vec2(10,10),[{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : message,
				GUI.WIDTH : 220,
				GUI.HEIGHT : 30,
				GUI.ON_CLICK : this->(fn(action){
					(this->action)();
					gui.closeAllMenus();
				}).bindLastParams(action)
			}]);
		}).bindLastParams( input.description.get(GUI.REQUEST_MESSAGE, input.description[GUI.LABEL]), input.description[GUI.ON_CLICK] );

		result.component = this._createComponentFromDescription(description2,input.width?input.width:100,input.insideMenu);
		result.component.addProperty(new GUI.ColorProperty(GUI.PROPERTY_BUTTON_HOVERED_TEXT_COLOR, GUI.RED));
	},

	// fileSelector
	GUI.TYPE_FILE : fn(input,result){
		// create text input
		var textInputDescription = input.description.clone();
		textInputDescription[GUI.TYPE] = GUI.TYPE_TEXT;
		result.component = this.createComponent(textInputDescription);
		var tf=result.component.getLastChild();

		var relButtonWidth = 0.06;

		// make textfield smaller
		tf.setExtLayout(
				GUI.POS_X_REL|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
				GUI.WIDTH_REL|GUI.HEIGHT_ABS,
				new Geometry.Vec2(relButtonWidth,0),new Geometry.Vec2( input.label ? 0.6-relButtonWidth : 1.0-relButtonWidth,input.height) );

//		tf.setWidth(tf.getWidth()-20);
		result.inputComponent = tf;

		// create search button
		var button = this.createComponent( {
			GUI.TYPE  : GUI.TYPE_BUTTON,
			GUI.LABEL : "...",
			GUI.TOOLTIP : "open file explorer",
			GUI.WIDTH : 20,
			GUI.ON_CLICK : [tf, input.description.get(GUI.ENDINGS,[""]), input.description.get(GUI.DIR,".") ]=>fn(tf,endings,dir){
					var f = new GUI.FileDialog("Select a file",dir, endings, [tf] => fn(tf, filename){
						if(tf.isDestroyed()){
							Runtime.warn("Trying to set data to a destroyed text field.");
							return;
						}
						tf.setData(filename);
						tf.onDataChanged(filename);
					});
					f.init();
				},
			GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 0,0],
			GUI.SIZE : [ GUI.WIDTH_REL|GUI.HEIGHT_REL , relButtonWidth, 1.0]
		});
		result.component+=button;
		button.setPosition(result.component.getWidth()-20,0);
	},
	// fileSelector
	GUI.TYPE_FOLDER : fn(input,result){
		loadOnce(__DIR__+"/Factory_Dialogs.escript");
		// create text input
		var textInputDescription = input.description.clone();
		textInputDescription[GUI.TYPE] = GUI.TYPE_TEXT;
		result.component = this.createComponent(textInputDescription);
		var tf=result.component.getLastChild();

		var relButtonWidth = 0.06;

		// make textfield smaller
		tf.setExtLayout(
				GUI.POS_X_REL|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
				GUI.WIDTH_REL|GUI.HEIGHT_ABS,
				new Geometry.Vec2(relButtonWidth,0),new Geometry.Vec2(0.6-relButtonWidth,input.height) );
		result.inputComponent = tf;

		// create search button
		var button = this.createComponent( {
			GUI.TYPE  : GUI.TYPE_BUTTON,
			GUI.LABEL : "...",
			GUI.TOOLTIP : "Open file explorer",
			GUI.WIDTH : 20,
			GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM, 0,0],
			GUI.SIZE : [ GUI.WIDTH_REL|GUI.HEIGHT_REL , relButtonWidth, 1.0],
			GUI.ON_CLICK : this->fn(target,endings,folder){
				this.openDialog({
					GUI.TYPE : GUI.TYPE_FOLDER_DIALOG,
					GUI.LABEL : "Select a folder",
					GUI.ENDINGS : endings,
					GUI.DIR : folder,
					GUI.ON_ACCEPT : target->fn(folder){
						this.setData(folder);
						this.onDataChanged(folder);
					}
				});
			}.bindLastParams(tf,input.description.get(GUI.ENDINGS,[]),input.description.get(GUI.DIR,"."))
		});
		result.component+=button;
		button.setPosition(result.component.getWidth()-20,0);
	},

	GUI.TYPE_ICON : fn(input,result){
		result.component = this.getIcon(input.description[GUI.ICON]);
		result.component.addProperty(new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR,
						new Util.Color4ub( input.description.get(GUI.ICON_COLOR ,[255,255,255,255] ))));

	},

	// label
	GUI.TYPE_LABEL : fn(input,result){
		result.component = this.createLabel(input.label);
		if(input.description[GUI.TEXT_ALIGNMENT]){
			result.component.setTextStyle(input.description[GUI.TEXT_ALIGNMENT]);
		}
	},

	// list view
	GUI.TYPE_LIST : fn(input,result){

		var wrapper = this.createContainer(input.width?input.width:300,input.height);

		var list = this.createListView();
		if(input.description[GUI.FLAGS])
			list.setFlag(input.description[GUI.FLAGS],true);
		list.setFlag(GUI.AUTO_MAXIMIZE,true);

		if(input.description[GUI.LIST_ENTRY_HEIGHT])
			list.setEntryHeight(input.description[GUI.LIST_ENTRY_HEIGHT]);

		wrapper += list;
		wrapper.list := list;

		// -----
		// add customized functions
		//! ---|> Container
		wrapper.add := fn(mixed){
			if(mixed---|>Array){
				addOption(mixed[0],mixed[1]);
			}else{
				list.add(mixed);
			}
			return this;
		};
		wrapper.addOption := fn(value,c){
			c = gui.create(c);
			c.__ListViewData__ := value;
			list.add(c);
		};
		//! ---|> Container
		wrapper."+=" := wrapper.add;
		//! ---|> Container
		wrapper.clear := list->list.clear;
		wrapper.destroyContents := list->list.destroyContents;
		wrapper.getData := fn(){
			var result = [];
			foreach(list.getData() as var c)
				result += c.isSet($__ListViewData__) ? c.__ListViewData__ : c;
			return result;
		};
		wrapper.onDataChanged := fn(data){
//			print_r(data);
		};
		list.onDataChanged := wrapper->fn(marking){
			var data = [];
			foreach(marking as var c)
				data += c.isSet($__ListViewData__) ? c.__ListViewData__ : c;
			this.onDataChanged(data);
		};
		wrapper.setData := fn(data){
			if(!(data---|>Array))
				data = [data];
			// map: value -> marking index
			var m = new Map();
			foreach(data as var index, var value){
				m[value] = index;
			}
			// collect the components having the desired data and set them at the corresponding position
			var marking = [];
			foreach(list.getContents() as var c){
				var value = c.isSet($__ListViewData__) ? c.__ListViewData__ : c;
				var index = m[value];
				if(index)
					marking[index] = c;
			}
			// remove unused entries
			marking.filter( fn(v){
				if(void===v){
					Runtime.warn("Value set on list view does not exist!");
					return false;
				}
				return true;
			});
			list.setData(marking);
		};
		// ---

		result.component = wrapper;
		result.inputComponent = result.component;

		foreach(input.description.get(GUI.OPTIONS,[]) as var option){
			wrapper+=option;
		}
	},

	// menu
	GUI.TYPE_MENU : fn(input,result){
		var button = this.createButton(input.width?input.width:100,input.height,input.label);
		button.isSubMenu := input.insideMenu;

		if(input.insideMenu){
	//			button.setColor(new Util.Color4f(1,1,1,1));
			button.setFlag(GUI.FLAT_BUTTON,true);
			button.setTextStyle (GUI.TEXT_ALIGN_MIDDLE);
			button += {
				GUI.TYPE : GUI.TYPE_LABEL,
				GUI.LABEL : ">>",
				GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
							GUI.POS_Y_ABS|GUI.REFERENCE_Y_CENTER|GUI.ALIGN_Y_CENTER, 0,0]
			};
		}
		if(input.description[GUI.ICON]) {

			var icon = gui.getIcon(input.description[GUI.ICON]);

			if(icon ---|> GUI.Component){
				button.setText('');
				button += icon;
//				button.setFlag(GUI.FLAT_BUTTON,true);
				if(!input.width){
					icon.setPosition(3,0);
					button.setWidth(icon.getWidth()+6);
				}
				if(!input.height || icon.getHeight()>input.height )
					button.setHeight(icon.getHeight());

				button.addProperty(new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR,
										new Util.Color4ub( input.description.get(GUI.ICON_COLOR ,[255,255,255,255] ))));

				// if no tooltip is given, use the label as tooltip
				if(input.label && !input.label.empty() && !input.description[GUI.TOOLTIP]){
					button.setTooltip(input.label);
				}

			}else{
				if(!input.label || input.label.empty())
					button.setText(input.description[GUI.ICON]);
			}

		}
		var context = (void==input.description[GUI.MENU_CONTEXT]) ? [] : [input.description[GUI.MENU_CONTEXT]];
		
		var menuEntries = input.description[GUI.MENU];
		if(!menuEntries){
			menuEntries = input.description[GUI.MENU];
			if(!menuEntries)
				menuEntries = ["..."];
		}else if(menuEntries---|>Array)
			menuEntries = menuEntries.clone();
		
		button.addOnClickHandler(	[	this,
										menuEntries,context,
										input.description[GUI.MENU_WIDTH]?input.description[GUI.MENU_WIDTH]:100
									] => fn( gui,menuEntries,context,menuWidth ){
			if( this.getParentComponent()---|> GUI.Menu ){
				getParentComponent().openSubmenu(this,menuEntries,menuWidth,context...);
			}else{
				var pos = getAbsPosition()+new Geometry.Vec2(isSubMenu ? getWidth()*0.95 : 0, isSubMenu ? 0 :getHeight());
				gui.openMenu(pos,menuEntries,menuWidth,context...);
			}
		});
		
		result.component = button;
	},

	// next column marker in Panel
	GUI.TYPE_NEXT_COLUMN : fn(input,result){
		var spacing = input.description[GUI.SPACING];
		result.component = this._createPanelNextColumn(spacing?spacing:0);

	},

	// next row marker in Panel
	GUI.TYPE_NEXT_ROW : fn(input,result){
		var spacing = input.description[GUI.SPACING];
		result.component = this._createPanelNextRow(spacing?spacing:0);
	},

	// number textfield
	GUI.TYPE_NUMBER : fn(input,result){
		// this is basically a copy of the TYPE_TEXT case with an added type constraints
		var w = input.width?input.width:300;
		result.component = this.createContainer(w,input.height);

		var tfWidth = 1.0; // relative size of textfield
		if(input.label){
			var label = this.createLabel(w*0.4,input.height,input.label);
			label.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
				GUI.WIDTH_REL|GUI.HEIGHT_ABS,
				new Geometry.Vec2(0,0),new Geometry.Vec2(0.4,input.height) );
			tfWidth -= 0.4;

			result.component += label;
		}
		var optionProvider = input.description[GUI.OPTIONS_PROVIDER];

		var options = input.description[GUI.OPTIONS];
		if(optionProvider){
			options = optionProvider();
		}

		var internalInput;
		if(options){
			internalInput = this.createCombobox(w*tfWidth,input.height,options);
			if(optionProvider){
				internalInput.optionProvider = optionProvider;
			}
		}else{
			internalInput = this.createTextfield(0,0,"");
		}

		internalInput.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
			GUI.WIDTH_REL|GUI.HEIGHT_ABS,
			new Geometry.Vec2(0,0),new Geometry.Vec2(tfWidth,input.height) );		result.component+=internalInput;

		internalInput.addDataChangedListener( result.component->fn(data){	this.onDataChanged(new Number(data));	});

		result.component.setData := internalInput->fn(data)	{	setData(""+new Number(data)); 	};
		result.component.getData := internalInput->fn()		{	return new Number(getData());	};
		result.component.onDataChanged := fn(data){};
		result.component.setLocked:=internalInput->internalInput.setLocked;
		result.inputComponent = result.component;
	},

	// panel
	GUI.TYPE_PANEL : fn(input,result){
		var p = this.createPanel(input.width?input.width:0,input.height);
		if( input.description[GUI.PANEL_MARGIN] )
			p.setMargin(input.description[GUI.PANEL_MARGIN]);
		if( input.description[GUI.PANEL_PADDING] )
			p.setPadding(input.description[GUI.PANEL_PADDING]);
		result.component = p;
	},
	
	// 	tab
	GUI.TYPE_TAB : fn(input,result){
		result.component = this.createTab(input.description.get(GUI.LABEL,"Tab"),
								input.description[GUI.TAB_CONTENT]);
	},
	
	// tabbed panel
	GUI.TYPE_TABBED_PANEL : fn(input,result){
		var p = this.createTabbedPanel(input.width?input.width:100,input.height);
		result.component = p;
	},

	// textfield
	GUI.TYPE_TEXT : fn(input,result){
		var w = input.width?input.width:300;
		result.component = this.createContainer(w,input.height);

		var tfWidth = 1.0; // relative size of textfield
		if(input.label){
			var label = this.createLabel(w*0.4,input.height,input.label);
			label.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
				GUI.WIDTH_REL|GUI.HEIGHT_ABS,
				new Geometry.Vec2(0,0),new Geometry.Vec2(0.4,input.height) );
			tfWidth -= 0.4;

			result.component += label;
		}
		var optionProvider = input.description[GUI.OPTIONS_PROVIDER];

		var options = input.description[GUI.OPTIONS];
		if(optionProvider){
			options = optionProvider();
		}

		var internalInput;
		if(options){
			internalInput = this.createCombobox(w*tfWidth,input.height,options);
			if(optionProvider){
				internalInput.optionProvider = optionProvider;
			}
		}else{
			internalInput = this.createTextfield(0,0,"");
		}

		internalInput.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
			GUI.WIDTH_REL|GUI.HEIGHT_ABS,
			new Geometry.Vec2(0,0),new Geometry.Vec2(tfWidth,input.height) );
		result.component += internalInput;
		result.inputComponent = internalInput;
	},
	// text area
	GUI.TYPE_MULTILINE_TEXT : fn(input,result){
		var w = input.width?input.width:300;

		var textarea = gui.createTextarea();
		result.inputComponent = textarea;

		if(input.label){
			var container = this.createContainer(w,input.height);
			container += {
				GUI.TYPE : GUI.TYPE_LABEL,
				GUI.LABEL : input.label,
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS,0,15],
				GUI.POSITION : [GUI.POS_X_ABS|GUI.POS_Y_ABS,0,0]
			};
			textarea.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
				GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS,
				new Geometry.Vec2(0,15),new Geometry.Vec2(0,0) );
			container += textarea;
			result.component = container;
		}else{
			result.component = textarea;
		}
	},


	// tree view
	GUI.TYPE_TREE : fn(input,result){
		var options = input.description.get(GUI.OPTIONS,[]);
		var w = input.width?input.width:300;
		result.component =this.createTreeView(w,input.height);
		result.component.setData := fn(data){
			if(data---|>Array){
				foreach(data as var d)
					markComponent(d);
			}else if(data){
				markComponent(data);
			}else{
				unmarkAll();
			}
		};
		foreach(options as var option){
			result.component+=option;
		}
		result.inputComponent = result.component;
	},

	// tree view sub group
	GUI.TYPE_TREE_GROUP : fn(input,result){
		var options = input.description.get(GUI.OPTIONS);
		var label = input.description[GUI.LABEL];
		if(!label){
			if(options && !options.empty()){
				label = options.front();
				options = options.slice(1);
			}else{
				label = "???";
			}
		}

		result.component = this.createTreeViewEntry(this.create(label));
		
		// special case: set flags early to prevent unnecessary executing of the optionProvider for a closed entry.
		if( (input.description.get(GUI.FLAGS,0) & GUI.COLLAPSED_ENTRY) > 0){
			result.component.setFlag(input.description.get(GUI.FLAGS),true);
		}
		
		result.component.setWidth(300);

		if(options){
			foreach(options as var option)
				result.component+=option;
		}

		var optionsProvider = input.description[GUI.OPTIONS_PROVIDER];
		if(optionsProvider){
			//! \see GUI.TreeViewEntry.DynamicSubentriesTrait
			Traits.addTrait( result.component, GUI.TreeViewEntry.DynamicSubentriesTrait,optionsProvider);
		}

	},

	// radio buttons
	GUI.TYPE_RADIO : fn(input,result){
		var options = input.description[GUI.OPTIONS];
		result.component = this.createRadioButtonSet(input.label);
		foreach(options as var option){
			result.component.addOption(option[0],option[1]);
		}
		result.inputComponent = result.component;
	},

	// range (slider)
	GUI.TYPE_RANGE : fn(input,result){
		var w = input.width?input.width:300;
		result.component = this.createContainer(w,input.height);
		var sliderWidth = 1.0;
		if(input.label){
			var label = this.createLabel(w*0.4,input.height,input.label);

			label.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
				GUI.WIDTH_REL|GUI.HEIGHT_REL,
				new Geometry.Vec2(0,0),new Geometry.Vec2(0.4,1.0) );
			result.component += label;
			sliderWidth-=0.4;
		}
		var mappingFunction = input.description.get(GUI.RANGE_FN, false);
		var inverseMappingFunction = input.description.get(GUI.RANGE_INV_FN, false);
		if(input.description[GUI.RANGE_FN_BASE]) {
			var base = input.description[GUI.RANGE_FN_BASE];
			mappingFunction = (fn(v, Number b) { return (b).pow(v); }).bindLastParams(base);
			inverseMappingFunction = (fn(v, Number b) { return (v).log(b); }).bindLastParams(base);
		}
		var range = input.description[GUI.RANGE];
		var steps = input.description[GUI.RANGE_STEP_SIZE] ?
						((range[1]-range[0]).abs() / input.description[GUI.RANGE_STEP_SIZE]) : 
						input.description.get(GUI.RANGE_STEPS, w*0.6);
		
		var s = this.createExtSlider( [0,15],
				range ,
				steps,
				mappingFunction,
				inverseMappingFunction);
		s.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
			GUI.WIDTH_REL|GUI.HEIGHT_REL,
			new Geometry.Vec2(0,0),new Geometry.Vec2(sliderWidth,1.0) );

		var options = input.description[GUI.OPTIONS];
		if(options)
			s.addOptions(options);
		result.component+=s;
		result.component.setRange := s -> s.setRange;
		result.inputComponent = s;
	},

	// select (dropdown)
	GUI.TYPE_SELECT : fn(input,result){
		var w = input.width?input.width:300;
		var container = this.createContainer(w,input.height);

		var ddWidth = 1.0; // relative size of textfield
		if(input.label){
			var label = this.createLabel(w*0.4,input.height,input.label);
			label.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
				GUI.WIDTH_REL|GUI.HEIGHT_ABS,
				new Geometry.Vec2(0,0),new Geometry.Vec2(0.4,input.height) );
			ddWidth -= 0.4;
			container += label;
		}
		var dropdown = this.createDropdown(w*ddWidth,input.height);


		var options = input.description[GUI.OPTIONS];
		var optionsProvider = input.description[GUI.OPTIONS_PROVIDER];
		if(optionsProvider){
				dropdown.setOptionsProvider(optionsProvider);
		}else if(options){
			foreach(input.description[GUI.OPTIONS] as var option){
				dropdown.addOption(option[0],option[1],option[2],option[3]);
			}
		}

		dropdown.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
				GUI.WIDTH_REL|GUI.HEIGHT_ABS,
				new Geometry.Vec2(0,0),new Geometry.Vec2(ddWidth,input.height) );
		container+=dropdown;

		container.addOption := dropdown->dropdown.addOption;
		container.selectOption := dropdown->dropdown.selectOption;
		container.clear := dropdown->dropdown.clear;

		result.component = container;
		result.inputComponent = dropdown;
	},

	GUI.TYPE_WINDOW : fn(input,result){
		var c = this.createWindow( input.width?input.width:300,
					input.description[GUI.HEIGHT]?input.description[GUI.HEIGHT]:100 ,
					input.label?input.label:"" );
		if(input.description[GUI.ON_WINDOW_CLOSED])
			c.onWindowClosed := input.description[GUI.ON_WINDOW_CLOSED];
		result.component = c;
	}
};

GUI.GUI_Manager.registerComponentFactory ::= fn(type,factory){
	this._componentFactories[type] = factory;
};
