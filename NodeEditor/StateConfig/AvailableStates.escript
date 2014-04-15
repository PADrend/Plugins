/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011-2013 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2011 Robert Gmyr
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/StateConfig/AvailableStates.escript
 ** Map of available states used for the "new"-button.
 **/
 
loadOnce("LibMinSGExt/LineWidthState.escript");

var m = new Map();

m["AlphaTestState"] = fn(){return new MinSG.AlphaTestState();};
m["BlendingState"] = fn(){return new MinSG.BlendingState();};
m["BudgetAnnotationState"] = fn() { return new MinSG.BudgetAnnotationState; };
m["CHC renderer"] = fn(){return new MinSG.OccRenderer();};
m["CHC++ renderer"] = fn(){return new MinSG.CHCppRenderer();};
if(MinSG.isSet($ColorCubeRenderer))
	m["ColorCube renderer"] = fn() { return new MinSG.ColorCubeRenderer();};
m["CullFaceState"] = fn(){return new MinSG.CullFaceState();};
m["HOM renderer"] = fn() { return new MinSG.HOMRenderer(512); };
m["GroupState"] = fn() { return new MinSG.GroupState(); };
m["Lighting"] = fn(){return new MinSG.LightingState();};
m[MinSG.LineWidthState._printableName] = fn() { return new MinSG.LineWidthState; };
m["LOD-Renderer"] = fn(){return new MinSG.LODRenderer();};
m["MaterialState"] = fn(){return new MinSG.MaterialState();};
m["Mirror"] = fn() { var state = new MinSG.MirrorState(512); return state; };
m["OccludeeRenderer"] = fn() { return new MinSG.OccludeeRenderer(); };
m["PolygonModeState"] = fn(){return new MinSG.PolygonModeState();};
m["ProjSizeFilterState"] = fn(){return new MinSG.ProjSizeFilterState();};
m["Shadow"] = fn(){return new MinSG.ShadowState(4096);};
m["Shader"] = fn(){	return new MinSG.ShaderState();	};
m["ShaderUniform"] = fn(){	return new MinSG.ShaderUniformState();	};
m["Shader: Universal2"] = fn(){
	var shaderState = new MinSG.ShaderState();
	var p = gui.createPopupWindow(200,200);

	var config = new ExtObject();
	config.shading := DataWrapper.createFromValue("shading_phong");
	config.color := DataWrapper.createFromValue("color_standard");
	config.texture := DataWrapper.createFromValue("texture");
	config.shadow := DataWrapper.createFromValue("shadow_disabled");
	config.effect := DataWrapper.createFromValue("effect_disabled");
	config.shaderState := shaderState;

	p.addOption({
		GUI.TYPE : GUI.TYPE_SELECT,
		GUI.LABEL : "Shading",
		GUI.DATA_WRAPPER :  config.shading,
		GUI.OPTIONS : [["shading_phong","Phong"], 
					["shading_normalMapped","NormalMapping"], 
					["shading_disabled","Disabled"]]
	});
	p.addOption({
		GUI.TYPE			:	GUI.TYPE_SELECT,
		GUI.LABEL			:	"Color",
		GUI.DATA_WRAPPER	:	config.color,
		GUI.OPTIONS			:	[	
									["color_standard", "Standard", "Standard", 
											"Get color value from material or vertex color"], 
									["color_mapping", "Specular Mapping", "Specular Mapping", 
											"Same as standard, but additionally get specular value from a texture"]
								]
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_SELECT,
		GUI.LABEL : "Texture",
		GUI.DATA_WRAPPER :  config.texture,
		GUI.OPTIONS : [["texture","enabled"], 
					["texture_disabled","disabled"]]
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_SELECT,
		GUI.LABEL : "Shadow",
		GUI.DATA_WRAPPER :  config.shadow,
		GUI.OPTIONS : [["shadow","enabled"], 
					["shadow_disabled","disabled"]]
	});
	p.addOption({
		GUI.TYPE			:	GUI.TYPE_SELECT,
		GUI.LABEL			:	"Effect",
		GUI.DATA_WRAPPER	: 	config.effect,
		GUI.OPTIONS			:	[	
									["effect_disabled", "no effect"],
									["effect_highlight", "highlight"],
									["effect_normalToAlpha", "normal to alpha"]
								]
	});
	p.addAction( "Init Shader",	config->fn(){

		var path = "universal2/";
		var vs = [path+"universal.vs",path+"sgHelpers.sfn"];
		var fs = [path+"universal.fs",path+"sgHelpers.sfn"];
		foreach([this.shading,this.texture,this.shadow,this.effect,this.color] as var f){
			vs+=path+f()+".sfn";
			fs+=path+f()+".sfn";
		}
		MinSG.initShaderState(shaderState,vs, [], fs, Rendering.Shader.USE_UNIFORMS);
		NodeEditor.onSelectionChanged(); // refresh the gui

	} );

	p.init();
	return shaderState;
};
m["Shader: Universal3"] = fn(){
	var shaderState = new MinSG.ShaderState;
	var p = gui.createPopupWindow(200,200);

	var config = new ExtObject;
	config.vertexEffect := DataWrapper.createFromValue("vertexEffect_none");
	config.surfaceProps := DataWrapper.createFromValue("surfaceProps_matTex");
	config.surfaceEffect := DataWrapper.createFromValue("surfaceEffect_none");
	config.lighting := DataWrapper.createFromValue("lighting_phong");
	config.fragmentEffect := DataWrapper.createFromValue("fragmentEffect_none");
	config.shaderState := shaderState;

	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "vertexEffect",
		GUI.DATA_WRAPPER :  config.vertexEffect,
		GUI.OPTIONS : ["vertexEffect_none","vertexEffect_dynamicPointSize" ]
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "surfaceProps",
		GUI.DATA_WRAPPER :  config.surfaceProps,
		GUI.OPTIONS : ["surfaceProps_mat","surfaceProps_matTex","surfaceProps_matTexSpecNorm" ,"surfaceProps_terrain_1" ]
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "surfaceEffect",
		GUI.DATA_WRAPPER :  config.surfaceEffect,
		GUI.OPTIONS : ["surfaceEffect_none","surfaceEffect_reflection","surfaceEffect_translucency" ]
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "lighting",
		GUI.DATA_WRAPPER :  config.lighting,
		GUI.OPTIONS : ["lighting_none","lighting_phong","lighting_shadow" ]
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "fragmentEffect",
		GUI.DATA_WRAPPER :  config.fragmentEffect,
		GUI.OPTIONS : ["fragmentEffect_none", "fragmentEffect_highlight", "fragmentEffect_normalToAlpha" ]
	});
	
	p.addAction( "Init Shader",	config->fn(){

		var path = "universal3/";
		var vs = [path+"main.sfn",path+"sgHelpers.sfn"];
		var fs = [path+"main.sfn",path+"sgHelpers.sfn"];
		foreach([this.vertexEffect,this.surfaceProps,this.surfaceEffect,this.lighting,this.fragmentEffect] as var f){
			vs+=path+f()+".sfn";
			fs+=path+f()+".sfn";
		}
		MinSG.initShaderState(shaderState,vs, [], fs, Rendering.Shader.USE_UNIFORMS);
		NodeEditor.onSelectionChanged(); // refresh the gui

	} );

	p.init();
	return shaderState;
};
m["Strange renderer"] = new MinSG.StrangeExampleRenderer();
m["Transparency Renderer"] = fn(){return new MinSG.TransparencyRenderer();};
if(MinSG.isSet($TreeVisualization)) {
	m["TreeVisualization"] = fn() { return new MinSG.TreeVisualization; };
}
m["Texture"] = fn(){return new MinSG.TextureState();};

if(MinSG.isSet($MAR)){
	m["MAR Surfel Renderer"] = fn(){return new MinSG.MAR.SurfelRenderer();};
}

return m;
// ---------------------------------------------------------------------------------------------
