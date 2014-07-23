/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

 static enabled = new Std.DataWrapper(false);
 static analyzedComponent = new Std.DataWrapper;
 static analyzedComponentText = new Std.DataWrapper("");

var plugin = new Plugin({
		Plugin.NAME : 'Tools_GUIInfo',
		Plugin.DESCRIPTION : "Show registered gui elements.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.OWNER : "All",

		Plugin.REQUIRES : ['PADrend/EventLoop'],
		Plugin.EXTENSION_POINTS : []
});


plugin.init @(override) := fn(){
	Util.registerExtension('PADrend_Init', fn(){
		gui.registerComponentProvider('Tools_DebugWindowTabs.x_guiInfo',	createTab);
	});
	static revoce = new Std.MultiProcedure;
	enabled.onDataChanged += fn(b){
		revoce();
		if(b){
			revoce += Util.registerExtensionRevocably('PADrend_UIEvent',fn(evt){
				if(evt.type==Util.UI.EVENT_MOUSE_MOTION){
					analyzedComponent(gui.getComponentAtPos(new Geometry.Vec2(evt.x, evt.y)));
//					outln( gui.getComponentAtPos(new Geometry.Vec2(evt.x, evt.y)) );
				}
				return;
			},Util.EXTENSION_PRIORITY_HIGH );
		}
	};
	
	analyzedComponent.onDataChanged += fn(c){
		var s = "";
		if(!c){
			s += "???";
		}else{
			while(c){
				s += c.toString()+" "+c.getLocalRect().toString()+ "\n";
				if(c.isSet($onClick)){
					s += "onClick: "+c.onClick.toDbgString() +"\n";
				}
				if(c.isSet($_componentId)){
					s += "         ID: '"+c._componentId+"'\n";
					foreach(gui.getRegisteredComponentProviders(c._componentId) as var name,var p){
						s+="                  '"+name+"' -> "+p.toDbgString()+"\n";
					}
				}
				var traits = [];
				foreach(Std.Traits.queryTraits(c) as var t)
					traits += t.getName();
				if(!traits.empty())
					s += "Traits: "+traits.implode(",")+"\n";
				s += "----\n";
				c = c.getParentComponent();
			}
			s += "--------------------\n";
		}
		analyzedComponentText(s);
	};
	
	return true;
};

static createTab = fn(){
	var panel = gui.create({
		GUI.TYPE			:	GUI.TYPE_CONTAINER,
		GUI.SIZE			:	GUI.SIZE_MAXIMIZE,
		GUI.LAYOUT			:	GUI.LAYOUT_FLOW
	});
	panel += {
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Enable GUI-Component info",
		GUI.DATA_WRAPPER : enabled,
		GUI.TOOLTIP : 	"If enabled, information about the component \n"
						"below the mouse cursor is shown below.\n"
						"Note: ComponentIds may be missing."
	};
	panel += GUI.NEXT_ROW;
	panel += '----';
	panel += GUI.NEXT_ROW;
	panel += {
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.DATA_WRAPPER : analyzedComponentText,
	};
	panel += GUI.NEXT_ROW;

	return gui.create({
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.TAB_CONTENT : panel,
		GUI.LABEL : "GUI Components",
	});
};

return plugin;
// ------------------------------------------------------------------------------
