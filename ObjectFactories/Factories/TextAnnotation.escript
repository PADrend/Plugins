/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

return fn() {
	var nodeContainer = new MinSG.ListNode;
	module('LibMinSGExt/SemanticObject').markAsSemanticObject(nodeContainer);
	module('LibMinSGExt/NodeAnchors').createAnchor(nodeContainer,'placingPos')(new Geometry.Vec3(0,0,0));
	module('../InternalTools').registerNodeWithUniqueId(nodeContainer,"Annotation");
	
	{	// create stick
		var node = new MinSG.GeometryNode;
		//! \see ObjectTraits/Geometry/DynamicCylinderTrait
		Std.Traits.addTrait( node, Std.module('ObjectTraits/Geometry/DynamicCylinderTrait'));
		node.cylRadius(0.01);
		node.cylHeight(3);
		node.cylNumSegments(6);
				
		var materialState = new MinSG.MaterialState;
		materialState.setAmbient(new Util.Color4f(0,0,0,1));
		materialState.setDiffuse(new Util.Color4f(0,0,0,1));
		node += materialState;
		
		module('LibMinSGExt/SemanticObject').markAsSemanticObject(node);
		nodeContainer += node;
	}

	{	// create billboard
		var node = new MinSG.BillboardNode( new Geometry.Rect(10,0 , 2, 1 ), false,false);
		module('LibMinSGExt/SemanticObject').markAsSemanticObject(node);

		Std.Traits.addTrait( node, Std.module('ObjectTraits/Misc/DynamicTextTextureTrait'));
		node.textureText("Some annotation...");

		var blendingState = new MinSG.BlendingState;
		blendingState.setBlendEquation(Rendering.BlendEquation.FUNC_ADD);
		blendingState.setBlendFuncSrc(Rendering.BlendFunc.SRC_ALPHA);
		blendingState.setBlendFuncDst(Rendering.BlendFunc.ONE_MINUS_SRC_ALPHA);
		node += blendingState;

		var materialState = new MinSG.MaterialState;
		materialState.setAmbient(new Util.Color4f(2,2,2,1));
		materialState.setDiffuse(new Util.Color4f(0,0,0,1));
		node += materialState;
		
		nodeContainer+=node;
	}

	return nodeContainer;
};
