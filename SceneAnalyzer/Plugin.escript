/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:SceneAnalyzer] SceneAnalyzer/Plugin.escript
 ** 2008-01-28
 **/

var plugin = new Plugin({
			Plugin.NAME : 'SceneAnalyzer',
			Plugin.VERSION : "2.3",
			Plugin.REQUIRES : ["Evaluator"],
			Plugin.AUTHORS : "Benjamin Eikel, Claudius Jaehn",
			Plugin.OWNER : "Claudius Jaehn",
			Plugin.DESCRIPTION : "Creates, manages and displays appxoximations of scene properties (formerly classification).\n[v] ... show current value.",
			Plugin.EXTENSION_POINTS : [	]
});

static cWindow;
static statId;

plugin.init @(override) := fn(){
	static GASPManager = module('./GlobalGASPManager');

	Util.registerExtension('PADrend_Init',this->fn(){
			
		statId = PADrend.frameStatistics.addCounter("SceneProp","ActiveSceneProperty");
		
		gui.registerComponentProvider('PADrend_PluginsMenu.gasp',{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL :  "SceneAnalyzer",
			GUI.ON_CLICK : fn(){
				toggleWindow();
				this.setSwitch(cWindow.isVisible());
			}
		});
	});

	Util.registerExtension('PADrend_AfterRenderingPass' , fn( renderingPass ){
		var c = GASPManager.getSelectedGASP();
		if(!c)
			return;
		var camera = renderingPass.getCamera();
		var value = c.getValueAtPosition(camera.getWorldOrigin());
		if(!value){
			PADrend.frameStatistics.setValue(statId,-1);
		}else if(value.count()<=1){
			PADrend.frameStatistics.setValue(statId,value[0]);
		}else{
//			print_r(value);
			PADrend.frameStatistics.setValue(statId,c.getDirectionalValue(camera));
		}
		
	});
	Util.registerExtension('PADrend_KeyPressed' , fn(evt) {
		if(evt.key == Util.UI.KEY_F5) {
			toggleWindow();
			return true;
		}
		return false;
	});

	// init sampler
	var sampler=["AdaptiveCSampler","UniformCSampler","ObserverCSampler"];
	if(Util.queryPlugin('JobScheduling')) 
		sampler += "AdaptiveCSampler_dist";

	foreach(sampler as var s)
		GASPManager.registerCSampler( Std.require( 'SceneAnalyzer/Sampling/' +s ) );

	var modules = [];
	if(Util.queryPlugin('PADrend') && MinSG.isSet($SamplingAnalysis)) 
		modules += __DIR__ + "/SamplingAnalyzer/Plugin.escript";

	modules += __DIR__ + "/ValueAnalysis/Plugin.escript";
	modules += __DIR__ + "/QualityAnalysis/Plugin.escript";
	Util.loadPlugins(modules);

    return true;
};


static toggleWindow = fn(){
	if(! cWindow ){
		cWindow = module('SceneAnalyzer/GUI').createWindow(440, 40);
	}else{
		cWindow.toggleVisibility();
	}
};

return plugin;


//plugin.screenshot:=0;

//plugin.ex_Init:=fn(){
	
//	plugin.rFlag_showSamplePoints := true;

	
//////	Listener.add(Listener.CSAMPLER_STEP,fn(evt,ctxt){
//////		for(var i=0;i<2;++i){
////////			var filename="m1/p"+(plugin.screenshot++)+".png";
////////			PADrend.getDolly().rotateRel_deg(0.5,new Geometry.Vec3(0,1,0));
//////			frameContext.setCamera(GLOBALS.camera);
//////			renderingContext.clearScreen(PADrend.bgColor);
//////			rootNode.display(frameContext,PADrend.getRenderingFlags());
//////			var c=GASPManager.getSelectedGASP();
//////			if(c)
//////				c.display(frameContext);
////////			var tex=Rendering.createTextureFromScreen();
////////			var b=Rendering.saveTexture(renderingContext,tex,filename);
////////////			var b=Rendering.saveTexture(renderingContext,tex,filename);
//////			PADrend.SystemUI.swapBuffers();
//////		}
//////	});
   /*
    var f=systemConfig.getValue('SceneAnalyzer.initialFile',false);
    if(f){
        var c=GASPManager.load(f);

        GASPManager.registerGASP(c);
        GASPManager.selectGASP(c);
    }*/
    /*
	Listener.add(Listener.CSAMPLER_STEP,fn(evt,ctxt){
			var filename="m1/p"+(plugin.screenshot++)+".png";

			frameContext.setCamera(GLOBALS.camera);
			renderingContext.clearScreen(PADrend.getBGColor());
			rootNode.display(frameContext,PADrend.getRenderingFlags());
			var c=GASPManager.getSelectedGASP();
			if(c)
				c.display(frameContext);
//			var tex=Rendering.createTextureFromScreen();
//			var b=Rendering.saveTexture(renderingContext,tex,filename);
//////			var b=Rendering.saveTexture(renderingContext,tex,filename);

			var tex=Rendering.createTextureFromScreen();
			var b=Rendering.saveTexture(renderingContext,tex,filename);
	});
	*/
//};
///**
// * [ext:PADrend_AfterRendering]
// * Show GASP
// */
//plugin.ex_AfterRendering:=fn(...){
//	var camera = PADrend.getActiveCamera();
//////////	
//    var c=GASPManager.getSelectedGASP();
//    if(!c)
//        return;
////////////
////////////	if( rFlag_showSamplePoints && c.sampleVisualizationNode ){
////////////		c.sampleVisualizationNode.display(GLOBALS.frameContext);
////////////	}
////////////	
////////////	if( rFlag_showSamplePoints && c.delaunayNode ){
////////////		c.delaunayNode.display(GLOBALS.frameContext);
////////////	}
////////////
//////////    if( (renderingFlags&MinSG.NO_GEOMETRY) ==0){
//////////		c.display(GLOBALS.frameContext,renderingFlags);
//////////    }
//
//    var value = c.getValueAtPosition(camera.getWorldOrigin());
//    if(value!==void){
////        out("\r ",value.implode(","),"    ");
//
//		// todo!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! move to GASPManager
//        if(value.count()<=1){
//            value=value.implode(",");
//        }else{ // interpolate Value
//        	print_r(value);
//            var interpolator=new MinSG.DirectionalInterpolator;
//            var cn=c.rootNode.getNodeAtPosition(camera.getWorldOrigin());
//            
//            var aperture = 90; //c.measurementAperture
//            value=interpolator.calculateValue(renderingContext,cn,camera,aperture);
//        }
//
//    }else{
//        value=false;
////        out("\r xxx        ");
//    }
////    Listener.notify(Listener.TYPE_CLASSIFICATION_VALUE,value);
////    exit(1);
//};
//
//////plugin.
//////	if(MinSG.SceneTool.SHADER_STATE == void){
//////		MinSG.SceneTool.SHADER_STATE = new MinSG.ShaderState();
////// 		var path = Util.requirePlugin('LibRenderingExt').getBaseFolder() + "/resources/shader/universal2/";
////// 		var vs = [path+"universal.vs",path+"sgHelpers.sfn"];
////// 		var fs = [path+"universal.fs",path+"sgHelpers.sfn"];
////// 		foreach(["shading_disabled","color_standard","texture_disabled","shadow_disabled","effect_disabled"] as var f){
////// 			vs+=path+f+".sfn";
////// 			fs+=path+f+".sfn";
////// 		}
//////		MinSG.initShaderState(MinSG.SceneTool.SHADER_STATE,vs, [], fs, Rendering.Shader.USE_UNIFORMS);
//////	}
//
///////////**
////////// * [ext:PADrend_AfterFrame]
////////// * Show CubeWindow
////////// */
//////////plugin.ex_AfterGUI:=fn(camera){
//////////    if(!GASPManager.getSelectedGASP())
//////////        return;
////////////    var cubeWindow=GLOBALS.gui.windows['CubeWindow'];
////////////    if(!cubeWindow || !cubeWindow.isVisible())
////////////        return;
////////////
////////////    var xSize=(cubeWindow.getRect().getWidth()/16).floor()*4;
////////////    var ySize=((cubeWindow.getRect().getHeight()-20)/12).floor()*4;
////////////    var size=xSize<ySize?xSize:ySize;
////////////    var pos=cubeWindow.panel.getWorldOrigin();
//////////////    var rect=new Geometry.Rect(pos.getX(),renderingContext.getWindowHeight()-pos.getY()+size*3,size*4,size*3);
////////////    var rect=new Geometry.Rect(pos.getX(),renderingContext.getWindowHeight()-pos.getY()-size*3,size*4,size*3);
////////////    var size=[(rect.width/4).floor(),(rect.getHeight()/3).floor()].min();
////////////
////////////
////////////    var results=GASPManager.getSelectedGASP().measure(
//////////////                GLOBALS.sceneRoot,
////////////                PADrend.getRootNode(),
////////////                /*Vec3*/camera.getWorldOrigin(),
////////////                /*MinSG.Evaluator*/EvaluatorManager.getSelectedEvaluator(),
////////////                /*MinSG.Camera*/camera,
////////////                /*Geometry.Rect*/rect,size);
////////////    GLOBALS.cubeWindow.setTitle(EvaluatorManager.getSelectedEvaluator().toString()+" ("+results.implode(" ; ")+")");
//////////};

