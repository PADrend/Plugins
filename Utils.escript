/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012-2013 Ralf Petring <ralf@petring.net>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

MinSG.BlueSurfels.createEnclosingOrthoCam := fn(Geometry.Vec3 worldDir,MinSG.Node node){
	var camera = new MinSG.CameraNodeOrtho();
	var nodeCenter = node.getWorldBB().getCenter();
	camera.setWorldOrigin( nodeCenter-(worldDir.getNormalized())*node.getWorldBB().getExtentMax() );
	camera.rotateToWorldDir(camera.getWorldOrigin()-nodeCenter);
	
	var bb = node.getBB();
	if(bb.getExtentX() ~= 0) {
		bb.setMaxX(bb.getMaxX()+0.001);
		bb.setMinX(bb.getMinX()-0.001);
	}
	if(bb.getExtentY() ~= 0) {
		bb.setMaxY(bb.getMaxY()+0.001);
		bb.setMinY(bb.getMinY()-0.001);
	}
	if(bb.getExtentZ() ~= 0) {
		bb.setMaxZ(bb.getMaxZ()+0.001);
		bb.setMinZ(bb.getMinZ()-0.001);
	}
	var frustum = Geometry.calcEnclosingOrthoFrustum(bb, camera.getWorldToLocalMatrix() * node.getWorldTransformationMatrix());
	camera.setNearFar(frustum.getNear()*0.99, frustum.getFar()*1.01);
	
	//	out("a)",frustum.getTop()-frustum.getBottom() ,"\nb)",frustum.getRight()-frustum.getLeft(),"\n");
	if( frustum.getRight()-frustum.getLeft() > frustum.getTop() - frustum.getBottom()){
		camera.rotateLocal_deg(90,new Geometry.Vec3(0,0,1));
		camera.setClippingPlanes( frustum.getBottom(), frustum.getTop(), frustum.getLeft(), frustum.getRight());
	}else{
		camera.setClippingPlanes(frustum.getLeft(), frustum.getRight(), frustum.getBottom(), frustum.getTop());
	}
	
	return camera;
};

MinSG.BlueSurfels.attachSurfels := fn(MinSG.Node node,ExtObject surfelInfo){
	if(node.isInstance())
		node = node.getPrototype();
	node.setNodeAttribute('surfels', surfelInfo.mesh);
	node.setNodeAttribute('surfelMinDist', surfelInfo.minDist);
	node.setNodeAttribute('surfelMedianDist', surfelInfo.medianDist);
};

MinSG.BlueSurfels.locateSurfels := fn(MinSG.Node node){
	return node.findNodeAttribute('surfels');
};
MinSG.BlueSurfels.getLocalSurfels := fn(MinSG.Node node){
	return node.getNodeAttribute('surfels');
};

//! @return true iff a surfel was removed.
MinSG.BlueSurfels.removeSurfels := fn(MinSG.Node node){
	if(node.isInstance())
		node = node.getPrototype();
	return node.unsetNodeAttribute('surfels');
};


MinSG.BlueSurfels.saveSurfelsToMMF := fn(MinSG.Node node, Util.FileName folder){

	Util.createDir(folder);

	foreach(NodeEditor.getSelectedNodes() as var node){
		node.traverse(this->fn(node){
			var surfels = MinSG.BlueSurfels.locateSurfels(node);
			if(surfels && surfels.getFileName().getPath()==""){
				surfels.setFileName(new Util.FileName());
				outln("removed file name ", surfels.getFileName().getFile().toString(), " from surfel", surfels);
			}
		});
	}
	
	foreach(NodeEditor.getSelectedNodes() as var node){
		node.traverse((fn(node, folder){
			var surfels = MinSG.BlueSurfels.locateSurfels(node);
			if(surfels && surfels.getFileName().getPath()==""){
				var file = Util.generateNewRandFilename(folder, "surfels_", ".mmf", 8);
				surfels.setFileName(file);
				Rendering.saveMesh(surfels,file);
				outln("set file name ", file.toString(), " for surfel", surfels, " and saved");
		}
	}).bindLastParams(folder));
}
};

return MinSG.BlueSurfels;
