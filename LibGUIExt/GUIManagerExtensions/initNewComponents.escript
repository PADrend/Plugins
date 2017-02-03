/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * Copyright (C) 2009-2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

// ------------------------------------------------------------------------------
// new components
// ------------------------------------------------------------------------------

/*! Creates a simple set of color sliders.
	\example
		var c = gui.createColorSelector(new Util.Color4f(1.0,0.0,0.0) );
		c.onDataChanged = fn(color){ print_r( color ); };
		c.setText( "This text is red" );
		panel.add(c);
 */
 
 {
	GUI.ColorSelectorTrait := new Std.Traits.GenericTrait("GUI_ColorSelector");

	var t = GUI.ColorSelectorTrait;

	t.attributes.label @(private) := void;
	t.attributes.sliders @(private,init) := Array;
	t.attributes.dataType @(private) := Util.Color4f; // Util.Color4f or Array
	
	t.attributes.getData := fn(){	return new dataType(sliders[0].getData(), sliders[1].getData(), sliders[2].getData(), sliders[3].getData());	};

	t.attributes.setData := fn([Util.Color4f,Array] color){
		dataType = color.getType(); // getData should return the same type.

		if(color.isA(Array))
			color = new Util.Color4f(color);

		sliders[0].setData(color.r());
		sliders[1].setData(color.g());
		sliders[2].setData(color.b());
		sliders[3].setData(color.a());
		label.setColor(color);
	};

	t.attributes.onDataChanged := fn(data){};
	t.attributes.setText := fn(text){
		this.label.setText(text);
		this.label.setTooltip(text);
	};
	t.attributes.setLocked := fn(b){
		foreach(sliders as var s)
			s.setLocked(b);
		(this->GUI.Component.setLocked)(b);
	};

	t.onInit += fn(GUI.Container container,gui){
		(container->fn(gui){

			label = gui.create({
				GUI.TYPE : GUI.TYPE_LABEL,
				GUI.LABEL : "#"*20,
				GUI.POSITION : [GUI.POS_X_ABS|GUI.POS_Y_REL,2,0.0],
				GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_REL,2,0.2 ]
			});
			this += label;
			
			foreach( ["Red","Green","Blue","Alpha"] as var index,var name){
				sliders[index] = gui.create({
					GUI.TYPE : GUI.TYPE_RANGE,
					GUI.RANGE : [0,1],
					GUI.RANGE_STEPS : 100,
					GUI.TOOLTIP : name,
					GUI.POSITION : [GUI.POS_X_ABS|GUI.POS_Y_REL,2,0.2 + 0.2*index],
					GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_REL,2,0.2 ],
					GUI.ON_DATA_CHANGED : this -> fn(dummy){
						var color = getData();
						this.label.setColor(new Util.Color4f(color));
						this.onDataChanged(color);
					},
				});
				this += sliders[index] ;
			}
		})(gui);
	};
}


GUI.GUI_Manager.createColorSelector ::= fn([Util.Color4f,Array] initialColor = new Util.Color4f(0,0,0,0)){
	var c = this.createContainer(300,100,GUI.RAISED_BORDER); 
	Std.Traits.addTrait(c,GUI.ColorSelectorTrait,this);
	c.setData(initialColor);
	return c;
};



// -------------------------------------------------------------------------------

/*! Create a Combobox-Component for storing text.
	Example:

		var cb=gui.createCombobox(100,15,["foo","bar","dings"]);
		cb.addOption("dings2");

	\todo Change option on mouse wheel and up/down key
 */
GUI.GUI_Manager.createCombobox ::= fn( width, height, [Collection,void] entries=void){
	var cb=createContainer(width,height);
	
	// let the combobox look like a textfield
	cb.setFlag(GUI.BACKGROUND);
	cb.addProperty(new GUI.UseShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,GUI.PROPERTY_TEXTFIELD_SHAPE));

	cb.tf:=createTextfield(width-height,height);
	cb.tf.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
			GUI.WIDTH_ABS|GUI.HEIGHT_REL,
			new Geometry.Vec2(0,0),new Geometry.Vec2(-height,1.0) );  
	
	cb.tf.cb := cb;
	cb.tf.onDataChanged = fn(data){
		cb.onDataChanged(data);
	};

	// remove the textfield look from the textfield
	cb.tf.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_TEXTFIELD_SHAPE,GUI.NULL_SHAPE));

	cb.button := createButton(height,height," ");
	cb.button += GUI.OPTIONS_MENU_MARKER;
	cb.button.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
			GUI.WIDTH_ABS|GUI.HEIGHT_REL,
			new Geometry.Vec2(0,0),new Geometry.Vec2(height,1.0) );
	cb.button.setFlag(GUI.FLAT_BUTTON,true);
	cb+=cb.button;
	cb.button.cb:=cb;
	cb.button.setPosition(width-height,0);

	// note: add the textfield after the button, so that the button comes first in 
	// the selection order. Thereby you can enter a text, press [enter] and the next
	// component is selected (and not the button).
	cb += cb.tf;

	// open options menu
	cb.button.onClick := [this] => cb->fn(gui){
		var menu = gui.createMenu();

		// find containing menu (required for proper closing of other submenus)
		for(var c = this; c; c = c.getParentComponent()){
			if(c.isA(GUI.Menu)){
				c._registerSubmenu(menu);
				break;
			}
		}
		
		this.options = optionProvider();
		var optionWidth = this.getWidth()-this.getHeight();
		foreach(options as var index,var option){
			var button=gui.createButton(optionWidth,getHeight(),option);
			button.setFlag(GUI.FLAT_BUTTON,true);
			button.setTextStyle (GUI.TEXT_ALIGN_LEFT|GUI.TEXT_ALIGN_MIDDLE);
			button.onClick := [this,index,menu] => fn(comboBox,index,menu){
				comboBox.selectOption(index);
				menu.close();
			};
			menu += button;
		};
		var position = this.getAbsPosition()+new Geometry.Vec2(0,this.getHeight());
		menu.layout(); // assure the height is initialized
		if(position.getY()+menu.getHeight()>gui.getScreenRect().getHeight())
			position.setY([position.getY()-menu.getHeight()-this.getHeight(),0].max());
		menu.open(position);
	};

	cb.options := [];
	cb.selectedIndex:=false;

	cb.addOption:=fn(text){
		this.options += text;
		if(!selectedIndex){
			this.selectOption(0);
		}
		this.tf.addOption(text);
	};
	cb.addOptions:=fn(Collection ops){
		foreach(ops as var option)
			addOption(option);
	};

	cb.selectOption:=fn(index){
		options = optionProvider();
		selectedIndex=index;
		var option=options[index];
		tf.setText(option);
		onDataChanged(option);
	};
	cb.getData:=fn(){
		return tf.getData();
	};
	cb.getText:=cb.getData;
	cb.setData:=fn(data){
		tf.setData(data);
	};
	cb.getText:=cb.getData;
	cb.setText:=cb.setData;

	cb.setLocked:=fn(b){
		this.button.setLocked(b);
		this.tf.setLocked(b);
		(this->GUI.Component.setLocked)(b);
	};


	//! ---o
	cb.onDataChanged:=fn(data){	};
	
	//! ---o
	cb.optionProvider := fn(){	return options;	};

	if(entries){
		foreach(entries as var t)
			cb.addOption(t);
	}
	return cb;
};

// -------------------------------------------------------------------------------

//! Create a delimiter line.
GUI.GUI_Manager.createDelimiter ::= fn(){
	var delimiter=this.createLabel(100,1,"",GUI.LOWERED_BORDER);
	delimiter.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
			GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
			new Geometry.Vec2(0,0),new Geometry.Vec2(-20,1) );
	return delimiter;
};

// ------------------------------------------------------------------------------

/*! Create a Dropdown-Component for selecting things.
	Example:

	var dd=gui.createDropdown(100,15);
	dd.addOption("Dings"); // value="Dings", Menue entry: "Dings", shown if selected:  "Dings"
	dd.addOption(1,"Foo"); // value=1, Menue entry: "Foo", shown if selected:  "Foo"
	dd.addOption(2,"Bar"); // value=2, Menue entry: "Bar", shown if selected: "Bar"
	dd.addOption("Value","Menu","Select"); // value="Value", Menue entry: "Menu", shown if selected:  "Select"
	dd.addOption("Value","Menu","Select","Tooltip"); // value="Value", Menue entry: "Menu", shown if selected:  "Select", tooltip of the entry in the dropdown

	\todo Open menu if clicked on selection panel.
	\bug Selected components sometimes disappear after moving
	\todo Change option on mouse wheel and up/down key
 */
 
static DropdownTrait = new Std.Traits.GenericTrait("GUI_Dropdown");

GUI.GUI_Manager.createDropdown ::= fn( width, height){
	var dd = this.createContainer(width,height);
	Std.Traits.addTrait(dd, DropdownTrait);
	dd.init(this,width,height);
	return dd;
};
{

	var attr = DropdownTrait.attributes;
	attr.currentOption := void;
	attr.entryContainer @(private) := void;
	attr.options @(init) := Array;
	attr.optionsProvider @(private) := void; // optional; function returning the current options [ [option1],[...], ... ]
	attr._gui @(private) := void; 
	
	/*! Add an option to the drop down component.
		@param  value	Value of the component
				menuComponent Component used inside the menu.
							if void, value is used.
							Uses createComponent internally to create a component
							if e.g. a String is given.
				selectedComponent Component used when option is selected.
							if void, menuComponent is used.
							Uses createComponent internally to create a component
							if e.g. a String is given. 
							tooltip [optional] tooltip for the selected component*/
	attr.addOption := fn(value,menuComponent=void,selectedComponent=void,[String,void] tooltip=void){
		var option=new ExtObject();
		if(menuComponent===void)
			menuComponent = value;
		if(selectedComponent===void)
			selectedComponent = menuComponent;
		option.menuComponent := this._gui.create(menuComponent,getWidth() );
		option.selectedComponent := this._gui.create(selectedComponent,getWidth()-getHeight());
		option.tooltip := tooltip;
		option.value := value;
		this.options += option;
		if(!currentOption){
			this.selectOption(option, false);
		}
	};
	attr.clear := fn(){
		options = [];
		currentOption = void;
		entryContainer.clear();
		onDataChanged(getData());
	};
	attr.getData := fn(){
		return currentOption ? currentOption.value : void;
	};
	attr.getOptions := fn(){
		if(optionsProvider){
			options.clear();
			foreach(optionsProvider() as var a){
				addOption(a[0],a[1],a[2],a[3]);
			}
		}
		return options;
	};
	attr._activeMenu := void;
	attr.init := fn(gui,width, height){
		this._gui = gui;
		this.addProperty(new GUI.UseShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,GUI.PROPERTY_COMPONENT_LOWERED_BORDER_SHAPE));
		this.setFlag(GUI.BACKGROUND);

		var selectorWidth = 15;
		entryContainer = gui.createButton(width-selectorWidth,height,""); // ,GUI.LOWERED_BORDER
		entryContainer.setFlag(GUI.FLAT_BUTTON,true);
			
		entryContainer.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
				GUI.WIDTH_ABS|GUI.HEIGHT_REL,
				new Geometry.Vec2(0,0),new Geometry.Vec2(-selectorWidth,1.0) );
		entryContainer.onClick := this->fn(){ showMenu(); };

//		entryContainer = gui.createContainer(width-selectorWidth,height); // ,GUI.LOWERED_BORDER
//		entryContainer.onMouseButton := this->fn(buttonEvent){
//			if(buttonEvent.pressed && buttonEvent.button == Util.UI.MOUSE_BUTTON_LEFT){
//				showMenu(); // \todo bug: if the dropdown is inside of a popdown-window, the menu may be behind the window.
//				return true;
//			}
//			return false;
//			
//		};
		this += entryContainer;
		gui.enableMouseButtonListener(entryContainer);

		var button=gui.createButton(selectorWidth,height,"");
		button.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
				GUI.WIDTH_ABS|GUI.HEIGHT_REL,
				new Geometry.Vec2(0,0),new Geometry.Vec2(selectorWidth,1.0) );
		button.setFlag(GUI.FLAT_BUTTON,true);
		button +=  GUI.OPTIONS_MENU_MARKER;
		button.onClick := this->fn(){ showMenu(); };

		this+=button;
	};
	//! ---o
	attr.onDataChanged := fn(data){};
	attr.selectOption := fn(option, fireDataChangedEvent = true){
		if(currentOption == option)
			return;
		entryContainer.clear();
		currentOption=option;
		if(option && option.selectedComponent){
			entryContainer.add(option.selectedComponent);
		}
		if(fireDataChangedEvent) {
			onDataChanged(getData());
		}
	};

	attr.setData := fn(data){
		if(currentOption && data==currentOption.value)
			return;
		entryContainer.clear();
		currentOption=void;
		foreach(getOptions() as var option){
			if(option.value==data){
				selectOption(option, false);
				break;
			}
		}
	};
	attr.setLocked:=fn(b){
		foreach(this.getContents() as var c){
			if(c.isSet($setLocked))
				c.setLocked(b);
		}
		(this->GUI.Component.setLocked)(b);
	};
	attr.setOptionsProvider := fn(p){
		optionsProvider = p;
	};
	attr.showMenu @(private) := fn(){
		if( this._activeMenu&& !this._activeMenu.isDestroyed()){
			this._activeMenu.close();
			this._activeMenu = void;
			return;
		}
		
		var menu = this._gui.createMenu();
		this._activeMenu = menu;
		var selectedEntry;
		foreach(getOptions() as var option){
			var button = this._gui.createButton(getWidth(),getHeight(),"");
			button.setFlag(GUI.FLAT_BUTTON,true);
			button.setTextStyle (GUI.TEXT_ALIGN_LEFT|GUI.TEXT_ALIGN_MIDDLE);
			button.add(option.menuComponent);
			button.option := option;
			button.dd := this;
			button.menu := menu;
			if(option.tooltip)
				button.setTooltip(option.tooltip);
			
			button.onClick = fn(){
				this.dd.selectOption(option);
				this.menu.close();

				this.dd.select(); // if the dd is inside a menu, make sure it is not closed here...
				this.dd.activate();
			};
			menu.add(button);
			if(option == this.currentOption)
				selectedEntry = button;
		};
		menu.open(getAbsPosition()+new Geometry.Vec2(0,getHeight()));
		if(selectedEntry)
			selectedEntry.select();
		menu.activate();
	};
}


// ------------------------------------------------------------------------------

/*! Creates an extended Slider with corresponding textfield and user defined scaling.
	Example: // logarithmic slider with range 10^0 - 10^5

	var s=gui.createExtSlider(  [150,15],[0,5],5,
							fn(v){ return (10).pow(v); },
							fn(v){ return (v).log(10); });
*/
GUI.GUI_Manager.createExtSlider ::= fn(Array size,Array range,Number steps,f=false,f_inv=false){
	var width=size[0];
	var height=size[1];
	var container = this.createContainer(width,height);
	var slider = this.createSlider(width-50.0,height,range[0],range[1],steps); //,GUI.SHOW_VALUE
							
	slider.setExtLayout(
		GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
		GUI.WIDTH_ABS|GUI.HEIGHT_REL,
		new Geometry.Vec2(0,0),new Geometry.Vec2(-50,1.0) );
	
	container.add(slider);
	slider.container:=container;
	slider.onDataChanged = fn(data){
		var v=container.getValue();
		container.tf.setText(v);
		return container.onDataChanged(v);
	};
	var tf = this.createTextfield( 50,height,"...",GUI.BORDER);
	
	tf.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
			GUI.WIDTH_ABS|GUI.HEIGHT_REL,
			new Geometry.Vec2(0,0),new Geometry.Vec2(50,1.0) );
	
	tf.container:=container;
	tf.onDataChanged = fn(data){
		var v=new Number(data);
		container.setValue(v);
		container.onDataChanged(v);
	};
	container.add(tf);
	// ---o
	container.onDataChanged:=fn(data){};

	container.setRange:=fn(left,right,steps){
		slider.setRange(left,right,steps);
	};

	container.slider := slider;
	container.tf := tf;
	container.f := f ? container->f : fn(value){ return value; };
	container.f_inv := f_inv ? container->f_inv : fn(value){ return value; };
	container.setValue := fn(value){
		slider.setValue(f_inv(value));
		tf.setText(value);
	};
	container.getValue := fn(){
		return f(slider.getValue());
	};
	container.getData := container.getValue; // alias
	container.setData := container.setValue; // alias
	container.addOption:=fn(optionValue){
		this.tf.addOption(optionValue);
	};
	container.addOptions := fn(Array optionValues){
		this.tf.addOptions(optionValues);
	};
	container.setLocked := fn(b){
		this.slider.setLocked(b);
		this.tf.setLocked(b);
		(this->GUI.Component.setLocked)(b);
	};

	// ---
//	container.connectToAttribute:=GUI.Slider.connectToAttribute;
	// ---
	slider.onDataChanged(slider.getValue());

	return container;
};

// -------------------------------------------------------------------------------

/*! Create an empty Component.
	\note Supports negative size values referencing the parent's size. */
GUI.GUI_Manager.createPlaceholder ::= fn(width,height=5){
	var c=this.createLabel("");
	c.setExtLayout(
			GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
			new Geometry.Vec2(0,0),new Geometry.Vec2(width,height) );
	return c;
};

// -------------------------------------------------------------------------------

/*! Create a PopupWindow of the given size and title and a button bar at the bottom.
	- Actions are added via popupWindow.addAction( name [,action] )
		if the action is a function which returns true; the window is kept open
	- Options and general gui elements can be added via popupWindow.addOption( component ) and not via "add"!
	- Options are automatically resized to fit into the window in width.
	- To enable the popupWindow, call popuWindow.init()
	\example
		// simple question:
		var p=gui.createPopupWindow( 300,50,"Are you sure?");
		p.addAction("Yes", fn(){out("Yes!\n");} );
		p.addAction("Perhaps", fn(){ out("Think again!\n"); return true;});
		p.addAction("No");
		p.init();
	\example
		// more complex, including an input option:
		var data=new ExtObject();
		data.m1:=true;
		var p=gui.createPopupWindow( 300,100,"Choose wisely!");
		p.addOption("Some additional information...");
		p.addOption({
					GUI.LABEL : "Select me!",
					GUI.TYPE : GUI.TYPE_BOOL,
					GUI.DATA_OBJECT:	data,
					GUI.DATA_ATTRIBUTE : $m1
		});
		p += "Alternative way of adding an option.";
		p.addAction( "Ok",
			data->fn(){
				out( m1 );
			}
		);
		p.addAction( "Cancel" );
		p.init();
*/
GUI.GUI_Manager.createPopupWindow ::= fn( Number width=300,Number height=50,String title="",
										Number flags=GUI.NO_CLOSE_BUTTON|GUI.NO_MINIMIZE_BUTTON|GUI.ALWAYS_ON_TOP|GUI.ONE_TIME_WINDOW){
	// create window
	var window=this.createWindow(width,height,title,flags);

	window._options := [];
	window._originalAdd := window.add; // backup

	window.addOption := [this]=>fn(gui,component,Bool adjustSize=true){
		var c = gui.create(component);
		if(adjustSize)
			c.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
				GUI.WIDTH_ABS,
				new Geometry.Vec2(0,0),new Geometry.Vec2(-20,0) );
		_options+=c;
	};
	
	window."+=" := window.addOption;
	window.add := window.addOption;

	window._actions := [];
	window.addAction:=fn(String actionName, action = fn(){}, tooltip = void){
		_actions+={'name':actionName,'action':action,'tooltip':tooltip};
	};

	window.init := [this]=>fn(gui){
		clear();
		// add options
		if(_options.count()>0){
			var optionPanel=gui.createPanel(10,10,GUI.AUTO_LAYOUT);
			optionPanel.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
				GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
				new Geometry.Vec2(0,0),new Geometry.Vec2(-4,-30) );
			_originalAdd(optionPanel);
			foreach(_options as var option){
				optionPanel+=gui.create(option,getWidth()-20);
				optionPanel.nextRow();
			}
			var delim=gui.create("----");
			delim.setExtLayout(
					GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
					GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM|
					GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
					new Geometry.Vec2(0,25),
					new Geometry.Vec2(-10,1) );
			_originalAdd(delim);
		}

		// add action buttons
		var numActions=_actions.count();
		foreach(_actions as var i,var action){
			var b=gui.createButton(100,15,action['name']);
			b._action:=action['action'];
			if(action['tooltip']) {
				b.setTooltip(action['tooltip']);
			}
			b._popupWindow:=this;
			b.onClick=fn(){
				var keepOpen=false;
				try{
					keepOpen=_action();
				}catch(e){
					Runtime.warn(e);
				}
				if(!keepOpen){
					_popupWindow.close();
				}
			};
			b.setExtLayout(
				GUI.POS_X_REL|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_LEFT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM|
				GUI.WIDTH_REL|GUI.HEIGHT_ABS,
				new Geometry.Vec2(i/numActions + 1.0/(2.0*numActions),4),
				new Geometry.Vec2(1.0/(numActions+1),15) );
			this._originalAdd(b);
		}
		setPosition(500-getWidth()*0.5,300);
		setEnabled(true);
		activate();
	};

	window.close:=fn(){
		clear();
		setEnabled(false);
	};

	return window;
};

// ------------------------------------------------------------------------------

/*! Creates a container for radio buttons. Buttons can be added with addOption(value[,label])
	e.g.:
	var rb:=gui.createRadioButtonSet("Export format");
	rb.addOption('mmf',"save as mmf");
	rb.addOption('ply',"save as ply");
	rb.setValue('mmf');
	panel.add(rb);
 */
GUI.GUI_Manager.createRadioButtonSet ::= fn(heading=false){
	var container = this.createComponent({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.LAYOUT : (new GUI.FlowLayouter()).setMargin(0),
		GUI.SIZE : [GUI.WIDTH_CHILDREN_ABS | GUI.HEIGHT_CHILDREN_ABS ,0,0]
	});
	if(heading){
		container+= heading;
		container++;
	}
	container.checkBoxes := [];
	container.value := void;
	//! ---o
	container.onDataChanged := fn(data){};

	container.setValue := fn(newValue,forcedRefresh=false){
		if(value!=newValue || forcedRefresh){
			this.value=newValue;
	//		out(newValue,"\n");
			foreach(checkBoxes as var cb){
				if(cb.value == this.value){
					if( ! cb.isChecked())
						cb.setChecked(true);
				}else{
					if( cb.isChecked())
						cb.setChecked(false);
				}
			}
			onDataChanged(newValue);
		}
		return this;
	};

	container.getValue:=fn(){
		return value;
	};

	container.setData:=container.setValue;
	container.getData:=container.getValue;
	container.addOption := [this]=>fn(gui,value,label=false){
		var cb=gui.createCheckbox(label ? label : value,false);
		
		cb.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_CHECKBOX_SHAPE,GUI.BUTTON_SHAPE_NORMAL));
		
		cb.value := value;
		cb.container := this;
		cb.onDataChanged = fn(data){
			if(data){
				container.setValue(this.value);
			}else if( container.getValue() == this.value){
				setChecked(true);
			}

		};
		this.checkBoxes += cb;
		this += cb;
		this++;
	};
	container.setLocked:=fn(b){
		foreach(checkBoxes as var cb){
			cb.setLocked(b);
		}
		(this->GUI.Component.setLocked)(b);
	};
	return container;
};

// ------------------------------------------------------------------------------

/// GUI-Toolbar
GUI.GUI_Manager.createToolbar ::= fn(Number width,Number height,Array entries,[Number,false] entryWidth=false){
	var toolbar = this.create({
		GUI.TYPE				:	GUI.TYPE_CONTAINER,
		GUI.LAYOUT				:	GUI.LAYOUT_TIGHT_FLOW,
		GUI.SIZE				:	[GUI.WIDTH_ABS | GUI.HEIGHT_ABS, width, height]
	});

	var xPos=0;

	var count=entries.count();
	var last=void;
	foreach(entries as var entry){
		count--;
		if( xPos>width-(entryWidth?entryWidth:50)){
			toolbar.nextRow();
			xPos=0;
		}

		if(entry.isA(String)){
			var s=entry.toString().replaceAll('\n','�\n�');
			foreach(s.split('\n') as var part){
				if(part.beginsWith('�')){
					toolbar.nextRow(4);
					xPos=0;
					if(last.isA(GUI.Button)){
						last.setButtonShape(GUI.BUTTON_SHAPE_RIGHT);
					}
				}
				part=part.replaceAll('�',"");
				if(part.length()>0){
					toolbar.add(this.createLabel(part));
					xPos+=entryWidth;
				}
			}
		}else{
			var c=this.create(entry,entryWidth);
			toolbar.add(c);
			if(c.isA(GUI.Button)){
				if(xPos==0)
					c.setButtonShape(GUI.BUTTON_SHAPE_LEFT);
				else if(count==0){
					c.setButtonShape(GUI.BUTTON_SHAPE_RIGHT);
				}else
					c.setButtonShape(GUI.BUTTON_SHAPE_MIDDLE);
			}
			xPos+=c.getWidth();
			last=c;
		}
	}
	return toolbar;
};

// ------------------------------------------------------------------------------------

return true;
