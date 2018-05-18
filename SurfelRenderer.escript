/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

//! MinSG.SurfelRenderer ---|> NodeRendererState
MinSG.ScriptedSurfelRenderer := new Type( MinSG.ScriptedNodeRendererState ); 

static Renderer = MinSG.ScriptedSurfelRenderer;
Renderer._printableName @(override) ::= $SurfelRenderer;

registerExtension( 'NodeEditor_QueryAvailableStates' , Renderer->fn(states){
	if(MinSG.ScriptedSurfelRenderer!=this)
		return Extension.REMOVE_EXTENSION;
	
	states[ "[scripted] "+_printableName ] = fn(){return new Renderer;};
});

Renderer.start @(init) :=  fn(){	return new Std.DataWrapper(0);	};
Renderer.end @(init) := fn(){	return new Std.DataWrapper(1.0);	};

Renderer.transitionStart @(init) := fn(){	return new Std.DataWrapper(200);	};
Renderer.transitionEnd @(init) := fn(){	return new Std.DataWrapper(100);	};

Renderer.countExpression := void;
Renderer.countFn := void;

Renderer.pointSizeExpression  := void;
Renderer.pointSizeFn  := fn(...){return 1.0;	};

Renderer._constructor ::= fn()@(super(MinSG.FrameContext.DEFAULT_CHANNEL)){
 	pointSizeExpression = new Std.DataWrapper("return (coverage*projectedSize*4)/count;");
//	pointSizeExpression = new Std.DataWrapper("return [(projectedSize.sqrt())*0.005,5].min();");
//		.setOptions(["return (projectedSize.sqrt())*0.05;","return 1.0;","return 2.0;","out(projectedSize);return 1.0;"])
	pointSizeExpression.onDataChanged += this->fn(value){
		try{
			outln(value);
			pointSizeFn = eval( "return fn(node,projectedSize,pSideLength,numSurfels,coverage,count){"+value+"};" );
		}catch(e){
			Runtime.warn(e);
		}
	};
	pointSizeExpression.forceRefresh();

// 	countExpression = new Std.DataWrapper("return (projectedSize.sqrt())*0.005;");
 	countExpression = new Std.DataWrapper("return coverage*projectedSize*4;");
//	countExpression = new Std.DataWrapper("return (projectedSize.sqrt())*0.05;");
//		.setOptions(["return (projectedSize.sqrt())*0.05;","return 1.0;","return 2.0;","out(projectedSize);return 1.0;"])
	countExpression.onDataChanged += this->fn(value){
		try{
			outln(value);
			countFn = eval( "return fn(node,projectedSize,pSideLength,numSurfels,coverage){"+value+"};" );
		}catch(e){
			Runtime.warn(e);
			countFn = fn(){ return 1;};
		}
	};
	countExpression.forceRefresh();
};



Renderer.cameraOrigin := void;
Renderer.projectionScale := 1;

Renderer.doEnableState @(override) ::= fn(node,params){
	var camera = frameContext.getCamera();
	this.cameraOrigin = camera.getWorldOrigin();

	if( camera.isA(MinSG.CameraNode)) { // else ortho cam
		var angles = camera.getAngles();
		projectionScale = camera.getWidth() / (((angles[1]-angles[0])*0.5).degToRad().tan()*2.0);
		
//	outln( (angles[1]-angles[0])," ",(angles[1]-angles[0])/2.0).degToRad()," ",(angles[1]-angles[0]).degToRad().tan()," " );
//	outln( projectionScale," " );
	}


	return MinSG.STATE_OK;
};
	
Renderer.displayNode @(override) ::= fn(node,params){
//	return MinSG.FrameContext.PASS_ON;
	var surfels = MinSG.BlueSurfels.locateSurfels(node);
	if(surfels){
		var tStart = transitionStart();
	
		var projectedRect = frameContext.getProjectedRect(node);
		var size = projectedRect.getWidth()*projectedRect.getHeight();

		var bb = node.getWorldBB();
		var pSideLength = bb.getDiameter() / (bb.getCenter()-this.cameraOrigin).length() * projectionScale; // projected side length
		

		var qSize = pSideLength;
		if(qSize>tStart)
			return MinSG.FrameContext.PASS_ON;
		
//		out( qSize," " );

		var tEnd = transitionEnd();
			
		var mesh = surfels;
		var maxCount = mesh.isUsingIndexData() ?  mesh.getIndexCount() : mesh.getVertexCount();

		var relCovering = node.findNodeAttribute("surfelRelCovering");
		if(!relCovering)
			relCovering =0.5;
		
		var count = 0;
		var pSize = 1;
		try{
			count = countFn(node,size,pSideLength,maxCount,relCovering).clamp(1,maxCount);
			pSize = pointSizeFn(node,size,pSideLength,maxCount,relCovering,count).clamp(1,32);
		}catch(e){
			outln(e);
		}
		
		
		if(qSize>tEnd && tStart>tEnd){
			pSize *= (tStart-qSize) / (tStart-tEnd);
			pSize = pSize.clamp(1,32);
		}
		if(qSize>tEnd && tStart>tEnd){
			count *= (tStart-qSize) / (tStart-tEnd);
			count = count.clamp(1,maxCount);
		}
		
		renderingContext.pushAndSetPointParameters(new Rendering.PointParameters(pSize));
		renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
		renderingContext.multMatrix_modelToCamera(node.getWorldTransformationMatrix());
		
		frameContext.displayMesh(mesh,	0, count );
		renderingContext.popMatrix_modelToCamera();
		renderingContext.popPointParameters();
		return qSize<tEnd ? MinSG.FrameContext.NODE_HANDLED : MinSG.FrameContext.PASS_ON;
	}
	return MinSG.FrameContext.PASS_ON;
};

NodeEditor.registerConfigPanelProvider( Renderer, fn(renderer, panel){
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "transitionStart",
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,2,0],
		GUI.DATA_WRAPPER : renderer.transitionStart,
		GUI.RANGE : [0,1000]
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "transitionEnd",
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,2,0],
		GUI.DATA_WRAPPER : renderer.transitionEnd,
		GUI.RANGE : [0,1000]
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Count",
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,2,0],
		GUI.DATA_WRAPPER : renderer.countExpression,
		GUI.OPTIONS : ["return coverage*projectedSize*4;","return (projectedSize.sqrt())*0.005;","return 1.0;","return 2.0;","out(projectedSize);return 1.0;"]
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "PointSize",
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,2,0],
		GUI.DATA_WRAPPER : renderer.pointSizeExpression,
		GUI.OPTIONS : ["return (projectedSize.sqrt())*0.003;","return 1.0;","return 2.0;","out(projectedSize);return 1.0;"]
    };
    panel++;
});



Std.module.on( 'LibMinSGExt/ScriptedStateImportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(description){	
		print_r(description);
		var state = new Renderer;
		if(	description['countExpr'] )	state.countExpression(description['countExpr']);
		if(	description['sizeExpr'] )	state.pointSizeExpression(description['sizeExpr']);
		if(	description['p0'] )			state.transitionStart(0+description['p0']);
		if(	description['p1'] )			state.transitionEnd(0+description['p1']);
		return state;
	};
});


Std.module.on( 'LibMinSGExt/ScriptedStateExportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(state,description){	
		description['countExpr'] = state.countExpression();
		description['sizeExpr'] = state.pointSizeExpression();
		description['p0'] = state.transitionStart();
		description['p1'] = state.transitionEnd();
	};
});
