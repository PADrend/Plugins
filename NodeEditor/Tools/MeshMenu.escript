/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2012,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 David Maicher
 * Copyright (C) 2009-2010 Jan Krems
 * Copyright (C) 2010-2011 Jonas Knoll
 * Copyright (C) 2010 Paul Justus
 * Copyright (C) 2010-2012 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2015 Sascha Brandt <myeti@mail.uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


gui.register('NodeEditor_NodeToolsMenu.meshes',fn(Array nodes){
	return nodes.empty() ? [] : [
		'----',
		{
			GUI.TYPE : GUI.TYPE_MENU,
			GUI.LABEL : "Mesh tools",
			GUI.MENU : 'NodeEditor_MeshToolsMenu',
			GUI.MENU_WIDTH : 150
		}
	];
});

// ------------------------------------------------------------------------------------------------
gui.register('NodeEditor_MeshToolsMenu.meshModifications',[
	"*Mesh modification*",
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Apply material states to meshes",
		GUI.ON_CLICK : fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var node)
				MinSG.materialToVertexColor(node);
		},
		GUI.TOOLTIP :  "Moves the colorinformations from materialstates \n"+
						"into the vertexdata of the meshes."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Bake transformations into meshes",
		GUI.ON_CLICK : fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var node)
				MinSG.bakeTransformations(node);
		},
		GUI.TOOLTIP :  "Combines group transformations of inner nodes \n"+
						"into global transformations of the meshes."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Reset Mesh Origins",
		GUI.ON_CLICK : fn(){
			showWaitingScreen();
			var nodes = new Set;
			foreach(NodeEditor.getSelectedNodes() as var node)
				nodes.merge(MinSG.collectGeoNodes(node));
			foreach(nodes as var node) {
				var mesh = node.getMesh();
				var bb = mesh.getBoundingBox();
				var matrix = new Geometry.Matrix4x4();
				matrix.translate(-bb.getCenter());
				Rendering.transformMesh(mesh, matrix);
				node.setMesh(mesh);
				node.moveLocal(bb.getCenter());
			}
		},
		GUI.TOOLTIP :  "Sets the origin of the meshes to its bounding box center."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Calculate tangent-space vectors",
		GUI.ON_CLICK : fn() {
			var data = new ExtObject();
			data.tanName := Rendering.VertexAttributeIds.TANGENT;
			data.uvName := Rendering.VertexAttributeIds.TEXCOORD0;

			var p = gui.createPopupWindow( 400, 120,"Tangent space calculation" );
			p.addOption("Create tangent-space vectors for selected meshes");

			p.addOption({
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "Source uv-coordinates name",
				GUI.DATA_OBJECT : data,
				GUI.DATA_ATTRIBUTE : $uvName,
				GUI.TOOLTIP : "Meshes' texture coordinate attribute's name"
			});
			p.addOption({
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "Target tangent name",
				GUI.DATA_OBJECT : data,
				GUI.DATA_ATTRIBUTE : $tanName,
				GUI.TOOLTIP : "Meshes' new tangent vector attribute's name"
			});
			p.addAction("Create vectors",data->fn(){
				out("Create tangent vectors [");

				foreach( NodeEditor.getSelectedNodes() as var subtree){
					foreach(MinSG.collectGeoNodes(subtree) as var geoNode){
						var mesh = geoNode.getMesh();
						try{
							Rendering.calculateTangentVectors(mesh,uvName,tanName);
						}
						catch(e){
							Runtime.warn(e);
						}
						out(".");
					}
				}
				outln("]");

				return true;

			});
			p.addAction("Close");
			p.init();
		},
		GUI.TOOLTIP : "Create tangent-space vectors \n from the meshes' normals and texture coordinates"
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Merge meshes",
		GUI.ON_CLICK : fn() {
			showWaitingScreen();
			var nodes=MinSG.collectGeoNodes(NodeEditor.getSelectedNode());
			var a=[];
			var t=[];
			foreach(nodes as var node){
				a+=node.getMesh();
				t+=node.getWorldTransformationMatrix();
			}
			var m=Rendering.combineMeshes(a,t);
			var g=new MinSG.GeometryNode();
			g.setMesh(m);
			var s=new MinSG.ListNode();
			s.name:="Merged scene";
			s.addChild(g);
			PADrend.registerScene(s);
			PADrend.selectScene(s);
		},
		GUI.TOOLTIP : "Merge all meshes (below the first selected node) which have the same vertex description"
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Optimize meshes",
		GUI.ON_CLICK : fn(){
			showWaitingScreen();
			foreach(NodeEditor.getSelectedNodes() as var node){
				MinSG.optimizeMeshes(node);
			}
		},
		GUI.TOOLTIP : "Optimize meshes for vertex-cache locality."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Reverse mesh winding",
		GUI.ON_CLICK : fn() {
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				foreach(MinSG.collectGeoNodes(subtree) as var geoNode){
					var mesh = geoNode.getMesh();
					Rendering.reverseMeshWinding(mesh);
					out(".");
				}
			}
			outln();
		},
		GUI.TOOLTIP : "Reverse the order of vertices of each triangle in all selected geometry nodes."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Recalculate normals",
		GUI.ON_CLICK : fn() {
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				foreach(MinSG.collectGeoNodes(subtree) as var geoNode){
					var mesh = geoNode.getMesh();
					Rendering.calculateNormals(mesh);
					out(".");
				}
			}
			outln();
		},
		GUI.TOOLTIP : "Recalculate normals of all selected geometry nodes."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Remove duplicated vertices",
		GUI.ON_CLICK : fn() {
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				foreach(MinSG.collectGeoNodes(subtree) as var geoNode){
					var mesh = geoNode.getMesh();
					Rendering.eliminateDuplicateVertices(mesh);
					out(".");
				}
			}
			outln();
		}
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Merge close vertices",
		GUI.ON_CLICK : fn() {
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				foreach(MinSG.collectGeoNodes(subtree) as var geoNode){
					var mesh = geoNode.getMesh();
					Rendering.mergeCloseVertices(mesh);
					out(".");
				}
			}
			outln();
		},
		GUI.TOOLTIP : "Recalculate normals of all selected geometry nodes."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Embed meshes",
		GUI.TOOLTIP : "Removes the filenames from meshes so that they are embedded into the minsg-file.",
		GUI.ON_CLICK : fn() {
			var count = 0;
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				foreach( MinSG.collectGeoNodes(subtree) as var geoNode){
					var filename = geoNode.getMesh().getFileName();
					if(!filename.empty()){
						outln("Removing '"+filename.toString()+"'.");
						geoNode.getMesh().setFileName();
						++count;
					}
				}
			}
			PADrend.message(""+count+" meshes embedded.");

		}
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Split connected parts",
		GUI.TOOLTIP : "Split a single selected mesh into connected sub-meshes.",
		GUI.ON_CLICK : fn() {
			var n = NodeEditor.getSelectedNode();
			if(!n.isA(MinSG.GeometryNode)){
				Runtime.warn("SplitMesh: select single GeometryNode.");
				return;
			}
			showWaitingScreen();
			var m = n.getMesh();
			var t = new Util.Timer;
			var parts = Std.module('LibRenderingExt/splitMeshIntoConnectedParts')(m,0.001);
			if(parts.count()<=1){
				PADrend.message("SplitMesh: Only one conntected component. ("+t.getSeconds()+")");
				return;
			}
			var states = n.getStates();
			foreach( parts as var m2){
				var n2 = new MinSG.GeometryNode(m2);
				n.getParent() += n2;
				n2.setRelTransformation( n.getRelTransformationSRT() );
				foreach(states as var s)
					n2 += s;
			}
			PADrend.message("SplitMesh: Splitted into ",parts.count()," conntected component. ("+t.getSeconds()+")");
		}
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Split polygons",
		GUI.TOOLTIP: "Split the polygons, whoch have side length > Max. poly. side length",
		GUI.ON_CLICK : fn() {
			static getMaxSideLength = fn(){
				var maxSideLengths = [];
				foreach( NodeEditor.getSelectedNodes() as var node){
					if(node.isA(MinSG.GeometryNode))
						maxSideLengths += Rendering.getLongestSideLength(node.getMesh());
				}
				return  maxSideLengths.max();
			};

			var lengthWrapper = new Std.DataWrapper(getMaxSideLength());
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_POPUP_DIALOG,
				GUI.LABEL : "Split polygons",
				GUI.SIZE : [350, 100],
				GUI.OPTIONS :[
						{
							GUI.TYPE : GUI.TYPE_NUMBER,
							GUI.LABEL : "Max. poly. side length",
							GUI.DATA_WRAPPER: lengthWrapper,
							GUI.WIDTH : 100
						}

					],
				GUI.ACTIONS		:	[
						["Split polygon", [lengthWrapper]=>fn(lengthWrapper){
								var nodes = [];
								foreach( NodeEditor.getSelectedNodes() as var subtree)
									nodes.append( MinSG.collectNodes(subtree,MinSG.GeometryNode) );

								foreach(nodes as var node){
									Rendering.splitLargeTriangles(node.getMesh(), lengthWrapper());
									out(".");
								}
								return true;

							}
						],
						["Refresh",[lengthWrapper]=>fn(lengthWrapper){
							lengthWrapper(getMaxSideLength());
							return true;
							}
						],

						"Cancel"
					]
				});


		}
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Swap meshes",
		GUI.ON_CLICK : fn(){
			showWaitingScreen();
			var nodes = NodeEditor.getSelectedNodes();
			if(nodes.count() != 2 || !(nodes[0] ---|> MinSG.GeometryNode) || !(nodes[1] ---|> MinSG.GeometryNode)) {
				PADrend.message("Please select 2 geometry nodes");
				return;
			}
			var mesh1 = nodes[0].getMesh();
			var mesh2 = nodes[1].getMesh();
			nodes[0].setMesh(mesh2);
			nodes[1].setMesh(mesh1);
		},
		GUI.TOOLTIP : "Swaps the meshes of two selected geometry nodes.",
	},
	'----'
]);

// -------------------------------------------------------------------------------

gui.register('NodeEditor_MeshToolsMenu.textures',[
	"*Textures etc.*",
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "UV Mapping - Camera projection",
		GUI.ON_CLICK : fn() {
			var data = new ExtObject();
			data.scale := 1.0;
			data.attrName := Rendering.VertexAttributeIds.TEXCOORD0;

			var p = gui.createPopupWindow( 400, 120,"UV Mapping - Camera projection" );
			p.addOption("Create texture coordinates by using the current camera matrix");
			p.addOption({
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.LABEL : "Scale ",
				GUI.RANGE : [0, 10],
				GUI.DATA_OBJECT : data,
				GUI.DATA_ATTRIBUTE : $scale,
				GUI.TOOLTIP : "Texture scale"
			});
			p.addOption({
				GUI.TYPE : GUI.TYPE_TEXT,
				GUI.LABEL : "uv attr name",
				GUI.DATA_OBJECT : data,
				GUI.DATA_ATTRIBUTE : $attrName
			});
			p.addAction("Create coordinates",data->fn(){
				out("Create uv coordinates for attribute '"+attrName+"' [");
				renderingContext.pushAndSetMatrix_modelToCamera( renderingContext.getMatrix_worldToCamera() );

				var matrix=(new Geometry.Matrix4x4()).scale(scale,scale,scale) *  renderingContext.getMatrix_cameraToClipping() * renderingContext.getMatrix_worldToCamera() ;

				foreach( NodeEditor.getSelectedNodes() as var subtree){
					var geoNodes=MinSG.collectGeoNodes(subtree);
					foreach(geoNodes as var geoNode){
						var mesh = geoNode.getMesh();

						Rendering.calculateTextureCoordinates_projection(mesh, attrName, matrix * geoNode.getWorldTransformationMatrix() );
						out(".");
					}

				}
				outln("]");
				renderingContext.popMatrix_modelToCamera();

				return true;

			});
			p.addAction("Close");
			p.init();
		},
		GUI.TOOLTIP : "Create texture coordinates by using the current camera matrix."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Flip TexCoord 0",
		GUI.ON_CLICK : fn() {
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				var geoNodes=MinSG.collectGeoNodes(subtree);
				foreach(geoNodes as var geoNode){
					var mesh = geoNode.getMesh();
					var acc = Rendering.TexCoordAttributeAccessor.create(mesh,Rendering.VertexAttributeIds.TEXCOORD0);

					for(var i = 0;acc.checkRange(i);++i){
						var p = acc.getCoordinate(i);
						p.setY(1 - p.getY());
						acc.setCoordinate(i,p);

					}
					mesh._markAsChanged();
					out(".");
				}
			}
			outln();
		},
		GUI.TOOLTIP : "Flip the y-texture coordinate to repair some objects."
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Scale texture coords *0.9 ",
		GUI.ON_CLICK : fn() {
			var meshes = new Std.Set;
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				foreach(MinSG.collectGeoNodes(subtree) as var geoNode){
					meshes += geoNode.getMesh();
				}
			}
			foreach(meshes as var mesh){
				var acc = Rendering.TexCoordAttributeAccessor.create(mesh,Rendering.VertexAttributeIds.TEXCOORD0);
				for(var i = 0;acc.checkRange(i);++i)
					acc.setCoordinate(i, acc.getCoordinate(i)*0.9);
				mesh._markAsChanged();
				out(".");
			}
			outln();
		},
		GUI.TOOLTIP : "Flip the y-texture coordinate to repair some objects."
	},{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Scale texture coords /0.9 ",
		GUI.ON_CLICK : fn() {
			var meshes = new Std.Set;
			foreach(NodeEditor.getSelectedNodes() as var subtree){
				foreach(MinSG.collectGeoNodes(subtree) as var geoNode){
					meshes += geoNode.getMesh();
				}
			}
			foreach(meshes as var mesh){
				var acc = Rendering.TexCoordAttributeAccessor.create(mesh,Rendering.VertexAttributeIds.TEXCOORD0);
				for(var i = 0;acc.checkRange(i);++i)
					acc.setCoordinate(i, acc.getCoordinate(i)/0.9);
				mesh._markAsChanged();
				out(".");
			}
			outln();
		},
		GUI.TOOLTIP : "Flip the y-texture coordinate to repair some objects."
	},
	'----'
]);
// -------------------------------------

gui.register('NodeEditor_MeshToolsMenu.export',[
	"*Mesh export*",
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Save Mesh as .mmf",
		GUI.ON_CLICK : fn(){
			var node = NodeEditor.getSelectedNode();
			if(! (node.isA(MinSG.GeometryNode)) ){
				outln("No GeometryNode selected!");
				return;
			}
			var mesh = node.getMesh();
			if(!mesh){
				outln("No Mesh available!");
				return;
			}
		
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_FILE_DIALOG,
				GUI.LABEL : "Filename for mesh export",
				GUI.ENDINGS : [".mmf"],
				GUI.FILENAME : (mesh.getFileName().getFile().empty() || mesh.getFileName().getEnding()!='mmf') ? "new.mmf" : mesh.getFileName().getFile(),
				GUI.DIR : mesh.getFileName().getDir().empty() ? PADrend.getDataPath() : mesh.getFileName().getDir(),
				GUI.ON_ACCEPT : [mesh]=>fn(mesh,filename) {
					outln("Exporting ",mesh,"->",filename);
					showWaitingScreen();
					Rendering.saveMesh(mesh,filename);
				}
			});
		},
		GUI.TOOLTIP :  "Save the mesh of the selected GeometryNode as .mmf"
	},
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Save Mesh as .ply",
		GUI.ON_CLICK : fn(){
			var node = NodeEditor.getSelectedNode();
			if(! (node.isA(MinSG.GeometryNode)) ){
				outln("No GeometryNode selected!");
				return;
			}
			var mesh = node.getMesh();
			if(!mesh){
				outln("No Mesh available!");
				return;
			}
		
			gui.openDialog({
				GUI.TYPE : GUI.TYPE_FILE_DIALOG,
				GUI.LABEL : "Filename for mesh export",
				GUI.ENDINGS : [".ply"],
				GUI.FILENAME : (mesh.getFileName().getFile().empty() || mesh.getFileName().getEnding()!='ply') ? "new.ply" : mesh.getFileName().getFile(),
				GUI.DIR : mesh.getFileName().getDir().empty() ? PADrend.getDataPath() : mesh.getFileName().getDir(),
				GUI.ON_ACCEPT : [mesh]=>fn(mesh,filename) {
					outln("Exporting ",mesh,"->",filename);
					showWaitingScreen();
					Rendering.saveMesh(mesh,filename);
				}
			});
		},
		GUI.TOOLTIP :  "Save the mesh of the selected GeometryNode as .ply"
	},
	'----'
]);
// -----------------------------------------------------------------------------------

if( Rendering.isSet($simplifyMesh)){
	gui.register('NodeEditor_MeshToolsMenu.meshSimplifications',[
		"*Mesh simplification*",
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Mesh Simplification",
			GUI.ON_CLICK : fn() {
				var node=NodeEditor.getSelectedNode();

				if(! (node.isA(MinSG.GeometryNode)) ){
					outln("No geometry node!!!");
					return;
				}

				var data=new ExtObject();
				data.node := NodeEditor.getSelectedNode();
				data.triangleCount := node.getTriangleCount();
				data.threshold := 0;
				data.useOptPos := true;
				data.maxAngle := 0.1;
				var height = 175;
				var p=gui.createPopupWindow( 400, height,"Mesh Simplification: "+ NodeEditor.getString(node) );
				p.addOption({
					GUI.LABEL : "New number of triangles: ",
					GUI.TYPE : GUI.TYPE_RANGE,
					GUI.RANGE : [0, node.getTriangleCount()],
					'steps' : node.getTriangleCount(),
					'object': data,
					'attr' : $triangleCount,
					'tooltip' : "New mesh will have at most this number of triangles."
				});
				p.addOption({
					GUI.LABEL : "Threshold: ",
					'input' : 'number',
					'object': data,
					'attr' : $threshold,
					'tooltip' : "Maximum distance of neighbors not connected by an edge.\n"+
								"Current bounding box extension is: "+node.getMesh().getBoundingBox().getExtentMax()
				});
				p.addOption({
					GUI.LABEL : "Maximum angle of face rotation: ",
					GUI.TYPE : GUI.TYPE_RANGE,
					GUI.RANGE : [-1, 1],
					'steps' : 100,
					'object': data,
					'attr' : $maxAngle,
					'tooltip' : "Sets the maximum angle a face may rotate per merge step.\n"+
								"Value is arccosine of angle -1=180 Degrees, 1=0 Degrees\n"+
								"Increase attribute to preserve correct flat surfaces"
				});
				data.weightVertex := 50.0;
				p.addOption({
					GUI.LABEL : "Weight of position: ",
					GUI.TYPE : GUI.TYPE_RANGE,
					GUI.RANGE : [1.0, 100.0],
					'steps' : 99,
					'object': data,
					'attr' : $weightVertex,
					'tooltip' : "Weight the vertex position has on merge cost."
				});
				if(node.getMesh().getVertexDescription().getAttribute(Rendering.VertexAttributeIds.NORMAL)){
					height += 20;
					data.weightNormal := 50.0;
					p.addOption({
						GUI.LABEL : "Weight of normal: ",
						GUI.TYPE : GUI.TYPE_RANGE,
						GUI.RANGE : [0.0, 100.0],
						'steps' : 100,
						'object': data,
						'attr' : $weightNormal,
						'tooltip' : "Weight the normal has on merge cost. Set to '0' so it will be ignored (faster)."
					});
				}else{
					data.weightNormal := 0.0;
				}
				if(node.getMesh().getVertexDescription().getAttribute(Rendering.VertexAttributeIds.COLOR)){
					height += 20;
					data.weightColor := 50.0;
					p.addOption({
						GUI.LABEL : "Weight of color: ",
						GUI.TYPE : GUI.TYPE_RANGE,
						GUI.RANGE : [0.0, 100.0],
						'steps' : 100,
						'object': data,
						'attr' : $weightColor,
						'tooltip' : "Weight the color has on merge cost. Set to '0' so it will be ignored (faster)."
					});
				}else{
					data.weightColor := 0.0;
				}
				if(node.getMesh().getVertexDescription().getAttribute(Rendering.VertexAttributeIds.TEXCOORD0)){
					height += 20;
					data.weightTex0 := 50.0;
					p.addOption({
						GUI.LABEL : "Weight of texture coordinates: ",
						GUI.TYPE : GUI.TYPE_RANGE,
						GUI.RANGE : [0.0, 100.0],
						'steps' : 100,
						'object': data,
						'attr' : $weightTex0,
						'tooltip' : "Weight the texture coordinates have on merge cost. Set to '0' so it will be ignored (faster)."
					});
				}else{
					data.weightTex0 := 0.0;
				}
				data.weightBoundary := 50.0;
				p.addOption({
					GUI.LABEL : "Weight of boundary: ",
					GUI.TYPE : GUI.TYPE_RANGE,
					GUI.RANGE : [0.0, 100],
					'steps' : 100,
					'object': data,
					'attr' : $weightBoundary,
					'tooltip' : "Weight boundaries have on merge cost."
				});
				p.addOption({
					GUI.LABEL : "Use optimal positioning: ",
					'input' : 'bool',
					'object': data,
					'attr' : $useOptPos,
					'tooltip' : "Enables calculation of optimal vertex positioning - may take longer."
				});
				p.addAction( "Simpify",
					data->fn(){
						showWaitingScreen();
						var weights = new Array();
						weights[0] = weightVertex;
						weights[1] = weightNormal;
						weights[2] = weightColor;
						weights[3] = weightTex0;
						weights[4] = weightBoundary;
						var m2 = Rendering.simplifyMesh(node.getMesh(), triangleCount, threshold, useOptPos, maxAngle, weights);
						if(m2!=void){
							node.setMesh(m2);
						}
					}
				);
				p.addAction( "Cancel" );
				p.setHeight(height);
				p.init();
				},
				GUI.TOOLTIP : "Mesh simplification using quadric error metrics"
			},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Mesh Simplification Test",
			GUI.ON_CLICK : fn() {
				var node=NodeEditor.getSelectedNode();

				if(! (node.isA(MinSG.GeometryNode)) ){
					outln("No geometry node!!!");
					return;
				}

				var data=new ExtObject();
				data.node := NodeEditor.getSelectedNode();
				data.window := gui.createWindow(300, 250, "Mesh Simplification Test: "+NodeEditor.getString(node));
				data.window.setPosition(500,200);
				var p = gui.createPanel(300, 250, GUI.AUTO_LAYOUT);
				data.window.add(p);

				p.nextColumn();
				var min = gui.createLabel(50, 15, "Min");
				min.setTooltip("Iteration starts from min value.\nMin value is used when step width==0.");
				p.add(min);
				p.nextColumn();
				var max = gui.createLabel(50, 15, "Max");
				max.setTooltip("Iteration ends at max value.");
				p.add(max);
				p.nextColumn();
				var step = gui.createLabel(50, 15, "Step Width");
				step.setTooltip("Iteration will proceed by step width.\nSet step width to 0 to not iterate this parameter and use min only.");
				p.add(step);
				p.nextRow();

				var triangleLabel = gui.createLabel(80, 15, "# Triangles:");
				triangleLabel.setTooltip("Has to be in range [0, #Triangles of Mesh].");
				p.add(triangleLabel);
				p.nextColumn();
				data.triangleMin := gui.createTextfield(60, 15, data.node.getTriangleCount());
				p.add(data.triangleMin);
				p.nextColumn();
				data.triangleMax := gui.createTextfield(60, 15, data.node.getTriangleCount());
				p.add(data.triangleMax);
				p.nextColumn();
				data.triangleStep := gui.createTextfield(60, 15, 0);
				p.add(data.triangleStep);
				p.nextRow();

				var thresholdLabel = gui.createLabel(80, 15, "Threshold:");
				thresholdLabel.setTooltip("Has to be >=0.");
				p.add(thresholdLabel);
				p.nextColumn();
				data.thresholdMin := gui.createTextfield(60, 15, 0);
				p.add(data.thresholdMin);
				p.nextColumn();
				data.thresholdMax := gui.createTextfield(60, 15, data.node.getMesh().getBoundingBox().getExtentMax());
				p.add(data.thresholdMax);
				p.nextColumn();
				data.thresholdStep := gui.createTextfield(60, 15, 0);
				p.add(data.thresholdStep);
				p.nextRow();

				var ffLabel = gui.createLabel(80, 15, "Flip face:");
				ffLabel.setTooltip("Has to be in range of [-1, 1].");
				p.add(ffLabel);
				p.nextColumn();
				data.flipMin := gui.createTextfield(60, 15, 0.1);
				p.add(data.flipMin);
				p.nextColumn();
				data.flipMax := gui.createTextfield(60, 15, 1);
				p.add(data.flipMax);
				p.nextColumn();
				data.flipStep := gui.createTextfield(60, 15, 0);
				p.add(data.flipStep);
				p.nextRow();

				var posLabel = gui.createLabel(80, 15, "Vertex weight:");
				posLabel.setTooltip("Weights >0 are relative to other weights.");
				p.add(posLabel);
				p.nextColumn();
				data.posMin := gui.createTextfield(60, 15, 0);
				p.add(data.posMin);
				p.nextColumn();
				data.posMax := gui.createTextfield(60, 15, 100);
				p.add(data.posMax);
				p.nextColumn();
				data.posStep := gui.createTextfield(60, 15, 0);
				p.add(data.posStep);
				p.nextRow();

				data.normalMin := gui.createTextfield(60, 15, 0);
				data.normalMax := gui.createTextfield(60, 15, 100);
				data.normalStep := gui.createTextfield(60, 15, 0);
				if(node.getMesh().getVertexDescription().getAttribute(Rendering.VertexAttributeIds.NORMAL)){
					var normalLabel = gui.createLabel(80, 15, "Normal weight:");
					normalLabel.setTooltip("Weights >0 are relative to other weights.");
					p.add(normalLabel);
					p.nextColumn();
					p.add(data.normalMin);
					p.nextColumn();
					p.add(data.normalMax);
					p.nextColumn();
					p.add(data.normalStep);
					p.nextRow();
				}

				data.colorMin := gui.createTextfield(60, 15, 0);
				data.colorMax := gui.createTextfield(60, 15, 100);
				data.colorStep := gui.createTextfield(60, 15, 0);
				if(node.getMesh().getVertexDescription().getAttribute(Rendering.VertexAttributeIds.COLOR)){
					var colorLabel = gui.createLabel(80, 15, "Color weight:");
					colorLabel.setTooltip("Weights >0 are relative to other weights.");
					p.add(colorLabel);
					p.nextColumn();
					p.add(data.colorMin);
					p.nextColumn();
					p.add(data.colorMax);
					p.nextColumn();
					p.add(data.colorStep);
					p.nextRow();
				}

				data.tex0Min := gui.createTextfield(60, 15, 0);
				data.tex0Max := gui.createTextfield(60, 15, 100);
				data.tex0Step := gui.createTextfield(60, 15, 0);
				if(node.getMesh().getVertexDescription().getAttribute(Rendering.VertexAttributeIds.TEXCOORD0)){
					var tex0Label = gui.createLabel(80, 15, "Tex0 weight:");
					tex0Label.setTooltip("Weights >0 are relative to other weights.");
					p.add(tex0Label);
					p.nextColumn();
					p.add(data.tex0Min);
					p.nextColumn();
					p.add(data.tex0Max);
					p.nextColumn();
					p.add(data.tex0Step);
					p.nextRow();
				}

				var boundaryLabel = gui.createLabel(80, 15, "Boundary weight:");
				boundaryLabel.setTooltip("Weights >0 are relative to other weights.");
				p.add(boundaryLabel);
				p.nextColumn();
				data.boundaryMin := gui.createTextfield(60, 15, 0);
				p.add(data.boundaryMin);
				p.nextColumn();
				data.boundaryMax := gui.createTextfield(60, 15, 100);
				p.add(data.boundaryMax);
				p.nextColumn();
				data.boundaryStep := gui.createTextfield(60, 15, 0);
				p.add(data.boundaryStep);
				p.nextRow();

				var optPosLabel = gui.createLabel(80, 15, "Use OptPos:");
				optPosLabel.setTooltip("Turn computation of optimal positioning on/off.");
				p.add(optPosLabel);
				p.nextColumn();
				data.useOptPos := gui.createCheckBox("", true);
				p.add(data.useOptPos);
				p.nextColumn();
				data.switchOptPos := gui.createCheckBox("Switch use opt. pos.", false);
				data.switchOptPos.setTooltip("\"iterate\" Use OptPos -> turn on and off");
				p.add(data.switchOptPos);
				p.nextRow();

				var ok = gui.createButton(130, 20, "OK");
				ok.onClick = data->fn() {
					showWaitingScreen();
					var origMesh = node.getMesh();

					// iterate triangel count
					if(triangleStep.getText().toNumber() != 0){
						var weights = new Array();
						weights[0] = 0+posMin.getText();
						weights[1] = 0+normalMin.getText();
						weights[2] = 0+colorMin.getText();
						weights[3] = 0+tex0Min.getText();
						weights[4] = 0+boundaryMin.getText();
						for(var i=triangleMin.getText().toNumber(); i<=0+triangleMax.getText().toNumber(); i+=0+triangleStep.getText()){
							var m2 = Rendering.simplifyMesh(node.getMesh(), i, thresholdMin.getText().toNumber(), useOptPos.getData(), flipMin.getText().toNumber(), weights);
							if(m2!=void){
								node.setMesh(m2);

								renderingContext.clearScreen(PADrend.getBGColor());
								PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());
								var tex=Rendering.createTextureFromScreen();
								var b=Rendering.saveTexture(renderingContext,tex,"screens/MeshSimplificationTest_tri."+i+"_thold."+thresholdMin.getText()+"_flip."+flipMin.getText()+"_pos."+weights[0]+"_norm."+weights[1]+"_col."+weights[2]+"_tex."+weights[3]+"_bound."+weights[4]+"_opt."+useOptPos.getData()+".png");
								outln("Screenshot: ",tex,"\t",(b?"ok.":"\afailed!"),"\n");
								node.setMesh(origMesh);
							}
						}
					}

					// iterate threshold
					if(thresholdStep.getText().toNumber() != 0){
						var weights = new Array();
						weights[0] = 0+posMin.getText();
						weights[1] = 0+normalMin.getText();
						weights[2] = 0+colorMin.getText();
						weights[3] = 0+tex0Min.getText();
						weights[4] = 0+boundaryMin.getText();
						for(var i=thresholdMin.getText().toNumber(); i<=0+thresholdMax.getText().toNumber(); i+=0+thresholdStep.getText()){
							var m2 = Rendering.simplifyMesh(node.getMesh(), triangleMin.getText().toNumber(), i, useOptPos.getData(), flipMin.getText().toNumber(), weights);
							if(m2!=void){
								node.setMesh(m2);

								renderingContext.clearScreen(PADrend.getBGColor());
								PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());
								var tex=Rendering.createTextureFromScreen();
								var b=Rendering.saveTexture(renderingContext,tex,"screens/MeshSimplificationTest_tri."+triangleMin.getText()+"_thold."+i+"_flip."+flipMin.getText()+"_pos."+weights[0]+"_norm."+weights[1]+"_col."+weights[2]+"_tex."+weights[3]+"_bound."+weights[4]+"_opt."+useOptPos.getData()+".png");
								outln("Screenshot: ",tex,"\t",(b?"ok.":"\afailed!"));
								node.setMesh(origMesh);
							}
						}
					}

					// iterate face flip
					if(flipStep.getText().toNumber() != 0){
						var weights = new Array();
						weights[0] = 0+posMin.getText();
						weights[1] = 0+normalMin.getText();
						weights[2] = 0+colorMin.getText();
						weights[3] = 0+tex0Min.getText();
						weights[4] = 0+boundaryMin.getText();
						for(var i=flipMin.getText().toNumber(); i<=0+flipMax.getText().toNumber(); i+=0+flipStep.getText()){
							var m2 = Rendering.simplifyMesh(node.getMesh(), triangleMin.getText().toNumber(), thresholdMin.getText().toNumber(), useOptPos.getData(), i, weights);
							if(m2!=void){
								node.setMesh(m2);

								renderingContext.clearScreen(PADrend.getBGColor());
								PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());
								var tex=Rendering.createTextureFromScreen();
								var b=Rendering.saveTexture(renderingContext,tex,"screens/MeshSimplificationTest_tri."+triangleMin.getText()+"_thold."+thresholdMin.getText()+"_flip."+i+"_pos."+weights[0]+"_norm."+weights[1]+"_col."+weights[2]+"_tex."+weights[3]+"_bound."+weights[4]+"_opt."+useOptPos.getData()+".png");
								outln("Screenshot: ",tex,"\t",(b?"ok.":"\afailed!"));
								node.setMesh(origMesh);
							}
						}
					}

					// iterate pos weight
					if(posStep.getText().toNumber() != 0){
						var weights = new Array();
						weights[0] = 0+posMin.getText();
						weights[1] = 0+normalMin.getText();
						weights[2] = 0+colorMin.getText();
						weights[3] = 0+tex0Min.getText();
						weights[4] = 0+boundaryMin.getText();
						for(weights[0]=posMin.getText().toNumber(); weights[0]<=0+posMax.getText().toNumber(); weights[0]+=0+posStep.getText()){
							var m2 = Rendering.simplifyMesh(node.getMesh(), triangleMin.getText().toNumber(), thresholdMin.getText().toNumber(), useOptPos.getData(), flipMin.getText().toNumber(), weights);
							if(m2!=void){
								node.setMesh(m2);

								renderingContext.clearScreen(PADrend.getBGColor());
								PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());
								var tex=Rendering.createTextureFromScreen();
								var b=Rendering.saveTexture(renderingContext,tex,"screens/MeshSimplificationTest_tri."+triangleMin.getText()+"_thold."+thresholdMin.getText()+"_flip."+flipMin.getText()+"_pos."+weights[0]+"_norm."+weights[1]+"_col."+weights[2]+"_tex."+weights[3]+"_bound."+weights[4]+"_opt."+useOptPos.getData()+".png");
								outln("Screenshot: ",tex,"\t",(b?"ok.":"\afailed!"));
								node.setMesh(origMesh);
							}
						}
					}

					// iterate normal weight
					if(normalStep.getText().toNumber() != 0){
						var weights = new Array();
						weights[0] = 0+posMin.getText();
						weights[1] = 0+normalMin.getText();
						weights[2] = 0+colorMin.getText();
						weights[3] = 0+tex0Min.getText();
						weights[4] = 0+boundaryMin.getText();
						for(weights[1]=normalMin.getText().toNumber(); weights[1]<=0+normalMax.getText().toNumber(); weights[1]+=0+normalStep.getText()){
							var m2 = Rendering.simplifyMesh(node.getMesh(), triangleMin.getText().toNumber(), thresholdMin.getText().toNumber(), useOptPos.getData(), flipMin.getText().toNumber(), weights);
							if(m2!=void){
								node.setMesh(m2);

								renderingContext.clearScreen(PADrend.getBGColor());
								PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());
								var tex=Rendering.createTextureFromScreen();
								var b=Rendering.saveTexture(renderingContext,tex,"screens/MeshSimplificationTest_tri."+triangleMin.getText()+"_thold."+thresholdMin.getText()+"_flip."+flipMin.getText()+"_pos."+weights[0]+"_norm."+weights[1]+"_col."+weights[2]+"_tex."+weights[3]+"_bound."+weights[4]+"_opt."+useOptPos.getData()+".png");
								outln("Screenshot: ",tex,"\t",(b?"ok.":"\afailed!"));
								node.setMesh(origMesh);
							}
						}
					}

					// iterate color weight
					if(colorStep.getText().toNumber() != 0){
						var weights = new Array();
						weights[0] = 0+posMin.getText();
						weights[1] = 0+normalMin.getText();
						weights[2] = 0+colorMin.getText();
						weights[3] = 0+tex0Min.getText();
						weights[4] = 0+boundaryMin.getText();
						for(weights[2]=colorMin.getText().toNumber(); weights[2]<=0+colorMax.getText().toNumber(); weights[2]+=0+colorStep.getText()){
							var m2 = Rendering.simplifyMesh(node.getMesh(), triangleMin.getText().toNumber(), thresholdMin.getText().toNumber(), useOptPos.getData(), flipMin.getText().toNumber(), weights);
							if(m2!=void){
								node.setMesh(m2);

								renderingContext.clearScreen(PADrend.getBGColor());
								PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());
								var tex=Rendering.createTextureFromScreen();
								var b=Rendering.saveTexture(renderingContext,tex,"screens/MeshSimplificationTest_tri."+triangleMin.getText()+"_thold."+thresholdMin.getText()+"_flip."+flipMin.getText()+"_pos."+weights[0]+"_norm."+weights[1]+"_col."+weights[2]+"_tex."+weights[3]+"_bound."+weights[4]+"_opt."+useOptPos.getData()+".png");
								outln("Screenshot: ",tex,"\t",(b?"ok.":"\afailed!"));
								node.setMesh(origMesh);
							}
						}
					}

					// iterate tex0 weight
					if(tex0Step.getText().toNumber() != 0){
						var weights = new Array();
						weights[0] = 0+posMin.getText();
						weights[1] = 0+normalMin.getText();
						weights[2] = 0+colorMin.getText();
						weights[3] = 0+tex0Min.getText();
						weights[4] = 0+boundaryMin.getText();
						for(weights[3]=tex0Min.getText().toNumber(); weights[3]<=0+tex0Max.getText().toNumber(); weights[3]+=0+tex0Step.getText()){
							var m2 = Rendering.simplifyMesh(node.getMesh(), triangleMin.getText().toNumber(), thresholdMin.getText().toNumber(), useOptPos.getData(), flipMin.getText().toNumber(), weights);
							if(m2!=void){
								node.setMesh(m2);

								renderingContext.clearScreen(PADrend.getBGColor());
								PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());
								var tex=Rendering.createTextureFromScreen();
								var b=Rendering.saveTexture(renderingContext,tex,"screens/MeshSimplificationTest_tri."+triangleMin.getText()+"_thold."+thresholdMin.getText()+"_flip."+flipMin.getText()+"_pos."+weights[0]+"_norm."+weights[1]+"_col."+weights[2]+"_tex."+weights[3]+"_bound."+weights[4]+"_opt."+useOptPos.getData()+".png");
								outln("Screenshot: ",tex,"\t",(b?"ok.":"\afailed!"));
								node.setMesh(origMesh);
							}
						}
					}

					// iterate boundary weight
					if(boundaryStep.getText().toNumber() != 0){
						var weights = new Array();
						weights[0] = 0+posMin.getText();
						weights[1] = 0+normalMin.getText();
						weights[2] = 0+colorMin.getText();
						weights[3] = 0+tex0Min.getText();
						weights[4] = 0+boundaryMin.getText();
						for(weights[4]=boundaryMin.getText().toNumber(); weights[4]<=0+boundaryMax.getText().toNumber(); weights[4]+=0+boundaryStep.getText()){
							var m2 = Rendering.simplifyMesh(node.getMesh(), triangleMin.getText().toNumber(), thresholdMin.getText().toNumber(), useOptPos.getData(), flipMin.getText().toNumber(), weights);
							if(m2!=void){
								node.setMesh(m2);

								renderingContext.clearScreen(PADrend.getBGColor());
								PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());
								var tex=Rendering.createTextureFromScreen();
								var b=Rendering.saveTexture(renderingContext,tex,"screens/MeshSimplificationTest_tri."+triangleMin.getText()+"_thold."+thresholdMin.getText()+"_flip."+flipMin.getText()+"_pos."+weights[0]+"_norm."+weights[1]+"_col."+weights[2]+"_tex."+weights[3]+"_bound."+weights[4]+"_opt."+useOptPos.getData()+".png");
								outln("Screenshot: ",tex,"\t",(b?"ok.":"\afailed!"));
								node.setMesh(origMesh);
							}
						}
					}

					// iterate uswOptPos
					if(switchOptPos.getData()){
						var weights = new Array();
						weights[0] = 0+posMin.getText();
						weights[1] = 0+normalMin.getText();
						weights[2] = 0+colorMin.getText();
						weights[3] = 0+tex0Min.getText();
						weights[4] = 0+boundaryMin.getText();
						var m2 = Rendering.simplifyMesh(node.getMesh(), triangleMin.getText().toNumber(), thresholdMin.getText().toNumber(), useOptPos.getData(), flipMin.getText().toNumber(), weights);
						if(m2!=void){
							node.setMesh(m2);

							renderingContext.clearScreen(PADrend.getBGColor());
							PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());
							var tex=Rendering.createTextureFromScreen();
							var b=Rendering.saveTexture(renderingContext,tex,"screens/MeshSimplificationTest_tri."+triangleMin.getText()+"_thold."+thresholdMin.getText()+"_flip."+flipMin.getText()+"_pos."+weights[0]+"_norm."+weights[1]+"_col."+weights[2]+"_tex."+weights[3]+"_bound."+weights[4]+"_opt."+useOptPos.getData()+".png");
							outln("Screenshot: ",tex,"\t",(b?"ok.":"\afailed!"));
							node.setMesh(origMesh);
						}

						m2 = Rendering.simplifyMesh(node.getMesh(), triangleMin.getText().toNumber(), thresholdMin.getText().toNumber(), !(useOptPos.getData()), flipMin.getText().toNumber(), weights);
						if(m2!=void){
							node.setMesh(m2);

							renderingContext.clearScreen(PADrend.getBGColor());
							PADrend.getRootNode().display(frameContext,PADrend.getRenderingFlags());
							var tex=Rendering.createTextureFromScreen();
							var b=Rendering.saveTexture(renderingContext,tex,"screens/MeshSimplificationTest_tri."+triangleMin.getText()+"_thold."+thresholdMin.getText()+"_flip."+flipMin.getText()+"_pos."+weights[0]+"_norm."+weights[1]+"_col."+weights[2]+"_tex."+weights[3]+"_bound."+weights[4]+"_opt."+!(useOptPos.getData())+".png");
							outln("Screenshot: ",tex,"\t",(b?"ok.":"\afailed!"));
							node.setMesh(origMesh);
						}
					}
				};
				p.add(ok);

				var cancel = gui.createButton(130, 20, "Cancel");
				cancel.onClick = data->fn() {
					window.setEnabled(false);
				};
				p.add(cancel);
			},
			GUI.TOOLTIP : "Test mesh simplification function by iterating some parameters."
		},
		'----'
	]);
}
// --------------------------------------------------------------------------------------------------
gui.register('NodeEditor_MeshToolsMenu.meshFixes',[
	"*Mesh fixes*",
	{
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "Fix normals (deep exploration)",
		GUI.ON_CLICK : fn(){
			showWaitingScreen();
			foreach( NodeEditor.getSelectedNodes() as var subtree){
				var geoNodes=MinSG.collectGeoNodes(subtree);
				foreach(geoNodes as var geoNode){
					var mesh = geoNode.getMesh();
					var posAcc = Rendering.PositionAttributeAccessor.create(mesh,"sg_Position");
					var normalAcc;
					try{
						normalAcc = Rendering.PositionAttributeAccessor.create(mesh,"sg_Normal");
					}catch(e){ // may fail if normals are sotred as bytes.
						out("o");
						continue;
					}
					if(!normalAcc)
						continue;
					var n0 = normalAcc.getPosition(0);
					var p0 = posAcc.getPosition(0);
					if(n0.length()<(n0-p0).length()){
						out("-");
						continue;
					}
					// guess normal offset
					var bb = new Geometry.Box;
					bb.invalidate();
					for(var i=0;posAcc.checkRange(i);++i)
						bb.include( normalAcc.getPosition(i) );

					if(bb.getExtentMax()<0.1){
						Rendering.calculateNormals(mesh);
						out("*");
					}else{
						var offset = bb.getCenter();

						for(var i=0;posAcc.checkRange(i);++i){
							normalAcc.setPosition(i, (normalAcc.getPosition(i)-offset).normalize() );
						}
						mesh._markAsChanged();
						outln(bb);
//							normalAcc.setPosition(i, (normalAcc.getPosition(i)-posAcc.getPosition(i)).normalize() );
						out("+");
					}

				}
			}
			outln("Finisehd.");
		},
		GUI.TOOLTIP :  "ColladaScenes exported from DeepExploation may\nstore normals with a (strange?) offset"
	},
]);

// ------------------------------------------------------------------------------

