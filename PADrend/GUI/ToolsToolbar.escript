/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[ToolsToolbar:PADrend] PADrend/GUI/ToolsToolbar.escript
 **
 **/


/***
 **   ---|> Plugin
 **/
var plugin = new Plugin({
		Plugin.NAME : 'PADrend/GUI/ToolsToolbar',
		Plugin.DESCRIPTION : "A toolbar for interactive tools.",
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/GUI'],
		Plugin.EXTENSION_POINTS : []
});

// -------------------

plugin.toolbarEnabled := DataWrapper.createFromConfig(PADrend.configCache,'PADrend.GUI.toolsToolbarEnabled',false);
plugin.toolbar := void;
plugin.componentFilter := DataWrapper.createFromConfig(PADrend.configCache,'PADrend.GUI.toolsToolbarFiltered',[]);

/**
 * Plugin initialization.
 * ---|> Plugin
 */
plugin.init := fn(){
	toolbarEnabled.onDataChanged += this->fn(value){
		if(value){
			createToolbar();
		}else if(toolbar){
			var t = toolbar;
			toolbar = void;
			t.close();
		}
	};
	
	
	registerExtension( 'PADrend_Init',this->fn(){
		gui.registerComponentProvider('PADrend_MiscConfigMenu.experimentalToolbar',[
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Show interaction tools",
				GUI.DATA_WRAPPER : toolbarEnabled,
				GUI.TOOLTIP : "Toolbar also opens with [F2]"
			}
		]);
		gui.registerComponentProvider('PADrend_SceneToolMenu.tools',{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.MENU : 'PADrend_ToolsToolbar',
			GUI.LABEL : "Interaction tools"
		});
		toolbarEnabled.forceRefresh();
	},Extension.LOW_PRIORITY*3.0); // execute after all menus and tabs are registered

	registerExtension( 'PADrend_KeyPressed',this->fn(evt){
		if(evt.key == Util.UI.KEY_F2 && !toolbarEnabled()) {
			toolbarEnabled(true);
			return true;
		}
		return false;
	});
	
	this.componentFilter.onDataChanged += [toolbarEnabled] => fn(toolbarEnabled, data){
		if(toolbarEnabled()){
			toolbarEnabled(false);
			PADrend.planTask(1,[true] => toolbarEnabled);
		}
	};
	
	return true;
};

static TOOLBAR_ID = 'PADrend_ToolsToolbar';

plugin.createToolbar := fn(){
	var layouter = (new GUI.FlowLayouter).setMargin(0).setPadding(3).enableAutoBreak();

	var entries = [];
	var width = 10;
	foreach(gui.createComponents({ 
						GUI.TYPE : GUI.TYPE_COMPONENTS,
						GUI.PROVIDER : TOOLBAR_ID,
						GUI.FILTER : [componentFilter] => fn(componentFilter,p){
							foreach(componentFilter() as var groupName)
								p.unset(groupName);
							return p;
						}
					}) as var e){
		e.layout();
		width+=e.getWidth()+5;
		entries+=e;
	}
	var container = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.FLAGS : GUI.BACKGROUND,
		GUI.LAYOUT : layouter,//GUI.LAYOUT_BREAKABLE_TIGHT_FLOW,
		GUI.CONTENTS : entries,
		GUI.SIZE : GUI.SIZE_MAXIMIZE,
		GUI.CONTEXT_MENU_PROVIDER : [this.componentFilter] => fn(componentFilter){
			var entries = [];
			foreach(gui.getRegisteredComponentProviders(TOOLBAR_ID) as var name,var p){
				entries += {
					GUI.TYPE : GUI.TYPE_BOOL,
					GUI.DATA_PROVIDER : [componentFilter,name] => fn(componentFilter,name){		return componentFilter().contains(name);		},
					GUI.LABEL : name,
					GUI.ON_DATA_CHANGED : [componentFilter,name] => fn(componentFilter,name, value){
						var m = componentFilter().clone();
						if(value)
							m+=name;
						else{
							m.removeValue(name);
						}
						componentFilter(m);
					}
				};
			}
			return entries;
		}
	
	});
	container._componentId := TOOLBAR_ID;
	
	this.toolbar = gui.create({
		GUI.TYPE : GUI.TYPE_WINDOW,
		GUI.SIZE : [width,40],
		GUI.LABEL : "InteractionTools",
		GUI.FLAGS : GUI.HIDDEN_WINDOW | GUI.ONE_TIME_WINDOW,
		GUI.ON_WINDOW_CLOSED : this->fn(){
//			out("!!!!!");
			toolbarEnabled(false);
		},
		
		GUI.CONTENTS : [container]
	});
	container.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_BUTTON_SHAPE,GUI.NULL_SHAPE) );
	container.addProperty(new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,gui._createRectShape(new Util.Color4ub(200,200,200,160),new Util.Color4ub(200,200,200,0),true)));
	container.addProperty(new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR,new Util.Color4ub(0,0,0,200)));
	toolbar.setPosition(gui.windows['Toolbar'].getWidth(),-10);
};
 
return plugin;
// ------------------------------------------------------------------------------
