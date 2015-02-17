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
Traits.addTrait(Tool,HelperTraits.MeshTransformationHandlerTrait);


Tool.normalTransform @(init) := fn(){	return DataWrapper.createFromValue(false);	};

Tool.editNode @(private) := void;
Tool.pivot_ws @(init) := fn(){	return DataWrapper.createFromValue(void);	};
Tool.stepSize @(private,init) := fn(){	return DataWrapper.createFromValue(1);	};
Tool.vertexMode @(init) := fn(){	return DataWrapper.createFromValue(false);	};

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

	// ----

	this.editNode = new MinSG.ListNode;
	metaRootNode += editNode;

	//! \see EditNodeTraits.AnnotatableTrait
	Traits.addTrait( editNode, EditNodeTraits.AnnotatableTrait);

	//! \see EditNodeTraits.AdjustableProjSizeTrait
	Traits.addTrait( editNode, EditNodeTraits.AdjustableProjSizeTrait);

	//! \see ToolHelperTraits.FrameListenerTrait
	this.onFrame +=	editNode->editNode.adjustProjSize; //! \see EditNodeTraits.AdjustableProjSizeTrait
	
	var pivotEditNode = EditNodeFactories.createTranslationEditNode();
	editNode += pivotEditNode;
	pivotEditNode.scale(0.5);

	pivotEditNode.onTranslationStart +=  this->fn(){
		this.initialPivot_ws @(private) := pivot_ws().clone();
	};
	pivotEditNode.onTranslate += this->fn(v){
		this.pivot_ws(new Geometry.Vec3( initialPivot_ws + v) );
	};
	pivotEditNode.onTranslationStop += this->fn(v){
		this.initialPivot_ws = void;
	};

	// ----------
	var rotationNode = EditNodeFactories.createRotationEditNode();
	editNode += rotationNode;
	
	//! \see ToolHelperTraits.NodeTransformationHandlerTrait
	rotationNode.onRotationStart += this->applyVertexTransformations;
	rotationNode.onRotate += this->fn(deg,axis_ws){
		deg = deg.round(this.stepSize());

		var origin = getTriangleOrigin();
	
		var node = getSelectedNodes()[0];
		var mat = new Geometry.Matrix4x4();
		mat.translate(node.worldPosToLocalPos(pivot_ws()));
		mat.rotate_deg(deg, node.worldDirToLocalDir(axis_ws.getDirection()));
		mat.translate(-node.worldPosToLocalPos(pivot_ws()));
		
		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		this.setRelTransformation(mat);
	};
	rotationNode.onRotationStop += this->fn(...){
		this.applyVertexTransformations();
		editNode.hideAnnotation();						//! \see EditNodeTraits.AnnotatableTrait
	};
	// ----

	var axisMarkerNode = new MinSG.GeometryNode(EditNodeFactories.createLineAxisMesh());
	metaRootNode += axisMarkerNode;
	axisMarkerNode.deactivate();
	pivotEditNode.onTranslationStart += axisMarkerNode->axisMarkerNode.activate;
	pivotEditNode.onTranslationStop += axisMarkerNode->fn(...){ deactivate(); };
};

//! \see ToolHelperTraits.FrameListenerTrait
Tool.onFrame_static += fn(){
	//! \see ToolHelperTraits.NodeSelectionListenerTrait
	var nodes = getSelectedNodes();
	if(nodes.empty())
		return;

	var metaRootNode = this.getMetaNode();

	var wm = nodes[0].getWorldTransformationMatrix();
	
	var origin;
	if(vertexMode()) {
		origin = new Geometry.SRT();
		_calculateVertexOrigin(); 
		origin.setTranslation(getVertexOrigin());
	} else {
		_calculateOrigin(); 
		origin = getTriangleOrigin();
	}
	
	if(!normalTransform()) {
		origin.setRotation(new Geometry.Vec3(-1,0,0),new Geometry.Vec3(0,1,0));
	}
	metaRootNode.setRelTransformation(wm * origin);
	metaRootNode.setWorldOrigin(pivot_ws());
};

Tool.onTrianglesSelected_static += fn(...) {
	var origin = getTriangleOrigin();
	var nodes = getSelectedNodes();
	if(!nodes.empty()) 
		pivot_ws(nodes[0].localPosToWorldPos(origin.getTranslation()));
	else
		pivot_ws(origin.getTranslation());
};

Tool.onVerticesSelected_static += fn(...) {
	var origin = getVertexOrigin();
	var nodes = getSelectedNodes();
	if(!nodes.empty()) 
		pivot_ws(nodes[0].localPosToWorldPos(origin));
	else
		pivot_ws(origin);
};

//! \see ToolHelperTraits.ContextMenuProviderTrait
Tool.doCreateContextMenu ::= fn(){
	return [
	"*Triangle Translation Tool*",
	{
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Vertex Mode",
		GUI.DATA_WRAPPER : vertexMode,
		GUI.ON_DATA_CHANGED : this->fn(value) {
			setVertexEditMode(value);
		},
	},
	{
		GUI.TYPE : GUI.TYPE_BOOL,
		GUI.LABEL : "Normal translation",
		GUI.DATA_WRAPPER : normalTransform,
		GUI.TOOLTIP : 	"Move the selected triangles according to the average normal of the triangles."
	},
	'----'];
};

return Tool;
