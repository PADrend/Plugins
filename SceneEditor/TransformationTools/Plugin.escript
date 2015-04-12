/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor/TransformationEdit2]
 **
 ** Graphical tools for transforming nodes
 **/
var plugin = new Plugin({
		Plugin.NAME : 'SceneEditor/TransformationTools3',
		Plugin.DESCRIPTION : 'Transform nodes.',
		Plugin.VERSION : 3.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['NodeEditor'],
		Plugin.EXTENSION_POINTS : [	]
});

plugin.init @(override) := fn(){
	Util.registerExtension('PADrend_Init',this->this.ex_Init);
	module.on('PADrend/gui',registerToolIcons);
	
	return true;
};

//!	[ext:PADrend_Init]
plugin.ex_Init:=fn(){

	{
		var t = new (Std.module('SceneEditor/TransformationTools/Tool_TranslationTool'));
		PADrend.registerUITool('TransformationTools3_Move')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}
	{
		var t = new (Std.module('SceneEditor/TransformationTools/Tool_RotationTool'));
		PADrend.registerUITool('TransformationTools3_Rotate')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);

	}{
		var t = new (Std.module('SceneEditor/TransformationTools/Tool_ScaleTool'));
		PADrend.registerUITool('TransformationTools3_Scale')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}
	{
		var t = new (Std.module('SceneEditor/TransformationTools/Tool_SnapTool'));
		PADrend.registerUITool('TransformationTools3_Snap')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}
	{
		var t = new (Std.module('SceneEditor/TransformationTools/Tool_SnapTool2'));
		PADrend.registerUITool('TransformationTools3_Snap2')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}
	{
		var t = new (Std.module('SceneEditor/TransformationTools/Tool_AnchorTool'));
		PADrend.registerUITool('TransformationTools3_Anchor')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}


};

static registerToolIcons = fn(gui) {

	static snapToolMode = new Std.DataWrapper(false);
	var chooseSnapToolMode = [
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.DATA_WRAPPER : snapToolMode,
			GUI.LABEL : "Snap to geometry"
		}
	];
	gui.register('PADrend_UIToolConfig:TransformationTools3_Snap',chooseSnapToolMode);
	gui.register('PADrend_UIToolConfig:TransformationTools3_Snap2',chooseSnapToolMode);
	snapToolMode.onDataChanged += [gui]=>fn(gui,mode){
		PADrend.setActiveUITool(mode?'TransformationTools3_Snap':'TransformationTools3_Snap2');
		gui.closeAllMenus();
	};
	
	static Style = module('PADrend/GUI/Style');
	static switchFun = fn(button,b){
		if(button.isDestroyed())
			return $REMOVE;
		foreach(Style.TOOLBAR_ACTIVE_BUTTON_PROPERTIES as var p)
			b ? button.addProperty(p) : button.removeProperty(p);
	};
	gui.register('PADrend_ToolsToolbar.40_transformationTools',[{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.ICON : '#NodeTranslate',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('TransformationTools3_Move');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('TransformationTools3_Move')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
		},
		GUI.TOOLTIP : "Translate selected nodes.\nSee context menu for options..."
	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.ICON : '#NodeRotate',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('TransformationTools3_Rotate');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('TransformationTools3_Rotate')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
		},
		GUI.TOOLTIP : "Rotate selected nodes.\nSee context menu for options..."

	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.ICON : '#NodeScale',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('TransformationTools3_Scale');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('TransformationTools3_Scale')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
		},
		GUI.TOOLTIP : "Scale selected nodes.\nSee context menu for options..."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.ICON : '#NodeSnap',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool(snapToolMode() ? 'TransformationTools3_Snap': 'TransformationTools3_Snap2');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('TransformationTools3_Snap')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
			PADrend.accessUIToolConfigurator('TransformationTools3_Snap2')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
		},
		GUI.TOOLTIP : "Snap selected nodes.\nSee context menu for options..."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.ICON : '#Anchor',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('TransformationTools3_Anchor');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('TransformationTools3_Anchor')
				.registerActivationListener( [this,true]=>switchFun )
				.registerDeactivationListener( [this,false]=>switchFun );
		},
		GUI.TOOLTIP : "AnchorTool: Edit a node's anchor points."
	},
	

	]);
};

//----------------------------------------------------------------------------


return plugin;
