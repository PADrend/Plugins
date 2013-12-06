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
 **	[Plugin:NodeEditor/TransformationEdit2]
 **
 ** Graphical tools for transforming nodes
 **/

declareNamespace($TransformationTools);

//! ---|> Plugin
TransformationTools.plugin := new Plugin({
		Plugin.NAME : 'SceneEditor/TransformationTools3',
		Plugin.DESCRIPTION : 'Transform nodes.',
		Plugin.VERSION : 3.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['NodeEditor'],
		Plugin.EXTENSION_POINTS : [	]
});

var plugin = TransformationTools.plugin;


plugin.init @(override) := fn(){
	loadOnce(__DIR__+"/Tool_AnchorTool.escript");
	loadOnce(__DIR__+"/Tool_RotationTool.escript");
	loadOnce(__DIR__+"/Tool_ScaleTool.escript");
	loadOnce(__DIR__+"/Tool_SnapTool.escript");
	loadOnce(__DIR__+"/Tool_TranslationTool.escript");

	registerExtension('PADrend_Init',this->this.ex_Init);
	return true;
};

//!	[ext:PADrend_Init]
plugin.ex_Init:=fn(){

	registerMenus();

	{
		var t = new TransformationTools.TranslationTool;
		PADrend.registerUITool('TransformationTools3_Move')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}
	{
		var t = new TransformationTools.RotationTool;
		PADrend.registerUITool('TransformationTools3_Rotate')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);

	}{
		var t = new TransformationTools.ScaleTool;
		PADrend.registerUITool('TransformationTools3_Scale')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}
	{
		var t = new TransformationTools.SnapTool;
		PADrend.registerUITool('TransformationTools3_Snap')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}	
	{
		var t = new TransformationTools.SnapTool2;
		PADrend.registerUITool('TransformationTools3_Snap2')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}
	{
		var t = new TransformationTools.AnchorTool;
		PADrend.registerUITool('TransformationTools3_Anchor')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}

};

plugin.registerMenus:=fn() {
	gui.registerComponentProvider('PADrend_ToolsToolbar.transform3',[{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.ICON : '#NodeTranslate',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('TransformationTools3_Move');	},
		GUI.ON_INIT : fn(...){
			var swithFun = fn(b){
				if(isDestroyed())
					return $REMOVE;
				setSwitch(b);
			};
			PADrend.accessUIToolConfigurator('TransformationTools3_Move')
				.registerActivationListener(this->(swithFun.bindFirstParams(true)))
				.registerDeactivationListener(this->(swithFun.bindFirstParams(false)));
		},
	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.ICON : '#NodeRotate',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('TransformationTools3_Rotate');	},
		GUI.ON_INIT : fn(...){
			var swithFun = fn(b){
				if(isDestroyed())
					return $REMOVE;
				setSwitch(b);
			};
			PADrend.accessUIToolConfigurator('TransformationTools3_Rotate')
				.registerActivationListener(this->(swithFun.bindFirstParams(true)))
				.registerDeactivationListener(this->(swithFun.bindFirstParams(false)));
		},
	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.ICON : '#NodeScale',
//		GUI.ICON_COLOR : GUI.BLACK,
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('TransformationTools3_Scale');	},
		GUI.ON_INIT : fn(...){
			var swithFun = fn(b){
				if(isDestroyed())
					return $REMOVE;
				setSwitch(b);
			};
			PADrend.accessUIToolConfigurator('TransformationTools3_Scale')
				.registerActivationListener(this->(swithFun.bindFirstParams(true)))
				.registerDeactivationListener(this->(swithFun.bindFirstParams(false)));
		},
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.ICON : '#NodeSnap',
		GUI.WIDTH : 24,
//		GUI.ICON_COLOR : GUI.BLACK,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('TransformationTools3_Snap');	},
		GUI.ON_INIT : fn(...){
			var swithFun = fn(b){
				if(isDestroyed())
					return $REMOVE;
				setSwitch(b);
			};
			PADrend.accessUIToolConfigurator('TransformationTools3_Snap')
				.registerActivationListener(this->(swithFun.bindFirstParams(true)))
				.registerDeactivationListener(this->(swithFun.bindFirstParams(false)));
		},
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.ICON : '#NodeSnap',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('TransformationTools3_Snap2');	},
		GUI.ON_INIT : fn(...){
			var swithFun = fn(b){
				if(isDestroyed())
					return $REMOVE;
				setSwitch(b);
			};
			PADrend.accessUIToolConfigurator('TransformationTools3_Snap2')
				.registerActivationListener(this->(swithFun.bindFirstParams(true)))
				.registerDeactivationListener(this->(swithFun.bindFirstParams(false)));
		},
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.ICON : '#Anchor',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('TransformationTools3_Anchor');	},
		GUI.ON_INIT : fn(...){
			var swithFun = fn(b){
				if(isDestroyed())
					return $REMOVE;
				setSwitch(b);
			};
			PADrend.accessUIToolConfigurator('TransformationTools3_Anchor')
				.registerActivationListener(this->(swithFun.bindFirstParams(true)))
				.registerDeactivationListener(this->(swithFun.bindFirstParams(false)));
		},
		GUI.TOOLTIP : "AnchorTool: Edit a node's anchor points."
	},
	

	]);
};

//----------------------------------------------------------------------------


return plugin;
