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
static HelperTraits = new Namespace;

static MeshEditor = Util.requirePlugin('MeshEditor');
static Picking = Util.requirePlugin('PADrend/Picking');
static ToolHelperTraits = module('SceneEditor/TransformationTools/ToolHelperTraits');

// -----------------------------------------------------------------------------------


/*! The given type represents an UITool.
	Adds the following methods:

	- onUIEvent					Function called whenever an ui event occurs (Extension 'PADrend_UIEvent').
	- enableUIEventListener		Enables the ui event listener.
	- disableUIEventListener	Disables the ui event listener.
	- isUIEventListenerActive	Returns true if the ui event listener is active.
	
	\see PADrend/EventLoop
*/
HelperTraits.UIEventListenerTrait := new Traits.GenericTrait("HelperTraits.UIEventListenerTrait");
{
	var t = HelperTraits.UIEventListenerTrait;
	
	t.attributes.onUIEvent ::= fn(evt){	return false; };
	t.attributes._revoceUIListener @(private) := void; // void | MultiProcedure

	t.attributes.enableUIEventListener ::= fn(){
		if(!this._revoceUIListener){
			this._revoceUIListener = new Std.MultiProcedure;
			this._revoceUIListener += Util.registerExtensionRevocably('PADrend_UIEvent', this->this.onUIEvent); 
		}
		return this;
	};

	t.attributes.disableUIEventListener ::= fn(){
		if(this._revoceUIListener){
			this._revoceUIListener();
			this._revoceUIListener = void;
		}
		return this;
	};
	t.attributes.isUIEventListenerActive ::= fn(){
		return true & this._revoceUIListener;
	};
}

// -----------------------------------------------------------------------------------

/*!	Adds a handler that is called after each frame while enabled.
	Adds the following methods:

	- enableAfterRenderingListener		Enables the frame listening (may be safely called if already enabled).
	- disableAfterRenderingListener		Disables the frame listening  (may be safely called if already disabled).
	- isAfterRenderingListenerActive	Returns whether the frame listening is enabled.
	- onAfterRendering					MultiProcedure called after each frame while enabled.
	- onAfterRendering_static			Static MultiProcedure called after each frame while enabled.

*/
HelperTraits.AfterRenderingListenerTrait := new Traits.GenericTrait("HelperTraits.AfterRenderingListenerTrait");
{
	var t = HelperTraits.AfterRenderingListenerTrait;
	
	t.attributes.onAfterRendering_static ::= void;
	t.attributes.onAfterRendering @(init) := Std.MultiProcedure;
	t.attributes._revoceAfterRenderingListener @(private) := void; // void | MultiProcedure

	t.attributes.enableAfterRenderingListener ::= fn(){
		if(!this._revoceAfterRenderingListener){
			this._revoceAfterRenderingListener = new Std.MultiProcedure;
			// use beforeRendering instead of afterRendering to keep the editNode and the moved nodes in sync.
			this._revoceAfterRenderingListener += Util.registerExtensionRevocably('PADrend_AfterRendering', this->fn(...){
				this.onAfterRendering_static();
				this.onAfterRendering();
			}); 
		}
		return this;
	};

	t.attributes.disableAfterRenderingListener ::= fn(){
		if(this._revoceAfterRenderingListener){
			this._revoceAfterRenderingListener();
			this._revoceAfterRenderingListener = void;
		}
		return this;
	};
	t.attributes.isAfterRenderingListenerActive ::= fn(){
		return true & this._revoceAfterRenderingListener;
	};
	t.onInit += fn(obj){
		obj.onAfterRendering_static = new MultiProcedure;
	};
}

// -----------------------------------------------------------------------------------

/*!	Adds a handler that is called whenever the MeshEditor's triangle selection changes.
	The handler is also called when the listener is started with the initially selected triangle 
	and -- if nodes are selected while the listener is finalized -- when the listener is finalized 
	with an empty array.

	Adds the following methods:
	
	- finalizeTriangleSelectionListener		Disables the listening and if triangles are selected, calls the onTrianglesSelected 
											handlers with an empty array. (may be safely called if already disabled).
	- getSelectedTriangles					returns the array of currently selected triangle.
	- getSelectedMesh						returns the selected mesh.
	- onTrianglesSelected(triangles)		MultiProcedure called when the triangle selection changes. The selected triangles are given as parameter.
	- onTrianglesSelected_static(triangles)	Static MultiProcedure called when the triangle selection changes. The selected triangle are given as parameter.
	- startTriangleSelectionListener		Enables the listening and calls the onTrianglesSelected handlers
											with the initially selected triangles (may be safely called if already enabled) 
	- getTriangleOrigin						returns the origin (Geometry.SRT) of all selected triangles.

	\see MeshEditor Plugin
*/
HelperTraits.TriangleSelectionListenerTrait := new Traits.GenericTrait("HelperTraits.TriangleSelectionListenerTrait");
{
	var t = HelperTraits.TriangleSelectionListenerTrait;
	
	t.attributes._triangleSelectionChangedHandler @(private) := void; 
	t.attributes._selectedTriangles @(private,init) := Array;
	t.attributes._selectedMesh @(private) := void;
	t.attributes._triangleOrigin @(private,init) := Geometry.SRT;

	t.attributes.onTrianglesSelected_static ::= void;
	t.attributes.onTrianglesSelected @(init) := Std.MultiProcedure;

	t.attributes.startTriangleSelectionListener ::= fn(){
		if(!_triangleSelectionChangedHandler){
			_triangleSelectionChangedHandler = this->fn(Array triangles){
				_selectedTriangles.swap(triangles.clone());
				onTrianglesSelected_static(_selectedTriangles);
				onTrianglesSelected(_selectedTriangles);
			};
			Util.registerExtension('MeshEditor_OnTrianglesSelected', _triangleSelectionChangedHandler);
			_triangleSelectionChangedHandler( MeshEditor.getSelectedTriangles() );
		}
		return this;
	};
	t.attributes.finalizeTriangleSelectionListener ::= fn(){
		if(_triangleSelectionChangedHandler){
			removeExtension('MeshEditor_OnTrianglesSelected', _triangleSelectionChangedHandler);
			if(!_selectedTriangles.empty())
				_triangleSelectionChangedHandler( [] ); //clean up by calling handler with empty array.
			_triangleSelectionChangedHandler = void;
		}
		return this;
	};
	
	t.attributes.getSelectedTriangles ::= fn(){
		return _selectedTriangles;
	};
	t.attributes.getSelectedMesh ::= 	fn(){ return _selectedMesh; };
	
	t.attributes._calculateOrigin ::= fn() {
		if(!_selectedMesh || _selectedTriangles.empty()) {
			_triangleOrigin.setValue(new Geometry.Vec3(0,0,0), new Geometry.Vec3(-1,0,0), new Geometry.Vec3(0,1,0));
			return;
		}
		var posAcc = Rendering.PositionAttributeAccessor.create(_selectedMesh, Rendering.VertexAttributeIds.POSITION);	
		var normAcc = Rendering.NormalAttributeAccessor.create(_selectedMesh, Rendering.VertexAttributeIds.NORMAL);	
		var indices = _selectedMesh._getIndices();
		
		var pos = new Geometry.Vec3(0,0,0);
		var normal = new Geometry.Vec3(0,0,0);
		var dir = new Geometry.Vec3(0,0,0);
		foreach(_selectedTriangles as var t) {
			var a = posAcc.getPosition(indices[3*t+0]);
			var b = posAcc.getPosition(indices[3*t+1]);
			var c = posAcc.getPosition(indices[3*t+2]);
			
			pos += a;
			pos += b;
			pos += c;
			var n = (c-b).cross(a-b);
			var d = (c-b);
			if(n.length() > 0)
				n.normalize();
			if(d.length() > 0)
				d.normalize();
			normal += n;
			dir += d;
		}

		pos /= _selectedTriangles.size()*3;
		normal /= _selectedTriangles.size();
		dir /= _selectedTriangles.size();
		
		_triangleOrigin.setValue(pos, dir, normal);
	};
	
	t.attributes.getTriangleOrigin ::= fn() {		
		return _triangleOrigin;
	};
		
	t.onInit += fn(obj){
		obj.onTrianglesSelected_static = new MultiProcedure;
		Std.Traits.assureTrait(obj, ToolHelperTraits.NodeSelectionListenerTrait);
	
		//! \see ToolHelperTraits.NodeSelectionListenerTrait
		obj.onNodesSelected_static += fn(Array nodes){
			if(nodes.empty() || !(nodes[0].isA(MinSG.GeometryNode))) {
				_selectedMesh = void;
				_calculateOrigin(); 
				return;
			}
			_selectedMesh = nodes[0].getMesh();
			_calculateOrigin(); 
		};
		
		obj.onTrianglesSelected_static += fn(...){
			_calculateOrigin(); 
		};
	};
}

// -----------------------------------------------------------------------------------

/*!	Adds a handler that is called whenever the MeshEditor's vertex selection changes.
	The handler is also called when the listener is started with the initially selected vertex 
	and -- if nodes are selected while the listener is finalized -- when the listener is finalized 
	with an empty array.

	Adds the following methods:
	
	- finalizeVertexSelectionListener		Disables the listening and if triangles are selected, calls the onTrianglesSelected 
											handlers with an empty array. (may be safely called if already disabled).
	- getSelectedVertices					returns the array of currently selected triangle.
	- onVerticesSelected(triangles)			MultiProcedure called when the triangle selection changes. The selected triangles are given as parameter.
	- onVerticesSelected_static(triangles)	Static MultiProcedure called when the triangle selection changes. The selected triangle are given as parameter.
	- startVertexSelectionListener			Enables the listening and calls the onTrianglesSelected handlers
											with the initially selected triangles (may be safely called if already enabled) 
	- getVertexOrigin						returns the origin (Geometry.Vec3) of all selected triangles.

	\see MeshEditor Plugin
*/
HelperTraits.VertexSelectionListenerTrait := new Traits.GenericTrait("HelperTraits.VertexSelectionListenerTrait");
{
	var t = HelperTraits.VertexSelectionListenerTrait;
	
	t.attributes._vertexSelectionChangedHandler @(private) := void; 
	t.attributes._selectedVertices @(private,init) := Array;
	t.attributes._vertexOrigin @(private,init) := Geometry.Vec3;

	t.attributes.onVerticesSelected_static ::= void;
	t.attributes.onVerticesSelected @(init) := Std.MultiProcedure;

	t.attributes.startVertexSelectionListener ::= fn(){
		if(!_vertexSelectionChangedHandler){
			_vertexSelectionChangedHandler = this->fn(Array vertices){
				_selectedVertices.swap(vertices.clone());
				onVerticesSelected_static(_selectedVertices);
				onVerticesSelected(_selectedVertices);
			};
			Util.registerExtension('MeshEditor_OnVerticesSelected', _vertexSelectionChangedHandler);
			_vertexSelectionChangedHandler( MeshEditor.getSelectedVertices() );
		}
		return this;
	};
	t.attributes.finalizeVertexSelectionListener ::= fn(){
		if(_vertexSelectionChangedHandler){
			removeExtension('MeshEditor_OnVerticesSelected', _vertexSelectionChangedHandler);
			if(!_selectedVertices.empty())
				_vertexSelectionChangedHandler( [] ); //clean up by calling handler with empty array.
			_vertexSelectionChangedHandler = void;
		}
		return this;
	};
	
	t.attributes.getSelectedVertices ::= fn(){
		return _selectedVertices;
	};
	
	t.attributes._calculateVertexOrigin ::= fn() {
		if(!getSelectedMesh() || _selectedVertices.empty()) {
			_vertexOrigin.setValue(0,0,0);
			return;
		}
		var mesh = getSelectedMesh();
		var posAcc = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);	
		// TODO: handle meshes without index buffer
		var indices = mesh._getIndices();
		_vertexOrigin.setValue(0,0,0);
		foreach(_selectedVertices as var idx) {		
			_vertexOrigin += posAcc.getPosition(indices[idx]);
		}
		_vertexOrigin /= _selectedVertices.size();
	};
	
	t.attributes.getVertexOrigin ::= fn() {		
		return _vertexOrigin;
	};
		
	t.onInit += fn(obj){
		obj.onVerticesSelected_static = new MultiProcedure;
		Std.Traits.assureTrait(obj, ToolHelperTraits.NodeSelectionListenerTrait);
		Std.Traits.assureTrait(obj, HelperTraits.TriangleSelectionListenerTrait);
	
		//! \see ToolHelperTraits.NodeSelectionListenerTrait
		obj.onNodesSelected_static += fn(Array nodes){
			_calculateVertexOrigin(); 
		};
		
		obj.onVerticesSelected_static += fn(...){
			_calculateVertexOrigin(); 
		};
	};
}

// -----------------------------------------------------------------------------------

/*!	Adds methods for highlighting selected triangles.
	Adds the following methods:

	- enableHighlight()		Enables the highlighting of triangles.
	- disableHighlight()	Disables the highlighting of triangles.
	- isHighlightActive()	Returns whether the highlighting is enabled.

*/
HelperTraits.TriangleHighlightTrait := new Traits.GenericTrait("HelperTraits.TriangleHighlightTrait");
{
	var t = HelperTraits.TriangleHighlightTrait;
		
	t.attributes._revoceAfterRender @(private) := void; // void | MultiProcedure
	t.attributes._drawWireFrame @(private) := true;

	t.attributes.enableHighlight ::= fn(){
		if(!this._revoceAfterRender){
			this._revoceAfterRender = new Std.MultiProcedure;
			this._revoceAfterRender += Util.registerExtensionRevocably('PADrend_AfterRenderingPass', this->this.highlightTriangles); 
		}
		return this;
	};

	t.attributes.disableHighlight ::= fn(){
		if(this._revoceAfterRender){
			this._revoceAfterRender();
			this._revoceAfterRender = void;
		}
		return this;
	};
	t.attributes.isHighlightActive ::= fn(){
		return true & this._revoceAfterRender;
	};
	t.attributes.setDrawWireFrame ::= fn(value){
		_drawWireFrame = value;
	};
	t.attributes.highlightTriangles ::= fn(...) {
		var nodes = getSelectedNodes();
		if(nodes.empty())
			return;
		var node = nodes[0];
		if(!(node.isA(MinSG.GeometryNode)))
			return;
		var triangles = getSelectedTriangles();			
		var mesh = node.getMesh();		
		var maxCount = mesh.getPrimitiveCount();				
		
		renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
		renderingContext.multMatrix_modelToCamera(node.getWorldTransformationMatrix());
		
		renderingContext.pushAndSetLighting(false);
		renderingContext.pushAndSetDepthBuffer(true,false,Rendering.Comparison.LEQUAL);
		
		if(_drawWireFrame) {
			renderingContext.pushAndSetPolygonMode(Rendering.PolygonModeParameters.LINE);
			renderingContext.pushAndSetLine(1);
			renderingContext.pushAndSetColorMaterial(new Util.Color4f(0,0,0,1));			
			frameContext.displayMesh(mesh);			
			renderingContext.popMaterial();
			renderingContext.popLine();
			renderingContext.popPolygonMode();
		}

		renderingContext.pushAndSetColorMaterial(new Util.Color4f(1,0.5,0.5,1));
		//renderingContext.pushAndSetPolygonOffset(-1.0, -1.0);
		foreach(triangles as var tri) {
			if(tri < maxCount)
				frameContext.displayMesh(mesh,tri*3,3 );
		}
		//renderingContext.popPolygonOffset();
		renderingContext.popMaterial();
		
		renderingContext.pushAndSetPolygonMode(Rendering.PolygonModeParameters.LINE);
		renderingContext.pushAndSetLine(1);
		renderingContext.pushAndSetColorMaterial(new Util.Color4f(0,0,0,1));
		foreach(triangles as var tri) {
			if(tri < maxCount)
				frameContext.displayMesh(mesh,tri*3,3 );
		}
		renderingContext.popMaterial();
		renderingContext.popLine();
		renderingContext.popPolygonMode();
		
		renderingContext.popDepthBuffer();
		renderingContext.popLighting();
		
		renderingContext.popMatrix_modelToCamera();
	};
	t.onInit += fn(obj){
		Std.Traits.requireTrait(obj, "ToolHelperTraits.NodeSelectionListenerTrait");
		Std.Traits.requireTrait(obj, "HelperTraits.TriangleSelectionListenerTrait");
	};
}

// -----------------------------------------------------------------------------------

/*!	Adds methods for highlighting selected vertices.
	Adds the following methods:

	- enableVertexHighlight()	Enables the highlighting of vertices.
	- disableVertexHighlight()	Disables the highlighting of vertices.
	- isVertexHighlightActive()	Returns whether the highlighting is enabled.

*/
HelperTraits.VertexHighlightTrait := new Traits.GenericTrait("HelperTraits.VertexHighlightTrait");
{
	var t = HelperTraits.VertexHighlightTrait;
		
	t.attributes._revoceAfterRenderVertex @(private) := void; // void | MultiProcedure

	t.attributes.enableVertexHighlight ::= fn(){
		if(!this._revoceAfterRenderVertex){
			this._revoceAfterRenderVertex = new Std.MultiProcedure;
			this._revoceAfterRenderVertex += Util.registerExtensionRevocably('PADrend_AfterRenderingPass', this->this.highlightVertices); 
		}
		return this;
	};

	t.attributes.disableVertexHighlight ::= fn(){
		if(this._revoceAfterRenderVertex){
			this._revoceAfterRenderVertex();
			this._revoceAfterRenderVertex = void;
		}
		return this;
	};
	t.attributes.isVertexHighlightActive ::= fn(){
		return true & this._revoceAfterRenderVertex;
	};
	t.attributes.highlightVertices ::= fn(...) {
		var nodes = getSelectedNodes();
		if(nodes.empty())
			return;
		var node = nodes[0];
		if(!(node.isA(MinSG.GeometryNode)))
			return;
		var vertices = getSelectedVertices();			
		var mesh = node.getMesh();		
		var maxCount = mesh.getIndexCount();
		
		renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );
		renderingContext.multMatrix_modelToCamera(node.getWorldTransformationMatrix());
		
		renderingContext.pushAndSetLighting(false);
		renderingContext.pushAndSetDepthBuffer(true,false,Rendering.Comparison.LEQUAL);
		
		// draw wireframe
		renderingContext.pushAndSetPolygonMode(Rendering.PolygonModeParameters.LINE);
		renderingContext.pushAndSetLine(1);
		renderingContext.pushAndSetColorMaterial(new Util.Color4f(0,0,0,1));			
		frameContext.displayMesh(mesh);			
		renderingContext.popMaterial();
		renderingContext.popLine();
		renderingContext.popPolygonMode();
		renderingContext.popDepthBuffer();
		
		renderingContext.pushAndSetDepthBuffer(false,false,Rendering.Comparison.ALWAYS);
				
		//renderingContext.pushAndSetPolygonMode(Rendering.PolygonModeParameters.POINT);
		renderingContext.pushAndSetPointParameters(new Rendering.PointParameters(10));
		renderingContext.pushAndSetColorMaterial(new Util.Color4f(1,0.5,0.5,1));
		var mode = mesh.getDrawMode();
		mesh.setDrawPoints();
		foreach(vertices as var v) {
			if(v < maxCount)
				frameContext.displayMesh(mesh,v,1);
		}
		mesh.setDrawMode(mode);
		renderingContext.popMaterial();
		renderingContext.popPointParameters();
		//renderingContext.popPolygonMode();
		
		renderingContext.popDepthBuffer();
		renderingContext.popLighting();
		
		renderingContext.popMatrix_modelToCamera();
	};
	t.onInit += fn(obj){
		Std.Traits.requireTrait(obj, "ToolHelperTraits.NodeSelectionListenerTrait");
		Std.Traits.requireTrait(obj, "HelperTraits.VertexSelectionListenerTrait");
	};
}
// -----------------------------------------------------------------------------------

/*!	Adds methods to handle the transformation of triangles based on Commands.
	Adds the following methods:

	- applyVertexTransformations()			Applies all pending transformations by creating an corresponding command.
	- getTransformedVertices()				Get all vertices set by the last setTransformedVertices(...) call.
	- setTransformedVertices(Array indices)	Applies the pending transformations by calling applyVertexTransformations() and
											memorizes the new transformed vertices and their current transformations.
	- setRelTransformation(Matrix4x4)		Sets the transformation matrix for the next transformation operation and applies 
											it to the selected vertices.

	\see PADrend.CommandHandling
*/
HelperTraits.MeshTransformationHandlerTrait := new Traits.GenericTrait("HelperTraits.MeshTransformationHandlerTrait");
{
	var t = HelperTraits.MeshTransformationHandlerTrait;
	
	t.attributes._transformedMesh @(private):= void; 
	t.attributes._transformedVertices @(init,private):= Array; 
	t.attributes._vertexOrigins @(init,private):= Map; 
	t.attributes._transformMatrix @(private):= void; 
	
	t.attributes._doApplyTransformations @(private) ::= fn(){
		if(!_transformedVertices.empty() && _transformMatrix && _transformedMesh) {
				
			_resetVertices(_transformedMesh, _transformedVertices, _vertexOrigins);
			static Command = Std.module('LibUtilExt/Command');
			PADrend.executeCommand({
				Command.DESCRIPTION : "Transform vertices",
				Command.EXECUTE : 	[_transformedMesh, _transformedVertices.clone(), _transformMatrix]=>this->_transformVertices,
				Command.UNDO : 		[_transformedMesh, _transformedVertices.clone(), _vertexOrigins.clone()]=>this->_resetVertices,
			});

			//_transformedVertices.clear();
			_vertexOrigins.clear();
			_transformMatrix = void;
			_storeOldTransformations();
		}
	};
	
	t.attributes._storeOldTransformations @(private) ::= fn(){
		if(!_transformedVertices.empty()){
			_vertexOrigins.clear();
			var nodes = getSelectedNodes();
			if(nodes.empty() || !(nodes[0].isA(MinSG.GeometryNode)))
				return;
			var mesh = nodes[0].getMesh();
			var acc = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);
			foreach(_transformedVertices as var v) {
				_vertexOrigins[v] = acc.getPosition(v);
			}
		}
	};
	
	t.attributes._transformVertices ::= fn(mesh, vertices, matrix){
		var acc = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);			
		foreach(vertices as var v) {
			acc.setPosition(v, matrix.transformPosition(acc.getPosition(v)));
		}
		mesh._markAsChanged();
		_calculateOrigin(); 
	};
	
	t.attributes._resetVertices @(private) ::= fn(mesh, vertices, oldPositions){
		var acc = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);			
		foreach(vertices as var v) {
			if(oldPositions[v])
				acc.setPosition(v, oldPositions[v]);
		}
		mesh._markAsChanged();
	};
	
	t.attributes.setRelTransformation ::= fn(mat){
		_transformMatrix = mat;
		if(!_transformedVertices.empty() && !_vertexOrigins.empty() && _transformMatrix && _transformedMesh) {
			_resetVertices(_transformedMesh, _transformedVertices, _vertexOrigins);
			_transformVertices(_transformedMesh, _transformedVertices, _transformMatrix);
		}
		return this;	
	};
	
	t.attributes.applyVertexTransformations ::= fn(){
		_doApplyTransformations();
		return this;	
	};
	
	t.attributes.setTransformedVertices ::= fn(Array indices){
		_doApplyTransformations();
		_transformedVertices.swap(indices.clone());
		_storeOldTransformations();
		return this;	
	};
	
	t.attributes.getTransformedVertices ::= 	fn(){ return _transformedVertices; };
	t.attributes.getTransformedMesh ::= 	fn(){ return _transformedMesh; };
	
	t.onInit += fn(obj){
		Std.Traits.assureTrait(obj, HelperTraits.TriangleSelectionListenerTrait);
		Std.Traits.assureTrait(obj,ToolHelperTraits.NodeSelectionListenerTrait);
		Std.Traits.assureTrait(obj, HelperTraits.VertexSelectionListenerTrait);
	
		//! \see HelperTraits.TriangleSelectionListenerTrait
		obj.onTrianglesSelected_static += fn(Array triangles){
			if(triangles.empty() || !_transformedMesh) {
				setTransformedVertices([]); 
				return;
			}
			// TODO: handle meshes without index buffer
			var indices = _transformedMesh._getIndices();
			var vertices = new Set;
			foreach(triangles as var t) {
				vertices += indices[3*t+0];
				vertices += indices[3*t+1];
				vertices += indices[3*t+2];
			}
			setTransformedVertices(vertices.toArray()); 
		};
	
		//! \see HelperTraits.TriangleSelectionListenerTrait
		obj.onVerticesSelected_static += fn(Array vertices){
			if(vertices.empty() || !_transformedMesh) {
				setTransformedVertices([]); 
				return;
			}
			var indices = _transformedMesh._getIndices();
			var vIndices = new Set;
			foreach(vertices as var v) {
				vIndices += indices[v];
			}
			setTransformedVertices(vIndices.toArray()); 
		};
		
		//! \see ToolHelperTraits.NodeSelectionListenerTrait
		obj.onNodesSelected_static += fn(Array nodes){
			if(nodes.empty() || !(nodes[0].isA(MinSG.GeometryNode))) {
				_transformedMesh = void;
				setTransformedVertices([]);
				return;
			}
			_transformedMesh = nodes[0].getMesh();
		};
	};
	
}

// -----------------------------------------------------------------------------------

/*! Adds and initializes a bunch of traits useful for a mesh edit tool.

	- general UIEvent listening				 		\see HelperTraits.UIEventListenerTrait
	- general UITool enabling and disabling 		\see ToolHelperTraits.UIToolTrait
	- per frame actions								\see ToolHelperTraits.FrameListenerTrait
	- extension to the right click context menu		\see ToolHelperTraits.ContextMenuProviderTrait
	- an interactive meta node						\see ToolHelperTraits.MetaNodeContainerTrait
	- a listener for changed node selections		\see ToolHelperTraits.NodeSelectionListenerTrait
	- a listener for changed triangle selections	\see HelperTraits.TriangleSelectionListenerTrait
	- highlighting of selected triangles			\see HelperTraits.TriangleHighlightTrait

*/
HelperTraits.GenericMeshEditTrait := new Traits.GenericTrait("HelperTraits.GenericMeshEditTrait");{
	var t = HelperTraits.GenericMeshEditTrait;
	
	t.attributes.setVertexEditMode ::= fn(value){ 
		if(value) {
			disableHighlight();
			finalizeTriangleSelectionListener();
			startVertexSelectionListener();
			enableVertexHighlight();
		} else {
			disableVertexHighlight();
			finalizeVertexSelectionListener();
			startTriangleSelectionListener();
			enableHighlight();
		}
	};
	
	t.onInit += fn(obj){
		//! \see HelperTraits.UIEventListenerTrait
		Std.Traits.addTrait(obj,HelperTraits.UIEventListenerTrait);
	
		//! \see ToolHelperTraits.UIToolTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.UIToolTrait);

		//! \see ToolHelperTraits.FrameListenerTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.FrameListenerTrait);

		//! \see ToolHelperTraits.ContextMenuProviderTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.ContextMenuProviderTrait);

		//! \see ToolHelperTraits.MetaNodeContainerTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.MetaNodeContainerTrait);

		//! \see ToolHelperTraits.NodeSelectionListenerTrait
		Std.Traits.addTrait(obj,ToolHelperTraits.NodeSelectionListenerTrait);

		//! \see ToolHelperTraits.NodeTransformationHandlerTrait
		//Traits.addTrait(obj,ToolHelperTraits.NodeTransformationHandlerTrait);
				
		//! \see HelperTraits.TriangleSelectionListenerTrait
		Std.Traits.addTrait(obj, HelperTraits.TriangleSelectionListenerTrait);
		
		//! \see HelperTraits.TriangleHighlightTrait
		Std.Traits.addTrait(obj, HelperTraits.TriangleHighlightTrait);
		
		//! \see HelperTraits.VertexSelectionListenerTrait
		Std.Traits.addTrait(obj, HelperTraits.VertexSelectionListenerTrait);
		
		//! \see HelperTraits.VertexHighlightTrait
		Std.Traits.addTrait(obj, HelperTraits.VertexHighlightTrait);
		
		//! \see ToolHelperTraits.NodeSelectionListenerTrait
		obj.onNodesSelected_static += fn(Array nodes){
			if(nodes.empty() || !(nodes[0].isA(MinSG.GeometryNode))) {
				// TODO: remember last state
				//MeshEditor.clearTriangleSelection();
			}
		};

		//! \see HelperTraits.TriangleSelectionListenerTrait
		obj.onTrianglesSelected_static += fn(Array triangles){
			if(triangles.empty()){
				//! \see ToolHelperTraits.FrameListenerTrait
				disableFrameListener();

				//! \see ToolHelperTraits.MetaNodeContainerTrait
				disableMetaNode();
			}else{
				//! \see ToolHelperTraits.FrameListenerTrait
				enableFrameListener();

				//! \see ToolHelperTraits.MetaNodeContainerTrait
				enableMetaNode();
			}
		};

		//! \see HelperTraits.VertexSelectionListenerTrait
		obj.onVerticesSelected_static += fn(Array vertices){
			if(vertices.empty()){
				//! \see ToolHelperTraits.FrameListenerTrait
				disableFrameListener();

				//! \see ToolHelperTraits.MetaNodeContainerTrait
				disableMetaNode();
			}else{
				//! \see ToolHelperTraits.FrameListenerTrait
				enableFrameListener();

				//! \see ToolHelperTraits.MetaNodeContainerTrait
				enableMetaNode();
			}
		};
		
		//! \see ToolHelperTraits.UIToolTrait
		obj.onToolActivation_static += fn(){
			//! \see HelperTraits.UIEventListenerTrait
			enableUIEventListener();
			
			//! \see ToolHelperTraits.NodeSelectionListenerTrait
			startNodeSelectionListener();
			
			//! \see ToolHelperTraits.ContextMenuProviderTrait
			enableContextMenu();
			
			//! \see HelperTraits.TriangleSelectionListenerTrait
			startTriangleSelectionListener();
			
			//! \see HelperTraits.TriangleHighlightTrait
			enableHighlight();
		};		
		
		//! \see ToolHelperTraits.UIToolTrait
		obj.onToolDeactivation_static += fn(){
			disableVertexHighlight();
			finalizeVertexSelectionListener();
			
			//! \see HelperTraits.TriangleHighlightTrait
			disableHighlight();
			
			//! \see HelperTraits.TriangleSelectionListenerTrait
			finalizeTriangleSelectionListener();
			
			//! \see ToolHelperTraits.ContextMenuProviderTrait
			disableContextMenu();

			//! \see ToolHelperTraits.NodeSelectionListenerTrait
			finalizeNodeSelectionListener();
			
			//! \see HelperTraits.UIEventListenerTrait
			disableUIEventListener();
		};	
		
	};
	
	
	/*! UIEvent function for selecting triangles of a mesh.
	*/
	t.attributes.selectTrianglesFunction ::= fn(evt) {
		if(	evt.type==Util.UI.EVENT_MOUSE_BUTTON && evt.button == Util.UI.MOUSE_BUTTON_LEFT){
			if(evt.pressed){
				var nodes = getSelectedNodes();
				if(nodes.empty())
					return false;
				var node = nodes[0];
				if(!(node.isA(MinSG.GeometryNode)))
					return false;								
				
				if(this.getMetaNode() && Picking.pickNode( [evt.x,evt.y], this.getMetaNode() ))
					return false;
					
				var mesh = node.getMesh();
				var mat = node.getWorldToLocalMatrix();
				var ray = Picking.getPickingRay([evt.x, evt.y]);
				ray.setOrigin(mat.transformPosition(ray.getOrigin()));
				ray.setDirection(mat.transformDirection(ray.getDirection()).normalize());
									
				var triangle = Rendering.getFirstTriangleIntersectingRay(mesh, ray);
				
				if(PADrend.getEventContext().isShiftPressed()){
					if(triangle >= 0) 
						if(MeshEditor.isTriangleSelected(triangle))
							MeshEditor.removeTrianglesFromSelection([triangle]);
						else
							MeshEditor.addSelectedTriangles([triangle]);
				} else {
					if(triangle >= 0 && (!MeshEditor.isTriangleSelected(triangle) || MeshEditor.getSelectedTriangles().size() > 1 )) 
						MeshEditor.selectTriangles([triangle]);
					else
						MeshEditor.clearTriangleSelection();
				}
				return true;
			}
		}
		return false;
	};
	
	
	/*! UIEvent function for selecting vertices of a mesh.
	*/
	t.attributes.selectVerticesFunction ::= fn(evt) {
		if(	evt.type==Util.UI.EVENT_MOUSE_BUTTON && evt.button == Util.UI.MOUSE_BUTTON_LEFT){
			if(evt.pressed){
				var nodes = getSelectedNodes();
				if(nodes.empty())
					return false;
				var node = nodes[0];
				if(!(node.isA(MinSG.GeometryNode)))
					return false;						
				if(this.getMetaNode() && Picking.pickNode( [evt.x,evt.y], this.getMetaNode() ))
					return false;
					
				var mesh = node.getMesh();
				var mat = node.getWorldToLocalMatrix();
				var ray = Picking.getPickingRay([evt.x, evt.y]);
				ray.setOrigin(mat.transformPosition(ray.getOrigin()));
				ray.setDirection(mat.transformDirection(ray.getDirection()).normalize());
									
				var triangle = Rendering.getFirstTriangleIntersectingRay(mesh, ray);
				
				var vertex = -1;
				if(triangle >= 0) {
					var acc = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);
					var indices = mesh._getIndices();
					var v1 = triangle*3+0;
					var v2 = triangle*3+1;
					var v3 = triangle*3+2;
					vertex = v1;
					var dist = ray.distance(acc.getPosition(indices[v1]));
					if(ray.distance(acc.getPosition(indices[v2])) < dist) {
						dist = ray.distance(acc.getPosition(indices[v2]));
						vertex = v2;
					}
					if(ray.distance(acc.getPosition(indices[v3])) < dist) {
						//dist = ray.distance(acc.getPosition(v3));
						vertex = v3;
					}
				}
				
				if(PADrend.getEventContext().isShiftPressed()){
					if(vertex >= 0) 
						if(MeshEditor.isVertexSelected(vertex))
							MeshEditor.removeVerticesFromSelection([vertex]);
						else
							MeshEditor.addSelectedVertices([vertex]);
				} else {
					if(vertex >= 0 && (!MeshEditor.isVertexSelected(vertex) || MeshEditor.getSelectedVertices().size() > 1 )) 
						MeshEditor.selectVertices([vertex]);
					else
						MeshEditor.clearVertexSelection();
				}
				return true;
			}
		}
		return false;
	};
}

// -----------------------------------------------------------------------------------


return HelperTraits;