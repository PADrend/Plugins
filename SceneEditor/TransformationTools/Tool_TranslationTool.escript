/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:SceneEditor/TransformationTools/Tool_TranslationTool.escript]
 **/

declareNamespace($TransformationTools);

loadOnce(__DIR__+"/EditNodeTraits.escript");
loadOnce(__DIR__+"/EditNodeFactories.escript");
loadOnce(__DIR__+"/ToolHelperTraits.escript");

//---------------------------------------------------------------------------------

TransformationTools.TranslationTool := new Type;
{
	var T = TransformationTools.TranslationTool;

	Traits.addTrait(T,TransformationTools.GenericNodeTransformToolTrait);

	T.localTransform @(init) := fn(){	return DataWrapper.createFromValue(false);	};
	T.smartSteps @(init) := fn(){	return DataWrapper.createFromValue(true);	};

	T.translationEditNode @(private) := void;
	T.gridSizes @(private,const) ::= { // scaling -> grid size
		0.0	:	0.0001,
		0.15 :	0.001,
		1.2 :	0.01,
		2.0 :	0.1,
		8.0 :	1.0
	};
	T.anchors := void;

	// experimental
	T.snapNode ::= fn(MinSG.Node node, anchors,MinSG.Node rootNode,Number searchDist){
		
		var searchBox = new Geometry.Box;
		searchBox.invalidate();
		var worldLocations = [];
		foreach(anchors as var anchor){
			var p = anchor();
			if(p---|>Geometry.Vec3){
				var worldPos = node.localPosToWorldPos(p);
				worldLocations += worldPos;
				searchBox.include(worldPos);
			}
		}
		searchBox.resizeAbs(searchDist*0.5);
		
		var nodes = MinSG.collectClosedNodesIntersectingBox(rootNode,searchBox);
//		print_r(searchBox,worldLocations,nodes);

		var nearestDistance = node.getWorldBB().getDiameter()*2;
		var nearestDiff;
		foreach(nodes as var n){
			if(n==node)
				continue;
			foreach(n.findAnchors() as var name,var anchor){
				var location = anchor();
				if(! (location---|>Geometry.Vec3))
					continue;
				var worldPos = n.localPosToWorldPos(location);
				foreach(worldLocations as var worldPos2){
					var diff = worldPos-worldPos2;
					var l = diff.length();
					if(l<nearestDistance){
						nearestDistance = l;
						nearestDiff = diff;
					}
				}
			}
		}
		if(nearestDiff && nearestDistance<searchDist)
			node.moveLocal(node.worldDirToLocalDir(nearestDiff));
//		print_r(nearestDiff);
		
//		var area2 = searchArea * 10;
//		foreach(anchors as var name,var anchor){
//			var location = anchor();
//			if( !(location---|>Geometry.Vec3) )
//				continue;
//			var worldLocation = node.localPosToWorldPos(location);
//			
//			var queryBox = new Geometry.Box(worldLocation,area2,area2,area2);
//			
//			var anchors = [];
//			rootNode.traverse( [node,queryBox,anchors] => fn(node,queryBox,anchors n){
//				if(n==node || ! n.getWorldBB().intersects(queryBox))
//					return $BREAK_TRAVERSAL;
//				anchors.append(n.findAnchors());
//			});
//			
//		}
//		MinSG.collectNodesIntersectingBox()
	};
	
	//! \see TransformationTools.UIToolTrait
	T.onToolInitOnce_static += fn(){
		var metaRootNode = new MinSG.ListNode;
		this.setMetaNode(metaRootNode);

		// ----

		this.translationEditNode = EditNodes.createTranslationEditNode();
		metaRootNode += translationEditNode;

		//! \see EditNodes.AnnotatableTrait
		Traits.addTrait( translationEditNode, EditNodes.AnnotatableTrait);

		//! \see EditNodes.AdjustableProjSizeTrait
		Traits.addTrait( translationEditNode, EditNodes.AdjustableProjSizeTrait);

		translationEditNode.onTranslationStart += this->fn(){
			this.applyNodeTransformations();				//! \see TransformationTools.NodeTransformationHandlerTrait
			if(this.getTransformedNodes().count()==1){		//! \see TransformationTools.NodeTransformationHandlerTrait
				this.anchors = this.getTransformedNodes()[0].findAnchors();
			}else{
				this.anchors = void;
			}
		};

		translationEditNode.onTranslate += this->fn(v){

			if(smartSteps()){
				var snap = 1;
				var currentScaling = this.translationEditNode.getRelScaling();
				foreach(gridSizes as var scaling, var grid){
					if(scaling>currentScaling)
						break;
					snap = grid;
				}
//				outln(snap);
				if(v.x()!=0)
					v.x(v.x().round(snap));
				if(v.y()!=0)
					v.y(v.y().round(snap));
				if(v.z()!=0)
					v.z(v.z().round(snap));
			}

			//! \see EditNodes.AnnotatableTrait
			this.translationEditNode.setAnnotation("World translation: "+v.x()+", "+v.y()+", "+v.z());

			//! \see TransformationTools.NodeTransformationHandlerTrait
			foreach( this.getTransformedNodesOrigins() as var node,var origin){
				var newMatrix = origin.clone().translate(node.worldDirToLocalDir(v));
				if(node.hasRelTransformationSRT()){
					node.setRelTransformation( newMatrix.toSRT() );
				}else{
					node.setRelTransformation(newMatrix);
				}
			}
			// snap (experimental)
			if(this.anchors&&!this.anchors.empty()){
				var node = this.getTransformedNodes()[0];
				var root = node;
				while(root.hasParent()) root=root.getParent();
				this.snapNode( this.getTransformedNodes()[0],this.anchors, root, this.translationEditNode.getRelScaling()*0.2 );
			}
		};

		translationEditNode.onTranslationStop += this->fn(v){
			//! \see EditNodes.AnnotatableTrait
			this.translationEditNode.hideAnnotation();

			//! \see TransformationTools.NodeTransformationHandlerTrait
			foreach( this.getTransformedNodesOrigins() as var node,var origin){
				var newMatrix = origin.clone().translate(node.worldDirToLocalDir(v));
				if(node.hasRelTransformationSRT()){
					node.setRelTransformation( newMatrix.toSRT() );
				}else{
					node.setRelTransformation(newMatrix);
				}
			}
			// snap (experimental)
			if(this.anchors&&!this.anchors.empty()){
				var node = this.getTransformedNodes()[0];
				var root = node;
				while(root.hasParent()) root=root.getParent();
				this.snapNode( this.getTransformedNodes()[0],this.anchors, root, this.translationEditNode.getRelScaling()*0.2 );
			}
			
			//! \see TransformationTools.NodeTransformationHandlerTrait
			this.applyNodeTransformations();
		};
		//! \see TransformationTools.FrameListenerTrait
		this.onFrame +=	translationEditNode->translationEditNode.adjustProjSize; //! \see EditNodes.AdjustableProjSizeTrait

		// ----

		var axisMarkerNode = new MinSG.GeometryNode(EditNodes.createLineAxisMesh());
		metaRootNode += axisMarkerNode;
		axisMarkerNode.deactivate();
		translationEditNode.onTranslationStart += axisMarkerNode->axisMarkerNode.activate;
		translationEditNode.onTranslationStop += axisMarkerNode->fn(...){ deactivate(); };
	};

	//! \see TransformationTools.FrameListenerTrait
	T.onFrame_static += fn(){
		//! \see TransformationTools.NodeTransformationHandlerTrait
		var nodes = getTransformedNodes();
		if(nodes.empty())
			return;

		var metaRootNode = this.getMetaNode();
		if(localTransform()){
			var wm = nodes[0].getWorldTransformationMatrix();
			metaRootNode.setRelTransformation(new Geometry.SRT(wm.transformPosition(0,0,0),
									wm.transformDirection(0,0,-1),wm.transformDirection(0,1,0),1.0));
		}else{
			metaRootNode.resetRelTransformation();
			metaRootNode.setWorldOrigin(MinSG.getCombinedWorldBB(nodes).getCenter());
		}
	};


	//! \see TransformationTools.ContextMenuProviderTrait
	T.doCreateContextMenu ::= fn(){
		return [
		"*Translation Tool*",
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Local translation",
			GUI.DATA_WRAPPER : localTransform,
			GUI.TOOLTIP : 	"When activated, the translation is performed relative \n"
							"to the coordinate system of the first selected node; \n"
							"otherwise, the world coordinates are used."
		},
		{
			GUI.TYPE : GUI.TYPE_BOOL,
			GUI.LABEL : "Smart steps",
			GUI.DATA_WRAPPER : smartSteps,
			GUI.TOOLTIP : 	"When activated, the translation vector is rounded \n"
							"according to the distance to the object. \n"
							"This may allow easier alignment."
		},
		// snap local position
		// snap world position
		// enter transformation manually
		'----'];
	};
}
//---------------------------------------------------------------------------------
