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


static font =  GUI.FONT_ID_LARGE;

static createTexture = fn(String text){

	var label = gui.create({
		GUI.TYPE : GUI.TYPE_LABEL,
		GUI.LABEL : text,
//		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -10.0,-10.0],
		GUI.POSITION : [5,5],
		GUI.FONT : font,
		GUI.COLOR : GUI.WHITE
	});
	label.layout();

	var width = label.getWidth()+10;
	var height = label.getHeight()+10;
	var p = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.SIZE : [width,height],
		GUI.POSITION : [0,0],
		GUI.FLAGS : GUI.BACKGROUND,
		GUI.PROPERTIES : [ // clear backround
			new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,
					gui._createRectShape(new Util.Color4ub(0,0,0,50),new Util.Color4ub(0,0,0,0),false))
		],
		GUI.CONTENTS : [ label ]
	});

	gui.registerWindow(p);

	gui.display();
	gui.markForRemoval(p);
	return Rendering.createTextureFromScreen( new Geometry.Rect(0,renderingContext.getWindowHeight()-height,width,height),true);
};

var PersistentNodeTrait = module('LibMinSGExt/Traits/PersistentNodeTrait');
static trait = new PersistentNodeTrait(module.getId());

trait.onInit += fn( node){
	node.annotationText := node.getNodeAttributeWrapper('annotationText', " " );
	node.annotationText.onDataChanged += [node]=>fn(node,text){
		foreach(node.getStates() as var state){	// remove all former texture states
			if(state.isA(MinSG.TextureState))
				node.removeState(state);

		var texture = createTexture(text);
		if(node.isA(MinSG.BillboardNode)){
			var scale = 0.01;
			var width = texture.getWidth()*scale;
			var height = texture.getHeight()*scale;
			node.setRect(new Geometry.Rect(-width, 3-height , width, height));
		}
		var textState = new MinSG.TextureState(texture);
		textState.setTempState(true);
		node.addState(textState) ;
	};
	
	node.annotationText.forceRefresh();
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

		];
	});
});

return trait;
