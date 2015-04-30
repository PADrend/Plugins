/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2015 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

return fn() {

	var node = new MinSG.GeometryNode;
	module('LibMinSGExt/SemanticObject').markAsSemanticObject(node);
	module('../InternalTools').registerNodeWithUniqueId(node,"Text");

	//! \see DynamicRectTrait
	Std.Traits.assureTrait( node, module('ObjectTraits/Geometry/DynamicRectTrait') );
	node.rectDimX(1);
	node.rectDimY(0.5);

	Std.Traits.addTrait( node, Std.module('ObjectTraits/Misc/DynamicTextTextureTrait'));
    node.textureText("Text...");
    node.textureBGStrength(0.2);

	var blendingState = new MinSG.BlendingState;
	blendingState.setBlendEquation(Rendering.BlendEquation.FUNC_ADD);
	blendingState.setBlendFuncSrc(Rendering.BlendFunc.SRC_ALPHA);
	blendingState.setBlendFuncDst(Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
	node += blendingState;
	
			
	var s = new MinSG.AlphaTestState;
	var alphaTestParams = s.getParameters();
	alphaTestParams.setMode(Rendering.Comparison.GREATER);
	alphaTestParams.setReferenceValue(0.25);
	s.setParameters(alphaTestParams);
	node += s;

	var materialState = new MinSG.MaterialState;
	materialState.setAmbient(new Util.Color4f(2,2,2,1));
	materialState.setDiffuse(new Util.Color4f(0,0,0,1));
	node += materialState;

	return node;
};
