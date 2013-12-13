/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Lukas Kopecki
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
uniform mat4 bindMat;

void doJointTransformations(inout vec4 newPosition_hms, inout vec4 newNormal_hms, in int weightCount, in float weights[16], in float weightsIndex[16])
{    
    // bringing mesh into bind pose    
    newPosition_hms = vec4(newPosition_hms.xyz, 1.0);
    newNormal_hms = vec4(newNormal_hms.xyz, 1.0);
}

