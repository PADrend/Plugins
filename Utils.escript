/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012-2013 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static NS = new Namespace;
static defaultRenderParam = (new MinSG.RenderParam).setFlags(MinSG.USE_WORLD_MATRIX | MinSG.NO_STATES).setRenderingLayers(PADrend.getRenderingLayers());

NS.nextPowOfTwo := fn(value) { return 2.pow(value.log(2).ceil()); };

NS.getDirectionPresets := fn() {
	static presets;
	@(once){
		presets = new Map;

		foreach({
					"cube" : Rendering.createCube(),
					"tetrahderon" : Rendering.createTetrahedron(),
					"octahedron" : Rendering.createOctahedron(),
					"icosahedron" : Rendering.createIcosahedron(),
					"dodecahedron" : Rendering.createDodecahedron(),
					"cube+down" : Rendering.createCube(),
					"cube+octahedron" : Rendering.combineMeshes([Rendering.createCube(), Rendering.createOctahedron()]),
					"cube+octahedron (upper)" : Rendering.combineMeshes([Rendering.createCube(), Rendering.createOctahedron()]),
				}	as var name, var mesh) {
			var arr = [];
			var posAcc = Rendering.PositionAttributeAccessor.create(mesh);
			var numVertives = mesh.getVertexCount();
			for(var i = 0; i<numVertives; ++i){
				var dir = posAcc.getPosition(i).normalize();
				if(!name.endsWith("(upper)") || dir.y() <= 0 )
					arr += dir;
			}
      if(name.endsWith("+down")) {
        arr += new Geometry.Vec3(0,-1,0);
      }
			presets[name] = arr;
		}
		presets["down"] = [new Geometry.Vec3(0,-1,0)];
	}
	return presets;
};

NS.getDirectionsFromPreset := fn(name) {
	return getDirectionPresets()[name];
};

NS.handleUserEvents := fn() {	
	PADrend.getEventQueue().process();
	while(PADrend.getEventQueue().getNumEventsAvailable() > 0) {
		var evt = PADrend.getEventQueue().popEvent();
		if (evt.type==Util.UI.EVENT_KEYBOARD && evt.pressed && (evt.key == Util.UI.KEY_ESCAPE || evt.key == Util.UI.KEY_SPACE)) {
			return true;
		}
	}
	return false;
};

/**
 * Creates single orthographic camera that encloses the node's bounding box.
 */
NS.createEnclosingOrthoCam := fn(Geometry.Vec3 worldDir, MinSG.Node node){
	var camera = new MinSG.CameraNodeOrtho();
	var nodeCenter = node.getWorldBB().getCenter();
	camera.setWorldOrigin( nodeCenter-(worldDir.getNormalized())*node.getWorldBB().getExtentMax() );
	camera.rotateToWorldDir(camera.getWorldOrigin()-nodeCenter);
	
	var bb = node.getBB();
	if(bb.getExtentX() < 0.001) {
		bb.setMaxX(bb.getMaxX()+0.001);
		bb.setMinX(bb.getMinX()-0.001);
	}
	if(bb.getExtentY() < 0.001) {
		bb.setMaxY(bb.getMaxY()+0.001);
		bb.setMinY(bb.getMinY()-0.001);
	}
	if(bb.getExtentZ() < 0.001) {
		bb.setMaxZ(bb.getMaxZ()+0.001);
		bb.setMinZ(bb.getMinZ()-0.001);
	}
	var frustum = Geometry.calcEnclosingOrthoFrustum(bb, camera.getWorldToLocalMatrix() * node.getWorldTransformationMatrix());
	camera.setNearFar(frustum.getNear()*0.99, frustum.getFar()*1.01);
	
	//	out("a)",frustum.getTop()-frustum.getBottom() ,"\nb)",frustum.getRight()-frustum.getLeft(),"\n");
	if( frustum.getRight()-frustum.getLeft() > frustum.getTop() - frustum.getBottom()){
		camera.rotateLocal_deg(90,new Geometry.Vec3(0,0,1));
		camera.setClippingPlanes( frustum.getBottom(), frustum.getTop(), frustum.getLeft(), frustum.getRight());
	}else{
		camera.setClippingPlanes(frustum.getLeft(), frustum.getRight(), frustum.getBottom(), frustum.getTop());
	}
	
	return camera;
};

/**
 * Creates multiple orthographic cameras that surround the node in the given directions.
 */
NS.placeCamerasAroundNode := fn(MinSG.Node node, resolution, Array directions) {
	var cameras = [];	
	foreach(directions as var dir)
		cameras += NS.createEnclosingOrthoCam(dir, node);

	var maxWidth = cameras.map(fn(idx,camera){return camera.getRightClippingPlane()-camera.getLeftClippingPlane();} ).max();
	var maxHeight = cameras.map(fn(idx,camera){return camera.getTopClippingPlane()-camera.getBottomClippingPlane();} ).max();
		
	var scaling = (resolution-2)/[maxWidth,maxHeight].max();
	var viewport = new Geometry.Rect(0, 0,(maxWidth*scaling).ceil(), (maxHeight*scaling).ceil());
	
	foreach(cameras as var camera)
		camera.setViewport(viewport);
	return cameras;
};

/**
 * copy & combine the pixels of MRT array textures (color, position, normal) into a single mesh where the color-alpha value is > 0.
 * \note The depth texture is only needed to have a depth attachment for the frame buffer that matches the array textures. Depth writing is disabled.
 */
NS.packMesh := fn(t_depth, t_color, t_position, t_normal, resolution, layers) {
	// TODO: check if resolution is power of two
	var blockSize = [resolution, 8].min();
	var workGroups = resolution / blockSize;
	
	// set up shader
	var shaderFile = __DIR__ + "/resources/shader/CountAndPackShader.sfn";
	var shader = Rendering.Shader.createShader(Rendering.Shader.USE_UNIFORMS);	
	shader.attachCSFile(shaderFile, {'BLOCK_SIZE' : blockSize});
		
	// set up atomic buffer
	var atomicBuffer = new Rendering.BufferObject;
	atomicBuffer.uploadData(Rendering.TARGET_SHADER_STORAGE_BUFFER, [0], Rendering.USAGE_DYNAMIC_COPY, Util.TypeConstant.UINT32);				
	atomicBuffer._bind(Rendering.TARGET_SHADER_STORAGE_BUFFER, 0);
	
	// set up rendering context	
	renderingContext.pushAndSetTexture(0, t_color);
	renderingContext.pushAndSetTexture(1, t_position);
	renderingContext.pushAndSetTexture(2, t_normal);
	renderingContext.pushAndSetShader(shader);
		
	// count pixels
  renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["countPixel"]);
  renderingContext.dispatchCompute(workGroups, workGroups, layers);
		
	// get pixel count & reset atomic buffer
	var pixelCount = atomicBuffer.downloadData(Rendering.TARGET_SHADER_STORAGE_BUFFER, 1, Util.TypeConstant.UINT32).front();
	atomicBuffer.uploadSubData(Rendering.TARGET_SHADER_STORAGE_BUFFER, [0], 0, Util.TypeConstant.UINT32);

	// create & upload mesh
	var vd = new Rendering.VertexDescription;
	vd.appendPosition3D();
	vd.appendNormalByte();
	vd.appendColorRGBAByte();
	var mesh = new Rendering.Mesh(vd, pixelCount, 0);	
	mesh._upload();
	mesh.releaseLocalData();
	var surfelBuffer = new Rendering.BufferObject;
	mesh._swapVertexBuffer(surfelBuffer);		
	surfelBuffer._bind(Rendering.TARGET_SHADER_STORAGE_BUFFER, 1);
	
	// copy pixels to mesh
  renderingContext.loadUniformSubroutines(Rendering.SHADER_STAGE_COMPUTE, ["packMesh"]);
  renderingContext.dispatchCompute(workGroups, workGroups, layers);
	
	// download mesh
	surfelBuffer._unbind(Rendering.TARGET_SHADER_STORAGE_BUFFER, 1);		
	mesh._swapVertexBuffer(surfelBuffer);
	mesh.assureLocalData();
	mesh._markAsChanged();
	mesh.setUseIndexData(false);
	mesh.setDrawPoints();
	
	// restore rendering context
	renderingContext.popTexture(0);
	renderingContext.popTexture(1);
	renderingContext.popTexture(2);	
	renderingContext.popShader();
	
	atomicBuffer._unbind(Rendering.TARGET_SHADER_STORAGE_BUFFER, 0);	
	
	return mesh;
};

//! @return true iff a surfel was removed.
NS.removeSurfels := fn(MinSG.Node node){
	if(node.isInstance())
		node = node.getPrototype();
	node.unsetNodeAttribute('surfelSurface');
	return node.unsetNodeAttribute('surfels');
};

NS.locateSurfels := fn(MinSG.Node node) {
	return node.findNodeAttribute('surfels');
};

NS.getLocalSurfels := fn(MinSG.Node node){
	return node.getNodeAttribute('surfels');
};

NS.attachSurfels := fn(MinSG.Node node, surfelMesh, surfelSurface){
	if(node.isInstance())
		node = node.getPrototype();
	node.setNodeAttribute('surfels', surfelMesh);
	node.setNodeAttribute('surfelSurface', surfelSurface);
};

NS.saveSurfelsToMMF := fn(MinSG.Node node, Util.FileName folder) {
	Util.createDir(folder);
	node.traverse([folder] => fn(folder, node) {
		var surfels = NS.locateSurfels(node);
		if(!surfels) return $CONTINUE_TRAVERSAL;
		
		var file = surfels.getFileName();
		if(file.getPath()=="") {
			file = Util.generateNewRandFilename(folder, "surfels_", ".mmf", 8);
			surfels.setFileName(file);
			outln("set file name ", file.toString(), " for surfel ", surfels);
		}
		Rendering.saveMesh(surfels,file);
	});
};

NS.computeTotalSurface := fn(MinSG.Node node) {
	var geoNodes = MinSG.collectGeoNodes(node);
	var surface = 0;
	foreach(geoNodes as var n)
		surface += Rendering.computeSurfaceArea(n.getMesh()) * n.getWorldTransformationSRT().getScale();
	return surface / node.getWorldTransformationSRT().getScale();
};

return NS;