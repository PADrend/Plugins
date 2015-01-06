/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012,2014-2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
var T = new Type;

T._printableName ::= "RenderingPass";
T.id := void;				//!< Can be used to identify the RenderingPass
T.camera := void;			//!< Camera used for rendering
T.renderingFlags := void;
T.renderingLayers := void;
T.rootNode := void;			//!< The rendered root node
T.clearColor := void;		//!< Util.Color4f or false

//! (ctor)
T._constructor ::= fn(_id,
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
T.execute ::= fn(){
	PADrend.renderScene( this.rootNode, this.camera, this.renderingFlags, this.clearColor, this.renderingLayers);
	renderingContext.setImmediateMode(true);
};

T.getCamera ::= 		fn(){	return camera;	};
T.getClearColor ::= 	fn(){	return clearColor;	};
T.getId ::= 			fn(){	return id;	};
T.getRenderingFlags ::= fn(){	return renderingFlags;	};
T.getRenderingLayers ::=fn(){	return renderingLayers;	};
T.getRootNode ::= 		fn(){	return rootNode;	};

return T;
