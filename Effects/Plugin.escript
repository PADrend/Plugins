/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Effects] Effects/Plugin.escript
 ** 2010-03-21
 **/

GLOBALS.EffectsPlugin := new Plugin({
			Plugin.NAME : "Effects",
			Plugin.VERSION : "1.0",
			Plugin.DESCRIPTION : "Container for various effects.",
			Plugin.AUTHORS : "Claudius Jaehn",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : ['LibRenderingExt']
});

EffectsPlugin.init @(override) :=fn() {
	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_Init',this->registerMenus);
	}
	var modules = [];
	modules+=__DIR__+"/"+"DynamicSky.escript";
	modules+=__DIR__+"/"+"InfiniteGround.escript";
	modules+=__DIR__+"/"+"PostProcessingEffects.escript";
	modules+=__DIR__+"/"+"LimitFPS.escript";
	modules+=__DIR__+"/"+"Stereo.escript";

	loadPlugins( modules,false );

    return true;
};

//!	[ext:PADrend_Init]
EffectsPlugin.registerMenus:=fn(){
	gui.registerComponentProvider('PADrend_MainToolbar.70_effects',{
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL:"Effects",
		GUI.ICON : "#EffectsSmall",
		GUI.ICON_COLOR : GUI.BLACK,
		GUI.MENU : 'Effects_MainMenu'
	});
	
	gui.registerComponentProvider('Effects_MainMenu.misc',{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Misc",
			GUI.MENU : 'Effects_MiscEffectsMenu'
	});

	// ----------------------------	
	gui.registerComponentProvider('Effects_MainMenu.environment',[
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Environment",
			GUI.MENU : 'Effects_EnvironmentMenu'
		}
	]);

	gui.registerComponentProvider('Effects_EnvironmentMenu',[
		"*Environment*",
		{
			GUI.LABEL		:	"Lake",
			GUI.TOOLTIP		:	"Demonstration of the MirrorState.\nLoad the file 'Lake.ply' and add a MirrorState to it.\nDemonstration of the MirrorState.",
			GUI.ON_CLICK	:	fn() {
									var geoNode = MinSG.loadModel(__DIR__+"/resources/Meshes/Lake.ply");
									geoNode.scale(10);
									var mirrorState = new MinSG.MirrorState(512);
									geoNode.addState(mirrorState);
									PADrend.getCurrentScene().addChild(geoNode);
								}
		},
		{
			GUI.LABEL		:	"Shadow",
			GUI.TOOLTIP		:	"Demonstration of the ShadowState.\nAttach a universal shader and a ShadowState to the current scene.\nUse the default light for shadow generation.",
			GUI.ON_CLICK	:	fn() {
									var scene = PADrend.getCurrentScene();
									
									var shaderState = new MinSG.ShaderState();
									
									var shaderPath = Util.requirePlugin('LibRenderingExt').getBaseFolder() + "/resources/shader/universal3/";
									var shaderFiles =	[
															shaderPath + "main.sfn",
															shaderPath + "sgHelpers.sfn",
															shaderPath + "vertexEffect_none.sfn",
															shaderPath + "surfaceProps_matTex.sfn",
															shaderPath + "surfaceEffect_none.sfn",
															shaderPath + "lighting_shadow.sfn",
															shaderPath + "fragmentEffect_none.sfn"
														];
									MinSG.initShaderState(shaderState,
														  shaderFiles,
														  [], 
														  shaderFiles,
														  Rendering.Shader.USE_UNIFORMS);
									scene.addState(shaderState);

									var shadow = new MinSG.ShadowState(4096);
									shadow.setLight(PADrend.getDefaultLight());
									scene.addState(shadow);
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Skybox",
			GUI.ON_CLICK : fn() {
			   PADrend.getRootNode().addState(MinSG.createSkybox("./"+PADrend.getDataPath()+"/texture/SKY_3_(?).bmp"));
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Skybox 2",
			GUI.ON_CLICK : fn() {
			   PADrend.getRootNode().addState(MinSG.createSkybox("./"+PADrend.getDataPath()+"/texture/SKY_Raster_(?).png"));
			}
		}
	]);
	// ----------------------------

};

return EffectsPlugin;
// ------------------------------------------------------------------------------
