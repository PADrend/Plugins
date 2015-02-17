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

static MeshEditor = Util.requirePlugin('MeshEditor');
static Command = Std.require('LibUtilExt/Command');

static EditNodeFactories = module('SceneEditor/TransformationTools/EditNodeFactories');
static EditNodeTraits = module('SceneEditor/TransformationTools/EditNodeTraits');

var Tool = new Type;
Traits.addTrait(Tool,HelperTraits.GenericMeshEditTrait);
Traits.addTrait(Tool,HelperTraits.MeshTransformationHandlerTrait);

Tool.editNode @(private) := void;

//! \see ToolHelperTraits.UIToolTrait
Tool.onToolInitOnce_static += fn(){
	//! \see HelperTraits.UIEventListenerTrait
	this.onUIEvent = this.selectTrianglesFunction;
	
	var metaRootNode = new MinSG.ListNode;
	this.setMetaNode(metaRootNode);


	// ----

	this.editNode = EditNodeFactories.createTranslationEditNode();
	metaRootNode += editNode;

	//! \see EditNodeTraits.AnnotatableTrait
	Traits.addTrait( editNode, EditNodeTraits.AnnotatableTrait);

	//! \see EditNodeTraits.AdjustableProjSizeTrait
	Traits.addTrait( editNode, EditNodeTraits.AdjustableProjSizeTrait);

	editNode.onTranslationStart += this->fn(){
		this.applyVertexTransformations();				//! \see HelperTraits.MeshTransformationHandlerTrait
		
		var triangles = this.getSelectedTriangles();
		var mesh = this.getTransformedMesh();
		var dir = getTriangleOrigin().getUpVector() * 0.0001;

		if(mesh && !triangles.empty()) {
			var oldMesh = new Rendering.Mesh(mesh);
			PADrend.executeCommand({
				Command.DESCRIPTION : "Extrude vertices",
				Command.EXECUTE : 	[mesh, triangles, dir]=>this->fn(mesh, triangles, dir) {
					Rendering.extrudeTriangles(mesh, dir, triangles);
					MeshEditor.selectTriangles(triangles);
				},
				Command.UNDO : [oldMesh, mesh]=>fn(oldMesh, mesh) {
					mesh.swap(oldMesh);
					mesh._markAsChanged();
				},
			});
		}
	};

	editNode.onTranslate += this->fn(v){

		//! \see EditNodeTraits.AnnotatableTrait
		this.editNode.setAnnotation("World translation: "+v.x()+", "+v.y()+", "+v.z());

		var nodes = getSelectedNodes();
	
		var mat = new Geometry.Matrix4x4();
		mat.translate(nodes[0].worldDirToLocalDir(v));
		
		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		this.setRelTransformation(mat);
	};

	editNode.onTranslationStop += this->fn(v){
		//! \see EditNodeTraits.AnnotatableTrait
		this.editNode.hideAnnotation();

		var nodes = getSelectedNodes();
		
		var mat = new Geometry.Matrix4x4();
		mat.translate(nodes[0].worldDirToLocalDir(v));
		
		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		this.setRelTransformation(mat);
				
		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		this.applyVertexTransformations();
	};
	//! \see ToolHelperTraits.FrameListenerTrait
	this.onFrame +=	editNode->editNode.adjustProjSize; //! \see EditNodeTraits.AdjustableProjSizeTrait

	// ----

	var axisMarkerNode = new MinSG.GeometryNode(EditNodeFactories.createLineAxisMesh());
	metaRootNode += axisMarkerNode;
	axisMarkerNode.deactivate();
	editNode.onTranslationStart += axisMarkerNode->axisMarkerNode.activate;
	editNode.onTranslationStop += axisMarkerNode->fn(...){ deactivate(); };
};

//! \see ToolHelperTraits.FrameListenerTrait
Tool.onFrame_static += fn(){
	//! \see ToolHelperTraits.NodeSelectionListenerTrait
	var nodes = getSelectedNodes();
	if(nodes.empty())
		return;

	var metaRootNode = this.getMetaNode();

	var wm = nodes[0].getWorldTransformationMatrix();
	var origin = getTriangleOrigin();
	metaRootNode.setRelTransformation(wm * origin);

};

return Tool;
