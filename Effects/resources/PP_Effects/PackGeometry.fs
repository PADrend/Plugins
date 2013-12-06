#version 130

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2009-2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/*!	PackGeometry - Shader that packs the geometry information for each pixel
	               into the color buffers
	2009-12-08 - Benjamin Eikel
 */

in vec4 position;
in vec3 normal;
in vec4 color;

out vec4 fragData[5];

struct sg_MaterialParameters {
	vec4 ambient;
	vec4 diffuse;
	vec4 specular;
	float shininess;
};
uniform sg_MaterialParameters sg_Material;
uniform bool sg_useMaterials;

void main(void) {
	// Store the depth value into the last component of the position.
	fragData[0] = vec4(position.xyz / position.w, gl_FragCoord.z);
	// Store the shininess coefficient in the last component of the normal.
	if(sg_useMaterials) {
		fragData[1] = vec4(normalize(normal), sg_Material.shininess);
		fragData[2] = sg_Material.ambient;
		fragData[3] = sg_Material.diffuse;
		fragData[4] = sg_Material.specular;
	} else {
		fragData[1] = vec4(normalize(normal), 64.0);
		fragData[2] = color;
		fragData[3] = color;
		fragData[4] = vec4(1.0, 1.0, 1.0, 1.0);
	}
}
