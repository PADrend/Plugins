/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

var plugin = new Plugin({
		Plugin.NAME : 'GUITools/MessageWindow',
		Plugin.DESCRIPTION : "A window for showing messages.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/GUI'],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) := fn(){

	registerExtension( 'PADrend_Init',this->fn(){
		var messageType = systemConfig.getValue('PADrend.GUI.messageType','popup'); // type = popup | txt
		if(messageType=='popup'){
			var window = this.createMessageWindow();
			registerExtension('PADrend_Message',window->window.message);
		}
	});
	
	return true;
};

plugin.createMessageWindow := fn() {
	var window = gui.create({
		GUI.TYPE : GUI.TYPE_WINDOW,
		GUI.LABEL : "Messages",
		GUI.FLAGS : GUI.NO_CLOSE_BUTTON | GUI.HIDDEN_WINDOW,
		GUI.POSITION : [1,renderingContext.getWindowHeight()-62],
		GUI.SIZE : [260,60]
	});
	window.panel := gui.create({
		GUI.TYPE	:	GUI.TYPE_PANEL,
		GUI.SIZE	:	GUI.SIZE_MAXIMIZE,
		GUI.FLAGS	:	GUI.BACKGROUND,
		GUI.PANEL_MARGIN	:	2,
		GUI.PANEL_PADDING	:	2,
		GUI.TOOLTIP	:	"Messages"
	});
	window.panel.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
			gui._createRectShape(new Util.Color4ub(20,20,20,80),new Util.Color4ub(20,20,20,0),true)));
	window += window.panel;
	window.newMessageCount := 0;
	window.prevLabel := void;

	window.message := fn(text) {
		if(prevLabel) {
			prevLabel.setFont(gui.getFont(GUI.FONT_ID_DEFAULT));
			prevLabel.setHeight(13);
		}

		var label = gui.create({
			GUI.TYPE	:	GUI.TYPE_LABEL,
			GUI.LABEL	:	text.substr(0, 200),
			GUI.FONT	:	GUI.FONT_ID_LARGE,
			GUI.COLOR	:	GUI.WHITE
		});
		panel += label;
		panel += GUI.NEXT_ROW;
		restore();
		panel.layout();
		panel.scrollTo(new Geometry.Vec2(0,panel.getContentContainer().getHeight()), 2.0);
		this.newMessageCount++;
		prevLabel = label;

		PADrend.planTask(3, [this] => fn(messageWindow) {
			if(--messageWindow.newMessageCount <= 0)
				messageWindow.minimize();
		});
	};
	
	return window;
};

return plugin;
// -----------------------------------------
