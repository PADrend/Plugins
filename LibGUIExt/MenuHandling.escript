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
 **	[PADrend] LibGUIExt/MenuHandling.escript
 **/

// ------------------------------------
// Menu
GUI.GUI_Manager._createMenu ::= GUI.GUI_Manager.createMenu;

//! \note Use gui.openMenu(...) instead; the Menu-object itself should not be stored or handled directly.
GUI.GUI_Manager.createMenu ::= fn(mixed = void, width = 150, context...){
	var menu = gui._createMenu(GUI.ONE_TIME_MENU);
	if(mixed){
		if(mixed.isA(String))	// for debugging
			menu._componentId := mixed;
		
		var components = this.createComponents({
								GUI.TYPE : 				GUI.TYPE_MENU_ENTRIES,
								GUI.PROVIDER :			mixed,
								GUI.WIDTH : 			width,
								GUI.CONTEXT_ARRAY : 	context
		});
		var height = 0;
		foreach(components as var c){
			c.layout();
			height += c.getHeight();
		}
		var maxHeight = this.getScreenRect().getHeight()*0.7;
		if(height<maxHeight){
			foreach(components as var c)
				menu += c;
		}else{ // if the overall height of the menu is too large, wrap its entries in a scrollable container.
			var container = this.create({
				GUI.TYPE :	GUI.TYPE_PANEL,
				GUI.PANEL_MARGIN :	0,
				GUI.PANEL_PADDING : 0,
				GUI.HEIGHT : maxHeight,
				GUI.WIDTH : width
			});
			foreach(components as var c){
				container += c;
				container++;
			}
			menu+=container;
		}
		
	}
	return menu;
};

/*! Open a one time menu at the given position.
	\param menuEntries GUI.Menu || String || fn(context...)-> [entries]
	\param context If a context is given and the menu is given by id, the context is passed to the 
			provider functions.
	\note This function does not return the menu as it may automatically be  destroyed (one time menu). 
	\note if the menu does not fit to the screen, its position is adjusted*/
GUI.GUI_Manager.openMenu ::= fn(Geometry.Vec2 position, menuEntries,width=150,context...){
	var menu = (menuEntries ---|> GUI.Menu) ? menuEntries : gui.createMenu(menuEntries,width,context...);

	menu.layout(); // assure the height is initialized
	var height = menu.getHeight();

	if(position.getX()+width>this.getScreenRect().getWidth())
		position.setX([position.getX()-width,0].max());
	if(position.getY()+height>this.getScreenRect().getHeight())
		position.setY([position.getY()-height,0].max());
	
	menu.open(position);
};

GUI.GUI_Manager.printMenuInfo ::= fn(){
	print_r(getComponentProviderRegistry());
};

// -------
// Menu extension

/*! Close prior submenus and open the given menu as submenu next to the given entry of the current menu.
	\see gui.openMenu(...)	*/
GUI.Menu.openSubmenu ::= fn(GUI.Component entry, menuEntries,width=150,context...){
	var menu = (menuEntries ---|> GUI.Menu) ? menuEntries : gui.createMenu(menuEntries,width,context...);

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
	if(this.isSet($_activeSubmenu) && this._activeSubmenu---|>GUI.Menu && submenu!=this._activeSubmenu){
		this._activeSubmenu.close();
		this._activeSubmenu = void;
	}
	this._activeSubmenu @(private) := submenu;
};
//
