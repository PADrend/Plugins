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
 
var m = new Map;

m["AlphaTestState"] = fn(){return new MinSG.AlphaTestState;};
m["BlendingState"] = fn(){return new MinSG.BlendingState;};
m["CullFaceState"] = fn(){return new MinSG.CullFaceState;};
m["GroupState"] = fn() { return new MinSG.GroupState; };
m["Lighting"] = fn(){return new MinSG.LightingState;};
m["MaterialState"] = fn(){return new MinSG.MaterialState;};
m["PolygonModeState"] = fn(){return new MinSG.PolygonModeState;};
m["ProjSizeFilterState"] = fn(){return new MinSG.ProjSizeFilterState;};
m["Shader"] = fn(){	return new MinSG.ShaderState;	};
m["Shader: univeral3 (compose)"] = fn(){
	var shaderState = new MinSG.ShaderState;
	var p = gui.createPopupWindow(200,200);

	var config = new ExtObject;
	config.vertexEffect := new Std.DataWrapper("vertexEffect_none");
	config.surfaceProps := new Std.DataWrapper("surfaceProps_matTex");
	config.surfaceEffect := new Std.DataWrapper("surfaceEffect_none");
	config.lighting := new Std.DataWrapper("lighting_phong");
	config.fragmentEffect := new Std.DataWrapper("fragmentEffect_none");
	config.shaderState := shaderState;

	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "vertexEffect",
		GUI.DATA_WRAPPER :  config.vertexEffect,
		GUI.OPTIONS : ["vertexEffect_none","vertexEffect_dynamicPointSize" ,"vertexEffect_instanced","vertexEffect_surfelSize"]
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
		GUI.OPTIONS : ["lighting_none","lighting_phong","lighting_phongEnv","lighting_shadow" ]
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "fragmentEffect",
		GUI.DATA_WRAPPER :  config.fragmentEffect,
		GUI.OPTIONS : ["fragmentEffect_none", "fragmentEffect_highlight", "fragmentEffect_normalToAlpha", "fragmentEffect_splitPlane", "fragmentEffect_ellipticSurfels" ]
	});
	
	p.addAction( "Init Shader",	config->fn(){

		var path = "shader/universal3/";
		var vs = [path+"main.sfn",path+"sgHelpers.sfn"];
		var fs = [path+"main.sfn",path+"sgHelpers.sfn"];
		foreach([this.vertexEffect,this.surfaceProps,this.surfaceEffect,this.lighting,this.fragmentEffect] as var f){
			vs+=path+f()+".sfn";
			fs+=path+f()+".sfn";
		}
		MinSG.initShaderState(shaderState,vs, [], fs, Rendering.Shader.USE_UNIFORMS,PADrend.getSceneManager().getFileLocator());
		NodeEditor.refreshSelectedNodes(); // refresh the gui

	} );
	p.addAction( "Cancel" );

	p.init();
	return shaderState;
};
m["Shader: univeral3 (preset)"] = fn(){

	var shaderState = new MinSG.ShaderState;

	var preset = new Std.DataWrapper("");
	preset.onDataChanged += [shaderState] => fn(shaderState, presetName){
		shaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME)(presetName);
		shaderState.recreateShader( PADrend.getSceneManager() );
	};
	
	gui.openDialog({
		GUI.TYPE : GUI.TYPE_POPUP_DIALOG,
		GUI.LABEL : "Init ShaderState with shader preset",
		GUI.ACTIONS : ["Done"],
		GUI.SIZE : [400,100],
		GUI.OPTIONS : [
			{
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "Preset:",
				GUI.OPTIONS_PROVIDER : fn(){
					var entries = [""];
					foreach(PADrend.getSceneManager()._getSearchPaths() as var path){
						foreach(Util.getFilesInDir(path,[".shader"]) as var filename){
							entries += (new Util.FileName(filename)).getFile();
						}
					}
					return entries;
				},
				GUI.DATA_WRAPPER : preset
			}
		]
	});
	preset( "universal3_default.shader" );
	
	return shaderState;
};
m["Shader Uniform"] = fn(){	return new MinSG.ShaderUniformState;	};
m["Transparency Renderer"] = fn(){return new MinSG.TransparencyRenderer;};
m["Texture"] = fn(){return new MinSG.TextureState;};


m["[ext] BudgetAnnotationState"] = fn() { return new MinSG.BudgetAnnotationState; };
m["[ext] CHC(old) renderer"] = fn(){return new MinSG.OccRenderer;};
m["[ext] CHC renderer"] = fn(){return new MinSG.CHCRenderer;};
m["[ext] CHC++ renderer"] = fn(){return new MinSG.CHCppRenderer;};
m["[ext] NaiveOccRenderer"] = fn(){return new MinSG.NaiveOccRenderer;};

if(MinSG.isSet($ColorCubeRenderer))
	m["[ext] ColorCube renderer"] = fn() { return new MinSG.ColorCubeRenderer;};
m["[ext] HOM renderer"] = fn() { return new MinSG.HOMRenderer(512); };
m["[ext] LineWidthState"] = fn() { return new (Std.module('LibMinSGExt/LineWidthState')); };
m["[ext] LOD-Renderer"] = fn(){return new MinSG.LODRenderer;};
if(MinSG.isSet($MAR))
	m["[ext] MAR Surfel Renderer"] = fn(){return new MinSG.MAR.SurfelRenderer;};
m["[ext] Mirror"] = fn() { var state = new MinSG.MirrorState(512); return state; };
m["[ext] OccludeeRenderer"] = fn() { return new MinSG.OccludeeRenderer; };
if (MinSG.isSet($PipelineStatistics)) {
	m["[ext] Pipeline Statistics Collector"] = fn() { return new MinSG.PipelineStatistics.Collector; };
}
m["[ext] Shadow"] = fn(){return new MinSG.ShadowState(4096);};
m["[deprecated] Shader: Universal2"] = fn(){
	var shaderState = new MinSG.ShaderState;
	var p = gui.createPopupWindow(200,200);

	var config = new ExtObject;
	config.shading := new Std.DataWrapper("shading_phong");
	config.color := new Std.DataWrapper("color_standard");
	config.texture := new Std.DataWrapper("texture");
	config.shadow := new Std.DataWrapper("shadow_disabled");
	config.effect := new Std.DataWrapper("effect_disabled");
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
		MinSG.initShaderState(shaderState,vs, [], fs, Rendering.Shader.USE_UNIFORMS, PADrend.getSceneManager().getFileLocator());
		NodeEditor.refreshSelectedNodes(); // refresh the gui

	} );

	p.init();
	return shaderState;
};

m["[ext] Strange renderer"] = new MinSG.StrangeExampleRenderer;
if(MinSG.isSet($SurfelRenderer))		
	m[ "[ext] SurfelRenderer" ] = fn(){return new MinSG.SurfelRenderer;};
if(MinSG.isSet($SurfelRenderer2))		
	m[ "[ext] SurfelRenderer2" ] = fn(){return new MinSG.SurfelRenderer2;};
  
if(MinSG.isSet($TreeVisualization))
	m["[ext] TreeVisualization"] = fn() { return new MinSG.TreeVisualization; };


return m;
// ---------------------------------------------------------------------------------------------
