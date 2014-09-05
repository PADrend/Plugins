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

/*!
    Fades out connected nodes using an animated blending state.

    Links

        Node -- fade* ------> Faded nodes
         |
         |----- animator ---> Motor (range 0...1) \see ObjectTraits/AnimatedBaseTrait


*/

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn(MinSG.Node node){
    var blendingValue = new DataWrapper(0); // 0 fully visible ... 1 invisible(deactivated)
    var connectedNodes = new Std.Set;

    var myBlendingState = new MinSG.BlendingState;
    myBlendingState.setTempState(true);


    // call when a new node has been connected or the blendingValue crossed 0 or 1
    var refreshConnectedNodes = [connectedNodes,blendingValue,myBlendingState] => fn(connectedNodes,value,myBlendingState){
        value = value();
        if(value<=0){
            foreach(connectedNodes as var n){
                n -= myBlendingState;
                n.activate();
            }
        }else if(value>=1){
            foreach(connectedNodes as var n){
                n -= myBlendingState;
                n.deactivate();
            }
        }else{
            foreach(connectedNodes as var n){
                n -= myBlendingState; // to be consistent
                n += myBlendingState;
                n.activate();
            }
        }
    };


    blendingValue.onDataChanged += [new DataWrapper(0),refreshConnectedNodes,myBlendingState] => fn(lastBlendingValue,refreshConnectedNodes,myBlendingState, v){
        if(v<=0){
            if(lastBlendingValue()>0)
                refreshConnectedNodes();
        }else if(v>=1){
            if(lastBlendingValue()>0)
                refreshConnectedNodes();
        }else{
            myBlendingState.setBlendConstAlpha( 1.0-v );
            myBlendingState.setBlendDepthMask( v<0.5 );
            if(lastBlendingValue()<=0 || lastBlendingValue()>=1 )
                refreshConnectedNodes();
        }
        lastBlendingValue(v);
    };

    // ---------------------------------------------------------

    // store connected nodes in 'connectedNodes'
    @(once) static NodeLinkTrait = module('../Basic/NodeLinkTrait');

	//! \see ObjectTraits/NodeLinkTrait
	Traits.assureTrait(node,NodeLinkTrait);

	static roleName = "fade";

	//! \see ObjectTraits/NodeLinkTrait
	node.availableLinkRoleNames += roleName;

	var connectTo = [connectedNodes,refreshConnectedNodes] => fn(connectedNodes,refreshConnectedNodes, MinSG.Node newNode){
		connectedNodes += newNode;
		refreshConnectedNodes();
	};


	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesLinked += [connectTo] => fn(connectTo, role,Array nodes){
		if(role==roleName){
			foreach(nodes as var node)
				connectTo(node);
		}
	};

	// connect to existing links
	//! \see ObjectTraits/NodeLinkTrait
	foreach(node.getLinkedNodes(roleName) as var cNode)
		connectTo(cNode);


	//! \see ObjectTraits/NodeLinkTrait
	node.onNodesUnlinked += [connectedNodes,myBlendingState] => fn(connectedNodes,myBlendingState, role,Array nodes){
		if(role==roleName){
			foreach(nodes as var node){
                node -= myBlendingState;
                node.activate();
                connectedNodes -= node;
			}
		}
	};

// ----------------------------
	Traits.assureTrait(node,module('./AnimatedBaseTrait'));

	//! \see ObjectTraits/AnimatedBaseTrait
	node.onAnimationInit += [blendingValue] => fn(blendingValue, time){
//		outln("onAnimationInit (FaderTrait)");
		blendingValue(time);
	};
	//! \see ObjectTraits/AnimatedBaseTrait
	node.onAnimationPlay += [blendingValue] => fn(blendingValue,time,lastTime){
		blendingValue(time);
	};
	//! \see ObjectTraits/AnimatedBaseTrait
	node.onAnimationStop += [blendingValue] => fn(blendingValue,...){
//		outln("onAnimationStop (FaderTrait)");
        blendingValue( 0.0 );
	};

};

trait.allowRemoval();

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
});

return trait;

