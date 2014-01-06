/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static t = new MinSG.PersistentNodeTrait('ObjectTraits.MetaObjectTrait');
declareNamespace($ObjectTraits);
ObjectTraits.MetaObjectTrait := t;


static highlightState = new MinSG.GroupState;

	{	// add lighting
		var defaultLight = new MinSG.LightNode(MinSG.LightNode.DIRECTIONAL);
		defaultLight.setAmbientLightColor(new Util.Color4f(0.2,0.2,0.2,1))
					.setDiffuseLightColor(new Util.Color4f(0,0,0,0))
					.setSpecularLightColor(new Util.Color4f(0,0,0,0));
	
		highlightState.addState(new MinSG.LightingState(defaultLight));
	}
	
	{	// add blending
		var blending = new Rendering.BlendingParameters;
		blending.enable();
		blending.setBlendFunc(Rendering.BlendFunc.SRC_ALPHA,Rendering.BlendFunc.ONE);
		var s = new MinSG.BlendingState;
		s.setParameters(blending);
		highlightState.addState( s );
	}
	
//	{	// depth test
//		var S = new Type( MinSG.ScriptedState );
//		S.doEnableState ::= fn(node,params){
//			renderingContext.pushAndSetDepthBuffer(false, false, Rendering.Comparison.LESS);
//			return MinSG.STATE_OK;
//		};
//		S.doDisableState ::= fn(node,params){
//			renderingContext.popDepthBuffer();
//		};
//		highlightState.addState( new S );
//	}
	

t.onInit += fn(MinSG.GeometryNode node){
	node += highlightState;
//	registerExtension('PADrend_RenderMetaNodes',[node]=>fn(node,...){
//		if(node.isDestroyed())
//			return $REMOVE;			
//		node.display(GLOBALS.frameContext, MinSG.USE_WORLD_MATRIX);
//	});
	
};

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(t,"MetaObject");
	registry.registerTraitConfigGUI(t,fn(node){
		return [ "MetaObjectTrait",
			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
//			{
//				GUI.TYPE : GUI.TYPE_RANGE,
//				GUI.RANGE : [-3,2],
//				GUI.RANGE_FN_BASE : 10,
//				GUI.LABEL : "X",
//				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
//				GUI.DATA_WRAPPER : node.dimX
//			},
//			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
//			{
//				GUI.TYPE : GUI.TYPE_RANGE,
//				GUI.RANGE : [-3,2],
//				GUI.RANGE_FN_BASE : 10,
//				GUI.LABEL : "Y",
//				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
//				GUI.DATA_WRAPPER : node.dimY
//			},
//			{	GUI.TYPE : GUI.TYPE_NEXT_ROW	},
//			{
//				GUI.TYPE : GUI.TYPE_RANGE,
//				GUI.RANGE : [-3,2],
//				GUI.RANGE_FN_BASE : 10,
//				GUI.LABEL : "Z",
//				GUI.SIZE : [GUI.WIDTH_FILL_ABS | GUI.HEIGHT_ABS,2,15 ],
//				GUI.DATA_WRAPPER : node.dimZ
//			},
		];
	});
});
