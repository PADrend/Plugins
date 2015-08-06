 /*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Sascha Brandt <myeti@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static HelperTraits = module('../HelperTraits');

static Picking = Util.requirePlugin('PADrend/Picking');
static MeshEditor = Util.requirePlugin('MeshEditor');

static EditNodeFactories = module('SceneEditor/TransformationTools/EditNodeFactories');
static EditNodeTraits = module('SceneEditor/TransformationTools/EditNodeTraits');

var Tool = new Type;
Traits.addTrait(Tool,HelperTraits.GenericMeshEditTrait);

Tool.vertexMode @(init) := fn(){	return new Std.DataWrapper(false);	};

Tool.onUIEvent = fn(evt) {
	if(vertexMode()) {
		return this.selectVerticesFunction(evt);
	} else {
		return this.selectTrianglesFunction(evt);
	}
};

//! \see ToolHelperTraits.UIToolTrait
Tool.onToolInitOnce_static += fn(){
	//! \see HelperTraits.UIEventListenerTrait
	var metaRootNode = new MinSG.ListNode;
	this.setMetaNode(metaRootNode);
};

//! \see ToolHelperTraits.ContextMenuProviderTrait
Tool.doCreateContextMenu ::= fn(){
	return [
	"*Triangle Selection Tool*",
	{
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Vertex Mode",
		GUI.DATA_WRAPPER : vertexMode,
		GUI.ON_DATA_CHANGED : this->fn(value) {
			setVertexEditMode(value);
		},
	},
	'----'];
};

return Tool;
