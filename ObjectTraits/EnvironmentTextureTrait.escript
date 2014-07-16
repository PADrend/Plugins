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
static eventLoop = Util.requirePlugin('PADrend/EventLoop');
static size = 256;
trait.onInit += fn(node){
    @(once) trait.directions := [
        [ new Geometry.Vec3( 0,  0,  1), new Geometry.Vec3(0, 1, 0), 0],
        [ new Geometry.Vec3( 1,  0,  0), new Geometry.Vec3(0, 1, 0), 1],
        [ new Geometry.Vec3( 0,  0, -1), new Geometry.Vec3(0, 1, 0), 2],
        [ new Geometry.Vec3(-1,  0,  0), new Geometry.Vec3(0, 1, 0), 3],
        [ new Geometry.Vec3( 0,  1,  0), new Geometry.Vec3(1, 0, 0), 4],
        [ new Geometry.Vec3( 0, -1,  0), new Geometry.Vec3(1, 0, 0), 5]
    ];
    @(once) trait.camera := new MinSG.CameraNode(90, 1.0, 1, 5000);
    trait.camera.setViewport(new Geometry.Rect(0, 0, size, size));
    @(once) trait.tp := (new (Std.require('LibRenderingExt/TextureProcessor')))
        .setOutputDepthTexture( Rendering.createDepthTexture(size, size) );

    trait.stateWrapper := DataWrapper.createFromValue(" ");
    trait.stateWrapper.onDataChanged += fn(data){
        var state = new MinSG.TextureState();
        PADrend.getSceneManager().registerState(data,state);
    };
    trait.layerWrapper := DataWrapper.createFromValue(1);
//    trait.layerWrapper.onDataChanged += fn(data){
//        eventLoop.setRenderingLayers(data);
//    };

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
                GUI.DATA_WRAPPER : trait.stateWrapper
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
				GUI.LABEL : "create img",
				GUI.ON_CLICK: [node, trait.stateWrapper, trait.layerWrapper]=>fn(node, stateWrapper, layerWrapper){
				    if(stateWrapper()==" "){
                        outln("No state selected or no state existed");
				    }
				    else{
                        var color_texture = Rendering.createStdCubeTexture(size, size);
                        eventLoop.setRenderingLayers(layerWrapper());
                        foreach(trait.directions as var dirArray){
                            trait.camera.setSRT(new Geometry.SRT(node.getWorldOrigin(), dirArray[0], dirArray[1]));
                            trait.tp.setOutputTexture( [color_texture, 0, dirArray[2]] );
                            trait.tp.begin();
                            PADrend.renderScene(PADrend.getRootNode(), trait.camera, PADrend.getRenderingFlags(), PADrend.getBGColor(), PADrend.getRenderingLayers());
                            trait.tp.end();
                            var state =  PADrend.getSceneManager().getRegisteredState(stateWrapper());
                            state.setTexture(color_texture);
                        }

				    }
                }
			}
		];
	});
});

return trait;
