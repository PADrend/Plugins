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

var plugin = new Plugin({
			Plugin.NAME : "GUITools/OSD",
			Plugin.VERSION : "1.1",
			Plugin.DESCRIPTION : "On Screen Display\nShow a temporary notification message on all connected clients.",
			Plugin.AUTHORS : "Claudius",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : ['PADrend/GUI', 'PADrend/CommandHandling']
});

plugin._enabled := false;
plugin._duration := false;
plugin._position := void;
plugin._window := void;
plugin._label := void;
plugin._timeout := false;

plugin.init @(override) := fn(){
	
	_duration = systemConfig.getValue("Effects.OSD.duration",3);
	_enabled = systemConfig.getValue("Effects.OSD.enabled",true);
	_position = systemConfig.getValue("Effects.OSD.position",[0.5,0.5]);
	systemConfig.setInfo("Effects.OSD.position",
									"Relative position [x,y]. [0,0] top left, [0.5,0.5] centered, [1,1] bottom right");
	
	
	return true;
};

//! (internal)
plugin._message := fn(	text ){
	if(!_enabled)
		return;
	if(!_window){
		var width = 320;
		var height = 160;
		var r = gui.getScreenRect();
		_window = gui.create({
			GUI.TYPE : GUI.TYPE_WINDOW,
			GUI.FLAGS : GUI.HIDDEN_WINDOW
		});
		Traits.addTrait(_window, Std.require('LibGUIExt/Traits/StorableRectTrait'),
					DataWrapper.createFromConfig(PADrend.configCache, "Effects.OSD.winRect", [	(r.getWidth() - width)*_position[0],(r.getHeight() - height)*_position[1],width,height]));
		var c = gui.create({
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.FLAGS : GUI.BORDER|GUI.BACKGROUND|GUI.AUTO_MAXIMIZE,
			GUI.FONT : GUI.FONT_ID_XLARGE,
		});
		
		c.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
										gui._createRectShape(new Util.Color4ub(0,0,0,200),new Util.Color4ub(20,20,20,20),true)));

		c.addProperty(new GUI.ColorProperty(GUI.PROPERTY_TEXT_COLOR,GUI.WHITE ));
				
		
		_label = gui.create({
			GUI.TYPE : GUI.TYPE_LABEL,
			GUI.LABEL : text,
			GUI.TEXT_ALIGNMENT : GUI.TEXT_ALIGN_MIDDLE | GUI.TEXT_ALIGN_CENTER,
			GUI.FLAGS : GUI.AUTO_MAXIMIZE
			
		});
		c+=_label;
		_window += c;
	}
	_label.setText(text);
	_window.restore();
	_window.setEnabled(true);
	_window.bringToFront();
	_window.unselect(); // hides the buttons
	
	if(!_timeout){
		registerExtension('PADrend_AfterFrame',this->fn(){
			if(clock()>_timeout){
				_window.setEnabled(false);
				_timeout = false;
				return Extension.REMOVE_EXTENSION;
			}		
		});	
	}
	
	_timeout = clock()+_duration;
	
};

//! Show the given text on all connected clients (where the OSD is enabled) for some seconds.
plugin.message := fn( text ){
	PADrend.executeCommand( [text] => fn(text){ if(var OSD=Util.queryPlugin('GUITools/OSD')) OSD._message(text);} ) ;
};

plugin.isActive := plugin->fn(){ return _timeout!=false; };

return plugin;
