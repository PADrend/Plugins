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
m["PointParameterState"] = fn(){return new MinSG.PointParameterState;};
m["PolygonModeState"] = fn(){return new MinSG.PolygonModeState;};
m["ProjSizeFilterState"] = fn(){return new MinSG.ProjSizeFilterState;};
m["Shader"] = fn(){	return new MinSG.ShaderState;	};
m["Shader: univeral3 (compose)"] = fn(){
	var shaderState = new MinSG.ShaderState;
	var p = gui.createPopupWindow(400,200);

	var config = new ExtObject;
	config.vertexEffect := new Std.DataWrapper("vertexEffect_none");
	config.surfaceProps := new Std.DataWrapper("surfaceProps_matTex");
	config.surfaceEffect := new Std.DataWrapper("surfaceEffect_none");
	config.lighting := new Std.DataWrapper("lighting_phong");
	config.fragmentEffect := new Std.DataWrapper("fragmentEffect_none");
	config.shaderState := shaderState;
    
  var vertexEffectOptions = [];
  var surfacePropsOptions = [];
  var surfaceEffectOptions = [];
  var lightingOptions = [];
  var fragmentEffectOptions = [];
  
  foreach(PADrend.getSceneManager()._getSearchPaths() as var path){
    foreach(Util.getFilesInDir(path,[".sfn"]) as var filename) {
      var file = (new Util.FileName(filename)).getFile();
      file = file.substr(0,file.length() - 4);
      if(file.beginsWith("vertexEffect_"))
        vertexEffectOptions += file;
      if(file.beginsWith("surfaceProps_"))
        surfacePropsOptions += file;
      if(file.beginsWith("surfaceEffect_"))
        surfaceEffectOptions += file;
      if(file.beginsWith("lighting_"))
        lightingOptions += file;
      if(file.beginsWith("fragmentEffect_"))
        fragmentEffectOptions += file;
    }
  }
  
  
	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "vertexEffect",
		GUI.DATA_WRAPPER :  config.vertexEffect,
		GUI.OPTIONS : vertexEffectOptions
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "surfaceProps",
		GUI.DATA_WRAPPER :  config.surfaceProps,
		GUI.OPTIONS : surfacePropsOptions
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "surfaceEffect",
		GUI.DATA_WRAPPER :  config.surfaceEffect,
		GUI.OPTIONS : surfaceEffectOptions
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "lighting",
		GUI.DATA_WRAPPER :  config.lighting,
		GUI.OPTIONS : lightingOptions
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "fragmentEffect",
		GUI.DATA_WRAPPER :  config.fragmentEffect,
		GUI.OPTIONS : fragmentEffectOptions
	});
	
	p.addAction( "Init Shader",	config->fn(){

		var path = "shader/universal3/";
		var vs = [path+"main.sfn",path+"sgHelpers.sfn"];
		var fs = [path+"main.sfn",path+"sgHelpers.sfn"];
		foreach([this.vertexEffect,this.surfaceProps,this.surfaceEffect,this.lighting,this.fragmentEffect] as var f){
			vs+=f()+".sfn";
			fs+=f()+".sfn";
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

m["[ext] Strange renderer"] = new MinSG.StrangeExampleRenderer;
if(MinSG.isSet($TreeVisualization))
	m["[ext] TreeVisualization"] = fn() { return new MinSG.TreeVisualization; };


return m;
// ---------------------------------------------------------------------------------------------
