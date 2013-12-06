/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/Tools/NodeTools.escript
 **
 ** Collection of various functions for node and tree modifications
 **/

/**
 * Print node info depending on the node type
 */
NodeEditorTools.printNodeInfo:=fn(MinSG.Node node) {
	if(node ---|> MinSG.GeometryNode){
		var mesh=node.getMesh();
//		var vbo=node.getVBOWrapper();
//		var vbo_mesh=vbo.getMesh();
		out("[Msh] BBox: "+mesh.getBoundingBox()+"\n");
		out("[Msh] Vtx-Description: "+mesh.getVertexDescription().toString()+"\n");
		out("[Msh] Has "+mesh.getVertexCount()+" vertices and "+mesh.getIndexCount()+" indices.\n");
//		out("[VBO] BBox: "+vbo_mesh.getBoundingBox()+"\n");
//		out("[VBO] Vtx-Description: "+vbo_mesh.getVertexDescription().toString()+"\n");
//		out("[VBO] Has "+vbo_mesh.getVertexCount()+" vertices and "+vbo_mesh.getIndexCount()+" indices.\n");
//		if(vbo.isUploaded())
//			out("[VBO] is uploaded\n");
	}

	out("Collected States in the subtree: \n");
	print_r(MinSG.collectStates(PADrend.getCurrentScene()/*,MinSG.ShaderState*/));

};


// ------------------------------------------------------------------------------

