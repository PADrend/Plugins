/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2015 Claudius Jähn <claudius@uni-paderborn.de>
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
			Plugin.VERSION : "1.3",
			Plugin.DESCRIPTION : "Display of a logo image, which can be changed by click.",
			Plugin.AUTHORS : "Benjamin Eikel, Claudius Jaehn",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : ['PADrend']
});


static window;
static path;
static activeLogoName;
static enabled;
static whiteBackground;
static autoTooltip;
static config;

plugin.init @(override) := fn() {
	config = new (module('LibUtilExt/ConfigGroup'))(systemConfig,'Effects.Logo');

	path = IO.condensePath(__DIR__ + "/../PADrend/resources/Logos");
	activeLogoName = Std.DataWrapper.createFromEntry( config,'logo', path + "/logo_padrend_small.png" );
	enabled = Std.DataWrapper.createFromEntry( config,'enabled',true );
	whiteBackground = Std.DataWrapper.createFromEntry( config,'whiteBackground', false);
	autoTooltip = Std.DataWrapper.createFromEntry( config,'autoTooltip', true);

	enabled.onDataChanged += refresh;
	activeLogoName.onDataChanged += refresh;
	whiteBackground.onDataChanged += refresh;

	PADrend.syncVars.addDataWrapper('GUITools.Logo.name',activeLogoName);
	PADrend.syncVars.addDataWrapper('GUITools.Logo.wbg',whiteBackground);

	Util.registerExtension('PADrend_Init',	fn(){enabled.forceRefresh();} );
	return true;
};

static refresh = fn(...){
	if(!enabled()){
		if(window){
			window.destroy();
			window = void;
		}
	}else{
		if(!window)
			window = gui.createWindow(1, 1, "Logo", GUI.HIDDEN_WINDOW);

		window.clear();
		var logo = gui.getIcon(activeLogoName());
		if(!logo)
			logo = gui.getIcon('#ErrorSmall');
				
		window.setExtLayout(
			GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT|
			GUI.POS_Y_ABS|GUI.REFERENCE_Y_BOTTOM|GUI.ALIGN_Y_BOTTOM|
			GUI.WIDTH_ABS|GUI.HEIGHT_ABS,
			new Geometry.Vec2(10,10),new Geometry.Vec2(logo.getWidth() + 5,logo.getHeight() + 20) );
		
		var c = gui.create({
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.ICON : logo,
			GUI.CONTEXT_MENU_PROVIDER : fn(){
				var m=[
					{
						GUI.TYPE : GUI.TYPE_BOOL,
						GUI.LABEL : "White background",
						GUI.DATA_WRAPPER : whiteBackground,
						GUI.SIZE : [GUI.WIDTH_REL|GUI.HEIGHT_ABS , 0.9 ,15 ]
					},
					'----'
				];
				
				foreach(Util.getFilesInDir(path,['.png']).sort() as var entry){
					m+={
						GUI.TYPE : GUI.TYPE_BUTTON,
						GUI.LABEL : (new Util.FileName(entry)).getFile(),
						GUI.ON_CLICK : [entry] => activeLogoName,
						GUI.TOOLTIP :entry
					};
				}
				m += '----';
				m += {
					GUI.TYPE : GUI.TYPE_BUTTON,
					GUI.LABEL : "Set as default",
					GUI.ON_CLICK : fn(){	config.save(); PADrend.message("Settings stored.");	}
				};
				return m;
			},
			GUI.CONTEXT_MENU_WIDTH : 200,
			GUI.TOOLTIP : autoTooltip() ? {
					var Version = Std.module('PADrend/Version');
					Version.VERSION_FULL_STRING + "\nBuild: "+ Version.BUILD;
				} : "",
			GUI.FLAGS : GUI.BACKGROUND
		});
		if(whiteBackground())
			c.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
												gui._createRectShape(GUI.WHITE,GUI.WHITE,true)));
		window += c;
		
		// force relayout. window.layout() does not work...
		window.select();
		window.unselect();
	}
};

plugin.setLogo := fn(String logoName){
	activeLogoName( logoName );
};

plugin.setWhiteBackround := fn(Bool b){
	whiteBackground( b );
};


return plugin;

