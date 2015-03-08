/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] LibGUIExt/ComponentExtensions.escript
 **/


// ------------------------------------------------------------------------------
// component helper functions
// ------------------------------------------------------------------------------

// -----------
// Button

/*! Replaces the original onClick method by an internal one, which allows the execution
	of several onClick methods and registeres the given handler accordingly. */
GUI.Button.addOnClickHandler ::= fn(handler){
	if( !isSet($_onClickHandler) ){
		// is this the first handler? ---> use the entry directly, we don't need an array here.
		if( this.onClick == GUI.Button.onClick){
			this.onClick = handler;
			return;
		}else{
			this._onClickHandler := [this.onClick];
			this.onClick = fn(data){
				foreach(_onClickHandler as var l)
					this->l();
			};
		}
	}
	_onClickHandler += handler;
};

GUI.Button.setButtonShape ::= fn( GUI.AbstractShape  s){
	this.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,s) );
};


// -----------
// Component 

GUI.Component.destroy ::= fn(){
	gui.markForRemoval(this);
	return this;
};


/*! Replaces the original onDataChanged method by an internal one, which allows the execution
	of several onDataChanged methods and registeres the given listener accordingly. */
GUI.Component.addDataChangedListener ::= fn(listener){
	if( !isSet($_dataChangedListeners) ){
		// is this the first listener? ---> use the entry directly, we don't need an array here.
		if( this.getType().isSet($onDataChanged) && 
				this.onDataChanged == this.getType().onDataChanged){
			this.onDataChanged = listener;
			return;
		}else{
			this._dataChangedListeners := [this.onDataChanged];
			this.onDataChanged = fn(data){
				foreach(_dataChangedListeners as var l)
					this->l(data);
			};		
		}
	}
	_dataChangedListeners += listener;
};

/*! A RefreshGroup can be used to update the data of gui components e.g. according to their
	connected attribute.  */
GUI.RefreshGroup := new Type();
GUI.RefreshGroup.refreshables 	:= void;
GUI.RefreshGroup._constructor 	::= fn()			{	refreshables=[];	};
GUI.RefreshGroup."+=" 			::= fn(refreshable)	{	refreshables+=refreshable;	};
GUI.RefreshGroup.refresh 		::= fn()			{	foreach(refreshables as var f) f();	};

/*! Connects the Component with the attribute @p parName of the given object.
	The checkbox is initialized with the value and the value is changed if the
	Data of the Component is changed.
	If a @p refreshGroup is given, the component is registered at it. */
GUI.Component.connectToAttribute::=fn(obj , varId, [GUI.RefreshGroup,void] refreshGroup=void){
	var dataWrapper = new ExtObject();

	dataWrapper.obj:=obj;
	dataWrapper.varId:=varId;

	this.refresh := [this,dataWrapper]->fn(){
		var component=this[0];
		var dataWrapper=this[1];
		var oldData=component.getData();
		var newData=dataWrapper.obj.getAttribute( dataWrapper.varId );
		
		if(oldData!=newData && 
				!(oldData ---|> Number && newData ---|> Number && ""+oldData == ""+newData)){
			component.setData(newData);
			component.onDataChanged(component.getData());
		}
	};
	refresh();

	addDataChangedListener(dataWrapper->fn(data){
		if(!obj.assignAttribute(this.varId,data))
			out("Member no set:",obj.toDbgString(),".",varId,"\n");
	});
	if(refreshGroup){
		refreshGroup+=this.refresh;
		addDataChangedListener(refreshGroup->fn(data){
			refresh();
		});
	}
};

/*! If the data of the component is changed, the corresponding
	config-variable is updated. 
	\deprecated
	*/
GUI.Component.connectToConfig::=fn(configName, defaultValue=void){
	addDataChangedListener( configName->fn(data){
//		out("Setting config ",this,":",data,"\n");
		systemConfig.setValue(this,data);
	});
	var initialValue=systemConfig.getValue(configName,defaultValue);
	if(void!=initialValue){
		setData(initialValue);
		onDataChanged(initialValue);
	}
};

// -----------
// Container

GUI.Container._add::=GUI.Container.add;  // store original 'add' function

/*! Allows adding of components as descriptions.
	E.g.
		panel.add("foo");	
		panel.add( { GUI.TYPE : GUI.TYPE_BUTTON,'label':"Do something" , GUI.ON_CLICK : fn(){out("foo!");}} );
		panel.add( [ "*Heading*", GUI.NEXT_ROW, GUI.H_DELIMITER, GUI.NEXT_ROW , "Some text..." ] );
		 */
GUI.Container.add::=fn(componentOrArrayOrDescription){
	if(componentOrArrayOrDescription ---|> Array){
		foreach(componentOrArrayOrDescription as var c){
			this._add(gui.create(c));
		}
		return this;
	}
	return this._add(gui.create(componentOrArrayOrDescription));
};
GUI.Container.append ::= fn( mixed,p... ){
	if(mixed.isA(String))// for debugging
		this._componentId := mixed;
	foreach( gui.createComponents( mixed,p... ) as var c)
		this._add(c);
	return this;
};

/*! Container += Component is an alias for Container.add(Component)*/
GUI.Container."+="::=GUI.Container.add;


GUI.Container.nextColumn ::= fn(additionalSpacing=0){
	this.add( gui.createNextColumn(additionalSpacing) );
	return this;
};
GUI.Container.nextRow ::= fn(additionalSpacing=0){
	this.add( gui.createNextRow(additionalSpacing) );
	return this;
};

//! Container++  is an alias for Container.nextRow()
GUI.Container."++_post"::=GUI.Container.nextRow;

// -------
// Menu extension

/*! Close prior submenus and open the given menu as submenu next to the given entry of the current menu.
	\see gui.openMenu(...)	*/
GUI.Menu.openSubmenu ::= fn(GUI.Component entry, menuEntries,width=150,context...){
	var menu = menuEntries.isA(GUI.Menu) ? menuEntries : gui.createMenu(menuEntries,width,context...);

	menu.layout(); // assure the height is initialized
	var height = menu.getHeight();
	
	this._registerSubmenu(menu);

	var position =  entry.getAbsPosition();
	if(position.getX()+width+entry.getWidth() > gui.getScreenRect().getWidth()){
		position.setX( position.getX()-width*0.5);
	}else{
		position.setX( position.getX()+entry.getWidth()*0.95);
	}
			
	if(position.getY()+height > gui.getScreenRect().getHeight()){
		position.setY([position.getY()-height,0].max());
	}

	menu.open(position);
};

//! (internal) Registers a menu as submenu. If another submenu is opened, it is closed automatically.
GUI.Menu._registerSubmenu ::= fn(GUI.Menu submenu){
	if(this.isSet($_activeSubmenu) && this._activeSubmenu.isA(GUI.Menu) && submenu!=this._activeSubmenu){
		this._activeSubmenu.close();
		this._activeSubmenu = void;
	}
	this._activeSubmenu @(private) := submenu;
};

// -----------
// Tabbed Panel
GUI.TabbedPanel.__add @(private) ::= GUI.TabbedPanel.add;
GUI.TabbedPanel.add ::= fn(GUI.Tab tab){	__add(tab);	};
GUI.TabbedPanel.'+=' ::= GUI.TabbedPanel.add;
GUI.TabbedPanel._addTab ::= GUI.TabbedPanel.addTab;
GUI.TabbedPanel.addTab ::= fn(String title,content,tooltip=false){
	var t = _addTab(title,gui.create(content));
	if(tooltip)
		t.setTooltip(tooltip);
	return t;
};
GUI.TabbedPanel.addTabs ::= fn( tabsOrComponentId){
	if(tabsOrComponentId.isA(String))// for debugging
		this._componentId := tabsOrComponentId;
	foreach(gui.createComponents(tabsOrComponentId) as var tab)
		this.add(tab);
	return this;
};

// -----------
// TreeViewEntry

GUI.TreeViewEntry.clearSubentries ::= fn(){
	for(var c=this.getFirstChild().getNext();c;c=c.getNext())
		gui.markForRemoval(c);
};

/*! Adds dynamically generated sub entries to a TreeViewEntry.
	The sub entries are (re-)generated when the entry is opened; 
	the old ones are then destroyed.
	
	\param Callable provider 		returning an Array of entries to add.
	
	Adds the following member function
		.refreshSubentries()	Manually refresh subentries.
	
	\note Multiple uses are allowed on one entry.
	\note The entry's onOpen-method should not be used otherwise.
*/
GUI.TreeViewEntry.DynamicSubentriesTrait ::= new Traits.GenericTrait;
{
	var t = GUI.TreeViewEntry.DynamicSubentriesTrait;
	t.allowMultipleUses();
	
	t.onInit += fn(GUI.TreeViewEntry entry, provider){
		Traits.requireTrait(provider, Traits.CallableTrait);
		if(!Traits.queryTrait(entry,this)){
			if(entry.isSet($onOpen))
				Runtime.warn("GUI.TreeviewEntry.onOpen already set.");
			entry.onOpen := new MultiProcedure;
			entry.onOpen += fn(){
				// remove old sub entries
				this.clearSubentries();
			};
			if(entry.isCollapsed())
				entry += "..."; // dummy

			entry.refreshSubentries := fn(){
				if(this.isCollapsed()){
					this.clearSubentries();
					this += "..."; // dummy
				}else{
					this.onOpen();
				}
			};
		}
		var p = [provider] => fn(provider){
			foreach(provider() as var entry)
				this += entry;
		};
		entry.onOpen += p;

		if(!entry.isCollapsed())
			(entry->p)();
	};
}

//! Add a \see GUI.TreeViewEntry.DynamicSubentriesTrait to the entry.
GUI.TreeViewEntry.addSubentryProvider := fn(provider){
	Traits.addTrait(this,GUI.TreeViewEntry.DynamicSubentriesTrait,provider);
	return this;
};


// -----------
// Window

//! Switch the visibility of a window. If a window gets visible, it's also activated.
GUI.Window.toggleVisibility:=fn(){
	var v=!this.isVisible();
	this.setEnabled(v);
	if(v){
		var c=this;
		while( (c=c.getFirstChild()) ---|> GUI.Container){
//			out("-",c,"\n");
			c.activate();
			c.select();
		}
		var pos=getAbsPosition();
		setPosition( [pos.getX(),0].max(),[pos.getY(),0].max() );
		restore();
	}
};


