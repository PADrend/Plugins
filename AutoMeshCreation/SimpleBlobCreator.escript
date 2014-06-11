/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static  TextureProcessor = Std.require('LibRenderingExt/TextureProcessor');

 var vs = "	void main( void ){  gl_TexCoord[0] = gl_MultiTexCoord0;  gl_Position = ftransform(); } ";
 
 var smooth_fs = 
	"#version 130\n"
	"uniform int resolution = 64; \n"
	"uniform int radius = 2; \n"
	"uniform sampler2D T_density; \n"
	"vec4 getValue(in ivec3 pos){\n"
	"  if(pos.x<0 || pos.x>=resolution ||pos.y<0 ||pos.y>=resolution||pos.z<0||pos.z>=resolution)\n"
	"	 return vec4(0.0);\n"
	"  return vec4(texelFetch(T_density,ivec2(pos.x+pos.z*resolution,pos.y),0).rgb,1.0);\n"
	"}\n"
	"\n"
	"void main(){\n"
	"	ivec3 pos = ivec3(mod(gl_FragCoord.x,resolution), int(gl_FragCoord.y),int(gl_FragCoord.x)/resolution);\n"
	"	float sum = 0.0;\n"
	"	vec4 accum;\n"
	"	ivec3 cursor;\n"
	"   for(cursor.x=-radius; cursor.x<=radius; ++cursor.x){\n"
	"   for(cursor.y=-radius; cursor.y<=radius; ++cursor.y){\n"
	"   for(cursor.z=-radius; cursor.z<=radius; ++cursor.z){\n"
	"		vec4 c = getValue( pos+cursor );"	
	"		float weight = pow( c.w / (1.0+length(vec3(cursor))) , 10.0); "
	"		accum += c * weight;"
	"		sum += weight;"
	"	}}}\n"
	"	gl_FragColor = accum / sum;\n"
	"}\n"
;
var invert_fs = 
	"#version 130\n"
	"uniform sampler2D T_density; \n"
	"uniform float densityOffset = 0.0; \n"
	"\n"
	"\n"
	"\n"
	"void main(){\n"
	"	vec4 c = texelFetch(T_density,ivec2(gl_FragCoord.xy),0);"
	"   float f = c.r; "
	"   f = (1.0-clamp(f,0.0,1.0)); "
	"	gl_FragColor = vec4(f+ densityOffset, f-densityOffset*2.0   ,0,0);\n"
	"}\n"
;
 var ambOcc_fs = 
	"#version 130\n"
	"uniform int radius = 5; \n"
	"uniform int resolution = 64; \n"
	"uniform sampler2D T_density; \n"
	"float getDensity(in ivec3 pos){\n"
	"  if(pos.x<0 || pos.x>=resolution ||pos.y<0 ||pos.y>=resolution||pos.z<0||pos.z>=resolution)\n"
	"	 return 1.0;\n"
	"  return clamp(texelFetch(T_density,ivec2(pos.x+pos.z*resolution,pos.y),0).r,0.0,1.0);\n"
	"}\n"
	"\n"
	"void main(){\n"
	"	float density = texelFetch(T_density,ivec2(gl_FragCoord.xy),0).r;"
	"	ivec3 pos = ivec3(mod(gl_FragCoord.x,resolution), int(gl_FragCoord.y),int(gl_FragCoord.x)/resolution);\n"
	"	float sum = 0.0;\n"
	"	float occlusion;\n"
	"	ivec3 cursor;\n"
	"   for(cursor.x=-radius; cursor.x<=radius; ++cursor.x){\n"
	"   for(cursor.y=-radius; cursor.y<=radius; ++cursor.y){\n"
	"   for(cursor.z=-radius; cursor.z<=radius; ++cursor.z){\n"
	"		float c = getDensity( pos+cursor );"	
//	"		float weight = pow( c.w / (1.0+length(vec3(cursor))) , 10.0); "
	"		float weight = 1.0; "
	"		occlusion += c * weight;"
	"		sum += weight;"
	"	}}}\n"
	"   occlusion /= sum;"
//	"	float f = occlusion*0.5;"
	"	float f = pow( occlusion ,2.0);"
	"	f = clamp(f,0.0,0.99);"
//	"	gl_FragColor = vec4(density,pow(0.5+occlusion/sum,2.0),0.0,0.0);\n"
	"	gl_FragColor = vec4(density,f,0.0,0.0);\n"
	"}\n"
;
static smoothShader = Rendering.Shader.createShader( vs,smooth_fs );
static invertShader = Rendering.Shader.createShader( vs,invert_fs );


static shaders = [];
shaders += smoothShader;
shaders += smoothShader;
shaders += smoothShader;
shaders += invertShader;
shaders += Rendering.Shader.createShader( vs,ambOcc_fs );;


var T = new Type;

T.points @(init) := Array; // [ [vec3,value] ]

T._printableName @(override) ::= $SimpleBlobCreator;

T.addPoint ::= fn(worldPos...,Number value){
	var pos = new Geometry.Vec3(worldPos...);
	this.points += [pos,value];
};

T.createGeometryNode ::= fn(Number resolution=64, Number densityOffset = 0.0){
	
	// calculate bb
	var bb = new Geometry.Box;
	var boxOffset;
	var scaling;
	{
		bb.invalidate();
		foreach( this.points as var point)
			bb.include(point[0]);
		var halfCubeLength = (bb.getExtentMax()*0.8).ceil();
		var center = bb.getCenter();
		bb.include( center-[halfCubeLength,halfCubeLength,halfCubeLength] );
		bb.include( center+[halfCubeLength,halfCubeLength,halfCubeLength] );
		boxOffset = new Geometry.Vec3( bb.getMinX(),bb.getMinY(),bb.getMinZ());
		scaling = bb.getExtentMax() / resolution;
	}

	// write points to density texture
	var densityTexture = Rendering.createHDRTexture( resolution*resolution,resolution,true);
	{
		
		var worldPosToTexturePos = [boxOffset,bb.getExtentMax(),resolution] => fn(offset,length,resolution, worldPos...){
			var localPos = (new Geometry.Vec3(worldPos...)-offset) * resolution / length;
			return [localPos.x()+localPos.z().floor()*resolution,localPos.y() ];
		};
		densityTexture.allocateLocalData();
		var pixels =  Rendering.createColorPixelAccessor(renderingContext, densityTexture);

		foreach(this.points as var point){
			var value = point[1];
			pixels.writeColor( worldPosToTexturePos( point[0] )..., new Util.Color4f(value,value,value,1) );
		}
		densityTexture.dataChanged();
	}
//	Rendering.showDebugTexture(densityTexture);
//	Rendering.showDebugTexture(densityTexture);
//	Rendering.showDebugTexture(densityTexture);

	 //smooth and invert density texture
	var t2 = Rendering.createHDRTexture( resolution*resolution,resolution,true);
	foreach(shaders as var shader)
	{
		var densityTexture2 = densityTexture;
		densityTexture = t2;
		shader.setUniform(renderingContext, new Rendering.Uniform('T_density', Rendering.Uniform.INT, [0]),false);
		shader.setUniform(renderingContext, new Rendering.Uniform('resolution', Rendering.Uniform.INT, [ resolution ]),false);
		shader.setUniform(renderingContext, new Rendering.Uniform('densityOffset', Rendering.Uniform.FLOAT, [densityOffset ]),false);

		(new TextureProcessor)
					.setInputTextures([densityTexture2])
					.setOutputTextures([densityTexture])
		//	//		.setOutputDepthTexture( myDepthTexture )
					.setShader(shader)
					.execute();

//		Rendering.showDebugTexture(densityTexture);
	}
		
	// create mesh
	var mesh;
	{
		densityTexture.download(renderingContext);

		var pixels =  Rendering.createColorPixelAccessor(renderingContext, densityTexture);

		mesh = Rendering.createMeshByMarchingCubesFromTiledImage(pixels,resolution,resolution,resolution);
		if(!mesh)
			return;
		// remove duplicate vertices
		Rendering.eliminateDuplicateVertices(mesh);
		// normals
		Rendering.calculateNormals(mesh);
	}
	
	// create node
	var node = new MinSG.GeometryNode( mesh );
	node.moveLocal( boxOffset );
	node.scale(scaling);
	return node;
};
//
//var t= new T;
//
//for(var i=0;i<640;++i){
//	t.addPoint( i*0.01,i*0.01,i*0.01, 1);
//}
//for(var i=0;i<640;++i){
//	t.addPoint( i*0.01+10,i*0.01,i*0.01, i*2);
//}
//for(var i=0;i<640;++i){
//	t.addPoint( i*0.01+20,i*0.01,i*0.01, i*10);
//}
//for(var i=0;i<640;++i){
//	t.addPoint( i*0.01+15,i*0.01,i*0.01, i*i);
//}
////
//var node = t.createGeometryNode();
//if(node)
//	PADrend.getCurrentScene() += node;

return T;

