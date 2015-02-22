/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Lukas Kopecki
 * Copyright (C) 2009-2013 Ralf Petring <ralf@petring.net>
 * Copyright (C) 2010-2011 Robert Gmyr
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static plugin = new Plugin({
		Plugin.NAME : 'Spielerei',
		Plugin.DESCRIPTION : "Collection of experiments, games and stuff that fits nowhere else,\nbut might be interesting for someone.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});


plugin.init @(override) :=fn() {
	registerExtension('PADrend_Init',this->registerMenus);

    // ----
	var modules = [];
	modules+=__DIR__+"/"+"StatOverlay.escript";
	modules+=__DIR__+"/"+"Anaglyph.escript";
	modules+=__DIR__+"/"+"BoardGame/Plugin.escript";
	modules+=__DIR__+"/"+"TicTacToe/Plugin.escript";

	loadPlugins( modules,false );

	if(systemConfig.getValue('Spielerei.newMenuDesign',false))
		newMenuDesign();

    return true;
};

// ------------------------------------------------------------------------------


plugin.registerMenus := fn(){
	gui.registerComponentProvider('PADrend_MainToolbar.70_spielerei',{
		GUI.TYPE : GUI.TYPE_MENU,
		GUI.LABEL : "Spielerei",
		GUI.ICON : "#Spielerei",
		GUI.ICON_COLOR : GUI.BLACK,
		GUI.MENU : 'Spielerei'
	});
								
	gui.registerComponentProvider('Spielerei.networkTest',[
		"*Network Test*",
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Chat Server",
			GUI.ON_CLICK : fn() {
				var s = new (Std.require('Spielerei/Chat').Server);
				s.init();
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Chat Client",
			GUI.ON_CLICK : fn() {
				var c=new (Std.require('Spielerei/Chat').Client);
				c.init();
			}
		},
		'----'
	]);

	// ----------------------
	
	gui.registerComponentProvider('Spielerei.~00_misc',[
		"*misc*",
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "MeshTest",
			GUI.ON_CLICK : this->fn() {
					var start=clock();
					var width=renderingContext.getWindowWidth()*1.0;
//					var width=512;//renderingContext.getWindowWidth()*1.0;
//					var height=512;//renderingContext.getWindowHeight()*1.0;
					var height=renderingContext.getWindowHeight()*1.0;

					var	fbo=new Rendering.FBO;

					var depthTexture=Rendering.createDepthTexture(width,height);
					var cam=new MinSG.CameraNode( 90.0, width/height, 1.0,5000);
					var pos=camera.getWorldOrigin();
					cam.setViewport(new Geometry.Rect(0,0,width,height));

					var meshes=[];
					var textures=[];

					var directions = [
							[ new Geometry.Vec3(0,0,1),new Geometry.Vec3(0,1,0)],
							[ new Geometry.Vec3(1,0,0),new Geometry.Vec3(0,1,0)],
							[ new Geometry.Vec3(0,0,-1),new Geometry.Vec3(0,1,0)],
							[ new Geometry.Vec3(-1,0,0),new Geometry.Vec3(0,1,0)],
							[ new Geometry.Vec3(0,1,0),new Geometry.Vec3(1,0,0)],
							[ new Geometry.Vec3(0,-1,0),new Geometry.Vec3(1,0,0)] 	];

					foreach(directions as var a){
						var dir=a[0];
						var up=a[1];
						renderingContext.pushAndSetFBO(fbo);
						
						var colorTexture = Rendering.createStdTexture(width,height,true);
						fbo.attachColorTexture(renderingContext,colorTexture);
						
						fbo.attachDepthTexture(renderingContext,depthTexture);

						cam.setRelTransformation( new Geometry.SRT(pos,dir,up) );
						
						PADrend.renderScene(PADrend.getRootNode(), cam, PADrend.getRenderingFlags(), PADrend.getBGColor(),PADrend.getRenderingLayers());

						renderingContext.popFBO();
						depthTexture.download(renderingContext);
						colorTexture.download(renderingContext);

						var m = Rendering.createMeshByQuadTree(Rendering.createDepthPixelAccessor(renderingContext, depthTexture));
						out("Original\t\t\t", m, "\tTriangles: ", m.getIndexCount() / 3, "\tVertices: ", m.getVertexCount(), "\n");
						
						// Determine the z range.
						var meshBB = m.getBoundingBox();
						if(meshBB.getMinZ() ~= 1 && meshBB.getMaxZ() ~= 1) {
							// Depth texture consisted only of the far plane.
							continue;
						}
						// Cut off the far plane.
						Rendering.eliminateTrianglesBehindPlane(m, new Geometry.Vec3(0, 0, 0.999), new Geometry.Vec3(0, 0, -1));
						out("Plane cut\t\t\t\t\tTriangles: ", m.getIndexCount() / 3, "\tVertices: ", m.getVertexCount(), "\n");
						Rendering.eliminateZeroAreaTriangles(m);
						out("Degenerate triangles removed\t\t\tTriangles: ", m.getIndexCount() / 3, "\tVertices: ", m.getVertexCount(), "\n");
//						Rendering.removeSkinsWithHoleCovering(m, 0.6, 0.1);
//						out("Long triangles removed\t\t\tTriangles: ", m.getIndexCount() / 3, "\tVertices: ", m.getVertexCount(), "\n");
						Rendering.eliminateUnusedVertices(m);
						out("Unused vertices removed\t\t\tTriangles: ", m.getIndexCount() / 3, "\tVertices: ", m.getVertexCount(), "\n");
//						m = Rendering.simplifyMesh(m, 16000, 0, true, 0.1, [100, 0, 0, 1, 1]);
//						out("Mesh simplification\t\t\t\tTriangles: ", m.getIndexCount() / 3, "\tVertices: ", m.getVertexCount(), "\n");

						frameContext.setCamera(cam);
						var transMat = (renderingContext.getMatrix_cameraToClipping() * renderingContext.getMatrix_worldToCamera()).inverse();
						Rendering._transformMeshCoordinates(m, Rendering.VertexAttributeIds.POSITION, transMat);

						meshes += m;
						textures += colorTexture;
					}


					var newScene=new MinSG.ListNode();

					PADrend.registerScene(newScene);
					PADrend.selectScene(newScene);

					for(var i = 0; i < meshes.count(); ++i) {
						var gn=new MinSG.GeometryNode(meshes[i]);
						gn.addState(new MinSG.TextureState(textures[i]));
						PADrend.getCurrentScene().addChild(gn);
						NodeEditor.selectNode(gn);
					}
					out("\n::",clock()-start,"sek\n");
			}
		},
		{
			GUI.LABEL		:	"Replace Node by Relief Board",
			GUI.TOOLTIP		:	"Generate a Relief Board for the selected node.\nWarning: The selected node is removed from the scene graph.",
			GUI.ON_CLICK	:	fn() {
					// Enable ambient light only
					var light = new MinSG.LightNode();
					light.setAmbientLightColor(new Util.Color4f(1, 1, 1, 1));
					light.setDiffuseLightColor(new Util.Color4f(0, 0, 0, 1));
					light.setSpecularLightColor(new Util.Color4f(0, 0, 0, 1));
					light.switchOn(frameContext);

					var node = NodeEditor.getSelectedNode();
					var reliefBoard = MinSG.createReliefBoardForNode(frameContext, node);

					light.switchOff(frameContext);

					if(node.hasParent()) {
						var parent = node.getParent();
						parent.removeChild(node);
						parent.addChild(reliefBoard);
						NodeEditor.selectNode(reliefBoard);
					}
				}
		},
		{
			GUI.LABEL		:	"Replace Node by TDM",
			GUI.TOOLTIP		:	"Generate a Textured Depth Mesh (TDM) for the selected node.\nWarning: The selected node is removed from the scene graph.",
			GUI.ON_CLICK	:	fn() {
					// Enable ambient light only
					var light = new MinSG.LightNode();
					light.setAmbientLightColor(new Util.Color4f(1, 1, 1, 1));
					light.setDiffuseLightColor(new Util.Color4f(0, 0, 0, 1));
					light.setSpecularLightColor(new Util.Color4f(0, 0, 0, 1));
					light.switchOn(frameContext);

					var node = NodeEditor.getSelectedNode();
					var tdm = MinSG.createTexturedDepthMeshForNode(frameContext, node);

					light.switchOff(frameContext);

					if(node.hasParent()) {
						var parent = node.getParent();
						parent.removeChild(node);
						parent.addChild(tdm);
						NodeEditor.selectNode(tdm);
					}
				}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "New menu layout",
			GUI.ON_CLICK : fn(){
				plugin.newMenuDesign();
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Old menu layout",
			GUI.ON_CLICK : fn(){
				// setting style
				gui.clearGlobalProperties();
			}
		}
	]);
};

plugin.newMenuDesign := fn(){
	// setting style
	gui.setDefaultColor(GUI.PROPERTY_MENU_TEXT_COLOR,new Util.Color4ub(255,255,255,255));
	gui.setDefaultShape(GUI.PROPERTY_MENU_SHAPE,
							gui._createShadowedRectShape( new Util.Color4ub(20,20,20,200),new Util.Color4ub(150,150,150,200),true) );
	gui.setDefaultShape(GUI.PROPERTY_TEXTFIELD_SHAPE,
							gui._createRectShape( new Util.Color4ub(230,230,230,240),new Util.Color4ub(128,128,128,128),true ));
};

return plugin;
// ------------------------------------------------------------------------------
