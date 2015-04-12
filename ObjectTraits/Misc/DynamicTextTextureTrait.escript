/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

	 
static createTexture = fn(String text, Number bg){
	static gui;
	@(once) {
		gui = new (Std.module('LibGUIExt/GUI_ManagerExt'));
		gui.initDefaultFonts();
		gui.registerFonts({
		//	GUI.FONT_ID_DEFAULT : Std.module('PADrend/gui').getFont(GUI.FONT_ID_XLARGE)
			GUI.FONT_ID_DEFAULT : Std.module('PADrend/gui').getFont(GUI.FONT_ID_HUGE)
		});
		gui.setDefaultColor(GUI.PROPERTY_TEXT_COLOR, GUI.WHITE);
	};
	
	var label = gui.create({
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : text,
		GUI.POSITION : [5,5]
	});
	label.layout(); // calculate required size

	var width = (label.getWidth()+10).round(4);
	var height = (label.getHeight()+10).round(4);

	var fbo = new Rendering.FBO;
	renderingContext.pushAndSetFBO(fbo);

	var texture = Rendering.createStdTexture(width,height,true);
	fbo.attachColorTexture(renderingContext,texture);
//	outln(fbo.getStatusMessage(renderingContext));

	renderingContext.clearScreen( new Util.Color4f(0,0,0,bg) );
	renderingContext.pushViewport();
	renderingContext.setViewport(0,0,width,height);
	
	gui.registerWindow(label);
	gui.display();
	gui.markForRemoval(label);
	
	renderingContext.popViewport();
	renderingContext.popFBO();
	return texture;
};

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn( node){
	node.annotationBG := node.getNodeAttributeWrapper('annotationBG', 0.5 );
	node.annotationText := node.getNodeAttributeWrapper('annotationText', " " );
	
	var update = [node,node.annotationText,node.annotationBG]=>fn(node,annotationText,annotationBG,...){
		foreach(node.getStates() as var state)	// remove all former texture states
			if(state.isA(MinSG.TextureState))
				node.removeState(state);

		var texture = createTexture(annotationText(),annotationBG());
		if(node.isA(MinSG.BillboardNode)){
			var scale = 0.005;
			var width = texture.getWidth()*scale;
			var height = texture.getHeight()*scale;
			node.setRect(new Geometry.Rect(-width, 3-height , width, height));
		}
		var textState = new MinSG.TextureState(texture);
		textState.setTempState(true);
		node.addState(textState) ;
	};
	node.annotationText.onDataChanged += update;
	node.annotationBG.onDataChanged += update;
	update();
};

trait.allowRemoval();

module.on('../ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_MULTILINE_TEXT,
				GUI.LABEL : "Text",
				GUI.HEIGHT : 100,
				GUI.DATA_WRAPPER : node.annotationText
			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.LABEL : "BG Strength",
				GUI.RANGE : [0,1],
				GUI.DATA_WRAPPER : node.annotationBG
			},

		];
	});
});

return trait;
