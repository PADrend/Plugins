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
static Command = Std.module('LibUtilExt/Command');
static Picking = Util.requirePlugin('PADrend/Picking');


var Tool = new Type;
Traits.addTrait(Tool,HelperTraits.GenericMeshEditTrait);
Traits.addTrait(Tool,HelperTraits.AfterRenderingListenerTrait);

Tool.tolerance @(init) := fn(){	return DataWrapper.createFromValue(0.0001);	};
Tool.cuttingLine @(private) := void;

//! \see ToolHelperTraits.UIToolTrait
Tool.onToolInitOnce_static += fn(){
	
};

Tool.makeCut := fn() {
	var mesh = this.getSelectedMesh();
	var triangles = this.getSelectedTriangles();
	if(!this.cuttingLine || !mesh || triangles.empty())
		return;
	var mat = getSelectedNodes()[0].getWorldToLocalMatrix();
	var v1 = Picking.getPickingRay(this.cuttingLine[0].toArray()).getOrigin();
	var v2 = Picking.getPickingRay(this.cuttingLine[0].toArray()).getPoint(1);
	var v3 = Picking.getPickingRay(this.cuttingLine[1].toArray()).getPoint(1);
	
	v1 = mat.transformPosition(v1);
	v2 = mat.transformPosition(v2);
	v3 = mat.transformPosition(v3);
	
	var p = new Geometry.Plane(v1,v2,v3);
	var oldMesh = new Rendering.Mesh(mesh);
	
	PADrend.executeCommand({
		Command.DESCRIPTION : "Transform vertices",
		Command.EXECUTE : 	[p, mesh, triangles.clone(), tolerance()]=>fn(p, mesh, triangles, tolerance) {
			var oldCount = mesh.getPrimitiveCount();
			Rendering.cutMesh(mesh, p.getNormal()*p.getOffset(), p.getNormal(), triangles, tolerance);
			var newTriangles = [];
			for(var i=oldCount; i<mesh.getPrimitiveCount(); ++i) 
				newTriangles += i;
			MeshEditor.addSelectedTriangles(newTriangles);
		},
		Command.UNDO : 	[oldMesh, mesh]=>fn(oldMesh, mesh) {
			mesh.swap(oldMesh);
			mesh._markAsChanged();
		},
	});
};

//! \see ToolHelperTraits.FrameListenerTrait
Tool.onAfterRendering_static += fn(){
	if(!this.cuttingLine) 
		return;
	Rendering.enable2DMode(GLOBALS.renderingContext);
	renderingContext.pushAndSetDepthBuffer(false,false,Rendering.Comparison.ALWAYS);
	Rendering.drawVector(GLOBALS.renderingContext, this.cuttingLine[0], this.cuttingLine[1], new Util.Color4f(0,0,0,1));
	renderingContext.popDepthBuffer();	
	Rendering.disable2DMode(GLOBALS.renderingContext);
};

//! \see HelperTraits.UIEventListenerTrait
Tool.onUIEvent = fn(evt) {		
	if(!PADrend.getEventContext().isShiftPressed()){
		if(	evt.type==Util.UI.EVENT_MOUSE_BUTTON && evt.button == Util.UI.MOUSE_BUTTON_LEFT){
			if(evt.pressed){
				this.cuttingLine = [new Geometry.Vec3(evt.x,evt.y,0), new Geometry.Vec3(evt.x,evt.y,0)];
				this.enableAfterRenderingListener();
			} else {
				if(this.cuttingLine[0].distanceSquared(this.cuttingLine[1]) < 0.0001) {				
					var nodes = getSelectedNodes();
					if(nodes.empty() || !(nodes[0].isA(MinSG.GeometryNode)))
						return false;
						
					var mesh = nodes[0].getMesh();
					var mat = nodes[0].getWorldToLocalMatrix();
					var ray = Picking.getPickingRay([evt.x, evt.y]);
					ray.setOrigin(mat.transformPosition(ray.getOrigin()));
					ray.setDirection(mat.transformDirection(ray.getDirection()).normalize());									
					var triangle = Rendering.getFirstTriangleIntersectingRay(mesh, ray);		
					if(triangle >= 0 && (!MeshEditor.isTriangleSelected(triangle) || MeshEditor.getSelectedTriangles().size() > 1 )) 
						MeshEditor.selectTriangles([triangle]);
					else
						MeshEditor.clearTriangleSelection();
					return true;
				}
			
				this.makeCut();
				this.cuttingLine = void;
				this.disableAfterRenderingListener();
			}
			return true;
		} else if(evt.type==Util.UI.EVENT_MOUSE_MOTION && evt.buttonMask ==Util.UI.MASK_MOUSE_BUTTON_LEFT && this.cuttingLine){
			this.cuttingLine[1].setValue(evt.x,evt.y,0);
			return true;
		}
	}
	return this.selectTrianglesFunction(evt);
};

//! \see ToolHelperTraits.ContextMenuProviderTrait
Tool.doCreateContextMenu ::= fn(){
	return [
	"*Knife Tool*",
	{
		GUI.TYPE : GUI.TYPE_NUMBER,
		GUI.LABEL : "Tolerance",
		GUI.DATA_WRAPPER : tolerance,
		GUI.TOOLTIP : 	"Tolerance for vertices on the cutting plane."
	},
	'----'];
};

return Tool;
