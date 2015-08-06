 /*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myeti@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
 /****
 **	[Plugin:MeshEditor] Plugin:MeshEditor/Plugin.escript
 **
 ** Provides tools for editing the mesh of a selected geometry node.
 **/
var plugin = new Plugin({
	Plugin.NAME				:	'MeshEditor',
	Plugin.DESCRIPTION		:	"Provides tools for editing the mesh of a selected geometry node.",
	Plugin.VERSION			:	0.1,
	Plugin.AUTHORS			:	"Sascha Brandt",
	Plugin.OWNER			:	"All",
	Plugin.LICENSE 			:   "Mozilla Public License, v. 2.0",
	Plugin.REQUIRES			:	['SceneEditor'],
	Plugin.EXTENSION_POINTS	:	[
			/* [ext:MeshEditor_OnTrianglesSelected]
			 * Called whenever the selected triangles change
			 * @param   Array of currently selected triangles (do not change!)
			 * @result  void
			 */
			'MeshEditor_OnTrianglesSelected',
			/* [ext:MeshEditor_OnVerticesSelected]
			 * Called whenever the selected vertices change
			 * @param   Array of currently selected vertex indices (do not change!)
			 * @result  void
			 */
			'MeshEditor_OnVerticesSelected']
});

plugin.init:=fn() {
	Util.registerExtension('PADrend_Init',this->this.ex_Init);
	return true;
};

//------------------------------------------------------------------------------------------------------
// Triangle selection

static selectedTriangles = [];
static selectedTrianglesSet = new Std.Set;

plugin.selectTriangles := fn(Array triangles){
	selectedTriangles.clear();
	selectedTrianglesSet.clear();
	addSelectedTriangles(triangles);
};
plugin.addSelectedTriangles := fn(Array triangles){
	foreach(triangles as var t){
		if(t && !selectedTrianglesSet.contains(t)){
			selectedTrianglesSet+=t;
			selectedTriangles+=t;
		}
	}
	Util.executeExtensions('MeshEditor_OnTrianglesSelected',selectedTriangles);
};
plugin.removeTrianglesFromSelection := fn(Array triangles){
	foreach(triangles as var t){
		if(t && selectedTrianglesSet.contains(t)){
			selectedTrianglesSet-=t;
			selectedTriangles.removeValue(t);
		}
	}
	Util.executeExtensions('MeshEditor_OnTrianglesSelected',selectedTriangles);
};
plugin.clearTriangleSelection := fn(){
	selectedTriangles.clear();
	selectedTrianglesSet.clear();
	Util.executeExtensions('MeshEditor_OnTrianglesSelected',selectedTriangles);
};
plugin.getSelectedTriangles := 	fn(){ return selectedTriangles.clone();	};
plugin.isTriangleSelected := fn(t) { return t && selectedTrianglesSet.contains(t); };

//------------------------------------------------------------------------------------------------------
// Vertex selection

static selectedVertices = [];
static selectedVerticesSet = new Std.Set;

plugin.selectVertices := fn(Array vertices){
	selectedVertices.clear();
	selectedVerticesSet.clear();
	addSelectedVertices(vertices);
};
plugin.addSelectedVertices := fn(Array vertices){
	foreach(vertices as var v){
		if(v && !selectedVerticesSet.contains(v)){
			selectedVerticesSet+=v;
			selectedVertices+=v;
		}
	}
	Util.executeExtensions('MeshEditor_OnVerticesSelected',selectedVertices);
};
plugin.removeVerticesFromSelection := fn(Array vertices){
	foreach(vertices as var v){
		if(v && selectedVerticesSet.contains(v)){
			selectedVerticesSet-=v;
			selectedVertices.removeValue(v);
		}
	}
	Util.executeExtensions('MeshEditor_OnVerticesSelected',selectedVertices);
};
plugin.clearVertexSelection := fn(){
	selectedVertices.clear();
	selectedVerticesSet.clear();
	Util.executeExtensions('MeshEditor_OnVerticesSelected',selectedVertices);
};
plugin.getSelectedVertices := 	fn(){ return selectedVertices.clone();	};
plugin.isVertexSelected := fn(v) { return v && selectedVerticesSet.contains(v); };

//------------------------------------------------------------------------------------------------------

//!	[ext:PADrend_Init]
plugin.ex_Init := fn(){
	gui.loadIconFile( __DIR__+"/resources/Icons.json");

	registerMenus();

	{
		var t = new (Std.module('MeshEditor/Tools/Select'));
		PADrend.registerUITool('MeshEditorTools_Select')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}

	{
		var t = new (Std.module('MeshEditor/Tools/Move'));
		PADrend.registerUITool('MeshEditorTools_Move')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}

	{
		var t = new (Std.module('MeshEditor/Tools/Rotate'));
		PADrend.registerUITool('MeshEditorTools_Rotate')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}

	{
		var t = new (Std.module('MeshEditor/Tools/Scale'));
		PADrend.registerUITool('MeshEditorTools_Scale')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}

	{
		var t = new (Std.module('MeshEditor/Tools/Extrude'));
		PADrend.registerUITool('MeshEditorTools_Extrude')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}

	{
		var t = new (Std.module('MeshEditor/Tools/Knife'));
		PADrend.registerUITool('MeshEditorTools_Knife')
			.registerActivationListener(t->t.activateTool)
			.registerDeactivationListener(t->t.deactivateTool);
	}
};

plugin.registerMenus:=fn() {
	static Style = module('PADrend/GUI/Style');
	static switchFun = fn(button,b){
		if(button.isDestroyed())
			return $REMOVE;
		foreach(Style.TOOLBAR_ACTIVE_BUTTON_PROPERTIES as var p)
			b ? button.addProperty(p) : button.removeProperty(p);
	};

	gui.register('PADrend_ToolsToolbar.80_MeshEditorTools',[{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.TOOLTIP	: "Triangle Selection Tool: Allows the selection of the triangles of a selected geometry node.",
		GUI.ICON : '#TriangleSelect',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('MeshEditorTools_Select');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('MeshEditorTools_Select')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
		},
	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.TOOLTIP	: "Triangle Move Tool: Allows the selection and movement of the triangles of a selected geometry node.",
		GUI.ICON : '#TriangleMove',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('MeshEditorTools_Move');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('MeshEditorTools_Move')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
		},
	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.TOOLTIP	: "Triangle Rotate Tool: Allows the selection and rotation of the triangles of a selected geometry node.",
		GUI.ICON : '#TriangleRotate',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('MeshEditorTools_Rotate');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('MeshEditorTools_Rotate')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
		},
	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.TOOLTIP	: "Triangle Scale Tool: Allows the selection and scaling of the triangles of a selected geometry node.",
		GUI.ICON : '#TriangleScale',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('MeshEditorTools_Scale');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('MeshEditorTools_Scale')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
		},
	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.TOOLTIP	: "Extrude Tool: Allows the selection and extrusion of the triangles of a selected geometry node.",
		GUI.ICON : '#TriangleExtrude',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('MeshEditorTools_Extrude');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('MeshEditorTools_Extrude')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
		},
	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.PRESET : './toolIcon',
		GUI.TOOLTIP	: "Knife Tool: Allows the selection and cutting of the triangles of a selected geometry node.",
		GUI.ICON : '#TriangleKnife',
		GUI.WIDTH : 24,
		GUI.ON_CLICK : fn(){	PADrend.setActiveUITool('MeshEditorTools_Knife');	},
		GUI.ON_INIT : fn(){
			PADrend.accessUIToolConfigurator('MeshEditorTools_Knife')
				.registerActivationListener([this,true]=>switchFun)
				.registerDeactivationListener([this,false]=>switchFun);
		},
	}]);
};

//----------------------------------------------------------------------------

return plugin;
