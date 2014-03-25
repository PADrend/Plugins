/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Jan Krems
 * Copyright (C) 2010-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Spielerei] Spielerei/PostProcessingEffects.escript
 ** 2009-11 Urlaubsprojekt...
 **/

//!	PPEffectPlugin ---|> Plugin
GLOBALS.PPEffectPlugin := new Plugin({
			Plugin.NAME : "Effects_PPEffects",
			Plugin.VERSION : "1.0",
			Plugin.DESCRIPTION : "Various post-processing effects",
			Plugin.AUTHORS : "Benjamin Eikel, Claudius Jaehn, Ralf Petring",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : []
});

static defaultEffect = DataWrapper.createFromEntry( PADrend.configCache, 'Effects.ppEffectDefault',false);
static activeEffectFile = new DataWrapper;
static plugin = PPEffectPlugin;

/*!	---|> Plugin	*/
PPEffectPlugin.init:=fn(){
     { // Register ExtensionPointHandler:
        registerExtension('PADrend_Init',this->initMenus);
        registerExtension('PADrend_AfterRenderingPass',this->this.ex_AfterRenderingPass,Extension.LOW_PRIORITY); // use low priority to include other afterFrame-effects (like selected node's annotation)
        registerExtension('PADrend_BeforeRenderingPass',this->this.ex_BeforeRenderingPass);
        registerExtension('PADrend_AfterRendering',this->this.ex_AfterRendering,Extension.LOW_PRIORITY); // use low priority to include other afterFrame-effects (like selected node's annotation)
        registerExtension('PADrend_BeforeRendering',this->this.ex_BeforeRendering);
    }
    this.effect:=false;
    this.optionWindow:=false;
    
    registerExtension('PADrend_Init',fn(){
		if(defaultEffect())
			plugin.loadAndSetEffect(defaultEffect());
    });

    return true;
};

//! name -> filename
static scanEffectFiles = fn(){
	var files = new Map; 
	foreach(Util.getFilesInDir(__DIR__+"/PPEffects",['.escript']) as var file){
		var name = file.substr(file.rFind("/")+1);
		name = name.substr(0,name.rFind("."));
		if(name.beginsWith("_"))
			continue;
		if(file.beginsWith("file://"))
			file = file.substr(7);
		files[name] = file;
	}
	return files;
};

PPEffectPlugin.initMenus := fn(){
	gui.registerComponentProvider('Effects_MainMenu.postprocessing',{
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "PP effects",
		GUI.MENU_WIDTH : 170,
		GUI.MENU : 'Effects_PPMenu'
	});
					
	gui.registerComponentProvider('Effects_PPMenu',this->fn(){
								
		var effects = scanEffectFiles();
		var m=[];

		m+="*PostProcessing*";

		m+={
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Options...",
			GUI.ON_CLICK :this->fn(){
				this.createOtionWindow(this.effect);
			}
		};

		m+={
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Disable",
			GUI.ON_CLICK : fn() {
				PADrend.executeCommand(fn(){PPEffectPlugin.setEffect(false);});
			}
		};
		m+={
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Set as default",
			GUI.ON_CLICK : fn() {
				defaultEffect(activeEffectFile());
				gui.closeAllMenus();
			},
			GUI.TOOLTIP : "Sets the active effect as default effect.\nThe default effect is loaded when the program is started."
		};

		m+='----';
		foreach(effects as var name, var file){
			m+={
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : defaultEffect()==file ? name+" (default)" : name,
				GUI.ON_CLICK : [file] => fn(file) {
					PADrend.executeCommand( [file]=>fn(file){PPEffectPlugin.loadAndSetEffect(file); });
				}
			};
		}
		return m;
	});

};

/**
 * [ext:PADrend_BeforeRendering]
 */
PPEffectPlugin.ex_BeforeRendering:=fn(...){
    if(!effect)
        return;
    effect.begin();
};

/**
 * [ext:PADrend_AfterRendering]
 */
PPEffectPlugin.ex_AfterRendering:=fn(...){
    if(!effect)
        return;
    effect.end();
};

/**
 * [ext:PADrend_BeforeRendering]
 */
PPEffectPlugin.ex_BeforeRenderingPass:=fn(PADrend.RenderingPass pass){
    if(!effect)
        return;
    effect.beginPass(pass);
};

/**
 * [ext:PADrend_AfterRendering]
 */
PPEffectPlugin.ex_AfterRenderingPass:=fn(PADrend.RenderingPass pass){
    if(!effect)
        return;
    effect.endPass(pass);
};

/**
 * [ext:PADrend_AfterRendering]
 */
PPEffectPlugin.createOtionWindow:=fn(effect){
    if(!optionWindow){
        this.optionWindow = gui.createWindow(400,200,"EffectOptions");
        this.optionWindow.setPosition(300,300);

    }else{
        this.optionWindow.clear();
    }
    if(effect){
        optionWindow.add(effect.getOptionPanel());
    }
    optionWindow.setEnabled(true);
};

PPEffectPlugin.setEffect:=fn(newEffect){
    this.effect=newEffect;
    if(optionWindow){
        optionWindow.clear();
        if(newEffect)
            optionWindow.add(effect.getOptionPanel());
    }
	activeEffectFile(false);
};

PPEffectPlugin.loadAndSetEffect := fn(filename){
	if(filename){
		var effect = load(filename);
		setEffect(effect);
		activeEffectFile(filename);
	}else{
		setEffect(void);
	}
};

/****************************************************************************
 * PPEffect
 ****************************************************************************/

GLOBALS.PPEffect:=new Type();
PPEffect._printableName @(override) ::= $PPEffect;
/*! ---o  */
PPEffect.begin:=fn(){};
/*! ---o  */
PPEffect.end:=fn(){};
/*! ---o  */
PPEffect.beginPass:=fn(PADrend.RenderingPass pass){};
/*! ---o  */
PPEffect.endPass:=fn(PADrend.RenderingPass pass){};
/*! ---o  */
PPEffect.getOptionPanel:=fn(){
    return gui.createLabel("Effect");
};
PPEffect.getShaderFolder ::= fn(){	return __DIR__+"/resources/PP_Effects/";	};

/****************************************************************************
 * PPEffect_Simple ---|> PPEffect
 ****************************************************************************/
GLOBALS.PPEffect_Simple := new Type(PPEffect);
PPEffect_Simple._constructor::=fn(Rendering.Shader shader){

	this.fbo := new Rendering.FBO;
	this.color := void;
	this.effect := void;
	this.depth := void;
	this.noise := void;
	this.numbers := void;

	this.viewport := void;
	this.shader := shader;

	this.border := 1.0;
};

PPEffect_Simple.applyUniforms ::= fn(){
};

PPEffect_Simple.beginPass ::= fn(PADrend.RenderingPass pass){
	
	this.viewport = pass.getCamera().getViewport();
	pass.getCamera().setViewport(new Geometry.Rect(0,0,viewport.width(),viewport.height()));
	
	if(!effect || viewport.width() != effect.getWidth() || viewport.height() != effect.getHeight()){
		effect = Rendering.createStdTexture(viewport.width(), viewport.height(),true);
		color = Rendering.createStdTexture(viewport.width(), viewport.height(),true);
		depth = Rendering.createDepthTexture(viewport.width(), viewport.height());
		if(noise)
			noise = Rendering.createNoiseTexture(viewport.width(), viewport.height(),true);
	}
	
	renderingContext.pushAndSetFBO(fbo);
	fbo.attachColorTexture(renderingContext,color);
	fbo.attachDepthTexture(renderingContext,depth);
	
};

PPEffect_Simple.endPass ::= fn(PADrend.RenderingPass pass){

	fbo.detachColorTexture(renderingContext);
	fbo.detachDepthTexture(renderingContext);
	renderingContext.popFBO();
	
	pass.getCamera().setViewport(viewport);
	frameContext.setCamera(pass.getCamera());
	
	renderingContext.pushAndSetShader(shader);
	
	shader.setUniform(renderingContext,"color", Rendering.Uniform.INT, [0], false);
	shader.setUniform(renderingContext,"depth", Rendering.Uniform.INT, [1], false);
	shader.setUniform(renderingContext,"noise", Rendering.Uniform.INT, [2], false);
	shader.setUniform(renderingContext,"numbers", Rendering.Uniform.INT, [3], false);
	shader.setUniform(renderingContext,"imageSize", Rendering.Uniform.VEC2I, [ [viewport.width(), viewport.height()] ], false);
	
	shader.setUniform(renderingContext,"border", Rendering.Uniform.FLOAT, [border], false);
	applyUniforms();
	
	renderingContext.pushAndSetTexture(0, color);
	renderingContext.pushAndSetTexture(1, depth);
	if(noise)
		renderingContext.pushAndSetTexture(2, noise);
	if(numbers)
		renderingContext.pushAndSetTexture(3, numbers);
	
	renderingContext.pushAndSetDepthBuffer(true, true, Rendering.Comparison.ALWAYS);
	Rendering.drawFullScreenRect(renderingContext);
	renderingContext.popDepthBuffer();
	
	renderingContext.popTexture(0);
	renderingContext.popTexture(1);
	if(noise)
		renderingContext.popTexture(2);
	if(numbers)
		renderingContext.popTexture(3);
	
	renderingContext.popShader();
};

PPEffect_Simple.getOptionPanel ::= fn(){
	var p = gui.createPanel(400,200,GUI.AUTO_MAXIMIZE|GUI.AUTO_LAYOUT);
	p += "*Global*";
    p++;
    p += {GUI.LABEL:"border", GUI.TYPE:GUI.TYPE_RANGE, GUI.RANGE:[0,1], GUI.RANGE_STEPS:100, GUI.DATA_OBJECT:this, GUI.DATA_ATTRIBUTE:$border};
	p++;
	addOptions(p);
	return p;
};

PPEffect_Simple.addOptions ::= fn(panel){
};

/****************************************************************************
 * PPEffect_DrawToScreen ---|> PPEffect
 ****************************************************************************/
GLOBALS.PPEffect_DrawToScreen := new Type(PPEffect);
PPEffect_DrawToScreen._constructor ::= fn() {
	this.fbo := new Rendering.FBO;
	
	this.colorTexture := Rendering.createStdTexture(renderingContext.getWindowWidth(), renderingContext.getWindowHeight(), true);
	this.depthTexture := Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
	
	renderingContext.pushAndSetFBO(fbo);
	fbo.attachColorTexture(renderingContext, colorTexture);
	fbo.attachDepthTexture(renderingContext, depthTexture);
	renderingContext.popFBO();
};

PPEffect_DrawToScreen.drawTexture ::= fn(Rendering.Texture texture) {
	Rendering.drawTextureToScreen(renderingContext, new Geometry.Rect(0, 0, renderingContext.getWindowWidth(), renderingContext.getWindowHeight()),
								  [texture], [new Geometry.Rect(0, 0, 1, 1)]);
};

/****************************************************************************
 * 
 ****************************************************************************/

return PPEffectPlugin;
