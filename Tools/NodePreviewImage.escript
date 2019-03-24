/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2019 Sascha Brandt <sascha@brandt.graphics>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
static T = new Type;
T._printableName := $NodePreviewImage;
T.node := void;

T._constructor ::= fn(w, h) {
	this.width := w;
	this.height := h;
	this.image := gui.createImage(new Util.Bitmap(w,h,Util.Bitmap.RGBA));
	this.fbo := new Rendering.FBO;
	this.colorTexture := Rendering.createStdTexture(w,h,true);
	this.depthTexture := Rendering.createDepthTexture(w,h);
	this.fbo.attachColorTexture(renderingContext, this.colorTexture);
	this.fbo.attachDepthTexture(renderingContext, this.depthTexture);
	this.camera := new MinSG.CameraNode;
	this.camera.setViewport(new Geometry.Rect(0,0,w,h),false);
};

T.getImage ::= fn() {
	return this.image;
};

T.clear ::= fn() {
	this.image.updateData(new Util.Bitmap(width,height,Util.Bitmap.RGBA));
};

T.setNode ::= fn(n) {
	this.node = n; 
	
	var bb = node.getWorldBB();	
	var angles = camera.getAngles();
	
	var dir = new Geometry.Vec3(0,0,1);
	var width = bb.getExtentX() * 1.001;
	var height = bb.getExtentY() * 1.001;
	var depth = bb.getExtentZ() * 1.001;
	
	var distances = [
		// X direction of scene will be horizontal
		(width / 2) / -angles[0].degToRad().tan(), // left
		(width / 2) / angles[1].degToRad().tan(), // right
		// Z direction of scene will be vertical
		(height / 2) / -angles[2].degToRad().tan(), // bottom
		(height / 2) / angles[3].degToRad().tan() // top
	];
	var dist = (distances.max() + depth / 2);
	var targetSRT = new Geometry.SRT(
		bb.getCenter() + dir * dist, // position
		dir, // direction (frustum goes to negative direction)
		PADrend.getWorldUpVector() // up
	);
	
	camera.setNearFar(dist - depth/2 - 0.01, dist + depth/2 + 0.01);
	camera.setWorldTransformation(targetSRT);
	
	update();
};


T.update ::= fn() {
	if(!node)
		return;
	
	frameContext.pushAndSetCamera(camera);
	renderingContext.pushAndSetFBO(fbo);
	renderingContext.clearScreen(new Util.Color4f(0,0,0,0));
	frameContext.displayNode(node, (new MinSG.RenderParam).setFlags(MinSG.USE_WORLD_MATRIX).setRenderingLayers(PADrend.getRenderingLayers()));
	renderingContext.popFBO();
	frameContext.popCamera();
	
	colorTexture.download(renderingContext);
	var bitmap = Rendering.createBitmapFromTexture(renderingContext, colorTexture);
	image.updateData(bitmap);
};

return T;