/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Lukas Kopecki
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

GLOBALS.ChickenHandler := new Type();
ChickenHandler.chickens := [];

ChickenHandler._constructor ::= fn(scene, chickenCount)
{
    loadOnce(__DIR__+"/../../SAPlayer/Skeleton.escript");
    loadOnce(__DIR__+"/Chicken.escript");
    
    var skeleton = new Skeleton();
    skeleton.loadFile(__DIR__+"/resources/chicken.minsg");
    for(var i=0; i<chickenCount; ++i)
    {
        var chickenClone = skeleton.skeleton.clone();
        var chicken = new Chicken(chickenClone, Rand.uniform(-100, 100), Rand.uniform(-100, 100));
        scene.addChild(chickenClone);
        this.chickens.pushBack(chicken);
    }
};

ChickenHandler.loop ::= fn()
{
    foreach(this.chickens as var chicken)
        chicken.move();
};

