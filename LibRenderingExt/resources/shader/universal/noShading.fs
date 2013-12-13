#version 120

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011-2013 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

varying vec4 pixelColor;

uniform bool sg_useMaterials;

struct sg_MaterialParameters {
	//vec4 emission;
	vec4 ambient;
	vec4 diffuse;
	vec4 specular;
	float shininess;
};

uniform sg_MaterialParameters sg_Material;

vec4 addLighting() {
	if (! sg_useMaterials) {
		return pixelColor;
	} else {
		return 0.3f * sg_Material.ambient + 0.7f * sg_Material.diffuse + 0.0f * sg_Material.specular;
	}
	return pixelColor;
}
