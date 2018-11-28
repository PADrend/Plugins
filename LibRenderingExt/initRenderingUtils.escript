/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*!
	Various extensions to the Rendering library.
 */

//------------------------------------

//! Show the given texture on the sceen for the given time and swap the frame buffer.
Rendering.showDebugTexture := fn(Rendering.Texture t, time = 0.5, scale = 1){
	
	if( t.getTextureType()!=Rendering.Texture.TEXTURE_2D ){
		var b = Rendering.createBitmapFromTexture( renderingContext, t );
		t = Rendering.createTextureFromBitmap( b );
	}
	
	renderingContext.pushAndSetScissor(new Rendering.ScissorParameters(new Geometry.Rect(0,0,t.getWidth()*scale,t.getHeight()*scale)));
	renderingContext.pushViewport();
	renderingContext.setViewport(0,0,t.getWidth()*scale,t.getHeight()*scale);

	Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,t.getWidth()*scale,t.getHeight()*scale) ,
							[t],[new Geometry.Rect(0,0,1,1)]);
	renderingContext.popScissor();
	renderingContext.popViewport();
	
	PADrend.SystemUI.swapBuffers();
	for(var i=clock()+time;clock()<i;);
};

//------------------------------------

Rendering.Shader._setUniform ::= Rendering.Shader.setUniform;

/*! Passes all additional parameters to the uniform's constructor. 
	Allows:
		shader.setUniform(renderingContext,'m1',Rendering.Uniform.FLOAT,[m1]);
	instead of:
		shader.setUniform(renderingContext, new Rendering.Uniform('m1',Rendering.Uniform.FLOAT,[m1]) );	*/
Rendering.Shader.setUniform ::= fn(rc,uniformOrName,params...){
	if(uniformOrName---|>Rendering.Uniform){
		return this._setUniform(rc,uniformOrName,params...);
	}else{
		var type = params.popFront();
		var values = params.popFront();
		return this._setUniform(rc,new Rendering.Uniform(uniformOrName,type,values),params...);
	}
};

// --------------------------------------

Rendering.RenderingContext._setGlobalUniform ::= Rendering.RenderingContext.setGlobalUniform;

/*! Passes all parameters to the uniform's constructor. 
	Allows:
		renderingContext.setGlobalUniform('m1',Rendering.Uniform.FLOAT,[m1]);
	instead of:
		renderingContext.setGlobalUniform(new Rendering.Uniform('m1',Rendering.Uniform.FLOAT,[m1]) );	*/
Rendering.RenderingContext.setGlobalUniform ::= fn(params...){
	return this._setGlobalUniform(new Rendering.Uniform(params...));
};

// --------------------------------------

Rendering.Shader.createComputeFromFile := fn(file, defines=new Map) {
	return Rendering.Shader.createShader().attachCSFile(file, defines);
};

// --------------------------------------

Rendering.Shader.createGeometryFromFile := fn(file, defines=new Map) {
	return Rendering.Shader.createShader()
												 .attachVSFile(file, defines)
												 .attachGSFile(file, defines)
												 .attachFSFile(file, defines);
};

//-------------------------------------

static getCubeSmoothShader = fn(){
	@(once) static shader = Rendering.Shader.createShader(
		"void main( void){  gl_TexCoord[0] = gl_MultiTexCoord0; gl_Position = ftransform(); }",
		"#version 120														\n"
		"#define M_PI 3.1415926535897932384626433832795						\n"
		"uniform int layer; 												\n"
		"uniform samplerCube t_envMapInput; 								\n"
		"void main(void){ 													\n"
		"	vec3 cubeDirection;												\n"
		"	vec2 v = gl_TexCoord[0].xy*2.0-1.0;								\n"
		"	if(layer==0)		cubeDirection = vec3(  1.0, -v.y,	-v.x);	\n"
		"	else if(layer==1)	cubeDirection = vec3( -1.0,	-v.y,	 v.x);	\n"
		"	else if(layer==2)	cubeDirection = vec3(  v.x,  1.0,	 v.y);	\n"
		"	else if(layer==3)	cubeDirection = vec3(  v.x, -1.0,	-v.y);	\n"
		"	else if(layer==4)	cubeDirection = vec3(  v.x, -v.y,	 1.0);	\n"
		"	else 				cubeDirection = vec3( -v.x, -v.y,	-1.0);	\n"
		"	cubeDirection = normalize(cubeDirection);						\n"
		"	vec4 inputColor = textureCube( t_envMapInput, cubeDirection );	\n"
		"	vec3 right = cross(cubeDirection,vec3(0,1,0));					\n"
		"	if( length(right)  <0.1 ){ 										\n"
		"		right = cross(cubeDirection,vec3(1,0,0));					\n"
		"		inputColor.r += 1.0; 										\n"
		"	}																\n"
		"	right = normalize(right);										\n"
		"	vec3 up = cross(right,cubeDirection);							\n"
		"	mat3 rot = mat3( right,up,cubeDirection); 						\n"
		"	vec4 color2;													\n"
		"	float w=0;														\n"
		"   for(float d=0.02; d<0.2; d *= 1.2){								\n"
		"   	for(float r=0; r<2.0*M_PI; r+=M_PI/32.0){					\n"
		"			vec3 dir2 = rot * vec3( d*cos(r), d*-sin(r),1);			\n"
		"			color2 += textureCube( t_envMapInput, dir2 ) * (1.0-d); \n"
		"			w += (1.0-d);											\n"
		"		}															\n"
		"	}																\n"
		"	color2 /= w;													\n"
		"   gl_FragColor = color2; 											\n"
		"}"
	);
	return shader;
};

static smoothCubeMap = fn(Rendering.Texture sourceMap,Rendering.Texture targetMap){
	var shader = getCubeSmoothShader();
	shader.setUniform(renderingContext, new Rendering.Uniform('t_envMapInput',Rendering.Uniform.INT, [0]));

	renderingContext.pushAndSetTexture(0,sourceMap);
	for(var layer=0;layer<6;++layer){
		shader.setUniform(renderingContext, new Rendering.Uniform('layer',Rendering.Uniform.INT, [layer]));
		(new (Std.module('LibRenderingExt/TextureProcessor')))
			.setOutputTexture(targetMap,0,layer)
			.setShader(shader)
			.execute();
	}
	renderingContext.popTexture(0);
};

Rendering.createSmoothedCubeMap := fn(Rendering.Texture sourceMap, Number iterations = 10){
	var t_input = sourceMap;
	var t_output = Rendering.createHDRCubeTexture(sourceMap.getWidth(), true);
	smoothCubeMap(t_input,t_output);

	if(iterations>1){
		t_input = Rendering.createHDRCubeTexture(sourceMap.getWidth(), true);
		for(var i=1; i<iterations; ++i){
			var t = t_input;
			t_input = t_output;
			t_output = t;
			smoothCubeMap(t_input,t_output);
		}
	}
	return t_output;
};



// --------------------------------------

Rendering.RenderingContext.bindBuffer ::= fn(buffer, target, location=-1){
	if(buffer ---|> Rendering.Mesh)
		return buffer.bindVertexBuffer(this, target, location);
	if(location >= 0)
		buffer._bind(target, location);
	else
		buffer._bind(target);
	return this;
};

static dummyBuffer = new Rendering.BufferObject;
Rendering.RenderingContext.unbindBuffer ::= fn(target, location=-1){
	if(location >= 0)
		dummyBuffer._unbind(target, location);
	else
		dummyBuffer._unbind(target);
	return this;
};

Rendering.Mesh.bindVertexBuffer ::= fn(rc, target, location=-1) {
	this._swapVertexBuffer(dummyBuffer);
	rc.bindBuffer(dummyBuffer, target, location);
	this._swapVertexBuffer(dummyBuffer);
	return this;
};

Rendering.Mesh.bindIndexBuffer ::= fn(rc, target, location=-1) {
	this._swapIndexBuffer(dummyBuffer);
	rc.bindBuffer(dummyBuffer, target, location);
	this._swapIndexBuffer(dummyBuffer);
	return this;
};

Rendering.Mesh.allocateGLData ::= fn() {
	var tmpBuffer = new Rendering.BufferObject;
	this._swapVertexBuffer(tmpBuffer);
	var valid = tmpBuffer.isValid();
	this._swapVertexBuffer(tmpBuffer);	
	if(!valid) {
		tmpBuffer.allocate(getVertexCount() * getVertexDescription().getVertexSize());
		tmpBuffer.clear();
		this._swapVertexBuffer(tmpBuffer);
	}
	return this;
};

Rendering.Mesh.clear ::= fn(param...) {
	this._swapVertexBuffer(dummyBuffer);
	dummyBuffer.clear(param...);
	this._swapVertexBuffer(dummyBuffer);
	return this;
};

Rendering.BufferObject.allocate ::= fn(size, hint=Rendering.USAGE_DYNAMIC_DRAW) {
	return this.allocateData(Rendering.TARGET_COPY_WRITE_BUFFER, size, hint);
};

Rendering.BufferObject.upload ::= fn(data, offset=0, type=void) {
	return this.uploadSubData(Rendering.TARGET_COPY_WRITE_BUFFER, data, offset, type);
};

Rendering.BufferObject.download ::= fn(count, type, offset=0) {
	var data = this.downloadData(Rendering.TARGET_COPY_READ_BUFFER, offset+count, type);
	if(offset>0)
		data = data.slice(offset, count);
	return data;
};

Rendering.BufferObject._clear ::= Rendering.BufferObject.clear;
Rendering.BufferObject.clear ::= fn(param...) {
	return this._clear(Rendering.TARGET_COPY_WRITE_BUFFER, param...);
};

// --------------------------------------

return Rendering;
