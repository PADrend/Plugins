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

GLOBALS.Chicken := new Type();
Chicken.node := void;
Chicken.x := 0;
Chicken.z := 0;

Chicken.targetX := 0;
Chicken.targetZ := 0;

Chicken.velX := 0.1;
Chicken.velZ := 0.1;

Chicken.angle := 0;

Chicken.animationOffset := 0;

Chicken._constructor := fn(_node, _x, _z)
{
    this.x = _x;
    this.z = _z;
    
    node = _node;
    node.moveLocal(x, 0, z);
    
    var bhm = PADrend.getSceneManager().getBehaviourManager();
    bhm.registerBehaviour(node.getAnimation("std"));
    
    animationOffset = Rand.uniform(0, 100);
    
    this.getNewTargetPosition();
};

Chicken.move := fn()
{
    if(animationOffset > 0)
    {
        animationOffset--;
        if(animationOffset <= 0)
            node.startLoop("std");
    }
    
    
    var moveX = velX;
    var moveZ = velZ;
    var atX = false;
    var atZ = false;
    if(targetX != this.x)
    {
        if(x < targetX)
            x += velX;
        else
        {
            moveX = -velX;
            x -= velX;
        }
    }else
        atX = true;
    
    if(targetZ != this.z)
    {
        if(z < targetZ)
            z = velZ;
        else
        {
            z = -velZ;
            moveZ = -velZ;
        }
    }else
        atZ = true;
    
    node.moveLocal(new Geometry.Vec3(moveX, 0, moveZ));
    
    if(atX && atZ)
        this.getNewTargetPosition();
};

Chicken.getNewTargetPosition := fn()
{
    this.targetX := Rand.uniform(-100, 100);
    this.targetZ := Rand.uniform(-100, 100);
    
    var source = new Geometry.Vec3(x, 0, z);
    source.normalize();
    var target = new Geometry.Vec3(targetX, 0, targetZ);
    target.normalize();
    
    var angle = (source.getX() * target.getX() + source.getZ() * target.getZ()).acos();
    node.rotateRel_rad(angle, new Geometry.Vec3(0, 1, 0));
};


