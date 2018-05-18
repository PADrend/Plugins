/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012-2013 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2017 Sascha Brandt <sascha@brandt.graphics>
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
SurfelGenerator.smartMode @(private) := false;
SurfelGenerator.additionalBenchmarkStats @(private) := false;
SurfelGenerator.traverseClosedNodes @(private) := false;

SurfelGenerator.surfelRenderer @(private,init) := MinSG.SurfelRendererFixedSize;

SurfelGenerator.setBlockerNodes @(public) ::= fn( Array nodes){
	this.blockerNodes = nodes.clone();
	return this;
};

SurfelGenerator.setDebugMode @(public) ::= fn(Bool v){
	debug = v;
	return this;
};
SurfelGenerator.setVerticalResolution @(public) ::= fn(Number v){
	verticalResolution = v;
	return this;
};
SurfelGenerator.setMaxRelSurfels @(public) ::= fn(Number v){
	maxRelSurfels = v;
	return this;
};
SurfelGenerator.setUseMaxRelSurfels @(public) ::= fn(Bool v){
	useMaxRelSurfels = v;
	return this;
};
SurfelGenerator.setMinimumComplexity @(public) ::= fn(Number v){
	minimumComplexity = v;
	return this;
};
SurfelGenerator.setSmartMode @(public) ::= fn(Bool v){
	smartMode = v;
	return this;
};
SurfelGenerator.setTraverseClosedNodes @(public) ::= fn(Bool v){
	traverseClosedNodes = v;
	return this;
};

SurfelGenerator.getBenchmarkResults @(public) ::= [SurfelGenerator.getBenchmarkResults] => fn(original){
	return (this->original)().merge( this.additionalBenchmarkStats );
};

static TextureProcessor = Std.module('LibRenderingExt/TextureProcessor');

/*!	\return ExtObject
				.mesh Mesh
				.relativeCovering
*/
SurfelGenerator.createSurfelsForNode @(public) ::= fn(MinSG.Node node){
	
	@(once) initShaders();
	
	this.additionalBenchmarkStats = new Map;
	var timer = new Util.Timer;
	
	var cameras = [];
	var resolution = void;
	{
		var directions = 	[
			new Geometry.Vec3(1,1,1),	new Geometry.Vec3(1,1,-1),	new Geometry.Vec3(1,-1,1),	new Geometry.Vec3(1,-1,-1),
			new Geometry.Vec3(-1,1,1),	new Geometry.Vec3(-1,1,-1),	new Geometry.Vec3(-1,-1,1),	new Geometry.Vec3(-1,-1,-1)
		];

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
	var t_size = Rendering.createStdTexture(resolution.x(),resolution.y(),true);
//	
	{ // render scene 
		var tp = (new TextureProcessor)
			.setOutputDepthTexture( t_depth )
			.setOutputTextures( [t_combinedColor,t_position_surfelSpace,t_normal_surfelSpace,t_ambient,t_diffuse] )
//			.setOutputTextures( [t_combinedColor,t_normal_surfelSpace,t_ambient,t_diffuse] )
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

//		// guess sizes
//		(new TextureProcessor)
//			.setInputTextures( [t_normal_surfelSpace] )
//			.setOutputTextures( [t_size] )
//			.setShader( shader_sizeHint )
//			.execute();
	}
	additionalBenchmarkStats["t_renderScene"] = timer.getSeconds();

	if(debug){
		Rendering.showDebugTexture(t_position_surfelSpace);
		Rendering.saveTexture(renderingContext,Rendering.createTextureFromScreen(true), "surfels_pos.png"); // float textures can't be saved directly.... :-(
		Rendering.showDebugTexture(t_normal_surfelSpace);
		Rendering.saveTexture(renderingContext,Rendering.createTextureFromScreen(true), "surfels_normal.png"); // float textures can't be saved directly.... :-(
		Rendering.showDebugTexture(t_diffuse);
		Rendering.saveTexture(renderingContext,Rendering.createTextureFromScreen(true), "surfels_color.png"); // float textures can't be saved directly.... :-(
//		Rendering.showDebugTexture(t_size);
	}


	var downloadTimer = new Util.Timer;
	var pAcc_pos = Rendering.createColorPixelAccessor(renderingContext,t_position_surfelSpace);
	var pAcc_normal = Rendering.createColorPixelAccessor(renderingContext,t_normal_surfelSpace);
	var pAcc_color = 	Rendering.createColorPixelAccessor(renderingContext,t_diffuse);
//	var pAcc_normal = Rendering.createColorPixelAccessor(renderingContext,t_size);
	additionalBenchmarkStats["t_download"] = downloadTimer.getSeconds();
	
	// create surfels
	var result =  this.createSurfels( pAcc_pos ,pAcc_normal, pAcc_color);
//		Rendering.createColorPixelAccessor(renderingContext,t_position_surfelSpace),
//		Rendering.createColorPixelAccessor(renderingContext,t_normal_surfelSpace),
//		Rendering.createColorPixelAccessor(renderingContext,t_combinedColor),
//		Rendering.createColorPixelAccessor(renderingContext,t_size)
//	);

	additionalBenchmarkStats["t_complete"] = timer.getSeconds();

//	outln("Relative covering:", result.relativeCovering );
	return result;
};

SurfelGenerator.createSurfelsForTree @(public) ::= fn(MinSG.Node root){

	outln("BlueSurfels: collecting data ");

	var statistics = {
		'instances' : 0,
		'inspected' : 0,
		'processed' : 0,
		'rejected' : 0,
		'skipped' : 0,
		'status' : 'started'
	};
	
	var todoList = [];
	
	root.traverse(this->(fn(node, statistics, todo){
		++statistics['inspected'];
		
		var complexity = MinSG.countTriangles(node);
		if(complexity < minimumComplexity){
			//out("-");
			++statistics['rejected'];
			return (!traverseClosedNodes && node.isClosed()) ? $BREAK_TRAVERSAL : void;
		}

		var targetCount = getMaxAbsSurfels();
		if(useMaxRelSurfels || smartMode)
			targetCount = [targetCount, maxRelSurfels * complexity].min();
		if(targetCount <= 0){
			//out("-");
			++statistics['rejected'];
			return (!traverseClosedNodes && node.isClosed()) ? $BREAK_TRAVERSAL : void;
		}

		if(MinSG.BlueSurfels.locateSurfels(node)){
			//out("o");
			++statistics['skipped'];
			return (!traverseClosedNodes && node.isClosed()) ? $BREAK_TRAVERSAL : void;
		}
		
		var proto = node.getPrototype();
		if(!proto){
			proto = node;
		}
		if(proto.isNodeAttributeSet('complexity')){
			++statistics['instances'];
			//out("i");
			return (!traverseClosedNodes && node.isClosed()) ? $BREAK_TRAVERSAL : void;
		}
		//out("+");
		proto.setNodeAttribute('complexity', complexity);
		proto.setNodeAttribute('targetCount', targetCount);
		todo += proto;
		
		return (!traverseClosedNodes && node.isClosed()) ? $BREAK_TRAVERSAL : void;
	}).bindLastParams(statistics, todoList));
	
	todoList.sort(fn(a,b){return a.getNodeAttribute('complexity') < b.getNodeAttribute('complexity');});
		
	progressBar.setDescription("Blue Surfels");
	progressBar.setMaxValue(todoList.size());
	progressBar.setToScreenCenter();
	progressBar.setSize(500, 32);
	progressBar.update(0);
	
	var tmpMaxAbs = this.getMaxAbsSurfels();
	var tmpRes = this.verticalResolution;
	var count = 0;
	var times = [];
	var timer = new Util.Timer;
	foreach(todoList as var node){
		
		this.setMaxAbsSurfels(node.getNodeAttribute('targetCount'));

		if(smartMode){
			if(this.getMaxAbsSurfels() > 100000)
				verticalResolution = 1024;
			else if(this.getMaxAbsSurfels() > 10000)
				verticalResolution = 512;
			else
				verticalResolution = 256;
		}

		progressBar.setDescription("Processing " + (++count) + "/" + todoList.size() +
			  " complexity=" + node.getNodeAttribute('complexity') +
			  " targetCount=" + node.getNodeAttribute('targetCount') +
			  " resolution=" + verticalResolution );
		
		var surfelInfo = createSurfelsForNode(node);
		MinSG.BlueSurfels.attachSurfels(node, surfelInfo);
		++statistics['processed'];

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
		
		//outln("BlueSurfels: last time: ",times.back()," time remaining: ", times.avg()*(todoList.size()-count));
		timer.reset();
		progressBar.update(count);
	}
	this.setMaxAbsSurfels(tmpMaxAbs);
	this.verticalResolution = tmpRes;

	foreach(todoList as var node){
		node.unsetNodeAttribute('targetCount');
		node.unsetNodeAttribute('complexity');
	}

	statistics['status'] = "finished";
	print_r(statistics);
	return statistics;
};

// (internal) ***********************************************************************************************************

// static
static shader_renderObject_mrt; // multi render target
static shader_sizeHint;

static initShaders = fn(){	
	PADrend.getSceneManager().addSearchPath(__DIR__ + "/resources/");
	
	var renderingShaderState = new MinSG.ShaderState;
	(renderingShaderState.getStateAttributeWrapper(MinSG.ShaderState.STATE_ATTR_SHADER_NAME))( "surfels_ortho_MRT.shader" );
	renderingShaderState.recreateShader( PADrend.getSceneManager() );
	shader_renderObject_mrt = renderingShaderState.getShader();
	

	{	// size shader
	var shaderPath = Util.requirePlugin('LibRenderingExt').getBaseFolder() + "/resources/shader/universal2/";
	var file = __DIR__+"/resources/"+"SizeShader.sfn";
	shader_sizeHint = Rendering.Shader.loadShader(file,file,Rendering.Shader.USE_UNIFORMS|Rendering.Shader.USE_GL);
	shader_sizeHint.attachVSFile(shaderPath + "sgHelpers.sfn");
	shader_sizeHint.attachFSFile(shaderPath + "sgHelpers.sfn");
	
	} // ----------
};

return SurfelGenerator;
