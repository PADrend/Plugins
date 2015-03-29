/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2015 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Test/Tests_GUI.escript
 **/
static gui;

var plugin = new Plugin({
		Plugin.NAME : 'Tests/Tests_GUI',
		Plugin.DESCRIPTION : 'For testing new gui features...',
		Plugin.VERSION : 0.2,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [ 'Tests' ],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) :=fn(){
	module.on('PADrend/gui', this->fn(_gui){
		gui = _gui;
		gui.register('Tests_TestsMenu.gui',[
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "GUI Tests",
				GUI.ON_CLICK : this->showWindow
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "GUI memory monitoring",
				GUI.ON_CLICK : this->showMemoryWindow,
				GUI.TOOLTIP : "All newly created Components are monitored for their destruction."
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Print GUI registry",
				GUI.ON_CLICK : fn(){
//						print_r(gui._getComponentProviderRegistry());
					// print only the groups and not the component themselves 
					var m = new Map;
					foreach(gui._getComponentProviderRegistry() as var groupName,var group){
						m[groupName] = new Map;
						foreach(group as var entryName,var entry)
							m[groupName][entryName] =  entry.toDbgString();
					}
					print_r(m);
				},
				GUI.TOOLTIP : "Print the registered component provider groups to the console."
			}
		]);
	});
	this.window:=void;
	this.memoryWindow:=void;
	this.panel:=void;
	return true;
};


//! (internal)
plugin.showMemoryWindow := fn(){
	if(this.memoryWindow){
		window.setEnabled(true);
		memoryWindow;
	}

	memoryWindow = gui.createWindow(320,200,"GUI memory monitor");
	memoryWindow.setPosition(200,20);

	var panel = gui.createPanel(1,1,GUI.AUTO_MAXIMIZE|GUI.AUTO_LAYOUT);
	memoryWindow+=panel;
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Enable/Reset",
		GUI.ON_CLICK : fn(){
			gui._destructionMonitor = new Util.DestructionMonitor();
		}
	};
	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Disable",
		GUI.ON_CLICK : fn(){
			gui._destructionMonitor = void;
		}
	};
	panel++;


	panel += "Pending components: ";

	var l = gui.create({
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : "......",
		GUI.FONT : GUI.FONT_ID_LARGE
	});
	panel += l;

	registerExtension('PADrend_AfterFrame',l->fn(){
		this.setText( gui._destructionMonitor ? gui._destructionMonitor.getPendingMarkersCount() :"[disabled]" );
	});

	panel++;
	panel+=" ";
	panel++;

	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Extract released markers",
		GUI.ON_CLICK : fn(){
			print_r(gui._destructionMonitor.extractMarkers());
		}
	};
	panel++;

	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "getPendingMarkersNames()",
		GUI.ON_CLICK : fn(){
			print_r(gui._destructionMonitor.getPendingMarkersNames());
		}
	};



};


//! (internal)
plugin.showWindow:=fn(){
	if(this.window){
		window.setEnabled(true);
		return;
	}
	window = gui.createWindow(800,800,"GUI Tests");
	window.setPosition(20,20);

	var ct = gui.createPanel(400,500,GUI.AUTO_MAXIMIZE);
	ct.setMargin(0);
	window += ct;
	

	panel = gui.createEditorPanel();
	ct.add(panel);
	
	var last=void;
	panel.components:=[];
	for(var i=1;i<10;i++){
		var component =gui.createContainer(110,30);

		var label =gui.createLabel(100,20,"Foo"+i,GUI.LOWERED_BORDER);
		label.setExtLayout(
					GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
					GUI.POS_Y_ABS|GUI.REFERENCE_Y_CENTER|GUI.ALIGN_Y_CENTER|
					GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
					new Geometry.Vec2(0,0),new Geometry.Vec2(-10,-10) );
		component.add(label);
		component.setPosition(Rand.uniform(300,1700),Rand.uniform(0,1700));

		var con1 = gui.create({
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.SIZE : [10,10],
			GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_CENTER|GUI.ALIGN_Y_CENTER, 0,0],
			GUI.ON_CLICK : fn(){
				var connectors=GUI.findConnectors(panel,this);
				print_r(connectors);
			}
		});

		component += con1;
		component.con1:=con1;
		con1.panel:=panel;
		con1.getConnectionVectors:=fn(){
			var connectors=GUI.findConnectors(panel,this);
			var vecs=[];
			foreach(connectors as var c){
				if(c.getFirstComponent() == this)
					vecs+= c.getSecondComponent().getAbsPosition()-
												c.getFirstComponent().getAbsPosition();
				else
					vecs+= c.getFirstComponent().getAbsPosition()-
								c.getSecondComponent().getAbsPosition();
			}
			return vecs;
		};
		var con2=gui.createButton(10,10,"");
		con2.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_CENTER|GUI.ALIGN_Y_CENTER,
			new Geometry.Vec2(0,0) );
		component.add(con2);
		component.con2:=con2;
		con2.panel:=panel;
		con2.onClick=con1.onClick;
		con2.getConnectionVectors:=con1.getConnectionVectors;

		panel.add(component);
		if(last){
			var con=gui.createConnector();
//			out(con);
			con.setFirstComponent(last);
			con.setSecondComponent(con2);
			panel.add(con);
		}
		last=con1;
		panel.components+=component;

		component.relax:=fn(dist,other){
			var vecs=con1.getConnectionVectors();
//			vecs.append(con2.getConnectionVectors());
			var move=new Geometry.Vec2();
			foreach(vecs as var v){
				var l=v.length();
				if(l<dist) continue; // todo: use rand!
				var v2=v.clone().normalize()*dist;
				move+=(v-v2)*0.3;
			}
			foreach(other as var c){
				if(c==this){
					continue;
				}
				if(c.getAbsRect().intersects(getAbsRect())){
					if(Rand.uniform(0,1)>0.8){
						var p=getPosition();
						setPosition(c.getPosition());
						c.setPosition(p);
					}else{
						move+=(getAbsPosition()-c.getAbsPosition())*0.8;
					}
				}
			}
			setPosition(getPosition()+move);
//			print_r(vecs);
		};
	}

	panel.onDataChanged = fn(data){
		print_r(getData());
	};

	//
	var b=gui.createButton(100,15,"relayout");
	b.setPosition( 0,70 );
	b.onClick=panel->fn(){
		for(var i=0;i<2;i++)
		foreach(components as var c){
			c.relax(200,components);
		}
	};
	panel.add(b);


	var cb=gui.createCombobox(100,15,["foo","bar","dings"]);
	panel.add(cb);

	var dd=gui.createDropdown(100,15);
	dd.setPosition( 0,50 );
	dd.addOption(1,"Foo");
	dd.addOption(2,"Bar");
	dd.addOption("Dings");
	dd.addOption("Value","Menu","Select");
	dd.setData(2);
	panel.add(dd);

	// ---------------

	b=gui.createButton(100,15,"Popup test 1");
	b.setPosition( 0,100 );
	b.onClick=fn(){
		var p=gui.createPopupWindow( 300,50,"Are you sure?");
		p.addAction("Yes", fn(){outln("Yes!");} );
		p.addAction("Perhaps", fn(){ outln("Think again!"); return true;});
		p.addAction("No");
		p.init();
	};
	panel.add(b);

	// ---------------

	panel += {
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Popup test 2",
		GUI.SIZE : [100,15],
		GUI.POSITION : [0,120],
		GUI.ON_CLICK : fn(){
			var data=new ExtObject({
				$name : "Norbert",
				$age : 276,
				$weight : 0.4,
				$sex : 0,
				$species :"Dragon",
				$vegetarian : true,
				$photo : "norbert.jpg"
			});
			
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_POPUP_DIALOG,
				GUI.LABEL : "Choose wisely!",
				GUI.SIZE : [300,240],
				GUI.OPTIONS : [
					"Who are you?",
					{
						GUI.LABEL : "Name",
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.DATA_OBJECT:	data,
						GUI.DATA_ATTRIBUTE : $name
					},
					{
						GUI.LABEL : "Age",
						GUI.TYPE : GUI.TYPE_NUMBER,
						GUI.DATA_OBJECT:	data,
						GUI.DATA_ATTRIBUTE : $age,
						GUI.OPTIONS : [0,100,1000]
					},
					{
						GUI.LABEL : "Weight (t)",
						GUI.TYPE : GUI.TYPE_RANGE,
						GUI.RANGE : [0,2.0],
						GUI.RANGE_STEP_SIZE : 0.1,
						GUI.DATA_OBJECT:	data,
						GUI.DATA_ATTRIBUTE : $weight
					},
					{
						GUI.LABEL : "Sex",
						GUI.TYPE  : GUI.TYPE_SELECT,
						GUI.OPTIONS : [ [-1,"(?) I don't know, what it is.","?","Please have a closer look!"] , [0,"male"] , [1,"female"]],
						GUI.DATA_OBJECT:	data,
						GUI.DATA_ATTRIBUTE : $sex
					},
					{
						GUI.LABEL : "Species",
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.OPTIONS : ["Human","Dragon","Thing"],
						GUI.DATA_OBJECT:	data,
						GUI.DATA_ATTRIBUTE : $species
					},
					{
						GUI.LABEL : "Vegetarian",
						GUI.TYPE : GUI.TYPE_BOOL,
						GUI.DATA_OBJECT:	data,
						GUI.DATA_ATTRIBUTE : $vegetarian
					},
					{
						GUI.LABEL : "Photo",
						GUI.TYPE : GUI.TYPE_FILE,
						GUI.ENDINGS : [".jpg",".png"],
						GUI.DATA_OBJECT : data,
						GUI.DATA_ATTRIBUTE : $photo
					}
				],
				GUI.ACTIONS : [
					["Ok", [data]=>fn(data){
						gui.openDialog({
							GUI.TYPE : GUI.TYPE_POPUP_DIALOG,
							GUI.LABEL : "Summary",
							GUI.SIZE : [300,300],
							GUI.OPTIONS : [toJSON(data._getAttributes())],
							GUI.ACTIONS : ["Done..."]
						});
					}],
					"Cancel"
				]
			});
		}
	};

	// -----------------------------------------------------------------
	var p=gui.createPanel(400,500,GUI.AUTO_LAYOUT|GUI.RAISED_BORDER);
	p.setPosition(0,200);
	panel+=p;
	// header
	p+="*Test panel for gui components created from descriptions*";
	p++;
	// delimiter
	p+="----";
	p++;

	gui.register('Tests_ContentTest.00_header',["*Container*","This content is provided by a component provider!"]);
	gui.register('Tests_ContentTest.10_somethingElse',["Some external extension to the content..."]);
	gui.register('Tests_ContentTest.90_footer',['----']);
	
	// registered components
	p += {
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.LAYOUT : GUI.LAYOUT_BREAKABLE_TIGHT_FLOW,
		GUI.CONTENTS : 'Tests_ContentTest',
		GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 5,40]
	};
	
	
	
	p++;
	// button
	p+={
		GUI.LABEL : "click me",
		GUI.ON_CLICK : fn(){
			setText(getText()+"!");
		},
		GUI.TOOLTIP : "changing its text on click"
	};
	p+={
		GUI.TYPE : GUI.TYPE_CRITICAL_BUTTON,
		GUI.LABEL : "Critical action",
		GUI.ON_CLICK : fn(){	PADrend.message("Critical action performed.");	},
		GUI.REQUEST_MESSAGE : "Really perform the critical action?",
		GUI.TOOLTIP : "Outputs a message after an additional confirmation."
	};

	p++;
	// menu
	p+={
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "Menu",
		GUI.MENU : [
			"*header*",
			"foo",
			"----",
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Submenu 1",
				GUI.TOOLTIP : "This submenu has already created and is opened when you push the button.",
				GUI.MENU : [
					{
						GUI.TYPE : GUI.TYPE_MENU,
						GUI.LABEL : "Submenu 1a",
						GUI.MENU : ["foo","bar"]
					},
					{
						GUI.TYPE : GUI.TYPE_MENU,
						GUI.LABEL : "Submenu 1a",
						GUI.MENU : ["foo","bar"]
					}
				]
			},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Submenu 2",
				GUI.TOOLTIP : "This submenu is \n created dynamically when \n you push the button.",
				GUI.ON_CLICK : fn(){
					// static counter
					if(!thisFn.isSet($counter)) thisFn.counter:=0;


					getParentComponent().openSubmenu(this,[
							"*Dynamic menu*",
							"Counter :"+( ++thisFn.counter);
						]);
				}
			},
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Submenu 3",
				GUI.TOOLTIP : "This submenu is also \n created dynamically when \n you push the button.",
				GUI.MENU : fn(){
					// static counter
					if(!thisFn.isSet($counter)) thisFn.counter:=0;

					return [
							"*Dynamic menu*",
							"Counter :"+( ++thisFn.counter);
					];
				}
			},
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Submenu 4",
				GUI.TOOLTIP : "This submenu is created using a registered component provider-",
				GUI.MENU : 'Tests_ContentTest'
				
			}
		]
	};

	p++;

	// create an ExtObject which holds all data attributes.
	var obj=new ExtObject();
	obj.t1:=17;
	obj.file:="test.txt";
	obj.color1:=new Util.Color4f(1.0,0.0,0.0);

	// this refreshGroup can be used to sync the components connected to the same attribute and
	// to update the data values.
	var refreshGroup=new GUI.RefreshGroup();

	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Text 1",
		GUI.DATA_OBJECT : obj,
		GUI.DATA_ATTRIBUTE : $t1,
		GUI.DATA_REFRESH_GROUP : refreshGroup
	};
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "value 2",
		GUI.RANGE : [0,32],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.DATA_OBJECT : obj,
		GUI.DATA_ATTRIBUTE : $t1,
		GUI.DATA_REFRESH_GROUP : refreshGroup,
		GUI.OPTIONS : [0,4,17,27],
		GUI.TOOLTIP : "This slider has some default values.\nUse the mouse wheel inside the text field to switch them through."
	};
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Exponential value ",
		GUI.RANGE : [0,5],
		GUI.RANGE_STEP_SIZE : 1,
		GUI.RANGE_FN : fn(v){ return (2).pow(v); },
		GUI.RANGE_INV_FN : fn(v){ return (0+v).log(2); }, // (0+v) as v can be -inf which is not properly interpreted as a number
		GUI.DATA_OBJECT : obj,
		GUI.DATA_ATTRIBUTE  : $t1,
		GUI.DATA_REFRESH_GROUP : refreshGroup
	};
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_NUMBER,
		GUI.LABEL : "Random dataProvider",
		GUI.DATA_PROVIDER : fn(){
			return Rand.equilikely(0,10);
		},
		GUI.ON_DATA_CHANGED : [refreshGroup,obj]=>fn(refreshGroup,dataObject, d){
			dataObject.t1 = d;
			refreshGroup.refresh();
		},
		GUI.DATA_REFRESH_GROUP : refreshGroup,
		GUI.TOOLTIP : "Whenever a refresh is issued a new random number is set.\n If a value is entered manually, it is assigned to the above elements."
	};
	p+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.ICON : "#RefreshSmall",
		GUI.ICON_COLOR : GUI.BLACK,
		GUI.FLAGS : GUI.FLAT_BUTTON,
		GUI.ON_CLICK : refreshGroup->refreshGroup.refresh
	};




	p++;
	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "File (manual)",
		GUI.DATA_OBJECT : obj,
		GUI.DATA_REFRESH_GROUP : refreshGroup,
		GUI.DATA_ATTRIBUTE : $file
	};
	p+={
		GUI.TYPE  : GUI.TYPE_BUTTON,
		GUI.LABEL : "...",
		GUI.WIDTH : 20,
		GUI.ON_CLICK : [obj,refreshGroup]=>fn(obj,refreshGroup){
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_FILE_DIALOG,
				GUI.LABEL : "select a txt file",
				GUI.ENDINGS : [".txt"],
				GUI.ON_ACCEPT : [obj,refreshGroup]=>fn(obj,refreshGroup,filename){
					obj.file=filename; 
					refreshGroup.refresh(); 
				}
			});
		}
	};
	p++;
	p+={
		GUI.TYPE  : GUI.TYPE_FILE,
		GUI.LABEL : "File (fileSelector)",
		GUI.ENDINGS : ['.escript'],
		GUI.DIR : "plugins",
		GUI.DATA_OBJECT : obj,
		GUI.DATA_REFRESH_GROUP : refreshGroup,
		GUI.DATA_ATTRIBUTE : $file
	};
	p++;
	p+={
		GUI.TYPE  : GUI.TYPE_COLOR,
		GUI.LABEL : "ColorPicker 1",
		GUI.DATA_OBJECT : obj,
		GUI.DATA_ATTRIBUTE : $color1,
		GUI.DATA_REFRESH_GROUP : refreshGroup
	};
	p++;
	p+={
		GUI.TYPE  : GUI.TYPE_COLOR,
		GUI.LABEL : "ColorPicker 2",
		GUI.DATA_OBJECT : obj,
		GUI.DATA_ATTRIBUTE : $color1,
		GUI.DATA_REFRESH_GROUP : refreshGroup
	};
	p++;
	p+='----';
	p++;

	{
		// ------------------------------------------
		p+="*DataWrapper*";
		p++;
		var sideLength = DataWrapper.createFromConfig( PADrend.configCache,'Test.GuiTests.sideLength',1 ).setOptions([1,2,4,9]);
		var area = DataWrapper.createFromFunctions( [sideLength]=>fn(sideLength){	return sideLength()*sideLength(); },
													[sideLength]=>fn(sideLength,data){	sideLength.set(data.sqrt());} );
		// propagate changes of the sideLength to the area. sideLength and data are now directly connected, even without any gui element triggering a refreshGroup.
		sideLength.onDataChanged += area->fn(data){refresh();};

		p+={
			GUI.TYPE  : GUI.TYPE_RANGE,
			GUI.LABEL : "Side length",
			GUI.RANGE : [0,10],
			GUI.DATA_WRAPPER : sideLength,
			GUI.TOOLTIP : "This value should be stored in the configCache"
		};
		p++;
		p+={
			GUI.TYPE  : GUI.TYPE_NUMBER,
			GUI.LABEL : "Side length (as Number)",
			GUI.DATA_WRAPPER : sideLength,
		};
		p++;
		p+={
			GUI.TYPE  : GUI.TYPE_TEXT,
			GUI.LABEL : "Side length (as Text)",
			GUI.DATA_WRAPPER : sideLength,
		};
		p++;
		p+={
			GUI.TYPE  : GUI.TYPE_NUMBER,
			GUI.LABEL : "Area",
			GUI.DATA_WRAPPER : area,
			GUI.TOOLTIP : "This input is coupled to the ones above using a direct data connection"
		};
		p++;

	}

	{
		// ------------------------------------------
		p+="*DataWrapper with GUI.RefreshGroup*";
		p++;
		var sideLength = DataWrapper.createFromValue( 9 );
		var area = DataWrapper.createFromFunctions( [sideLength]=>fn(sideLength){	return sideLength()*sideLength(); },
													[sideLength]=>fn(sideLength,data){	sideLength.set(data.sqrt());} );

		// Use a refresh group to connect dependent data values using their gui components.
		var refreshGroup = new GUI.RefreshGroup();

		p+={
			GUI.TYPE  : GUI.TYPE_RANGE,
			GUI.LABEL : "Side length",
			GUI.RANGE : [0,10],
			GUI.DATA_WRAPPER : sideLength,
			GUI.DATA_REFRESH_GROUP : refreshGroup,
			GUI.TOOLTIP : "This value has an initial value of 9"
		};
		p++;


		p+={
			GUI.TYPE  : GUI.TYPE_RANGE,
			GUI.LABEL : "Area",
			GUI.RANGE : [0,100],
			GUI.DATA_WRAPPER : area,
			GUI.DATA_REFRESH_GROUP : refreshGroup,
			GUI.TOOLTIP : "This input is coupled to the one above using a refreshGroup"
		};
		p++;

	}

	// -------------------------------
	p+="*TreeView*";
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_TREE,
		GUI.HEIGHT : 100,
		GUI.OPTIONS : [
			{
				GUI.TYPE : GUI.TYPE_TREE_GROUP,
				GUI.OPTIONS : [
					"foods",
					"banana",
					"potato",
					{
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : "stuff",
						GUI.ON_CLICK : fn(){outln("Stuff!");}
					}
				]
			},
			"drinks"
		]
	};
	p++;
	// -------------------------------
	p+="*MouseButtonListener*";
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_PANEL,
		GUI.HEIGHT : 70,
		GUI.WIDTH : 300,
		GUI.FLAGS : GUI.BORDER,
		GUI.TOOLTIP : "Click me!\nAnd create an element at the border, scroll there and try if \nnew elements are even inserted correctly\n while the clientAreaPanel is moved.",
		GUI.ON_MOUSE_BUTTON : fn(evt){
			if(!evt.pressed)
				return false;
			this += {
				GUI.TYPE : GUI.TYPE_LABEL,
				GUI.LABEL : "B:"+evt.button,
				GUI.FLAGS : GUI.BORDER,
				GUI.POSITION : [evt.x, evt.y]
			};
			if(this.numChildren()>35)
				clear();
			return false;
		},
		GUI.FLAGS : GUI.BORDER // make shure that the clientAreaPanel tightly encloses children, so that scrollbars may appear.
	};

	p++;
	// -------------------------------
	p+="*Dragging*";
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.WIDTH : 60,
		GUI.HEIGHT : 60,
		GUI.LABEL : "Drag me!",
		GUI.TOOLTIP : "Drag me with the left mouse button",
		GUI.ON_INIT : fn(...){
			this.x:=0;
			this.y:=0;
		},
		GUI.DRAGGING_ENABLED : true,
		GUI.DRAGGING_BUTTONS : [Util.UI.MOUSE_BUTTON_LEFT],
		GUI.ON_DRAG : fn(evt){
			this.x+=evt.deltaX;
			this.y+=evt.deltaY;
			setText(""+x+":"+y);
		}
	};
	p+={
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : "Drag Me!",
		GUI.TOOLTIP : "Changes the text and the style of the connection depending on the component under the cursor.",
		GUI.DRAGGING_ENABLED : true,
		GUI.DRAGGING_MARKER : true,
		GUI.DRAGGING_CONNECTOR : true,
		GUI.ON_START_DRAGGING : fn(evt){
			PADrend.message("Dragging...");
		},
		GUI.ON_DROP : fn(evt){
			var c = gui.getComponentAtPos(gui.screenPosToGUIPos( [evt.x,evt.y] ));
			PADrend.message("Dropped on "+c);
			this.setText("Drag Me!");
		},
		GUI.ON_DRAG : fn(evt){
			getDraggingMarker().setEnabled(false);
			getDraggingConnector().setEnabled(false);
			
			var c = gui.getComponentAtPos(gui.screenPosToGUIPos( [evt.x,evt.y] ));
			if(c.isSet($getData)){
				getDraggingConnector().clearProperties();
				getDraggingConnector().addProperty(
						new GUI.ShapeProperty(GUI.PROPERTY_CONNECTOR_LINE_SHAPE,
							gui._createStraightLineShape(new Util.Color4f(0,1,0,0.3),5)));
				this.setText("Data:" + c.getData());
			}else if(c!=this && c.isSet($getText)){
				getDraggingConnector().clearProperties();
				getDraggingConnector().addProperty(
						new GUI.ShapeProperty(GUI.PROPERTY_CONNECTOR_LINE_SHAPE,
							gui._createSmoothConnectorShape(new Util.Color4f(1,0,0,0.3),5)));
				this.setText("Text:" + c.getText());
			}else{
				getDraggingConnector().clearProperties();
				getDraggingConnector().addProperty(
						new GUI.ShapeProperty(GUI.PROPERTY_CONNECTOR_LINE_SHAPE,
							gui._createSmoothConnectorShape(new Util.Color4f(0,0,0,0.3),500/(1+getDraggingConnector().getLength()))));
				this.setText("Place over a component!" );
			}
				
			getDraggingMarker().setEnabled(true);
			getDraggingConnector().setEnabled(true);
		}
	};

	p++;
	// -------------------------------
	p+="*Locked components*";
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "text...",
		GUI.FLAGS : GUI.LOCKED,
		GUI.DATA_VALUE : "Try to change me!"
	};
	p++;
	p+={
		GUI.LABEL : "select",
		GUI.TYPE : GUI.TYPE_SELECT,
		GUI.OPTIONS : [ [0,"Option 1"], [1,"Option 2"], [2,"Option 3"]],
		GUI.FLAGS : GUI.LOCKED
	};
	p++;
	p+={
		GUI.LABEL : "Locked button",
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.FLAGS : GUI.LOCKED
	};
	p++;
	// -------------------------------
	p++;
	p+="*Column test*";
	p++;

	{
		var p2 = gui.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.FLAGS : GUI.BORDER | GUI.AUTO_LAYOUT,
			GUI.SIZE : [GUI.WIDTH_CHILDREN_ABS|GUI.HEIGHT_CHILDREN_ABS,2,2]
		});

		p2+="Header";
		p2.nextColumn();
		p2+="Header 2";
		p2.nextColumn();
		p2+="Header 3";
		p2++;

		p2+="0";
		p2.nextColumn();
		p2+="Some very long entry... foo bar blubb blubb";
		p2.nextColumn();
		p2+="2";
		p2++;

		p2+="77";
		p2.nextColumn();
		p2+="4";
		p2.nextColumn();
		p2+="5";
		p2++;

		p2+="0";
		p2.nextColumn();
		p2+="Some very long entry";
		p2.nextColumn();
		p2+="2";
		p2++;

		p+=p2;
	}

	// -------------------------------
	p++;
	p+="*ListView test (with binary numbers)*";
	p++;
//	{
//		var lv=gui.createListView();
//		lv.setWidth(320);
//		lv.setHeight(200);
//		lv+="foo";
//		lv+="bar";
//		for(var i=0;i<1000;++i){
//			lv+="dumdidum"+i;
//
//		}
//
//		p+=lv;
//	}
	p++;
	// \todo tree view with marking limit: 0,1,>0
	{
		var refreshGroup = new GUI.RefreshGroup();
		var numbers = [1,3,5]; // == 42

		var options = [];
		for(var i=0;i<16;++i)
			options += [i,"2^"+i+" = "+2.pow(i)];
		p+={
			GUI.TYPE : GUI.TYPE_LIST,
			GUI.WIDTH : 320,
			GUI.HEIGHT : 100,
			GUI.OPTIONS : options,
			GUI.ON_DATA_CHANGED : [numbers,refreshGroup]=>fn(numbers,refreshGroup,data){
				numbers.swap(data);
				refreshGroup.refresh();
			},
			GUI.DATA_REFRESH_GROUP : refreshGroup,
			GUI.DATA_PROVIDER : [numbers]=>fn(numbers){
				return numbers.clone();
			},
		};
		p++;
		p+={
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "Numbers:",
			GUI.DATA_REFRESH_GROUP : refreshGroup,
			GUI.DATA_PROVIDER : [numbers]=>fn(numbers){
				return numbers.implode(",");
			},
			GUI.ON_DATA_CHANGED : [numbers,refreshGroup]=>fn(numbers,refreshGroup,data){
				numbers.swap(data.split(","));
				refreshGroup.refresh();
			}
		};
		p++;
		p+={
			GUI.TYPE : GUI.TYPE_RANGE,
			GUI.LABEL : "Numbers:",
			GUI.RANGE : [0,65535],
			GUI.DATA_REFRESH_GROUP : refreshGroup,
			GUI.DATA_PROVIDER : [numbers]=>fn(numbers){
				var v = 0;
				foreach(numbers as var p)
					v += 2.pow(p);
				return v;
			},
			GUI.ON_DATA_CHANGED : [numbers,refreshGroup]=>fn(numbers,refreshGroup,data){
				var a = [];
				for(var i=0;i<16;++i){
					if( (2.pow(i)&data) > 0 )
						a+=i;
				}
				numbers.swap(a);
				refreshGroup.refresh();
			}
		};

	}
	p++;
	p+="----";
	p++;
	{
		p+="*ListView test 2*";
		p++;
		var lv = gui.create({
			GUI.TYPE : GUI.TYPE_LIST,
			GUI.WIDTH : 320,
			GUI.HEIGHT : 50,
			GUI.LIST_ENTRY_HEIGHT : 10,
			GUI.FLAGS : GUI.AT_LEAST_ONE_MARKING | GUI.AT_MOST_ONE_MARKING,
			GUI.ON_DATA_CHANGED : fn(data){
				print_r(data);
			},GUI.TOOLTIP : "Exactly one component should always be selected.\nThe data is written to the default ouput."
		});
		lv.clear(); // this clear() should have no effect, but it lead to a crash in an early version. Leave it as regression test!
		for(var i=0;i<1000;++i){
			lv+="Some entry #"+i;
			lv+=[i,"Some entry with value #"+i];
		}
		p+=lv;
		p++;
	}
	p++;



	var sampleList = gui.create({
		GUI.TYPE				:	GUI.TYPE_LIST,
		GUI.OPTIONS				:	[],
		GUI.ON_DATA_CHANGED		:	(fn(data) {
										print_r(data);
		}),
		GUI.SIZE				:	[GUI.WIDTH_REL | GUI.HEIGHT_ABS, 1, 50]
	});
	// When there is a real list view, this function can be changed into a GUI.DATA_PROVIDER function.
	sampleList.clear();
	sampleList += [1,"foo"];
	sampleList += [2,"bar"];
	p+=sampleList;
	p++;

	p+=sampleList;
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "!!!",
		GUI.ON_CLICK : sampleList -> fn(){
			this.clear();
			for(var i=0;i<10;++i)
				this += [i,"foo"+i];
			this += [false,"bar"];

		}
	};
	// Tabbed Panel
	{
		p++;
		p+='----';
		p++;
		p+="Tabbed Panel";
		p++;

		var tabbedPanel = gui.create({
			GUI.TYPE : GUI.TYPE_TABBED_PANEL,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS, 10, 70]
		});
		p+=tabbedPanel;

		tabbedPanel.addTab("TabA",{
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.SIZE : GUI.SIZE_MAXIMIZE,
			GUI.LAYOUT : GUI.LAYOUT_FLOW,
			GUI.CONTENTS : [
				"*This is tab A*"
			]
		});
		var tabContent_2 = gui.create({
			GUI.TYPE : GUI.TYPE_PANEL,
			GUI.SIZE : GUI.SIZE_MAXIMIZE,
			GUI.LAYOUT : GUI.LAYOUT_FLOW,
			GUI.CONTENTS : [
				"*This is tab B*",
				{	GUI.TYPE : GUI.TYPE_NEXT_ROW },
				"Some text...\n"*50,
			]
		});
		tabbedPanel.addTab("TabB",tabContent_2,"This tab internally uses a panel \n that provides a scrollbar when needed.");

	}


	// Drag and Drop test

//	{
//
//		// EXPERIMENTAL!!!
//
//		var l = gui.create({
//			GUI.TYPE : GUI.TYPE_LABEL,
//			GUI.LABEL : "(Drag me!)",
//			GUI.ON_MOUSE_BUTTON : fn(evt){
//				print_r(evt._getAttributes());
//			}
//		});
////		p+=l;
//		gui.onMouseMove := l->fn(evt){
//			print_r(evt._getAttributes());
//			setPosition(evt.absPosition);
//		};
//
//		gui.registerWindow(l);
//
//
//	}



	//!!!!!!!!!!!!!!!!!
	p++;
	p+='----';
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_MULTILINE_TEXT,
		GUI.LABEL : "Multi line text entry",
		GUI.SIZE : [320,200],
		GUI.DATA_VALUE : "Foo\nBar\nHoobel\ndoobel\n",
		GUI.ON_DATA_CHANGED : fn(text){outln('"',text,'"');}
	};


	p++;
	p+='----';
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.LABEL : "Collapsible container",
		GUI.CONTENTS : ["foo","bar",
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW },
			{
				GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
				GUI.LABEL : "Nested container",
				GUI.CONTENTS : ["foo","bar"],
				GUI.COLLAPSED : true
			},
		
		]
	};
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_COLLAPSIBLE_CONTAINER,
		GUI.HEADER : ["Collapsible"," container ","II"],
		GUI.CONTENTS : fn(){return ["The collapsing state of this container\nis stored in the config."];},
		GUI.COLLAPSED : DataWrapper.createFromConfig( PADrend.configCache,'Test.GuiTests.collapsedContainer',false )
	};
	p++;
	p+='----';
	p++;

	{	// LibGUIExt/Traits/RefreshableContainerTrait
		p+="LibGUIExt/Traits/RefreshableContainerTrait";
		p++;
		var c = gui.create({
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Refresh with random content",
			GUI.ON_CLICK : fn(){	this.refresh();	},	//! \see LibGUIExt/Traits/RefreshableContainerTrait
			GUI.WIDTH : 300,
		});
		Traits.addTrait(c,Std.require('LibGUIExt/Traits/RefreshableContainerTrait'),fn(){
			var s="";
			for(var i=Rand.equilikely(2,10);i>0;--i )
				s += " "+i;
			return [s];
		});
		p+=c;
		
		p++;
	}
	{	// DynamicContainer
		
		p+="DynamicContainer";
		p++;
		var text = new Std.DataWrapper;
		var words = new Std.DataWrapper;
		text.onDataChanged += [words]=>fn(words,t){	words(t.split(" "));};
		text("foo bar");
		gui.register('Test_dynamicContainer',["registeredText"]);
		words('Test_dynamicContainer');
		p += {
			GUI.TYPE : GUI.TYPE_TEXT,
			GUI.LABEL : "Type some words",
			GUI.DATA_WRAPPER : text
		};
		p++;
		p += {
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.CONTENTS : words,
			GUI.LAYOUT : GUI.LAYOUT_BREAKABLE_TIGHT_FLOW,
			GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 5,40],
			GUI.TOOLTIP : "Initially: registeredText"
		};
		p++;
	}
	{	// presets
		p+='----';
		p += GUI.NEXT_ROW;
		p += "*Presets*";
		p += GUI.NEXT_ROW;
		
		var preset = {
			GUI.TOOLTIP : "Tooltip added by preset",
			GUI.PROPERTIES : [new GUI.ColorProperty(GUI.PROPERTY_TEXT_COLOR, new Util.Color4ub(0,100,0,255))]
		};
		gui.registerPreset('test/greenLabel1',preset);
		gui.registerPreset('test',{
			GUI.FLAGS : GUI.BORDER,
			GUI.WIDTH :100
		});
		p += {
			GUI.TYPE : GUI.LABEL,
			GUI.PRESET : 'test/greenLabel1',
			GUI.LABEL : "Using named preset for green text."
		};
		p += GUI.NEXT_ROW;
		p += {
			GUI.TYPE : GUI.LABEL,
			GUI.PRESET : preset,
			GUI.LABEL : "Using preset map for green text."
		};
		p += GUI.NEXT_ROW;
		p += {
			GUI.TYPE : GUI.LABEL,
			GUI.PRESET : [preset]=>fn(preset){return preset;},
			GUI.LABEL : "Using preset-callback for green text."
		};
		p += GUI.NEXT_ROW;
		p += {
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.PRESET : 'test',
			GUI.CONTENTS : [{
				GUI.TYPE : GUI.LABEL,
				GUI.PRESET : './greenLabel1',
				GUI.LABEL : "Using relatively named preset for green text."
			}],
		};
		p += GUI.NEXT_ROW;
		p += {
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.PRESET : 'test',
			GUI.CONTENTS : [{
					GUI.TYPE : GUI.TYPE_CONTAINER,
					GUI.WIDTH : GUI.SIZE_MAXIMIZE,
					GUI.CONTENTS : [{
						GUI.TYPE : GUI.LABEL,
						GUI.PRESET : './greenLabel1',
						GUI.LABEL : "Using relatively named preset in nested container for green text."
					}],
			}]
		};
		p += GUI.NEXT_ROW;
		
	}


	p+="----";
	p++;
	p+="*Bug Testcases*";
	p++;
	p+="WIDTH_FILL_...";
	p++;
	p+={
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.SIZE : [GUI.WIDTH_FILL_REL,0.5,0],
		GUI.FLAGS : GUI.BORDER,
		GUI.LABEL : "50% ->"
	};
	p+={
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,30,0],
		GUI.FLAGS : GUI.BORDER,
		GUI.LABEL : "30px ->"
	};
	p++;
	
	// DataWrapper cleanup
	p+="DataWrapper de-registration";
	p++;
	var v = DataWrapper.createFromValue("foo");
	p+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "...",
		GUI.ON_CLICK : [v]=>fn(v){
			var container = gui.create({	GUI.TYPE : GUI.TYPE_CONTAINER	});
			container += {
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.DATA_WRAPPER : v
			};
			container.destroyContents();
			v(v()+"."); // trigger onDataChanged.
			setText(v.onDataChanged.empty() ? "ok" : v.onDataChanged.count());
		},
		GUI.TOOLTIP : "When pressing the button, a component is bound to a \n"
			"DataWrapper and is then destroyed.\n"
			"The button shows the number of onDataChanged-listeners (or 'ok')and should\n"
			"always be 0, as the listeners should be removed automatically."
	};
	{
		p++;
		p += {
			GUI.TYPE : GUI.TYPE_MENU , 
			GUI.LABEL : "Bug: Recursive onDataChange calls...",
			GUI.TOOLTIP : "... if a TextFields focus is lost\nin the onDataChanged handling.",
			GUI.MENU : [
				{
					GUI.TYPE : GUI.TYPE_TEXT,
					GUI.ON_DATA_CHANGED : window->fn(...){
						outln("You should see this only once!"); 
						this->activate(); // this calles an repeated onUnselect() on the Textfield
						// this should NOT issue a further dataChnaged event!
					}
				}
			]
			
		};
		
		
		
	}
};

// ---------------------------------------------------------
return plugin;
