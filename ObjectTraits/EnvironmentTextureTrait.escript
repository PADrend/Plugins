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
@(once) static TextureProcessor = Std.require('LibRenderingExt/TextureProcessor');
static directions = [
        [ new Geometry.Vec3( 0,  0,  1), new Geometry.Vec3(0, 1, 0), 0],
        [ new Geometry.Vec3( 1,  0,  0), new Geometry.Vec3(0, 1, 0), 1],
        [ new Geometry.Vec3( 0,  0, -1), new Geometry.Vec3(0, 1, 0), 2],
        [ new Geometry.Vec3(-1,  0,  0), new Geometry.Vec3(0, 1, 0), 3],
        [ new Geometry.Vec3( 0,  1,  0), new Geometry.Vec3(1, 0, 0), 4],
        [ new Geometry.Vec3( 0, -1,  0), new Geometry.Vec3(1, 0, 0), 5]
    ];
static size = 256;
static camera = new MinSG.CameraNode(90, 1.0, 1, 5000);
static tp = (new TextureProcessor)
        .setOutputDepthTexture( Rendering.createDepthCubeTexture(size, size) );
static color_texture = Rendering.createStdCubeTexture(size, size, true);
//static color_texture = Rendering.createStdTexture(size, size, true);

static index = 0;
trait.onInit += fn(node){
    camera.setViewport(new Geometry.Rect(0, 0, size, size));
    var text= [];

//    foreach(directions as var dirArray){
//        var color_texture = Rendering.createStdCubeTexture(size, size, true);
//        camera.setSRT(new Geometry.SRT(node.getWorldOrigin(), dirArray[0], dirArray[1]));
//        tp.setOutputTextures( [color_texture, dirArray[2], dirArray[2]] )
//            .begin();
//        PADrend.renderScene(PADrend.getRootNode(), camera, PADrend.getRenderingFlags(), PADrend.getBGColor(), PADrend.getRenderingLayers());
//        color_texture.download(renderingContext);
//        text+=color_texture;
//        tp.end();
//
//    }
//
//    foreach (text as var texture){
//        var filename = new Util.FileName(__DIR__+"/TestImages/testImage"+ id+".png");
//        Rendering.saveTexture(renderingContext, texture, filename);
//        Rendering.showDebugTexture(texture);
//        id++;
//    }

};

trait.allowRemoval();

Std.onModule('ObjectTraits/ObjectTraitRegistry', fn(registry){
	registry.registerTrait(trait);
	registry.registerTraitConfigGUI(trait,fn(node,refreshCallback){
		return [
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "create img",
				GUI.ON_CLICK: [node]=>fn(node){
                    if(index < 6){
                        var dirArray = directions[index];
                        outln( __FILE__,":",__LINE__); Rendering.checkGLError();
                        camera.setSRT(new Geometry.SRT(node.getWorldOrigin(), dirArray[0], dirArray[1]));
                        outln( __FILE__,":",__LINE__); Rendering.checkGLError();
                        tp.setOutputTexture( [color_texture, 0, dirArray[2]] );

                        outln( __FILE__,":",__LINE__); Rendering.checkGLError();
                        tp.begin();
                        outln( __FILE__,":",__LINE__); Rendering.checkGLError(); outln(">>>>");
                        PADrend.renderScene(PADrend.getRootNode(), camera, PADrend.getRenderingFlags(), PADrend.getBGColor(), PADrend.getRenderingLayers());
                        outln( __FILE__,":",__LINE__); Rendering.checkGLError();
                        tp.end();
                        outln( __FILE__,":",__LINE__); Rendering.checkGLError();

//                        index++;

                    }
                    else{
                        outln("All images are created!");
                        Rendering.showDebugTexture(color_texture);
                    }

                }

			},

		];
	});
});

return trait;
