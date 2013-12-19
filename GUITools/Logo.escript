/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


var plugin = new Plugin({
			Plugin.NAME : "GUITools/Logo",
			Plugin.VERSION : "1.2",
			Plugin.DESCRIPTION : "Display of a logo image, which can be changed by click.",
			Plugin.AUTHORS : "Benjamin Eikel, Claudius Jaehn",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : ['PADrend']
});

plugin.init @(override) := fn() {
	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_Init',	this->fn(){	setLogo(activeLogoName);} );
	}
	
	this.path := __DIR__ + "/../PADrend/resources/Logos";
	this.enabled := systemConfig.getValue('Effects.Logo.enabled', true); 
	this.activeLogoName := systemConfig.getValue('Effects.Logo.logo', this.path + "/logo_padrend_small.png");
	this.whiteBackground := systemConfig.getValue('Effects.Logo.whiteBackground', false);
	
	this.logoWindow := void;

	return true;
};

//! (internal)
plugin.refresh := fn(){
	if(!enabled)
		return;
	
	if(!logoWindow){
		logoWindow = gui.createWindow(1, 1, "Logo", GUI.HIDDEN_WINDOW);
		gui.windows["logoWindow"] = logoWindow;
	}

	logoWindow.clear();
	var logo = gui.getIcon(activeLogoName);
	if(!logo)
		return;
			
	logoWindow.setExtLayout(
		GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
		GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM|
		GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
		new Geometry.Vec2(10,10),new Geometry.Vec2(logo.getWidth() + 5,logo.getHeight() + 20) );
	
	var c = gui.create({
		GUI.TYPE : GUI.TYPE_ICON,
		GUI.ICON : logo,
		GUI.CONTEXT_MENU_PROVIDER : this->getSelectionMenu,
		GUI.TOOLTIP : "Logo: "+activeLogoName,
		GUI.FLAGS : GUI.BACKGROUND
	});
	if(whiteBackground)
		c.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
											gui._createRectShape(GUI.WHITE,GUI.WHITE,true)));
	logoWindow += c;
};

plugin.setLogo := fn(String logoName){
	activeLogoName = logoName;
	systemConfig.setValue('Effects.Logo.logo', logoName);
	refresh();
};

plugin.setWhiteBackround := fn(Bool b){
	whiteBackground = b;
	systemConfig.setValue('Effects.Logo.whiteBackground', b);
	refresh();
};

plugin.getSelectionMenu := fn(){
	
	var m=[];
	m+={
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "White background",
		GUI.DATA_PROVIDER : this->fn(){ return whiteBackground; },
		GUI.ON_DATA_CHANGED : fn(data){
			PADrend.executeCommand( [data] => fn(data){ if(var LogoPlugin=Util.queryPlugin('GUITools/Logo')) LogoPlugin.setWhiteBackround(data); } );
		},
		GUI.SIZE : [GUI.WIDTH_REL|GUI.HEIGHT_ABS , 0.9 ,15 ]
	};
	m+='----';
	
	foreach(Util.getFilesInDir(path,['.png']).sort() as var entry){
		m+={
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : entry,
			GUI.ON_CLICK : [entry] => fn(entry){
				PADrend.executeCommand( [entry] => fn(logoName){ if(var LogoPlugin=Util.queryPlugin('GUITools/Logo')) LogoPlugin.setLogo(logoName); } );
			}
		};
	}
	return m;
};

return plugin;

