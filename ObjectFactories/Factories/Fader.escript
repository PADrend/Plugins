/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

return fn() {
	static tools = module('../InternalTools');


    var fader = new MinSG.GeometryNode;

	module('LibMinSGExt/SemanticObject').markAsSemanticObject(fader);

	tools.registerNodeWithUniqueId(fader,"Fader");

	//! \see ObjectTrait.NodeLinkTrait
	Std.Traits.addTrait( fader, Std.module('ObjectTraits/Basic/NodeLinkTrait'));

	//! \see ObjectTraits/MetaObjectTrait
	Std.Traits.addTrait( fader, Std.module('ObjectTraits/Basic/MetaObjectTrait'));

	//! \see ObjectTraits/MetaObjectTrait
	Std.Traits.addTrait( fader, Std.module('ObjectTraits/Animation/FaderTrait'));

	//! \see ObjectTraits/DynamicBoxTrait
	Std.Traits.addTrait( fader, Std.module('ObjectTraits/Geometry/DynamicBoxTrait'));
	fader.boxDimX(0.10);
	fader.boxDimY(0.10);
	fader.boxDimZ(0.10);
	tools.addSimpleMaterial(fader,0.5,0.0,0.5,0.3);


	//! \see ObjectTraits/ConstrainedAnimatorTrait
	Std.Traits.addTrait( fader, Std.module('ObjectTraits/Animation/ConstrainedAnimatorTrait'));

	//! \see ObjectTrait.NodeLinkTrait
	fader.addLinkedNodes("animator", tools.createRelativeNodeQuery(fader,fader)); // the fader's animates itself


	tools.planInit( [fader] => fn(MinSG.Node node,Array otherNodes){
		foreach(otherNodes as var n2){
			if(!MinSG.isInSubtree(node,n2)){  // if selected node is not an ancestor -> selected node is transformed by this node
				var query = tools.createRelativeNodeQuery(node,n2);
				if(query){
					PADrend.message("Fade: ",query);
					node.addLinkedNodes( "fade", query, [n2]);
				}
			}
		}
	});

	//! \see ObjectTraits/ButtonTrait
	Std.Traits.addTrait( fader, Std.module('ObjectTraits/Animation/ButtonTrait'));

	fader.buttonFn1( "animatorGoToMax" ); //! \see ObjectTraits/ButtonTrait
	fader.buttonFn2( "animatorGoToMin" ); //! \see ObjectTraits/ButtonTrait

	fader.buttonLinkRole("myfader"); //! \see ObjectTraits/ButtonTrait

	//! \see ObjectTrait.NodeLinkTrait
	fader.addLinkedNodes( "myfader", tools.createRelativeNodeQuery(fader,fader) );

	// ------------------------------------------------------

	return fader;
};
