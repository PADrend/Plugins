/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
declareNamespace($SVS);

loadOnce(__DIR__ + "/SphericalSamplePoint.escript");

/**
 * Generate sample from the vertex positions of a mesh.
 * 
 * @return Array of MinSG.SphericalSampling.SamplePoints
 */
SVS.createSamplesFromMesh := fn(Rendering.Mesh mesh, String sampleName) {
	var samples = [];
	var accessor = Rendering.PositionAttributeAccessor.create(mesh, Rendering.VertexAttributeIds.POSITION);
	for(var i = 0; accessor.checkRange(i); ++i) {
		var point = new MinSG.SphericalSampling.SamplePoint(accessor.getPosition(i));
		point.description = sampleName + " " + i;
		samples += point;
	}
	return samples;
};

/**
 * Generate sample positions for the requested number of increments of spherical coordinates.
 * 
 * @return Array of MinSG.SphericalSampling.SamplePoints
 */
SVS.createSphericalCoordinateSamples := fn(Number inclinationSegments, Number azimuthSegments) {
	var inclinationIncrement = Math.PI / inclinationSegments;
	var azimuthIncrement = 2 * Math.PI / azimuthSegments;
	var samples = [];
	{
		var point = new MinSG.SphericalSampling.SamplePoint(new Geometry.Vec3(0, 1, 0));
		point.description = "Spherical (0, 0) ";
		samples += point;
	}
	for(var inclination = inclinationIncrement; inclination < Math.PI; inclination += inclinationIncrement) {
		for(var azimuth = 0; azimuth < 2 * Math.PI; azimuth += azimuthIncrement) {
			var position = Geometry.Sphere.calcCartesianCoordinateUnitSphere(inclination, azimuth);
			var point = new MinSG.SphericalSampling.SamplePoint(position);
			point.description = "Spherical (" + inclination.radToDeg() + ", " + azimuth.radToDeg() + ") ";
			samples += point;
		}
	}
	{
		var point = new MinSG.SphericalSampling.SamplePoint(new Geometry.Vec3(0, -1, 0));
		point.description = "Spherical (180, 0) ";
		samples += point;
	}
	return samples;
};

/**
 * Generate the requested number of random sample positions by generating random spherical coordinates.
 * 
 * @return Array of MinSG.SphericalSampling.SamplePoints
 */
SVS.createRandomSphericalCoordinateSamples := fn(Number numSamples) {
	var samples = [];
	for(var sample = 0; sample < numSamples; ++sample) {
		var inclination = (1.0 - Rand.uniform(0.0, 2.0)).acos();
		var azimuth = Rand.uniform(0.0, 2.0 * Math.PI);
		var position = Geometry.Sphere.calcCartesianCoordinateUnitSphere(inclination, azimuth);
		var point = new MinSG.SphericalSampling.SamplePoint(position);
		point.description = "Spherical (" + inclination.radToDeg() + ", " + azimuth.radToDeg() + ") ";
		samples += point;
	}
	return samples;
};
