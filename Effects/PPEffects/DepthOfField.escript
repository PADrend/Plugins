/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Effects] Effects/PPEffects/SSAO.escript
 **/


var Effect = new Type( Std.require('Effects/PPEffect') );

Effect._constructor:=fn(){
    this.fbo:=new Rendering.FBO;

    renderingContext.pushAndSetFBO(fbo);
//    this.colorTexture:=Rendering.createStdTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
    this.colorTexture:=Rendering.createHDRTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight(),true);
    fbo.attachColorTexture(renderingContext,colorTexture);
    this.depthTexture:=Rendering.createDepthTexture(renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
    fbo.attachDepthTexture(renderingContext,depthTexture);
    out(fbo.getStatusMessage(renderingContext),"\n");

    renderingContext.popFBO();

    this.blurShader:=Rendering.Shader.loadShader( getShaderFolder()+"Simple_GL.vs",getShaderFolder()+"Blur.fs");
    renderingContext.pushAndSetShader(blurShader);
    blurShader.setUniform(renderingContext,'TUnit_1',Rendering.Uniform.INT,[0]) ;
    blurShader.setUniform(renderingContext,'range',Rendering.Uniform.INT,[10]) ;
	renderingContext.popShader();

    this.dofShader:=Rendering.Shader.loadShader(getShaderFolder()+"Simple_GL.vs",getShaderFolder()+"DoF.fs");
	renderingContext.pushAndSetShader(dofShader);
    dofShader.setUniform(renderingContext,'TUnit_1',Rendering.Uniform.INT,[0]) ;
    dofShader.setUniform(renderingContext,'TUnit_Blur',Rendering.Uniform.INT,[1]) ;
    dofShader.setUniform(renderingContext,'TUnit_Depth',Rendering.Uniform.INT,[2]) ;
	renderingContext.popShader();

    this.blurResolution:=0.5;
    
    this.settings := new ExtObject({
		$autoFocusRange : DataWrapper.createFromValue(2.5),
		$autoFocus : DataWrapper.createFromValue(false),
		$bloomingLimit : DataWrapper.createFromValue(1.9),
		$blurRange : DataWrapper.createFromValue(7),
		$dofArea_1 : DataWrapper.createFromValue(0.7),
		$dofArea_2 : DataWrapper.createFromValue(1.5),
		$dofArea_3 : DataWrapper.createFromValue(500),
		$dofArea_4 : DataWrapper.createFromValue(800),
	});

//    this.blurFBO:=new Rendering.FBO;
    this.blurTexture_1:=Rendering.createHDRTexture(renderingContext.getWindowWidth()*blurResolution,renderingContext.getWindowHeight()*blurResolution,true);
    this.blurTexture_2:=Rendering.createHDRTexture(renderingContext.getWindowWidth()*blurResolution,renderingContext.getWindowHeight()*blurResolution,true);

//    blurFBO.attachColorTexture(renderingContext,blurTexture);
//    out(blurFBO.getStatusMessage(),"\n");
    

    this.currentDepth:=0;



};
/*! ---|> PPEffect  */
Effect.begin @(override) ::= fn(){
    renderingContext.pushAndSetFBO(fbo);
    fbo.attachColorTexture(renderingContext,colorTexture);
    fbo.attachDepthTexture(renderingContext,depthTexture);
};
/*! ---|> PPEffect  */
Effect.end  @(override) ::= fn(){
    if(settings.autoFocus())   {   // get depth for focus
        var depth=Rendering.readDepthValue(renderingContext.getWindowWidth()*0.5,renderingContext.getWindowHeight()*0.5);
        var zNear=camera.getNearPlane();
        var zFar=camera.getFarPlane();
        this.currentDepth = (zNear * zFar) / (zFar - depth * (zFar - zNear));

        if(currentDepth<zFar*0.99){
            settings.dofArea_1( (settings.dofArea_1()*2.0 + currentDepth *(0.7).pow(settings.autoFocusRange())*0.2)/3);
            settings.dofArea_2( (settings.dofArea_2()*2.0 + currentDepth *(0.7).pow(settings.autoFocusRange()))/3);
            settings.dofArea_3( (settings.dofArea_3()*2.0 + currentDepth *(1.3).pow(settings.autoFocusRange()))/3);
            settings.dofArea_4( (settings.dofArea_4()*2.0 + currentDepth *(1.3).pow(settings.autoFocusRange())*2.0)/3);

        }
    }

    // colorTexture contains image
    // depthTexture contains depth info
    fbo.detachDepthTexture(renderingContext);

	renderingContext.pushAndSetShader(blurShader);
    blurShader.setUniform(renderingContext,'range',Rendering.Uniform.INT,[settings.blurRange()]) ;
    blurShader.setUniform(renderingContext,'pixelSize',Rendering.Uniform.FLOAT,[1.0/(renderingContext.getWindowWidth()*blurResolution)]) ;
    blurShader.setUniform(renderingContext,'orientation',Rendering.Uniform.INT,[0]) ;

    // color -(blur1)-> blurTexture_1
    fbo.attachColorTexture(renderingContext,blurTexture_1);
    Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth()*blurResolution,renderingContext.getWindowHeight()*blurResolution) ,
                            this.colorTexture,new Geometry.Rect(0,0,1,1));

    // blurTexture_1 -(blur2)-> blurTexture_2
    fbo.attachColorTexture(renderingContext,blurTexture_2);
    blurShader.setUniform(renderingContext,'pixelSize',Rendering.Uniform.FLOAT,[1.0/(renderingContext.getWindowHeight()*blurResolution)]) ;
    blurShader.setUniform(renderingContext,'orientation',Rendering.Uniform.INT,[1]) ;

    Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth()*blurResolution,renderingContext.getWindowHeight()*blurResolution) ,
                            this.blurTexture_1,new Geometry.Rect(0,0,1,1));


    renderingContext.popFBO();

	renderingContext.popShader();

	renderingContext.pushAndSetShader(dofShader);

    var m1 = 1.0/(settings.dofArea_1()-settings.dofArea_2()+0.00001);
    var c1 = -settings.dofArea_2()*m1;
    var m2 = 1.0/((settings.dofArea_4()-settings.dofArea_3()+0.00001));
    var c2 = -settings.dofArea_3()*m2;

//    out( "\r ",m2,"\t",c2,"                       ");
    dofShader.setUniform(renderingContext,'m1',Rendering.Uniform.FLOAT,[m1]) ;
    dofShader.setUniform(renderingContext,'c1',Rendering.Uniform.FLOAT,[c1]) ;
    dofShader.setUniform(renderingContext,'m2',Rendering.Uniform.FLOAT,[m2]) ;
    dofShader.setUniform(renderingContext,'c2',Rendering.Uniform.FLOAT,[c2]) ;

    dofShader.setUniform(renderingContext,'bloomingLimit',Rendering.Uniform.FLOAT,[settings.bloomingLimit()]) ;

    Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()),
                              [colorTexture,blurTexture_2,depthTexture ] ,
                              [new Geometry.Rect(0,0,1,1),new Geometry.Rect(0,0,1,1),new Geometry.Rect(0,0,1,1)]);

    renderingContext.popShader();

};
/*! ---|> PPEffect  */
Effect.getOptionPanel  @(override) ::= fn(){
    var p=gui.createPanel(200,200,GUI.AUTO_MAXIMIZE|GUI.AUTO_LAYOUT);
    p.add(gui.createLabel("DoF"));
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Blur range",
		GUI.RANGE : [1,100],
		GUI.DATA_WRAPPER : settings.blurRange
    };
    p++;   
	p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "bloomingLimit",
		GUI.RANGE : [0,10],
		GUI.DATA_WRAPPER : settings.bloomingLimit
    };
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "dofArea_1",
		GUI.RANGE : [0,500],
		GUI.DATA_WRAPPER : settings.dofArea_1
    };
    p++;    
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "dofArea_2",
		GUI.RANGE : [0,500],
		GUI.DATA_WRAPPER : settings.dofArea_2
    };
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "dofArea_3",
		GUI.RANGE : [0,500],
		GUI.DATA_WRAPPER : settings.dofArea_3
    };
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "dofArea_4",
		GUI.RANGE : [0,500],
		GUI.DATA_WRAPPER : settings.dofArea_4
    };
    p++;    
	p+={
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "autoFocus",
		GUI.DATA_WRAPPER : settings.autoFocus
    };
    p++;
    p+={
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "autoFocusRange",
		GUI.RANGE : [0.1,10],
		GUI.DATA_WRAPPER : settings.autoFocusRange
    };
    p++;

    return p;
};

return new Effect;
