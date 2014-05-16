/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:PADrend] PADrend/EventLoop/RenderingPass.escript
 **
 **/

PADrend.RenderingPass := new Type();
var RenderingPass = PADrend.RenderingPass;

RenderingPass._printableName ::= "RenderingPass";
RenderingPass.id := void;				//!< Can be used to identify the RenderingPass
RenderingPass.camera := void;			//!< Camera used for rendering
RenderingPass.renderingFlags := void;
RenderingPass.renderingLayers := void;
RenderingPass.rootNode := void;			//!< The rendered root node
RenderingPass.clearColor := void;		//!< Util.Color4f or false

//! (ctor)
RenderingPass._constructor ::= fn(_id,
								MinSG.Node _rootNode,
								MinSG.AbstractCameraNode _camera, 
								Number _renderingFlags, 
								[Util.Color4f,false] _clearColor,
								Number _renderingLayers = 1
								){
	this.id = _id;
	this.camera = _camera;
	this.renderingFlags = _renderingFlags;
	this.rootNode = _rootNode;
	this.clearColor = _clearColor.clone();
	this.renderingLayers = _renderingLayers;
};


//! Render the stored scene
RenderingPass.execute ::= fn(){
	PADrend.renderScene( this.rootNode, this.camera, this.renderingFlags, this.clearColor, this.renderingLayers);
};

RenderingPass.getCamera ::= 		fn(){	return camera;	};
RenderingPass.getClearColor ::= 	fn(){	return clearColor;	};
RenderingPass.getId ::= 			fn(){	return id;	};
RenderingPass.getRenderingFlags ::= fn(){	return renderingFlags;	};
RenderingPass.getRenderingLayers ::=fn(){	return renderingLayers;	};
RenderingPass.getRootNode ::= 		fn(){	return rootNode;	};

// ------------------------------------------------------------------------------
