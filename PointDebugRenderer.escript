/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
/*! MinSG.PointDebugRenderer ---|> ScriptedState	*/
MinSG.PointDebugRenderer := new Type( MinSG.ScriptedState ); 


static Renderer = MinSG.PointDebugRenderer;
Renderer._printableName @(override) ::= $PointDebugRenderer;


registerExtension( 'NodeEditor_QueryAvailableStates' , Renderer->fn(states){
	if(MinSG.PointDebugRenderer!=this)
		return Extension.REMOVE_EXTENSION;
	
	states[ "[scripted] "+_printableName ] = this->fn(){return new this();};
});

Renderer.start @(init) :=  fn(){	return new Std.DataWrapper(0);	};
Renderer.end @(init) := fn(){	return new Std.DataWrapper(1.0);	};
Renderer.pointSize @(init) := fn(){	return new Std.DataWrapper(1.0);	};

Renderer.doEnableState @(override) ::= fn(node,params){
//		params.setFlag(MinSG.BOUNDING_BOXES | MinSG.USE_WORLD_MATRIX);
//		node.display(frameContext,params);
	if( node.isA(MinSG.GeometryNode)){
		var mesh = node.getMesh();
		
		var maxCount = mesh.isUsingIndexData() ?  mesh.getIndexCount() : mesh.getVertexCount();
		var first = [start(),0.0].max() * maxCount;
		first -= first % 3;
		first = [first,maxCount].min();
		var count = [[end()-start(),0.0].max(),1.0].min() * maxCount;
		
//		out(first,":",count,"\n");
		renderingContext.pushAndSetPointParameters(new Rendering.PointParameters(pointSize()));
		
		frameContext.displayMesh(mesh,
								first, 
								count );
		renderingContext.popPointParameters();
		return MinSG.STATE_SKIP_RENDERING;	
	}
	return MinSG.STATE_OK;


//	var m = mode;
//	if(m==0){
//		if(node.isSet(id))
//			return MinSG.FrameContext.PASS_ON;
//		else{
//			var f = params.clone();
//			f.setChannel(MinSG.FrameContext.APPROXIMATION_CHANNEL);
//			frameContext.displayNode(node,f);
//			return MinSG.FrameContext.NODE_HANDLED;
//		}
//	}else{
//		node.setAttribute(id,true);
//		return MinSG.FrameContext.PASS_ON;
//	}
};

//Renderer.mode := 0;
//Renderer.id := "rId0";

NodeEditor.registerConfigPanelProvider( Renderer, fn(renderer, panel){
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "Start",
		GUI.DATA_WRAPPER : renderer.start,
		GUI.RANGE : [0,1]
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "End",
		GUI.DATA_WRAPPER : renderer.end,
		GUI.RANGE : [0,1]
    };
    panel++;
    panel += {
		GUI.TYPE : GUI.TYPE_RANGE,
		GUI.LABEL : "PointSize",
		GUI.DATA_WRAPPER : renderer.pointSize,
		GUI.RANGE : [1,10]
    };
    panel++;

});

Std.module.on( 'LibMinSGExt/ScriptedStateImportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(description){	
		print_r(description);
		var state = new Renderer;
		if(	description['start'] )	state.start(0+description['start']);
		if(	description['end'] )	state.end(0+description['end']);
		if(	description['pointSize'] )	state.pointSize(0+description['pointSize']);
		return state;
	};
});


Std.module.on( 'LibMinSGExt/ScriptedStateExportersRegistry',fn(registry){
	registry[Renderer._printableName] = fn(state,description){	
		description['start'] = state.start();
		description['end'] = state.end();
		description['pointSize'] = state.pointSize();
	};
});