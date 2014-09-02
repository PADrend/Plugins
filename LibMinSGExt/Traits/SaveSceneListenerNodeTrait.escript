/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! Before a scene is saved, the node's onSave() multiProcedure is called. 
	Adds the following attributes:
	 - onSaveScene(SceneManager)  	MultiProcedure		
	\code
		{
			Traits.addTrait(NodeEditor.getSelectedNode(),MinSG.SaveSceneListenerNodeTrait);
			NodeEditor.getSelectedNode().onSaveScene += fn(...){outln("Huhu!");};
		}
	\endcode
*/
MinSG.SaveSceneListenerNodeTrait := new Std.Traits.GenericTrait('MinSG.SaveSceneListenerNodeTrait');
{
	var t = MinSG.SaveSceneListenerNodeTrait;
	var MARKER_ATTRIBUTE = '$sic$containsOnSaveMethod';// privateAttribute
	var saveFn = MinSG.SceneManager.saveMinSGFile;
	
	// annotate saveMinSGFile
	MinSG.SceneManager.saveMinSGFile @(override) ::= [MARKER_ATTRIBUTE,saveFn] => fn(MARKER_ATTRIBUTE,saveFn, filename, nodes, p... ){
		foreach(nodes as var root){
			foreach(MinSG.collectNodesWithAttribute(root,MARKER_ATTRIBUTE) as var node){
				if(node.isSet($onSaveScene))
					node.onSaveScene(this);
			}
		}
		return (this->saveFn)(filename,nodes,p...);
	};

	t.onInit += [MARKER_ATTRIBUTE] => fn(MARKER_ATTRIBUTE, MinSG.Node node){
		/*
		\todo EScript.VERSION >= 607
			@(once){
				static originalSaveFun;
				// init saveMinSGFile hook only if necessary
			}
		
		*/
		
		node.setNodeAttribute(MARKER_ATTRIBUTE,true); 
		node.onSaveScene := new MultiProcedure;
	};
}
return MinSG.SaveSceneListenerNodeTrait;

