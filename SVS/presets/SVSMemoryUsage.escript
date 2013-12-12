/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var rootNode = PADrend.getCurrentScene();
var svsSize = DataWrapper.createFromValue(0);
var memNodes = DataWrapper.createFromValue(0);
var meshes = new Map;
var textures = new Map;

var formatMebibytes = fn(Number bytes) {
	return (bytes / (1024.0 * 1024.0)).format(3, false, 8, ' ') + " MiB";
};

// Instances are ignored.
rootNode.traverse([svsSize, memNodes, meshes] => fn(DataWrapper svsSize, DataWrapper memNodes, Map meshes, MinSG.Node node) {
	memNodes(memNodes() + node.getMemoryUsage());
	if(node ---|> MinSG.GeometryNode) {
		var mesh = node.getMesh();
		if(mesh) {
			meshes[mesh] = true;
		}
	}
	if(node ---|> MinSG.GroupNode && MinSG.SVS.hasVisibilitySphere(node)) {
		svsSize(svsSize() + MinSG.SVS.getSphereMemoryUsage(node));
	}
});

rootNode.traverseStates([textures] => fn(Map textures, node, state) {
	if(state ---|> MinSG.TextureState && state.hasTexture()) {
		textures[state.getTexture()] = true;
	}
});

outln("--- Memory usage for scene ", rootNode.filename, " ---");

outln("SVS:        ", formatMebibytes(svsSize()));
outln("Tree nodes: ", formatMebibytes(memNodes()));

var memMeshes = 0;
foreach(meshes as var mesh, var dummy) {
	mesh.assureLocalData();
	memMeshes += mesh.getMainMemoryUsage();
}
outln("Meshes:     ", formatMebibytes(memMeshes));

var memTextures = 0;
foreach(textures as var texture, var dummy) {
	memTextures += texture.getDataSize();
}
outln("Textures:   ", formatMebibytes(memTextures));

outln("Sum:        ", formatMebibytes(svsSize() + memNodes() + memMeshes + memTextures));
