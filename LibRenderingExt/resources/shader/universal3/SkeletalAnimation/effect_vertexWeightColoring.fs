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

struct CompositeColor {
	vec4 ambient;
	vec4 diffuse;
	vec4 specular;
};

varying vec4 debugColor;
varying float debug;

void addFragmentEffect(inout CompositeColor color) {
	if(debug > 0.9) {
        color.ambient = debugColor*0.2;
        color.diffuse = debugColor;
        color.specular = debugColor;
    }
}
