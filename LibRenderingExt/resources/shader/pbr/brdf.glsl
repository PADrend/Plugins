/*
	This file is part of the open source part of the
	Platform for Algorithm Development and Rendering (PADrend).
	Web page: http://www.padrend.de/
	Copyright (C) 2020-2021 Sascha Brandt <sascha@brandt.graphics>

	PADrend consists of an open source part and a proprietary part.
	The open source part of PADrend is subject to the terms of the Mozilla
	Public License, v. 2.0. You should have received a copy of the MPL along
	with this library; see the file LICENSE. If not, you can obtain one at
	http://mozilla.org/MPL/2.0/.
*/
#ifndef RENDERING_SHADER_BRDF_GLSL_
#define RENDERING_SHADER_BRDF_GLSL_

#define M_PI 3.1415926535897932384626433832795
#define M_PI_INV 0.3183098861837906715377675267450

vec3 fresnelSchlick(vec3 f0, vec3 f90, float VdotH) {
	return f0 + (f90 - f0) * pow(1.0 - clamp(VdotH, 0.0, 1.0), 5.0);
}

// Normal distribution function: D_GGX(H) = alpha^2 / ( PI * ((N dot H)^2 * (alpha^2-1) + 1)^2 )
float evalGGX(float alpha, float NdotH) {
	float a2 = alpha * alpha;
	float d = ((NdotH * a2 - NdotH) * NdotH) + 1.0;
	return a2 * M_PI_INV / (d * d);
}

// Visibility term: V(L,V) = G(L,V,H) / 4 (N dot L)(N dot V) (G = geometry term)
float evalSmithGGX(float NdotL, float NdotV, float alpha) {
	// Smith: G(L,V,H) = G_1(V) * G_1(L)
	// GGX: G_GGX(V) = 2(N dot V) / ( (N dot V) + sqrt(alpha^2 + (1-alpha^2)(N dot V)^2) )
	// Combined: V(L,V) = 1 / (( (N dot V) + sqrt(alpha^2 + (1-alpha^2)(N dot V)^2) ) * ( (N dot L) + sqrt(alpha^2 + (1-alpha^2)(N dot L)^2) ))
	float a2 = alpha*alpha;
	float G_GGX_V = NdotL + sqrt( (NdotV - NdotV * a2) * NdotV + a2 );
	float G_GGX_L = NdotV + sqrt( (NdotL - NdotL * a2) * NdotL + a2 );
	return 1 / ( G_GGX_V * G_GGX_L );
}

// General microfacet BRDF: f(L,V) = F(L,H) * V(L,V) * D(H)
vec3 evalSpecularBRDF(vec3 f0, vec3 f90, float alphaRoughness, float VdotH, float NdotL, float NdotV, float NdotH) {
	float D = evalGGX(alphaRoughness, NdotH); // normal distribution
	float V = evalSmithGGX(NdotL, NdotV, alphaRoughness); // visibility term
	vec3 F = fresnelSchlick(f0, f90, VdotH); // fresnel
	return D * V * F;
}

// Lambertian diffuse BRDF
vec3 evalDiffuseBRDF(vec3 f0, vec3 f90, vec3 diffuse, float VdotH) {
	return (1.0 - fresnelSchlick(f0, f90, VdotH)) * diffuse * M_PI_INV;
}

#endif /* end of include guard: RENDERING_SHADER_BRDF_GLSL_ */