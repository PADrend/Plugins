/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2016 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

//! MinSG.SurfelRenderer ---|> NodeRendererState
MinSG.ScriptedSurfelRenderer2 := new Type( MinSG.ScriptedNodeRendererState ); 

static Renderer = MinSG.ScriptedSurfelRenderer2;
Renderer._printableName @(override) ::= $SurfelRenderer2;

registerExtension( 'NodeEditor_QueryAvailableStates' , Renderer->fn(states){
	if(MinSG.ScriptedSurfelRenderer2!=this)
		return Extension.REMOVE_EXTENSION;
	
	states[ "[scripted] "+_printableName ] = fn(){return new Renderer;};
});

Renderer.start @(init) :=  fn(){	return new Std.DataWrapper(0);	};
Renderer.end @(init) := fn(){	return new Std.DataWrapper(1.0);	};



Renderer.countExpression := void;
Renderer.countFn := void;

Renderer.pointSizeExpression  := void;
Renderer.pointSizeFn  := fn(...){return 1.0;	};

Renderer._constructor ::= fn()@(super(MinSG.FrameContext.DEFAULT_CHANNEL)){
 	pointSizeExpression = new Std.DataWrapper("return 3.0;");
//	pointSizeExpression = new Std.DataWrapper("return [(projectedSize.sqrt())*0.005,5].min();");
//		.setOptions(["return (projectedSize.sqrt())*0.05;","return 1.0;","return 2.0;","out(projectedSize);return 1.0;"])
	pointSizeExpression.onDataChanged += this->fn(value){
		try{
			outln(value);
			pointSizeFn = eval( "return fn(node,projectedSize,pSideLength,numSurfels,coverage,numCover){"+value+"};" );
		}catch(e){
			Runtime.warn(e);
		}
	};
	pointSizeExpression.forceRefresh();

// 	countExpression = new Std.DataWrapper("return (projectedSize.sqrt())*0.005;");
 	countExpression = new Std.DataWrapper("return numCover*2/pointSize;");
//	countExpression = new Std.DataWrapper("return (projectedSize.sqrt())*0.05;");
//		.setOptions(["return (projectedSize.sqrt())*0.05;","return 1.0;","return 2.0;","out(projectedSize);return 1.0;"])
	countExpression.onDataChanged += this->fn(value){
		try{
			outln(value);
			countFn = eval( "return fn(node,projectedSize,pSideLength,numSurfels,coverage,numCover,pointSize){"+value+"};" );
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
		if(!node.isSet($getSurfelCountForDistance)){
		//	var mesh = node.getMesh();
			var bsg = new MinSG.BlueSurfels.SurfelGenerator;
			var d_1000 = bsg.getMedianOfNthClosestNeighbours(surfels,1000,2);
			
			node.getSurfelCountForDistance := [d_1000]=>fn(d_1000,d_n){
				return 1000*d_1000*d_1000/(d_n*d_n);
				
			};
			
			/*var d2000 = bsg.getMedianOfNthClosestNeighbours(mesh,2000,2);
			outln(d1000,":",d2000,":",(1000/2000).sqrt()*d1000);
			var d4000 = bsg.getMedianOfNthClosestNeighbours(mesh,4000,2);
			outln(d1000,":",d4000,":",(1000/4000).sqrt()*d1000);

			for(var i=0;i<10;++i)
			outln( i,"\t",bsg.getMedianOfNthClosestNeighbours(mesh,2000,i));*/
		}
		var meterPerPixel;
		{
			var centerWorld = node.localPosToWorldPos( node.getBB().getCenter() );
			var oneMeterVector = frameContext.getCamera().localDirToWorldDir( [1,0,0] ).normalize()*0.1;
			var screenPos1 = frameContext.convertWorldPosToScreenPos(centerWorld);
			var screenPos2 = frameContext.convertWorldPosToScreenPos(centerWorld+oneMeterVector);
			var d = screenPos1.distance(screenPos2)*10;
			var nodeScale = node.getWorldTransformationSRT().getScale();
			meterPerPixel = 1/(d!=0?d:1) / nodeScale;
			//outln(screenPos1,"\t",screenPos2,"\t",meterPerPixel,"\t",node.getSurfelCountForDistance( meterPerPixel ));
		}
	
		var projectedRect = frameContext.getProjectedRect(node);
		var size = projectedRect.getWidth()*projectedRect.getHeight();

		var bb = node.getWorldBB();
		var pSideLength = bb.getDiameter() / (bb.getCenter()-this.cameraOrigin).length() * projectionScale; // projected side length
		
		
		var mesh = surfels;
		var maxCount = mesh.isUsingIndexData() ?  mesh.getIndexCount() : mesh.getVertexCount();

		var relCovering = node.findNodeAttribute("surfelRelCovering");
		if(!relCovering)
			relCovering =0.5;
		
		var count = 0;
		var pSize = 1;
		try{
			var numCover = node.getSurfelCountForDistance(meterPerPixel);
			pSize = pointSizeFn(node,size,pSideLength,maxCount,relCovering,numCover).clamp(1,32);
			count = countFn(node,size,pSideLength,maxCount,relCovering,numCover,pSize);
		}catch(e){
			outln(e);
		}
		// return numCover*16;
		var renderOriginal = count>maxCount;
		var surfelCount = (count>maxCount ? 2*maxCount-count : count).clamp(0,maxCount);

		//outln(count,"\t",surfelCount,"\t",renderOriginal);

		if(surfelCount>0){
			renderingContext.pushAndSetPointParameters(new Rendering.PointParameters(pSize));
			renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
			renderingContext.multMatrix_modelToCamera(node.getWorldTransformationMatrix());
			
			frameContext.displayMesh(mesh,	0, surfelCount );
			renderingContext.popMatrix_modelToCamera();
			renderingContext.popPointParameters();
			
		}
		return renderOriginal ? MinSG.FrameContext.PASS_ON : MinSG.FrameContext.NODE_HANDLED;
	}
	return MinSG.FrameContext.PASS_ON;
};

NodeEditor.registerConfigPanelProvider( Renderer, fn(renderer, panel){

    panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Count",
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,2,0],
		GUI.DATA_WRAPPER : renderer.countExpression,
		GUI.OPTIONS : ["return numCover*numCover.ln()*0.1;","return numCover*1.2;","return numCover;","return 1.0;","return 2.0;","return numCover*2/pointSize;"]
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "PointSize",
		GUI.SIZE : [GUI.WIDTH_FILL_ABS,2,0],
		GUI.DATA_WRAPPER : renderer.pointSizeExpression,
		GUI.OPTIONS : ["return 3.0;","return 1.0;","return 2.0;"]
    };
    panel++;
});



Std.module.on( 'LibMinSGExt/ScriptedStateImportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(description){	
		print_r(description);
		var state = new Renderer;
		if(	description['countExpr'] )	state.countExpression(description['countExpr']);
		if(	description['sizeExpr'] )	state.pointSizeExpression(description['sizeExpr']);
		return state;
	};
});


Std.module.on( 'LibMinSGExt/ScriptedStateExportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(state,description){	
		description['countExpr'] = state.countExpression();
		description['sizeExpr'] = state.pointSizeExpression();
	};
});
