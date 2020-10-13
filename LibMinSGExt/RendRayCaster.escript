/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2018 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] LibMinSGExt/RendRayCaster.escript
 **/

/*! A Class for ray casting based on rendering.
	Internally a thin orthographic camera is used to render
	the scene in order to identify intersections.
	This is very flexible, works with any type of geometry and does not use any
	external libraries, but it may be quite slow!
	(Cl: Szene1.minsg on my computer takes about 0.3 - 0.6ms per query)
	*/
MinSG.RendRayCaster := new Type(ExtObject);

var T = MinSG.RendRayCaster;

T.castCam @(private) := void;
T.resolution @(private) := void;
T.fbo @(private) := void;
T.shader @(private) := void;
T.renderingLayers @(public,init) := Std.module('Std/DataWrapper');

T._constructor ::= fn(Number _resolution=10){
	this.renderingLayers( 1 );
	this.resolution = _resolution;
	this.castCam = new MinSG.CameraNodeOrtho;
	this.castCam.setViewport( new Geometry.Rect(0,0,resolution,resolution));
	this.castCam.setFrustumFromScaledViewport(0.001);
	
	this.shader = Rendering.Shader.createPassThroughShader();	

	// create FBO
	this.fbo = new Rendering.FBO;
	var depthBuffer = Rendering.createDepthTexture(_resolution,_resolution);
	this.fbo.attachDepthTexture(renderingContext,depthBuffer);
	Rendering.checkGLError();
};

/*! (internal) */
T.setup @(private) ::= fn(Geometry.Vec3 source,Geometry.Vec3 target){
	this.castCam.setNearFar(0,(target-source).length());
	this.castCam.setRelPosition(source);
	this.castCam.rotateToWorldDir(source-target); // looking in -z
};

/*! Returns the first node (or void) intersecting the line from source to target.
	\note if restrictSearchingDistance is true, the depth component is read and the query is restricted up to that distance.
			This introduces an additional overhead, but may be significantly faster for huge scenes.
*/
T.queryNode ::= fn(MinSG.FrameContext fc,MinSG.Node rootNode,Geometry.Vec3 source,Geometry.Vec3 target, Bool restrictSearchingDistance=false ){
	Rendering.checkGLError();
	this.setup(source,target);
	var rc = fc.getRenderingContext();
		
	fc.pushAndSetCamera(castCam);
	rc.pushAndSetShader(shader);
	rc.pushAndSetFBO(fbo);

	var maxDistance = false;
	/* 
	// this is not necessary
	// maybe if we sample the depth of the current frame buffer without redrawing the entire scene
	if(restrictSearchingDistance){
		rc.clearScreen(new Util.Color4f(0,0,0,1));

		var params = (new MinSG.RenderParam)
					.setFlags(MinSG.USE_WORLD_MATRIX|MinSG.FRUSTUM_CULLING) //|MinSG.NO_STATES);
					.setRenderingLayers( this.renderingLayers() );
					
		rootNode.display(fc, params );
		// read depth
		var screenCenter=resolution*0.5;
		var screenSpaceDepth=Rendering.readDepthValue(screenCenter,screenCenter);
		// map to world coordinates
		var worldIntersection = fc.convertScreenPosToWorldPos(new Geometry.Vec3(screenCenter,screenCenter,screenSpaceDepth));
		maxDistance = (worldIntersection-source).length()*1.01;
		//out(maxDistance,"\n");
	}*/
	
 	var nodes = MinSG.collectVisibleNodes(rootNode, fc, maxDistance, true, this.renderingLayers());
	rc.popFBO();
	rc.popShader();
	fc.popCamera();
	Rendering.checkGLError();
	return nodes[0];
};

/*! Returns the first node (or void) intersecting a line from the camera through the given pixel.
	\note if restrictSearchingDistance is true, the depth component is read and the query is restricted up to that distance.
			This introduces an additional overhead, but may be significantly faster for huge scenes. */
T.queryNodeFromScreen ::= fn(MinSG.FrameContext fc,MinSG.Node rootNode,Geometry.Vec2 screenPos,Bool restrictSearchingDistance=false){
	var cam=fc.getCamera();
	var source=cam.getWorldOrigin();
	var bounds = rootNode.getWorldBB();
	var dist = [cam.getFarPlane(), bounds.getDistance(cam.getWorldOrigin()) + ( bounds.getExtentMax() * 1.415 /* sqrt(2) */ ) ].min();
	var destination=source + (fc.convertScreenPosToWorldPos(new Geometry.Vec3(screenPos.getX(),screenPos.getY(),0))-source).normalize()*dist;
	return this.queryNode(fc,rootNode,source,destination,restrictSearchingDistance);
};

/*! Returns the coordinate (or false) of the first intersection of the line from source to target. */
T.queryIntersection ::= fn(MinSG.FrameContext fc,[MinSG.Node,Array] rootNodes,Geometry.Vec3 source,Geometry.Vec3 target){
		Rendering.checkGLError();
	if(! (rootNodes---|>Array))
		rootNodes = [rootNodes];
	if(rootNodes.empty())
		return;
	var rc = fc.getRenderingContext();

	this.setup(source,target);
	rc.pushAndSetFBO(fbo);
	rc.pushAndSetShader(shader);

	// render scene
	fc.pushAndSetCamera(castCam);
	rc.clearScreen(new Util.Color4f(0,0,0,1));
	
	var params = (new MinSG.RenderParam)
					.setFlags(MinSG.USE_WORLD_MATRIX|MinSG.FRUSTUM_CULLING) //|MinSG.NO_STATES);
					.setRenderingLayers( this.renderingLayers() );
	foreach(rootNodes as var node)
		node.display(fc,params);
	// read depth
	var screenCenter=resolution*0.5;
	var depth=Rendering.readDepthValue(screenCenter,screenCenter);

	var result = false;
	if(depth<1){
		// map to world coordinates
		result = fc.convertScreenPosToWorldPos(new Geometry.Vec3(screenCenter,screenCenter,depth));
	}
	fc.popCamera();
	rc.popShader();
	rc.popFBO();
	Rendering.checkGLError();
	return result;
};

/*! Returns the coordinate (or false) of the first intersection of the line from the camera through the given pixel. */
T.queryIntersectionFromScreen ::= fn(MinSG.FrameContext fc,MinSG.Node rootNode,Geometry.Vec2 screenPos){
		Rendering.checkGLError();
	var cam=fc.getCamera();
	var source=cam.getWorldOrigin();
	var destination=source + (fc.convertScreenPosToWorldPos(new Geometry.Vec3(screenPos.getX(),screenPos.getY(),0))-source).normalize()*cam.getFarPlane();
		Rendering.checkGLError();
	return queryIntersection(fc,rootNode,source,destination);
};

return T;

