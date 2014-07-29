/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2014 Mouns Almarrani <murrani@mail.upb.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static trait = new MinSG.PersistentNodeTrait('ObjectTraits/EnvironmentTextureTrait');
static size = 256;
trait.onInit += fn(node){

    @(once) trait.directions := [
        [ new Geometry.Vec3(-1,  0,  0), new Geometry.Vec3(0, -1, 0) ],
        [ new Geometry.Vec3( 1,  0,  0), new Geometry.Vec3(0, -1, 0) ],
        [ new Geometry.Vec3( 0, -1,  0), new Geometry.Vec3(0, 0, 1) ],
        [ new Geometry.Vec3( 0,  1,  0), new Geometry.Vec3(0, 0, 1) ],
        [ new Geometry.Vec3( 0,  0, -1), new Geometry.Vec3(0, -1, 0) ],
        [ new Geometry.Vec3( 0,  0,  1), new Geometry.Vec3(0, -1, 0) ],
    ];
    @(once) trait.camera := new MinSG.CameraNode(90, 1.0, 1, 5000);
    trait.camera.setViewport(new Geometry.Rect(0, 0, size, size));
    @(once) trait.tp := (new (Std.require('LibRenderingExt/TextureProcessor')))
        .setOutputDepthTexture( Rendering.createDepthTexture(size, size) );

    trait.stateNameWrapper := DataWrapper.createFromValue("");
    trait.layerWrapper := DataWrapper.createFromValue(1);

};

trait.allowRemoval();

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
                GUI.TYPE : GUI.TYPE_TEXT,
                GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
                GUI.LABEL : "StateIds",
                GUI.OPTIONS_PROVIDER : fn(){
                        var stateNames = PADrend.getSceneManager().getNamesOfRegisteredStates();
                        if(stateNames.size() >0){
                            stateNames.sort();
                            return stateNames;
                        }
                        else
                            return;

                    },
                GUI.DATA_WRAPPER : trait.stateNameWrapper
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
                GUI.TYPE : GUI.TYPE_NUMBER,
                GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_ABS, 10, 20],
                GUI.LABEL : "Rendering layers",
                GUI.DATA_WRAPPER : trait.layerWrapper
			},
			{   GUI.TYPE : GUI.TYPE_NEXT_ROW},
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "create texture",
				GUI.ON_CLICK: [node, trait.stateNameWrapper, trait.layerWrapper]=>fn(node, stateNameWrapper, layerWrapper){
				    if(stateNameWrapper().empty()){
                        outln("No state selected/entered");
				    }
				    else{
                        var color_texture = Rendering.createHDRCubeTexture(size, size);
                        foreach(trait.directions as var i,var dirArray){
                            trait.camera.setSRT(new Geometry.SRT(node.getWorldBB().getCenter(), dirArray[0], dirArray[1]));
                            trait.tp.setOutputTexture( color_texture, 0, i );
                            trait.tp.begin();
                            PADrend.renderScene(PADrend.getRootNode(), trait.camera, PADrend.getRenderingFlags(), PADrend.getBGColor(), layerWrapper());
                            trait.tp.end();
                        }
                        var state =  PADrend.getSceneManager().getRegisteredState(stateNameWrapper());
                        if(!state){
                            state = new MinSG.TextureState;
                            PADrend.getSceneManager().registerState(stateNameWrapper(),state);
                        }
                        state.setTexture(color_texture);

				    }
                }
			}
		];
	});
});

return trait;
