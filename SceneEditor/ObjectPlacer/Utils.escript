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
 **	[Plugin:NodeEditor/ObjectPlacer/Utils]
 **/

declareNamespace($ObjectPlacer);

//
///*! The object contains a factory for nodes.
//	Adds  the following methods:
//	
//	- getNodeFactory() Should return an object with the nodeFactoryTrait.
//	
//	\param factory  The contained factory.
//*/
//ObjectPlacer.NodeFactoryOwnerTrait := new Traits.GenericTrait("ObjectPlacer.NodeFactoryOwnerTrait");
//{
//	var t = ObjectPlacer.NodeFactoryOwnerTrait;
//	t.attributes.getNodeFactory ::= fn(){	return this._nodeFactory;	};
//
//	t.onInit += fn(obj,factory){
//		obj._nodeFactory @(private) := factory;
//	};
//
//}

/*!
	\see Traits.CallableTrait
*/
ObjectPlacer.ObjectFactoryTrait := new Traits.GenericTrait("ObjectPlacer.ObjectFactoryTrait");
{
	var t = ObjectPlacer.ObjectFactoryTrait;
	
	t.attributes.getDescription ::= fn(){	return "Create a Node.";	};
	t.attributes.createNode ::= fn(){	return doCreateNode();	};

	//! --o
	t.attributes.doCreateNode ::= UserFunction.pleaseImplement;

	t.onInit += fn(obj){
		//! \see Traits.CallableTrait
		Traits.addTrait(obj,Traits.CallableTrait,fn(caller){	return doCreateNode();	});
	};
}

/*! DOCU!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! */
ObjectPlacer.AcceptsObjectCreatorsTrait := new Traits.GenericTrait("ObjectPlacer.AcceptsObjectCreatorsTrait");
{
	var t = ObjectPlacer.AcceptsObjectCreatorsTrait;


	//! ---o
	t.attributes.addObjectCreator ::= fn(creator){	
		outln( "New ObjectCreator received!");
	};
	
	t.onInit += fn(GUI.Component component){
	};
}		
	


/*!	Makes the given component draggable; when dropped, the function component.createObject( ),
	is called and the result is passed to the given object inserter function.
	
	\param objectInserter(Vec2 screenPos,object)  callable that accepts the created object 
	\param objectCreator()  callable that creates an object

	\see GUI.DraggableTrait
	\code
		Traits.addTrait(myComponent,GUI.DraggableObjectCreatorTrait, 
					ObjectPlacer.defaultNodeInserter, 
					fn(){	return new Geometry.Node(someMesh); });
	\endcode
*/
ObjectPlacer.DraggableObjectCreatorTrait := new Traits.GenericTrait("ObjectPlacer.DraggableObjectCreatorTrait");
{
	var t = ObjectPlacer.DraggableObjectCreatorTrait;

	t.onInit += fn(GUI.Component component,objectInserter,objectCreator){
		
	
		if(!Traits.queryTrait(component,GUI.DraggableTrait))
			Traits.addTrait(component,GUI.DraggableTrait);
		component.onDrag += fn(evt){
			var hasDraggingMarker = Traits.queryTrait(this,GUI.DraggingMarkerTrait);
			var hasDraggingConnector = Traits.queryTrait(this,GUI.DraggingConnectorTrait);
		
			if(hasDraggingMarker)
				getDraggingMarker().setEnabled(false);	//! \see GUI.DraggingMarkerTrait
			if(hasDraggingConnector)
				getDraggingConnector().setEnabled(false);
		
			var droppingComponent = gui.getComponentAtPos(gui.screenPosToGUIPos( [evt.x,evt.y] ));
			var droppingPossible = !droppingComponent.getParentComponent() || 
					Traits.queryTrait(droppingComponent,ObjectPlacer.AcceptsObjectCreatorsTrait); //! \see ObjectPlacer.AcceptsObjectCreatorsTrait
			
			if(hasDraggingConnector){
				getDraggingConnector().clearProperties();
		
				getDraggingConnector().clearProperties();
				getDraggingConnector().addProperty(
					new GUI.ShapeProperty(GUI.PROPERTY_CONNECTOR_LINE_SHAPE,
						gui._createSmoothConnectorShape(droppingPossible ? GUI.GREEN : GUI.RED,1)));

				getDraggingConnector().setEnabled(true);
			}
			if(hasDraggingMarker)
				getDraggingMarker().setEnabled(true);
		};
		
		component.onDrop += [objectInserter,objectCreator]=>fn(objectInserter,objectCreator, evt){
			var droppingComponent = gui.getComponentAtPos(gui.screenPosToGUIPos( [evt.x,evt.y] ));
			if(Traits.queryTrait(droppingComponent,ObjectPlacer.AcceptsObjectCreatorsTrait)){
				droppingComponent.addObjectCreator(objectCreator); //! \see ObjectPlacer.AcceptsObjectCreatorsTrait
				return;
			}
			
			var droppingPossible = !droppingComponent.getParentComponent();
			if( !droppingPossible){
				PADrend.message("Dropping not possible.");
				return;
			}
			var obj = objectCreator();
			objectInserter([evt.x,evt.y],obj);

		};
	};
}

//ObjectPlacer.onNodeInserted := new MultiProcedure; //! \todo move to prominent place?

//! Place the given node at the given position and add it to the current scene.
ObjectPlacer.defaultNodeInserter := fn(screenPos,MinSG.Node node){
	screenPos = new Geometry.Vec2(screenPos);
	var Picking = Util.requirePlugin('PADrend/Picking');
	
	var pos = Picking.queryIntersection( screenPos );
	if(!pos)
		pos = PADrend.getCurrentSceneGroundPlane().getIntersection( Picking.getPickingRay(screenPos) );
	if(pos){
		var scene = PADrend.getCurrentScene();

//		print_r(pos);
		scene += node;

		// apply coordinate system corrections
		if(scene.hasSRT()){ // remove scene's rotation
			var correctionSRT = new Geometry.SRT;
			correctionSRT.setRotation( scene.getSRT().getRotation().getInverse() );
			node.setSRT( node.getSRT() * correctionSRT );
		}
		if(PADrend.isSceneCoordinateSystem_YUp(scene) && PADrend.isSceneCoordinateSystem_ZUp(node)){
			node.rotateLocal_deg(-90,new Geometry.Vec3(1,0,0));
		}else if(PADrend.isSceneCoordinateSystem_ZUp(scene) && PADrend.isSceneCoordinateSystem_YUp(node)){
			node.rotateLocal_deg(90,new Geometry.Vec3(1,0,0));
		}
		
		var snappingNormal = PADrend.getWorldUpVector();
		var nodeAnchor = node.getWorldBB().getRelPosition(	0.5-snappingNormal.x()*0.5,
															0.5-snappingNormal.y()*0.5,
															0.5-snappingNormal.z()*0.5);
															
//		var nodeAnchor = n.getBB().getCenter()+ new Geometry.Vec3(0,-n.getBB().getExtentY()*0.5,0);
		node.setWorldPosition(pos-nodeAnchor);
		NodeEditor.selectNode(node);
		
		executeExtensions('ObjectPlacer_OnObjectInserted',node);
//		ObjectPlacer.onNodeInserted(n);
	}else{
		PADrend.message("Could not place object: invalid position.");
	
	}
};

//----------------------------------------------------------------------------
