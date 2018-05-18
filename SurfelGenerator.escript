/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012-2013 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2014-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
var SurfelGenerator = MinSG.BlueSurfels.SurfelGenerator;
static ProgressBar = Std.module('Tools/ProgressBar');
static progressBar = new ProgressBar;

// c++ implementations, just to know they exist+++++++++++++++++++++++++++++++++++++++++++++++++++
SurfelGenerator.setMaxAbsSurfels; // := fn(Number)
SurfelGenerator.getMaxAbsSurfels; // := fn()
SurfelGenerator.createSurfels; // := fn(PixelAccessor, PixelAccessor, PixelAccessor, PixelAccessor) -> ExtObject({$mesh : MESH, $relativeCovering : NUMBER})
// -----------------------------------------------------------------------------------------------

SurfelGenerator.blockerNodes @(private) := void;
SurfelGenerator.debug @(private) := false;
SurfelGenerator.verticalResolution @(private) := 256;
SurfelGenerator.maxRelSurfels @(private) := 1.0;
SurfelGenerator.useMaxRelSurfels @(private) := true;
SurfelGenerator.minimumComplexity @(private) := 10000;
SurfelGenerator.additionalBenchmarkStats @(private) := false;
SurfelGenerator.traverseClosedNodes @(private) := false;
SurfelGenerator.minObjCount @(private) := 64;
SurfelGenerator.minOccFactor @(private) := 0.5;
SurfelGenerator.directions @(private,init) := fn() { 
	return [
		new Geometry.Vec3( 1,1,1), new Geometry.Vec3( 1,1,-1), new Geometry.Vec3( 1,-1,1), new Geometry.Vec3( 1,-1,-1),
		new Geometry.Vec3(-1,1,1), new Geometry.Vec3(-1,1,-1), new Geometry.Vec3(-1,-1,1), new Geometry.Vec3(-1,-1,-1)
	]; 
};

SurfelGenerator.surfelRenderer @(private,init) := MinSG.SurfelRendererFixedSize;

SurfelGenerator.setBlockerNodes @(public) ::= fn( Array nodes) {
	this.blockerNodes = nodes.clone();
	return this;
};

SurfelGenerator.setDebugMode @(public) ::= fn(Bool v) {
	debug = v;
	return this;
};
SurfelGenerator.setVerticalResolution @(public) ::= fn(Number v) {
	verticalResolution = v;
	return this;
};
SurfelGenerator.setMaxRelSurfels @(public) ::= fn(Number v) {
	maxRelSurfels = v;
	return this;
};
SurfelGenerator.setUseMaxRelSurfels @(public) ::= fn(Bool v) {
	useMaxRelSurfels = v;
	return this;
};
SurfelGenerator.setMinimumComplexity @(public) ::= fn(Number v) {
	minimumComplexity = v;
	return this;
};
SurfelGenerator.setTraverseClosedNodes @(public) ::= fn(Bool v) {
	traverseClosedNodes = v;
	return this;
};
SurfelGenerator.setDirections @(public) ::= fn(Array dir) {
	directions = dir;
	return this;
};

SurfelGenerator.setMinimumObjectCount @(public) ::= fn(Number v) {
	minObjCount = v;
	return this;
};

SurfelGenerator.setMinOcclusionFactor @(public) ::= fn(Number v) {
	minOccFactor = v;
	return this;
};

SurfelGenerator.getBenchmarkResults @(public) ::= [SurfelGenerator.getBenchmarkResults] => fn(original) {
	return (this->original)().merge( this.additionalBenchmarkStats );
};

static TextureProcessor = Std.module('LibRenderingExt/TextureProcessor');

/*!	\return ExtObject
				.mesh Mesh
				.relativeCovering
*/
SurfelGenerator.createSurfelsForNode @(public) ::= fn(MinSG.Node node) {	
	@(once) initShaders();
	
	this.additionalBenchmarkStats = new Map;
	var timer = new Util.Timer;
	
	var cameras = [];
	var resolution = void;
	{
		foreach(directions as var dir){
			cameras += MinSG.BlueSurfels.createEnclosingOrthoCam(dir,node);
		}

		var maxWidth = cameras.map(fn(idx,camera){return camera.getRightClippingPlane()-camera.getLeftClippingPlane();} ).max();
		var maxHeight = cameras.map(fn(idx,camera){return camera.getTopClippingPlane()-camera.getBottomClippingPlane();} ).max();

		var scaling = (verticalResolution-2)/[maxWidth,maxHeight].max();
		var x=0;
		foreach(cameras as var camera){
			var viewport = new Geometry.Rect(x, 0, 	((camera.getRightClippingPlane()-camera.getLeftClippingPlane())*scaling).ceil(),
											((camera.getTopClippingPlane()-camera.getBottomClippingPlane())*scaling).ceil());
			camera.setViewport(viewport);
			x = viewport.getMaxX().ceil()+1;
		}
		resolution = new Geometry.Vec2( (x-5).round(8)+8 +2, verticalResolution );
		if(debug)
			outln("Resolution: ",resolution);
	}
	var t_depth = Rendering.createDepthTexture(resolution.x(),resolution.y());
	var t_combinedColor = Rendering.createHDRTexture(resolution.x(),resolution.y(),true); // may include lighting !!
	var t_position_surfelSpace = Rendering.createHDRTexture(resolution.x(),resolution.y(),true); 
	var t_normal_surfelSpace = Rendering.createHDRTexture(resolution.x(),resolution.y(),true);
	var t_ambient = Rendering.createHDRTexture(resolution.x(),resolution.y(),true);
	var t_diffuse = Rendering.createHDRTexture(resolution.x(),resolution.y(),true);
	
	{ // render scene 
		var tp = (new TextureProcessor)
			.setOutputDepthTexture( t_depth )
			.setOutputTextures( [t_combinedColor,t_position_surfelSpace,t_normal_surfelSpace,t_ambient,t_diffuse] )
			.setShader( shader_renderObject_mrt )
			.begin();

		var matrix_worldToImpostorRel = node.getWorldTransformationMatrix().inverse();
		
		renderingContext.clearScreenRect(new Geometry.Rect(0,0,resolution.x(),resolution.y()),new Util.Color4f(0,0,0,0),true);
		
		renderingContext.applyChanges(true);		
	  renderingContext.pushAndSetCullFace((new Rendering.CullFaceParameters()).disable());
		frameContext.pushCamera();
		var rp = (new MinSG.RenderParam).setFlags(MinSG.USE_WORLD_MATRIX).setRenderingLayers(PADrend.getRenderingLayers());
		
		if(this.blockerNodes){
			foreach(cameras as var camera){
				var matrix_cameraToImpostorRel = matrix_worldToImpostorRel * camera.getWorldTransformationMatrix();
				renderingContext.setGlobalUniform(new Rendering.Uniform('sg_mrt_matrix_cameraToCustom',  Rendering.Uniform.MATRIX_4X4F,[matrix_cameraToImpostorRel]));
			
				frameContext.setCamera( camera );
				foreach(this.blockerNodes as var node)
					frameContext.displayNode(node, rp);
			}
			renderingContext.clearScreenRect(new Geometry.Rect(0,0,resolution.x(),resolution.y()),new Util.Color4f(1,0,0,0),false);			
		}
				
		foreach(cameras as var camera){
			var matrix_cameraToImpostorRel = matrix_worldToImpostorRel * camera.getWorldTransformationMatrix();
			renderingContext.setGlobalUniform(new Rendering.Uniform('sg_mrt_matrix_cameraToCustom',  Rendering.Uniform.MATRIX_4X4F,[matrix_cameraToImpostorRel]));
			frameContext.setCamera(camera);
		
			surfelRenderer.enableState(frameContext, node, rp);
			frameContext.displayNode(node, rp);
			surfelRenderer.disableState(frameContext, node, rp);
		}
		
		frameContext.popCamera();
		renderingContext.popCullFace();
		renderingContext.finish();
		tp.end();
	}
	additionalBenchmarkStats["t_renderScene"] = timer.getSeconds();

	if(debug){
		Rendering.showDebugTexture(t_depth);
		Rendering.showDebugTexture(t_position_surfelSpace);
		Rendering.saveTexture(renderingContext,Rendering.createTextureFromScreen(true), "surfels_pos.png"); // float textures can't be saved directly.... :-(
		Rendering.showDebugTexture(t_normal_surfelSpace);
		Rendering.saveTexture(renderingContext,Rendering.createTextureFromScreen(true), "surfels_normal.png"); // float textures can't be saved directly.... :-(
		Rendering.showDebugTexture(t_diffuse);
		Rendering.saveTexture(renderingContext,Rendering.createTextureFromScreen(true), "surfels_color.png"); // float textures can't be saved directly.... :-(
	}

	var downloadTimer = new Util.Timer;
	var pAcc_pos = Rendering.createColorPixelAccessor(renderingContext,t_position_surfelSpace);
	var pAcc_normal = Rendering.createColorPixelAccessor(renderingContext,t_normal_surfelSpace);
	var pAcc_color = 	Rendering.createColorPixelAccessor(renderingContext,t_diffuse);
	additionalBenchmarkStats["t_download"] = downloadTimer.getSeconds();
	
	// create surfels
	var result = this.createSurfels( pAcc_pos ,pAcc_normal, pAcc_color);
	additionalBenchmarkStats["t_complete"] = timer.getSeconds();
	return result;
};


SurfelGenerator.countSurfelNodes @(public) ::= fn(MinSG.Node node) {
	var count = [0];
	node.traverse([count] => fn(count, node) {
		if(MinSG.BlueSurfels.locateSurfels(node)) {
			++count[0];
			return $BREAK_TRAVERSAL;
		}
		if(node ---|> MinSG.GeometryNode) {
			++count[0];
			return $BREAK_TRAVERSAL;
		}
	});
	return count[0];
};

SurfelGenerator.estOcclusionFactor @(public) ::= fn(MinSG.Node node) {
	var oldRes = verticalResolution;
	var oldMax = this.getMaxAbsSurfels();
	this.setMaxAbsSurfels(100);
	verticalResolution = 64;	
	
	var s = node.getWorldTransformationSRT().getScale();
	var surfelInfo = createSurfelsForNode(node);
	var medianDist = surfelInfo.medianDist;
  var r = MinSG.BlueSurfels.getRadiusForPrefix(100, medianDist, surfelInfo.mesh.getVertexCount());
  var surfelArea = 100 * ( r * r * 2 / 3.sqrt()) * s;
	
	this.setMaxAbsSurfels(oldMax);
	verticalResolution = oldRes;
		
	// compute surface of surfels/geometry in subtree
	var surface = [0];
	node.traverse([surface] => fn(surface, node) {
		var proto = node.getPrototype();
		if(proto) node = proto;
		
		var surfels = MinSG.BlueSurfels.locateSurfels(node);
		var s = node.getWorldTransformationSRT().getScale();
		if(surfels) {
	    var median = node.findNodeAttribute('surfelMedianDist');
		  var r = MinSG.BlueSurfels.getRadiusForPrefix(1000, median, 1000);
			var area = 1000 * ( r * r * 2 / 3.sqrt());
			surface[0] += area * s;
			return $BREAK_TRAVERSAL;
		} else if(node ---|> MinSG.GeometryNode) {
			var area = 0;
			if(node.isNodeAttributeSet('$cs$surfaceArea')) {
				area = node.getNodeAttribute('$cs$surfaceArea');
			} else {
				// estimate surface of geometry nodes 
				area = Rendering.computeSurfaceArea(node.getMesh());
				//node.setNodeAttribute('surfaceArea', area);
			}
			surface[0] += area * s;
			return $BREAK_TRAVERSAL;
		}
	});
	return (1.0 - surfelArea / surface[0]).clamp(0,1);
};

SurfelGenerator.createSurfelsForTree @(public) ::= fn(MinSG.Node root) {
	progressBar.setDescription("BlueSurfels: collecting data");
	progressBar.setSize(500, 32);
	progressBar.setToScreenCenter();
	progressBar.setMaxValue(1);
	progressBar.update(0);

	var statistics = {
		'instances' : 0,
		'inspected' : 0,
		'processed' : 0,
		'rejected' : 0,
		'skipped' : 0,
		'status' : 'started'
	};
	var todoList = [];
	
	// traverse scene graph breadth-first & collect potential surfel nodes	
	root.traverse([statistics, todoList] => this->fn(statistics, todo, node){
		++statistics['inspected'];
		
		var complexity = MinSG.countTriangles(node);
		if(complexity < minimumComplexity){
			//out("-");
			++statistics['rejected'];
			return $BREAK_TRAVERSAL;
		}

		var targetCount = getMaxAbsSurfels();
		if(useMaxRelSurfels)
			targetCount = [targetCount, maxRelSurfels * complexity].min();
		if(targetCount <= 0){
			//out("-");
			++statistics['rejected'];
			return $BREAK_TRAVERSAL;
		}

		if(MinSG.BlueSurfels.locateSurfels(node)){
			//out("o");
			++statistics['skipped'];
			return $BREAK_TRAVERSAL;
		}
		
		var proto = node.getPrototype();
		if(!proto){
			proto = node;
		}
		if(proto.isNodeAttributeSet('$cs$complexity')){
			++statistics['instances'];
			//out("i");
			return $BREAK_TRAVERSAL;
		}
		//out("+");
		
		proto.setNodeAttribute('$cs$complexity', complexity);
		proto.setNodeAttribute('$cs$targetCount', targetCount);
		todo += proto;
		
		if(proto ---|> MinSG.GeometryNode) {
			var area = Rendering.computeSurfaceArea(proto.getMesh());
			node.setNodeAttribute('$cs$surfaceArea', area);
		}
		return (!traverseClosedNodes && node.isClosed()) ? $BREAK_TRAVERSAL : void;
	}, true);
	
	if(todoList.empty()) {
		statistics['status'] = "finished";
		print_r(statistics);
		return statistics;
	}
	
	// reverse list to get bottom-up traversal order
	todoList.reverse();
		
	progressBar.setMaxValue(todoList.size());
	progressBar.update(0);
	
	var tmpMaxAbs = this.getMaxAbsSurfels();
	var count = 0;
	
	foreach(todoList as var node) {
		
		progressBar.setDescription(
			"Processing " + (++count) + "/" + todoList.size()
			//+ " complexity=" + node.getNodeAttribute('complexity')
			//+ " targetCount=" + node.getNodeAttribute('targetCount')
			//+ " #obj=" + objCount
			//+ " occ=" + occFactor
		);
		
		var generateSurfels = true; 
		var objCount = 0;
		var occFactor = 0;
		if(node ---|> MinSG.ListNode && !node.isClosed()) {
			objCount = countSurfelNodes(node);
			if(objCount < minObjCount) {
				// test occlusion
				occFactor = estOcclusionFactor(node);
				if(occFactor < minOccFactor)
					generateSurfels = false;
			} 
		}
		
		if(generateSurfels) {			
			this.setMaxAbsSurfels(node.getNodeAttribute('$cs$targetCount'));		
			var surfelInfo = createSurfelsForNode(node);
			MinSG.BlueSurfels.attachSurfels(node, surfelInfo);
			++statistics['processed'];
		} else {
			++statistics['rejected'];
		}

		var esc = false;
		PADrend.getEventQueue().process();
		while(PADrend.getEventQueue().getNumEventsAvailable() > 0) {
			var evt = PADrend.getEventQueue().popEvent();
			if (evt.type==Util.UI.EVENT_KEYBOARD && evt.pressed && (evt.key == Util.UI.KEY_ESCAPE || evt.key == Util.UI.KEY_SPACE)) {
				statistics['status'] = "aborted";
				esc = true;
			}
		}
		if(esc)
			break;		
		progressBar.update(count);
	}
	this.setMaxAbsSurfels(tmpMaxAbs);

	foreach(todoList as var node) {
		node.unsetNodeAttribute('$cs$targetCount');
		node.unsetNodeAttribute('$cs$complexity');
		node.unsetNodeAttribute('$cs$surfaceArea');
	}

	statistics['status'] = "finished";
	print_r(statistics);
	return statistics;
};

// (internal) ***********************************************************************************************************

// static
static shader_renderObject_mrt; // multi render target
static initShaders = fn(){	
	PADrend.SceneManagement.addSearchPath(__DIR__ + "/resources/");	
	var renderingShaderState = new MinSG.ShaderState;
	(renderingShaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME))( "surfels_ortho_MRT.shader" );
	renderingShaderState.recreateShader( PADrend.getSceneManager() );
	shader_renderObject_mrt = renderingShaderState.getShader();
};

return SurfelGenerator;
