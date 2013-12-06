#version 130

/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

uniform sampler2D depth;
uniform float border = 1.0;
uniform int[4] sg_viewport;

uniform int derivativeOrder = 1;
uniform bool edgeHighlightMode = false;
uniform float epsilon = 0.00001;

out vec4 fragColor;

float getDepth(in int x, in int y) {
	return texelFetch(depth, ivec2(x, y), 0).x;
}

// Sources for formulae:
// http://en.wikipedia.org/wiki/Finite_difference
// http://reference.wolfram.com/mathematica/ref/DifferenceDelta.html

float firstOrderPartialDerivativeApproximationX(in int x, in int y) {
	return 	  getDepth(x, y)
			- getDepth(x + 1, y);
}

float firstOrderPartialDerivativeApproximationY(in int x, in int y) {
	return 	  getDepth(x, y)
			- getDepth(x, y + 1);
}

float firstOrderDerivativeApproximation(in int x, in int y) {
	return 	  getDepth(x, y)
			- getDepth(x, y + 1)

			- getDepth(x + 1, y)
			+ getDepth(x + 1, y + 1);
}

float secondOrderPartialDerivativeApproximationX(in int x, in int y) {
	return 	      getDepth(x, y)
			- 2 * getDepth(x + 1, y)
			+     getDepth(x + 2, y);
}

float secondOrderPartialDerivativeApproximationY(in int x, in int y) {
	return 	      getDepth(x, y)
			- 2 * getDepth(x, y + 1)
			+     getDepth(x, y + 2);
}

float secondOrderDerivativeApproximation(in int x, in int y) {
	return 	      getDepth(x, y)
			- 2 * getDepth(x, y + 1)
			+     getDepth(x, y + 2)

			- 2 * getDepth(x + 1, y)
			+ 4 * getDepth(x + 1, y + 1)
			- 2 * getDepth(x + 1, y + 2)

			+     getDepth(x + 2, y)
			- 2 * getDepth(x + 2, y + 1)
			+     getDepth(x + 2, y + 2);
}

float thirdOrderPartialDerivativeApproximationX(in int x, in int y) {
	return 	-     getDepth(x, y)
			+ 3 * getDepth(x + 1, y)
			- 3 * getDepth(x + 2, y)
			+     getDepth(x + 3, y);
}

float thirdOrderPartialDerivativeApproximationY(in int x, in int y) {
	return 	-     getDepth(x, y)
			+ 3 * getDepth(x, y + 1)
			- 3 * getDepth(x, y + 2)
			+     getDepth(x, y + 3);
}

float thirdOrderDerivativeApproximation(in int x, in int y) {
	return 	      getDepth(x, y)
			- 3 * getDepth(x, y + 1)
			+ 3 * getDepth(x, y + 2)
			-     getDepth(x, y + 3)

			- 3 * getDepth(x + 1, y)
			+ 9 * getDepth(x + 1, y + 1)
			- 9 * getDepth(x + 1, y + 2)
			+ 3 * getDepth(x + 1, y + 3)

			+ 3 * getDepth(x + 2, y)
			- 9 * getDepth(x + 2, y + 1)
			+ 9 * getDepth(x + 2, y + 2)
			- 3 * getDepth(x + 2, y + 3)

			-     getDepth(x + 3, y)
			+ 3 * getDepth(x + 3, y + 1)
			- 3 * getDepth(x + 3, y + 2)
			+     getDepth(x + 3, y + 3);
}

vec4 addEffect(in ivec2 pos) {
	float diffX = firstOrderPartialDerivativeApproximationX(pos.x, pos.y);
	float diffY = firstOrderPartialDerivativeApproximationY(pos.x, pos.y);
	float diffXY = firstOrderDerivativeApproximation(pos.x, pos.y);

	float diffXX = secondOrderPartialDerivativeApproximationX(pos.x, pos.y);
	float diffYY = secondOrderPartialDerivativeApproximationY(pos.x, pos.y);
	float diffXXYY = secondOrderDerivativeApproximation(pos.x, pos.y);

	float diffXXX = secondOrderPartialDerivativeApproximationX(pos.x, pos.y);
	float diffYYY = secondOrderPartialDerivativeApproximationY(pos.x, pos.y);
	float diffXXXYYY = thirdOrderDerivativeApproximation(pos.x, pos.y);

	if(edgeHighlightMode) {
		// Check for extremum
		bool extremumX = diffX < epsilon && abs(diffXX) > epsilon;
		bool extremumY = diffY < epsilon && abs(diffYY) > epsilon;
		bool extremumXY = diffXY < epsilon && abs(diffXXYY) > epsilon;
		if(extremumX || extremumY || extremumXY) {
			return vec4(0.0, 0.0, 0.0, 1.0);
		}

		if(derivativeOrder > 2) {
			// Check for inflection point
			bool inflectionX = diffXX < epsilon && abs(diffXXX) > epsilon;
			bool inflectionY = diffYY < epsilon && abs(diffYYY) > epsilon;
			bool inflectionXY = diffXXYY < epsilon && abs(diffXXXYYY) > epsilon;
			if(inflectionX || inflectionY || inflectionXY) {
				return vec4(0.0, 0.0, 0.0, 1.0);
			}
		}
		return vec4(1.0);
	} else {
		if(derivativeOrder < 2) {
			return vec4(diffX + 0.5, diffY + 0.5, diffXY + 0.5, 1.0);
		} else if(derivativeOrder < 3) {
			return vec4(diffXX + 0.5, diffYY + 0.5, diffXXYY + 0.5, 1.0);
		} else {
			return vec4(diffXXX + 0.5, diffYYY + 0.5, diffXXXYYY + 0.5, 1.0);
		}
	}
}

void main(void) {
	ivec2 pos = ivec2(gl_FragCoord.xy) - ivec2(sg_viewport[0], sg_viewport[1]);

	int b = int(float(sg_viewport[2]) * border);

	if(pos.x < b) {
		fragColor = addEffect(pos);
	} else if(pos.x == b) {
		fragColor = vec4(1, 0, 0, 1);
	} else {
		float depthValue = getDepth(pos.x, pos.y);
		fragColor = vec4(depthValue, depthValue, depthValue, 1);
	}
}
