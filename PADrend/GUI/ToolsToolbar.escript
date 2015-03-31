/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[ToolsToolbar:PADrend] PADrend/GUI/ToolsToolbar.escript
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

static toolbarEnabled = DataWrapper.createFromConfig(PADrend.configCache,'PADrend.GUI.toolsToolbarEnabled',false);
plugin.toolbarEnabled := toolbarEnabled; // public interface
static toolbar;
static componentFilter = DataWrapper.createFromConfig(PADrend.configCache,'PADrend.GUI.toolsToolbarFiltered',[]);
static gui;

plugin.init @(override) := fn(){
	module.on('PADrend/gui',fn(_gui){
		gui = _gui;
		gui.register('PADrend_MiscConfigMenu.toolsToolsbar',[
			{
				GUI.TYPE : GUI.TYPE_BOOL,
				GUI.LABEL : "Show interaction tools",
				GUI.DATA_WRAPPER : toolbarEnabled,
				GUI.TOOLTIP : "Toolbar also opens with [F2]"
			}
		]);
		gui.register('PADrend_SceneToolMenu.tools',{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.MENU : 'PADrend_ToolsToolbar',
			GUI.LABEL : "Interaction tools",
			GUI.MENU_WIDTH : 50
		});
		toolbarEnabled.onDataChanged += fn(value){
			if(value){
				createToolbar();
			}else if(toolbar){
				var t = toolbar;
				toolbar = void;
				t.close();
			}
		};
	}); 
	
	Util.registerExtension( 'PADrend_Init',fn(){	toolbarEnabled.forceRefresh();	},Extension.LOW_PRIORITY*3.0); // execute after all menus and tabs are registered

	Util.registerExtension( 'PADrend_KeyPressed',fn(evt){
		if(evt.key == Util.UI.KEY_F2 && !toolbarEnabled()) {
			toolbarEnabled(true);
			return true;
		}
		return false;
	});
	
	componentFilter.onDataChanged += fn(data){
		if(toolbarEnabled()){
			toolbarEnabled(false);
			PADrend.planTask(1,[true] => toolbarEnabled);
		}
	};
	
	return true;
};

static createToolbar = fn(){
	var wWidth = new Std.DataWrapper; // used to initially adjust the window's width
	toolbar = gui.create({
		GUI.TYPE : GUI.TYPE_WINDOW,
		GUI.SIZE : [50,40],
		GUI.LABEL : "InteractionTools",
		GUI.FLAGS : GUI.HIDDEN_WINDOW | GUI.ONE_TIME_WINDOW,
		GUI.ON_WINDOW_CLOSED : fn(){	toolbarEnabled(false);	},
		GUI.ON_INIT : [wWidth] => fn(wWidth){	this.setWidth(wWidth());	},
		GUI.CONTENTS : [{
			GUI.TYPE : GUI.TYPE_CONTAINER,
			GUI.SIZE : GUI.SIZE_MAXIMIZE,
			GUI.PRESET : 'toolbar',
			GUI.CONTENTS : { 
				GUI.TYPE : GUI.TYPE_COMPONENTS,
				GUI.PROVIDER : 'PADrend_ToolsToolbar',
				GUI.FILTER : fn(Map p){
					foreach(componentFilter() as var groupName)
						p.unset(groupName);
					return p;
				}
			},
			GUI.CONTEXT_MENU_PROVIDER : fn(){
				var entries = ["Hide entries:"];
				foreach(gui.getRegisteredComponentProviders('PADrend_ToolsToolbar') as var name,var p){
					entries += {
						GUI.TYPE : GUI.TYPE_BOOL,
						GUI.DATA_PROVIDER : [name] => fn(name){		return componentFilter().contains(name);		},
						GUI.LABEL : name,
						GUI.ON_DATA_CHANGED : [name] => fn(name, value){
							var m = componentFilter().clone();
							if(value){
								m+=name;
							}else{
								m.removeValue(name);
							}
							componentFilter(m);
						}
					};
				}
				return entries;
			},
			GUI.ON_INIT : [wWidth] => fn(wWidth){
				var width = 10; 
				foreach(this.getContents() as var child){
					child.layout();
					width += child.getWidth()+3;
				}
				wWidth(width);
			}
		}]
	});
	toolbar.setPosition(gui.windows['Toolbar'].getWidth(),-10);
};
 
return plugin;
// ------------------------------------------------------------------------------
