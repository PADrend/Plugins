/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2007-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 ** [PADrend] scenes.escript
 **/
GLOBALS.getSchwein:=fn(){
    if(!PADrend.getSceneManager().getRegisteredNode("texturedPig")){
        var scale=3;
        var transMat=new Geometry.Matrix4x4();
        transMat.scale(scale,scale,scale);
        transMat.rotate_deg(180,0,1,0);
        var t=Rendering.createTextureFromFile(PADrend.getDataPath()+"/texture/Schwein.low.t.bmp");
        var node=MinSG.loadModel(PADrend.getDataPath()+"/model/Schwein.low.t.ply",MinSG.MESH_AUTO_CENTER_BOTTOM|MinSG.MESH_AUTO_SCALE,transMat);
        node.addState(new MinSG.TextureState(t));
        PADrend.getSceneManager().registerNode("texturedPig",node);
    }
    var p=PADrend.getSceneManager().createInstance("texturedPig");
//    PADrend.getSceneManager().registerBehaviour(MinSG.__createSimplePhysics(p));

    return p;
};
