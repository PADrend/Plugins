/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] LibGUIExt/IconHandling.escript
 **/

// ----------------
// icons

//! (internal)
GUI.GUI_Manager._getIconRegistry ::= fn( ){
	if(!this.isSet($_iconRegistry))
		this._iconRegistry := new Map();
	return this._iconRegistry;
};

/*! Get a Icon from a name or a filename (including implicit caching)
	\example gui.getIcon("#RefreshSmall"); 	*/
GUI.GUI_Manager.getIcon ::= fn( [GUI.Component,String] nameOrIconOrFilename, [Util.Color4ub,false] color=false){
	// Component given? ---> return it
	if(nameOrIconOrFilename ---|> GUI.Component){
		if(color)
			nameOrIconOrFilename.addProperty(new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR,color));
		return nameOrIconOrFilename;
	}
	var icon = void;
	var filename = void;
	var registryEntry = _getIconRegistry()[nameOrIconOrFilename];
	
	// found icon in the registry ---> return a clone
	if(registryEntry ---|> GUI.Component ){
		icon = this.createIcon( registryEntry.getImageData(),registryEntry.getImageRect() );
		if(color)
			icon.addProperty(new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR,color));
		return icon;
	} // found a filename?
	else if(registryEntry ---|> String){
		filename = registryEntry;
	}else { // nothing found in registry ---> the given nameOrIconOrFilename should be a filename
		filename = nameOrIconOrFilename;
	}
	
	// try to load
	if(Util.isFile(filename)){
		var img = this.loadImage(filename);
		if(img){
			icon = this.createIcon(img,new Geometry.Rect(0,0,img.getWidth(),img.getHeight()));
			this.registerIcon(nameOrIconOrFilename,this.createIcon(img,icon.getImageRect())); // store in registry
		}
	}

	if(!icon){
		Runtime.warn("Icon not found:"+filename);
	}else if(color){
		icon.addProperty(new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR,color));
	}
	return icon;
};

/*! Register a named icon.
	\note if a filename (and no icon) is given, the icon is created on first access 
	\example gui.registerIcon("#RefreshSmall","resources/Icons/Refresh.png");	*/
GUI.GUI_Manager.registerIcon ::= fn( String name, [GUI.Component,String] iconOrFilename ){
	_getIconRegistry()[name] = iconOrFilename;
};

GUI.GUI_Manager.registerIcons ::= fn( Map icons){
	foreach(icons as var name, var i)
		registerIcon(name,i);
};

/*! An icon file is a json formatted collection of icon descriptions
	\example file:
		[{
		"image" : "icons.png",
		"icons" : {
				"#RefreshSmall" : [ 0,0,16,16], // name -> rectangle
				"#Load" : [ 16,0,16,16]
			}
		},{ "image" : "...", ...} ]	*/
GUI.GUI_Manager.loadIconFile ::= fn( String filename ){
	var f = IO.fileGetContents(filename);
	if(!f){
		Runtime.warn("Icon file not found "+filename);
		return;
	}
	try{
		foreach(parseJSON(f) as var map1){
			var imageFile = map1['image'];
			// if file is not found, search the icon file relative to the given filename
			if(!Util.isFile(imageFile) && Util.isFile(IO.dirname(filename)+"/"+imageFile ) ){
				imageFile=IO.dirname(filename)+"/"+imageFile;
			}
			var img = this.loadImage(imageFile);
			if(!img){
				Runtime.warn("Image not found: "+imageFile);
			}
			foreach(map1['icons'] as var name,var dimensions){
				this.registerIcon(name,this.createIcon(img,
						new Geometry.Rect(dimensions[0],dimensions[1],dimensions[2],dimensions[3])));
			}
		}
	}catch(e){
		Runtime.warn(e);
		return;
	}
};
