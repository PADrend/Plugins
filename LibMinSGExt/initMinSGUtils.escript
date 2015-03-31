/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Lukas Kopecki
 * Copyright (C) 2012 Mouns R. Husan Almarrani
 * Copyright (C) 2010-2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[MinSG] Util/MinSG_Utils.escript
 **
 **  MinSG helper functions
 **/

/*!	Registers the handler for creating a ScriptedState from a description.
	To register an importer for a custom type, add it to the 'LibMinSGExt/ScriptedStateImportersRegistry':
		state's printableName  -> fn(description){} -> return state
*/
MinSG.setScriptedStateImporter( fn(parentNode,Map description){
	try{
		var handler = Std.module('LibMinSGExt/ScriptedStateImportersRegistry')[ description['sStateType'] ];
		if(handler){
			var state = handler(description);
			if(state){
				parentNode += state;
				return true;
			}
		}
	}catch(e){ // catch all exceptions here -> the handler is called externally and the execution is fragile
		outln(e);
	}
	return false;
//	print_r(description);
//	// dispatch according to description['sStateType'
});

/*!  Registers the handler for describing scripted states.
	To be able to export scripted states, they require a proper printableName.
	(optionally) You can add custom exporters in the 'LibMinSGExt/ScriptedStateExportersRegistry'.
		state's printableName -> fn(State, Map description)
	\note Attention: only add valid data (no void!) to the description map -- the program may crash otherwise!
*/
MinSG.setScriptedStateExporter( fn(state,description){
	try{
		var typeName = state._printableName;
		description['sStateType'] = ""+typeName;
		var handler = Std.module('LibMinSGExt/ScriptedStateExportersRegistry')[ typeName ];
		if(handler)
			handler(state,description);

		print_r(description);
	}catch(e){  // catch all exceptions here -> the handler is called externally and the execution is fragile
		outln(e);
	}

});

// -------------------------------------------------------------------------
// node visitors

/*! Applies the transformations of all geomtryNodes to their meshes. Instantiated meshes are duplicated.
	\note uses makeTransformationsLocal_allLeafs	*/
MinSG.bakeTransformations := fn(MinSG.Node root, Geometry.Matrix4x4 worldMatrix=new Geometry.Matrix4x4()){
	Util.info("bakeTransformations...\n");
	moveTransformationsIntoLeaves(root);

	var geometryNodes=MinSG.collectGeoNodes(root);
	var i=0;
	foreach(geometryNodes as var gNode){
		Util.info("\rApplying transformation ",++i,"/",geometryNodes.count(),"    ");
		if(!gNode.hasTransformation())
			continue;
		var matrix=gNode.getRelTransformationMatrix();
		var mesh=gNode.getMesh();
		if(!mesh)
			continue;
		var newMesh=mesh.clone();
		Rendering.transformMesh(newMesh,matrix);
		gNode.setMesh(newMesh);
		gNode.resetRelTransformation();
	}
	Util.info("\n");
};

/*!	Remove empty GroupNodes; replace GroupNodes with a single child by that child.*/
MinSG.cleanupTree := fn(MinSG.Node root, [MinSG.SceneManagement.SceneManager,void] sceneManager=void){
	Util.info( "cleanupTree...\n");
	var counter=0;

	var nodes=[root];
	while(!nodes.empty()){
		var node=nodes.popBack();

		var children=MinSG.getChildNodes(node);

		if(children.count() == 0){ // is leaf node
			if(node.isA(MinSG.GroupNode)){ // remove empty leaf node
				MinSG.destroy(node);
			}
		}else if (children.count() == 1){ // only single child
			var child=children[0];
			var states=node.getStates();
			foreach(states as var state){
				child.addState(state);
			}
			// apply transformation
			var m = node.getRelTransformationMatrix() * child.getRelTransformationMatrix();
			if(m.convertsSafelyToSRT())
				child.setRelTransformation( m.toSRT() );
			else
				child.setRelTransformation(m);

			if(sceneManager){
				var id=sceneManager.getNameOfRegisteredNode(node);
				if(id)
					sceneManager.registerNode(id,child);
			}

			node.getParent().addChild(child);
			MinSG.destroy(node);
			nodes+=child;
		}else {
			nodes.append(children);
		}
		Util.info("\r",++counter," ");
	}
	Util.info("\ndone.\n");
};

MinSG.closeNodesHavingStates := fn(MinSG.Node node){
	var nodes=[node];
	while(!nodes.empty()){
		var n=nodes.popBack();
		if(n.hasStates())
			n.setClosed(true);
		nodes.append(MinSG.getChildNodes(n));
	}
};

MinSG.collectLeafNodes := fn(MinSG.Node root){
	var nodes = [root];
	var leafs = [];
	while(!nodes.empty()){
		var node = nodes.popBack();
		var children = MinSG.getChildNodes(node);
		if(children.empty())
			leafs+=node;
		else
			nodes.append(children);
	}
	return leafs;
};

MinSG.collectNodesWithState := fn(MinSG.Node root,MinSG.State state){
	var nodes = [root];
	var results = [];
	while(!nodes.empty()){
		var node = nodes.popBack();
		if(node.getStates().contains(state))
			results += node;
		nodes.append(MinSG.getChildNodes(node));
	}
	return results;
};

/**
 * Traverse a MinSG tree beginning at the given root node and collect
 * statistics (e.g. number of inner nodes). The statistics are returned as a
 * map. The keys are strings describing the statistics (e.g. "Nodes"). The
 * values are numbers or arrays (e.g. "NodesInLevels").
 */
MinSG.collectTreeStatistics := fn(MinSG.Node root) {
	var statistics = {
		"Nodes"				: 0,
		"GroupNodes"		: 0,
		"GeometryNodes"		: 0,
		"Triangles"			: 0,
		"Vertices"			: 0,
		"States"			: 0
	};
	foreach(MinSG.collectNodes(root) as var node) {
		++statistics["Nodes"];
		if(node.isA(MinSG.GeometryNode)) {
			++statistics["GeometryNodes"];
			statistics["Triangles"] += node.getTriangleCount();
			statistics["Vertices"] += node.getVertexCount();
		}
		if(node.isA(MinSG.GroupNode)) {
			++statistics["GroupNodes"];
		}
		if(node.hasStates()) {
			statistics["States"] += node.getStates().count();
		}
	}
	if(root ---|> MinSG.GroupNode) {
		statistics["NodesInLevels"] = MinSG.countNodesInLevels(root);
	}
	return statistics;
};

MinSG.combineLeafs:=fn(MinSG.Node root,minNumber=2){
	var nodes=[root];
	var counter=0;
	while(!nodes.empty()){
		Util.info("\r",counter++," ");
		var node=nodes.popBack();
		var geoNodes=[];
		var children=MinSG.getChildNodes(node);
		foreach(children as var child){
			if(child---|>MinSG.GeometryNode)
				geoNodes+=child;
			else
				nodes+=child;
		}
		if(geoNodes.count()<minNumber) continue;


		MinSG.bakeTransformations( node );

		var combineGroups=new Map();
		var i=0;
		foreach(geoNodes as var gNode){
			var mesh=gNode.getMesh();

			if(!mesh)
				continue;

			var s=mesh.getVertexDescription().toString();
			foreach(gNode.getStates() as var state){
				s+=":  "+state.toString();
			}
//            out(s,"\n");
			if(!combineGroups[s]){
				var g=new ExtObject();
				g.node:=void;
				g.meshes:=[];
				combineGroups[s]=g;
			}
			var g=combineGroups[s];
			g.meshes+=mesh;

			if(g.node)
				MinSG.destroy(gNode);
			else
				g.node=gNode;
		}
		foreach(combineGroups as var g){

			var newMesh=Rendering.combineMeshes(g.meshes);
			g.node.setMesh(newMesh);
//            g.node.createVBOFromMesh();
			g.node.resetRelTransformation();
		}
	}
	Util.info("\ndone.\n");
};

MinSG.getCombinedWorldBB := fn(Array nodes){
	var bb = void; 
	foreach(nodes as var node){
		if(!bb){
			bb = node.getWorldBB();
		}else{
			bb.include(node.getWorldBB());
		}
	}
	return bb;
};

//! Returns the root node of the smallest common subtree of @p node1 and @p node2 or void.
MinSG.getRootOfCommonSubtree := fn(MinSG.Node node1, MinSG.Node node2){
	var path1 = new Set;
	for(var n = node1; n ; n=n.getParent())
		path1 += n;
	for(var n = node2; n ; n=n.getParent())
		if(path1.contains(n))
			return n;
	return void;
};
			
//! returns whether node is located somewhere in the tree starting from subtreeRoot
MinSG.isInSubtree := fn(MinSG.Node node, MinSG.Node subtreeRoot){
	for( ; node; node = node.getParent() ){
		if(node==subtreeRoot)
			return true;
	}
	return false;
};

//!
MinSG.materialToVertexColor:=fn(MinSG.Node node, oldState = void) {
	var state = oldState;
	foreach(node.getStates() as var s) {
		if(s ---|> MinSG.MaterialState) {
			state = s;
			node.removeState(s);
		}
	}

	if(node.isA(MinSG.GroupNode)) {
		foreach(MinSG.getChildNodes(node) as var child) {
			thisFn(child, state);
		}
	} else if(state && node.isA(MinSG.GeometryNode)) {
		Rendering.setMaterial(node.getMesh(), state.getAmbient(), state.getDiffuse(), state.getSpecular(), state.getShininess());
	}
};

MinSG.openAllInnerNodes := fn(MinSG.Node node){
	var nodes=[node];
	while(!nodes.empty()){
		var n=nodes.popBack();
		var children=MinSG.getChildNodes(n);
		if(children.count() != 0){
			n.setClosed(false);
			nodes.append(children);
		}
	}
};

//! removes duplicate vertices and optimizes indices for vertex cache locality
MinSG.optimizeMeshes := fn(rootNode, cacheSize = 24){
	var nodes = MinSG.collectGeoNodes(rootNode);
	var set = new Set;
	foreach(nodes as var node){
		if(node.hasMesh())
			set += node.getMesh();
	}
	foreach(set as var mesh){
		Rendering.eliminateDuplicateVertices(mesh);
		Rendering.optimizeIndices(mesh, cacheSize);
	}
};

//!returns number of removed states
MinSG.pullUpStates := fn(MinSG.Node subtree){
	var removedStateCount=0;

	var children=MinSG.getChildNodes(subtree);
	if(children.empty() )
		return removedStateCount;

	foreach(children as var child){
		removedStateCount+=thisFn(child);
	}
	var states=children[0].getStates();
	var stateCount=states.count();
	if(stateCount==0)
		return removedStateCount;

	foreach(children as child){
		var childStates=child.getStates();
		if(childStates.count()!=stateCount)
			return removedStateCount;
		for(var i=0;i<stateCount;++i){
			if(states[i]!=childStates[i])
				return removedStateCount;
		}
	}

	foreach(states as var s){
		subtree.addState(s);
	}
	foreach(children as var child){
		out(".");
		child.removeStates();
	}
	removedStateCount+=(children.count()-1)*stateCount;
	return removedStateCount;
};

MinSG.removeAllStates := fn(MinSG.Node node){
	var nodes=[node];
	while(!nodes.empty()){
		var n=nodes.popBack();
		n.removeStates();
		nodes.append(MinSG.getChildNodes(n));
	}
};

/*! Adds all leafs (and closed nodes) as direct children of the given @p root node.
	All inner (non closed) nodes are removed and their states are lost.
	\note calls moveTransformationsIntoClosedNodes
	\note calls moveStatesIntoClosedNodes
	\note if you want to keep the states in the inner nodes, call
			closeNodesHavingStates in advance. */
MinSG.removeOpenNodes := fn(MinSG.GroupNode root){
	Util.info( "removeOpenNodes...\n");
	var counter=0;

	moveTransformationsIntoClosedNodes(root);
	moveStatesIntoClosedNodes(root);

	var wasteContainer=new MinSG.ListNode;
	var nodes=MinSG.getChildNodes(root);
	while(!nodes.empty()){
		var n=nodes.popBack();
		if(n.isClosed()){
			root.addChild(n);
		}else{
			nodes.append(MinSG.getChildNodes(n));
			wasteContainer.addChild(n);
			Util.info("\r",++counter," ");
		}
	}
	MinSG.destroy(wasteContainer);
	Util.info("\ndone.\n");
};

/*! (static) Render the given sceneGraph with the given camera and flags.
	\note If the clearColor is false, the rendering buffer is not cleared before rendering */
MinSG.renderScene := fn( MinSG.FrameContext fc,
							MinSG.Node _rootNode, [MinSG.AbstractCameraNode,void] _camera, 
							Number _renderingFlags = MinSG.FRUSTUM_CULLING | MinSG.USE_WORLD_MATRIX, 
							[Util.Color4f,false] _clearColor = new Util.Color4f(0,0,0,0), 
							Number renderingLayers = 1 ){
	var iMode = renderingContext.getImmediateMode();
	renderingContext.setImmediateMode(false);
	// force a reset of the opengl state 
	renderingContext.applyChanges(true);
	// \note The camera has to be enabled before the screen is cleared because it also defines the viewport to clear
	fc.pushCamera();
	if(_camera)
		fc.setCamera(_camera);
	if(_clearColor) 
		renderingContext.clearScreen(_clearColor);
	fc.displayNode(_rootNode, (new MinSG.RenderParam)
												.setFlags(_renderingFlags)
												.setRenderingLayers(renderingLayers));
	fc.popCamera();
	renderingContext.setImmediateMode(iMode);
	renderingContext.applyChanges(true);
};

//! replaces colors and normals in meshes with smaller datatypes (bytes)
MinSG.shrinkMeshes := fn(rootNode){
	var nodes = MinSG.collectGeoNodes(rootNode);
	var set = new Set;
	foreach(nodes as var node){
		if(node.hasMesh())
			set += node.getMesh();
	}
	foreach(set as var m){
		Rendering.shrinkMesh(m);
	}
};


/*! \note this function is NOT bullet proof. Use with care! */
MinSG.updatePrototype := fn(MinSG.Node node, MinSG.Node newPrototype){

	if(!node.isInstance()){
		Runtime.warn("MinSG.updatePrototype: "+node+" was no instance node.");
	}

	var newInstance = MinSG.Node.createInstance(newPrototype);
	
	if(newInstance.getType() == node.getType()){
		
		// attributes and position stay the same...
		
		// set new states
		node.removeStates();
		foreach(newInstance.getStates() as var s)
			node += s;
		
		// move child nodes
		foreach(MinSG.getChildNodes(node) as var c)
			MinSG.destroy(c);
		foreach(MinSG.getChildNodes(newInstance) as var c)
			node += c;

		if(node.isA(MinSG.GeometryNode))
			node.setMesh(newInstance.getMesh());

		node._setPrototype(newPrototype);
		MinSG.destroy(newInstance);
		return node;
	}else{
		Runtime.warn("MinSG.updatePrototype: Node type changed :"+node+"--->"+newInstance+" Possible information loss.");

		node.getParent().addChild(newInstance);
		newInstance.setRelTransformation(node.getRelTransformationSRT());
		MinSG.destroy(node);
		return newInstance;
	}
};


// ---------------------------
// ShaderState extension

MinSG.ShaderState._setUniform ::= MinSG.ShaderState.setUniform;

/*! Passes all parameters to the uniform's constructor. 
	Allows:
		shaderState.setUniform('m1',Rendering.Uniform.FLOAT,[m1]);
	instead of:
		shaderState.setUniform(new Rendering.Uniform('m1',Rendering.Uniform.FLOAT,[m1]) );	*/
MinSG.ShaderState.setUniform ::= fn(params...){
	return this._setUniform(new Rendering.Uniform(params...));
};


static ExtSceneManager = Std.module('LibMinSGExt/SceneManagerExt');
MinSG.ShaderState.recreateShader ::= fn(ExtSceneManager sm){
	var shaderState = this;
	var vs = [];
	var fs = [];
	var gs = [];
	var shaderName = shaderState.getStateAttribute(MinSG.ShaderState.STATE_ATTR_SHADER_NAME);
	if(shaderName&&!shaderName.empty()){
		var shaderFile = sm.locateFile( shaderName );
		if(!shaderFile){
			Runtime.warn("Unknown shader:"+shaderName);
			return;
		}
		var m = parseJSON( Util.loadFile(shaderFile) );
		if(m['shader/glsl_fs'])
			fs = m['shader/glsl_fs'];
		if(m['shader/glsl_gs'])
			gs = m['shader/glsl_gs'];
		if(m['shader/glsl_vs'])
			vs = m['shader/glsl_vs'];
		
		print_r(m); 
	}else{
		var fileInfo = shaderState.getStateAttribute(MinSG.ShaderState.STATE_ATTR_SHADER_FILES);
		var cleanedPrograms = new Map();

		foreach(fileInfo as var progInfo){
			var file = progInfo['file'].trim();
			var type = progInfo['type'].trim().toLower();
			if(file.empty()){
				continue;
			}else if(type=='shader/glsl_vs'){
				vs+=file;
			}else if(type=='shader/glsl_fs'){
				fs+=file;
			}else if(type=='shader/glsl_gs'){
				gs+=file;
			}
			cleanedPrograms[type+"|"+file] = {'type':type,'file':file};
		}
		var sortedPrograms=[];
		foreach(cleanedPrograms as var prog) 
			sortedPrograms+=prog;
		shaderState.setStateAttribute(MinSG.ShaderState.STATE_ATTR_SHADER_FILES,sortedPrograms);
	}
	MinSG.initShaderState(shaderState,vs,gs,fs, Rendering.Shader.USE_UNIFORMS|Rendering.Shader.USE_GL,   sm.getFileLocator());
};

// ---------------------------
// ShaderUniformState extension

MinSG.ShaderUniformState._setUniform ::= MinSG.ShaderUniformState.setUniform;

/*! Passes all parameters to the uniform's constructor. 
	Allows:
		shaderUniformState.setUniform('m1',Rendering.Uniform.FLOAT,[m1]);
	instead of:
		shaderUniformState.setUniform(new Rendering.Uniform('m1',Rendering.Uniform.FLOAT,[m1]) );	*/
MinSG.ShaderUniformState.setUniform ::= fn(params...){
	return this._setUniform(new Rendering.Uniform(params...));
};

// -------------------------------------------------------
// misc tools

/**
 * Returns the minimum distance from the given node in the given direction to the current scene.
 * @param res the resolution for the depth-textures (1024 if unspecified)
 * @param zFar the distance of the far plane of the camera (if ommited, it is set to the diameter of the BB of the rootNode)
 * @param debugMode if true, the colorBuffers of the cameras are drawn and debug info is printed to the console (false if unspecified)
 */
MinSG.calcNodeToSceneDistance := fn(MinSG.FrameContext fc, MinSG.Node rootNode, MinSG.Node node, Geometry.Vec3 dir, Number res = 1024, Number zFar = 0, debugMode = false) {
	dir.normalize();

	var zNear = 0.001;
	if(zFar == 0) {
		zFar = rootNode.getWorldBB().getDiameter();
	}

	// setup fbo and buffers
	var fbo = new Rendering.FBO();
	var colorBuffer1 = Rendering.createStdTexture(res, res, true);
	var colorBuffer2 = Rendering.createStdTexture(res, res, true);
	var depthBuffer1 = Rendering.createDepthTexture(res, res);
	var depthBuffer2 = Rendering.createDepthTexture(res, res);

	var backupCam = frameContext.getCamera();


	// setup cameara
	var cam = new MinSG.CameraNodeOrtho();
	var nodeWorldPos = node.getWorldBB().getCenter();
	cam.setViewport(new Geometry.Rect(0, 0, res, res));
	cam.setFrustumFromScaledViewport(node.getWorldBB().getDiameter() / res);
	cam.setNearFar(zNear, zFar);

	renderingContext.pushAndSetFBO(fbo);
	renderingContext.pushAndSetCullFace(new Rendering.CullFaceParameters());

	// render from object to scene
	fbo.attachColorTexture(renderingContext,colorBuffer1);
	fbo.attachDepthTexture(renderingContext,depthBuffer1);
	cam.setWorldOrigin(nodeWorldPos - dir * 0.5 * node.getWorldBB().getDiameter());
	cam.rotateToWorldDir(-dir);
	fc.setCamera(cam);
	renderingContext.clearScreen(PADrend.getBGColor());
	node.deactivate();
	rootNode.display(fc, MinSG.USE_WORLD_MATRIX|MinSG.FRUSTUM_CULLING|MinSG.NO_STATES);
	node.activate();

	// render from scene to object
	fbo.attachColorTexture(renderingContext,colorBuffer2);
	fbo.attachDepthTexture(renderingContext,depthBuffer2);
	cam.setWorldOrigin(nodeWorldPos + dir * (zFar - 0.5 * node.getWorldBB().getDiameter()));
	cam.rotateLocal_deg(180, new Geometry.Vec3(0, 1, 0));
	fc.setCamera(cam);
	renderingContext.clearScreen(PADrend.getBGColor());
	node.display(fc, MinSG.USE_WORLD_MATRIX|MinSG.FRUSTUM_CULLING|MinSG.NO_STATES);
	renderingContext.popCullFace();
	renderingContext.popFBO();

	// determine camera and world distance
	var cameraDistance = Rendering.minDepthDistance(renderingContext, depthBuffer1, depthBuffer2);
	var worldDistance = cameraDistance * (zFar - zNear);

	// for debugging only: draw renderBuffers to screen and output debug info
	if(debugMode) {
		colorBuffer1.download(renderingContext);
		colorBuffer2.download(renderingContext);
		for(var i = 0; i < 5000; i++) {
			Rendering.drawTextureToScreen(renderingContext, new Geometry.Rect(0 ,0, 512, 512), colorBuffer1, new Geometry.Rect(0,0,1,1));
			PADrend.SystemUI.swapBuffers();
		}
		for(var i = 0; i < 5000; i++) {
			Rendering.drawTextureToScreen(renderingContext, new Geometry.Rect(0 ,0, 512, 512), colorBuffer2, new Geometry.Rect(0,0,1,1));
			PADrend.SystemUI.swapBuffers();
		}

		if(cameraDistance == -1) {
			out("Intersecting objects.\n");
		} else if(cameraDistance == -2) {
			out("No scene intersection found, textures disjoint.\n");
		} else {
			out("cameraDistance: ", cameraDistance, "\n");
			out("worldDistance: ", worldDistance, "\n");
		}
	}

	frameContext.setCamera(backupCam);

	// return worldDistance if no error occured, else return false
	if(cameraDistance < 0) {
		return false;
	} else {
		return worldDistance;
	}
};

//! Waiting screen.
GLOBALS.showWaitingScreen:=fn(fancy=void){
	if(void===fancy){ // use default
		fancy = thisFn.fancy;
	}
	if(!fancy){
//        renderingContext.clearScreen(new Util.Color4f(0,37/256,79/256,0)); // upb-blue
		renderingContext.clearScreen(new Util.Color4f(0, 0, 0, 0));
		PADrend.SystemUI.swapBuffers();
	}else{
		if(!thisFn._waitingScreenShader){
			thisFn._waitingScreenShader=Rendering.Shader.createShader(
				"void main( void ){  gl_TexCoord[0] = gl_MultiTexCoord0;  gl_Position = ftransform();}",
				"uniform sampler2D tex; \n"+
				"void main(){ \n"+
				" vec4 c1 = texture2D(tex,vec2(gl_TexCoord[0].s, gl_TexCoord[0].t)); \n"+
				" float f = c1.r + c1.g + c1.b ; \n"+
				" gl_FragColor = vec4( (c1.r+f)*0.1 , (c1.g+f)*0.1 , (c1.b+f)*0.1,0.0);}");
			
			thisFn._waitingScreenShader.setUniform(renderingContext,'tex',Rendering.Uniform.INT,[0]);

		}
		var t=Rendering.createTextureFromScreen();
		renderingContext.pushAndSetShader(thisFn._waitingScreenShader);
		Rendering.drawTextureToScreen(renderingContext,new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight()) , 
							t,new Geometry.Rect(0,0,1,1));
		renderingContext.popShader();
		PADrend.SystemUI.swapBuffers();
	}
};
GLOBALS.showWaitingScreen.fancy := true;
GLOBALS.showWaitingScreen._waitingScreenShader := void;


// -------------------------
return true;
