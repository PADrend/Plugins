/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/NodeConfig/AvailableNodes.escript
 ** Collection of factories for new nodes.
 **/


var m = {
	"DirectionalLight" : 	fn(){	return new MinSG.LightNode( MinSG.LightNode.DIRECTIONAL );	},
	"GenericMetaNode" : 	fn(){	return new MinSG.GenericMetaNode();	},
	"ListNode" : 			fn(){	return new MinSG.ListNode();	},
	"Orthographic Camera" : fn(){	return new MinSG.CameraNodeOrtho();	},
	"Perspective Camera" : 	fn(){	return new MinSG.CameraNode();	},
	"PointLight" : 			fn(){	return new MinSG.LightNode( MinSG.LightNode.POINT );	},
	"SpotLight" : 			fn(){	return new MinSG.LightNode( MinSG.LightNode.SPOT );	},
};



return m;

// ------------------------------------------------------------------------------

