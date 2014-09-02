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
 **	[Plugin:NodeEditor/EditNodeTraits]
 ** Collection of traits for editNodes (meta nodes for direct interactions in the 3-d-space).
 **
 ** \note this file depends on PADrend (e.g. extension 'PADrend_UIEvent'), but all other dependencies to high-level
 **			plugins should be avoided.
 **
 **/

declareNamespace($EditNodes);

// --------------------------------------------------------------------------------
/*!
*/
EditNodes.AnnotatableTrait := new Traits.GenericTrait("EditNodes.AnnotatableTrait");
{
	var t = EditNodes.AnnotatableTrait;
	
	t.attributes._activeAnnotationMessage @(private) := void; 
	
	t.attributes.setAnnotation ::= fn(message){
		if(!_activeAnnotationMessage && message){ // activate
			//! \see PADrend.EventLoop
			registerExtension('PADrend_AfterRenderingPass',this->fn(...){
				if( this.isDestroyed() || !this.isActive() || !this.isSet($_activeAnnotationMessage) || !this._activeAnnotationMessage)
					return Extension.REMOVE_EXTENSION;
				GLOBALS.frameContext.showAnnotation(this, _activeAnnotationMessage, 0, false);
			});
		}
		_activeAnnotationMessage = message;
	};
	t.attributes.hideAnnotation ::= fn(){	setAnnotation(void);	};
	t.onInit += fn(MinSG.Node node){}; // require  MinSG.Nodes.
}

/*! Make the given MinSG.Node colorable. This is internally done by adding MaterialStates.
	Adds the following methods:

	>	self Node.setColor(Util.Color4f color)
	>	self Node.pushColor(Util.Color4f color)
	>	self Node.popColor()
*/
EditNodes.ColorTrait := new Traits.GenericTrait("EditNodes.ColorTrait");
{
	var t = EditNodes.ColorTrait;
	t.attributes.popColor ::= fn(){
		var m;
		foreach(this.getStates() as var s) // get the last material state
			if(s---|>MinSG.MaterialState)
				m=s;
		if(m)
			this-=m;
	};
	t.attributes.pushColor ::= fn(Util.Color4f color){
		this += (new MinSG.MaterialState).setAmbient( color ).setDiffuse( color );
		return this;
	};
	t.attributes.setColor ::= fn(Util.Color4f color){
		popColor();
		pushColor(color);
		return this;
	};
	t.onInit += fn(MinSG.Node node,[Util.Color4f,void] color=void){
		if(color)
			node.setColor(color);
	};
}


/*! Make the given MinSG.Node clickable. Adds the following methods:

	>	void Node.onClick(UI.Event)		(extendable MultiProcedure)
*/
EditNodes.ClickableTrait := new Traits.GenericTrait("EditNodes.ClickableTrait");
{
	var t = EditNodes.ClickableTrait;
	t.attributes.onClick @(init) := MultiProcedure;
	t.onInit += fn(MinSG.Node node){};
}

/*! Make the given MinSG.Node draggable. Adds the following methods:

	>	void Node.onDraggingStart(UI.Event)		(extendable MultiProcedure)
	>	void Node.onDragging(UI.Event)			(extendable MultiProcedure)
	>	void Node.onDraggingStop()				(extendable MultiProcedure)

	\note Adds the EditNodes.ClickableTrait if not already present.
*/
EditNodes.DraggableTrait := new Traits.GenericTrait("EditNodes.DraggableTrait");
{
	var t = EditNodes.DraggableTrait;
	t.attributes.onDraggingStart @(init) := MultiProcedure;
	t.attributes.onDragging @(init) := MultiProcedure;
	t.attributes.onDraggingStop @(init) := MultiProcedure;

	t.onInit += fn(MinSG.Node node){
		Traits.assureTrait(node,EditNodes.ClickableTrait);

		//! \see EditNodes.ClickableTrait
		node.onClick += fn(evt){
			onDraggingStart(evt);

			registerExtension('PADrend_UIEvent',this->fn(evt){
				if(this.isDestroyed()){
					if(this.isSet($onDraggingStop))
						onDraggingStop();
					return Extension.REMOVE_EXTENSION;									
				}
				for(var n=this;n;n=n.getParent()){ // if the node is inactive, stop dragging
					if(!n.isActive()){
						onDraggingStop();
						return Extension.REMOVE_EXTENSION;
					}
				}
				if(evt.type==Util.UI.EVENT_MOUSE_BUTTON && !evt.pressed){
					onDraggingStop();
					return Extension.REMOVE_EXTENSION;
				}else if(evt.type == Util.UI.EVENT_MOUSE_MOTION){
					onDragging(evt);
				}
				return Extension.CONTINUE;
			});
		};

	};
}

/*! Allows to use the given Node for transformations along an axis (local 1,0,0).
	Adds the following methods:

	>	void Node.onTranslationStart()								(extendable MultiProcedure)
	>	void Node.onTranslate(Geometry.Vec3 worldTranslation)		(extendable MultiProcedure)
	>	void Node.onTranslationStop(Geometry.Vec3 worldTranslation)	(extendable MultiProcedure)

	\note Adds the EditNodes.DraggableTrait if not already present.
	\see EditNodes.DraggableTrait
*/
EditNodes.TranslatableAxisTrait := new Traits.GenericTrait("EditNodes.TranslatableAxisTrait");
{
	var t = EditNodes.TranslatableAxisTrait;
	t.attributes.onTranslate @(init) := MultiProcedure; // fn(Geometry.Vec3)
	t.attributes.onTranslationStart @(init) := MultiProcedure; //fn(){...}
	t.attributes.onTranslationStop @(init) := MultiProcedure; //fn(){Geometry.Vec3}

	t.attributes.__NE_TranslAxis_axis_ws @(private) := void;
	t.attributes.__NE_TranslAxis_initialPos_ws @(private) := void;
	t.attributes.__NE_TranslAxis_currentTranslation_ws @(private) := void;

	t.onInit += fn(MinSG.Node node){
		Traits.assureTrait(node,EditNodes.DraggableTrait);

		//! \see EditNodes.DraggableTrait
		node.onDraggingStart += fn(evt){
			// store the nodes translation axis in world space
			this.__NE_TranslAxis_axis_ws = new Geometry.Line3(this.getWorldOrigin(),
										(this.getWorldTransformationMatrix() * new Geometry.Vec4(1,0,0,0)).xyz().normalize());
			// store initial closest point to the mouse
			this.__NE_TranslAxis_initialPos_ws = __NE_TranslAxis_axis_ws.getClosestPointToRay(
										Util.requirePlugin('PADrend/Picking').getPickingRay( [evt.x,evt.y] ));
			__NE_TranslAxis_currentTranslation_ws = new Geometry.Vec3(0,0,0);
			onTranslationStart();
		};

		//! \see EditNodes.DraggableTrait
		node.onDragging += fn(evt){
			var newPos_ws = __NE_TranslAxis_axis_ws.getClosestPointToRay(
								Util.requirePlugin('PADrend/Picking').getPickingRay( [evt.x,evt.y] ));
			__NE_TranslAxis_currentTranslation_ws = newPos_ws-__NE_TranslAxis_initialPos_ws;
			onTranslate(__NE_TranslAxis_currentTranslation_ws);
		};

		//! \see EditNodes.DraggableTrait
		node.onDraggingStop += fn(){
			onTranslationStop(__NE_TranslAxis_currentTranslation_ws);
		};
	};
}
/*! Allows to use the given Node for transformations on a plane (local normal 0,0,1).
	Adds the following methods:

	>	void Node.onTranslationStart()								(extendable MultiProcedure)
	>	void Node.onTranslate(Geometry.Vec3 worldTranslation)		(extendable MultiProcedure)
	>	void Node.onTranslationStop(Geometry.Vec3 worldTranslation)	(extendable MultiProcedure)

	\note Adds the EditNodes.DraggableTrait if not already present.
	\see EditNodes.DraggableTrait
*/
EditNodes.TranslatablePlaneTrait := new Traits.GenericTrait("EditNodes.TranslatablePlaneTrait");
{
	var t = EditNodes.TranslatablePlaneTrait;
	t.attributes.onTranslate @(init) := MultiProcedure; // fn(Geometry.Vec3)
	t.attributes.onTranslationStart @(init) := MultiProcedure; //fn(){...}
	t.attributes.onTranslationStop @(init) := MultiProcedure; //fn(){Geometry.Vec3}

	t.attributes.__NE_TranslPlane_plane_ws @(private) := void;
	t.attributes.__NE_TranslPlane_initialPos_ws @(private) := void;
	t.attributes.__NE_TranslPlane_currentTranslation_ws @(private) := void;

	t.onInit += fn(MinSG.Node node){
		Traits.assureTrait(node,EditNodes.DraggableTrait);

		//! \see EditNodes.DraggableTrait
		node.onDraggingStart += fn(evt){
			// store the nodes translation plane in world space
			this.__NE_TranslPlane_plane_ws = new Geometry.Plane( this.getWorldOrigin(),
									(this.getWorldTransformationMatrix() * new Geometry.Vec4(0,0,1,0)).xyz().normalize()); // plane normal
			// store initial intersection
			this.__NE_TranslPlane_initialPos_ws = __NE_TranslPlane_plane_ws.getIntersection(
									Util.requirePlugin('PADrend/Picking').getPickingRay( [evt.x,evt.y] ));
			__NE_TranslPlane_currentTranslation_ws = new Geometry.Vec3(0,0,0);
			onTranslationStart();
		};

		//! \see EditNodes.DraggableTrait
		node.onDragging += fn(evt){
			var newPos_ws = __NE_TranslPlane_plane_ws.getIntersection(
									Util.requirePlugin('PADrend/Picking').getPickingRay( [evt.x,evt.y] ) );
			if(newPos_ws){
				__NE_TranslPlane_currentTranslation_ws = newPos_ws-__NE_TranslPlane_initialPos_ws;
				onTranslate(__NE_TranslPlane_currentTranslation_ws);
			}
		};

		//! \see EditNodes.DraggableTrait
		node.onDraggingStop += fn(){
			onTranslationStop(__NE_TranslPlane_currentTranslation_ws);
		};
	};
}
/*! Allows to use the given Node for rotation around a line defined by its origin and z-up-direction.
	Adds the following methods:

	>	void Node.onRotate(Number angle_deg, Geometry.Line3 axis_ws)			(extendable MultiProcedure)
	>	void Node.onRotationStart()												(extendable MultiProcedure)
	>	void Node.onRotationStop(Number angle_deg, Geometry.Line3 axis_ws)		(extendable MultiProcedure)

	\note Adds the EditNodes.DraggableTrait if not already present.
	\see EditNodes.DraggableTrait
*/
EditNodes.RotatableTrait := new Traits.GenericTrait("EditNodes.RotatableTrait");
{
	var t = EditNodes.RotatableTrait;
	t.attributes.onRotate @(init) := MultiProcedure; // fn(Number angle_deg, Geometry.Line3 axis_ws)
	t.attributes.onRotationStart @(init) := MultiProcedure; //fn(){...}
	t.attributes.onRotationStop @(init) := MultiProcedure; // fn(Number angle_deg, Geometry.Line3 axis_ws)

	t.onInit += fn(MinSG.Node node){
		Traits.assureTrait(node,EditNodes.DraggableTrait);

		node.__EditNode_rotationData @(private) := new ExtObject({
			$plane_ws : void,
			$pivot_ws : void,
			$initialDir_ws : void,
			$currentAngle_deg : 0
		});

		//! \see EditNodes.DraggableTrait
		node.onDraggingStart += fn(evt){
			var d = __EditNode_rotationData;

			// store the nodes translation plane in world space
			d.plane_ws = new Geometry.Plane( this.getWorldOrigin(),
									(this.getWorldTransformationMatrix() * new Geometry.Vec4(0,0,1,0)).xyz().normalize()); // plane normal
			d.pivot_ws = this.getWorldOrigin();

			var intersection = d.plane_ws.getIntersection( Util.requirePlugin('PADrend/Picking').getPickingRay( [evt.x,evt.y] ));
			d.initialDir_ws = intersection ? (intersection-d.pivot_ws).normalize() : new Geometry.Vec3(1,0,0);
			d.currentAngle_deg = 0;
			onRotationStart();
		};

		//! \see EditNodes.DraggableTrait
		node.onDragging += fn(evt){
			var d = __EditNode_rotationData;
			var intersection = d.plane_ws.getIntersection( Util.requirePlugin('PADrend/Picking').getPickingRay( [evt.x,evt.y] ));
			if(intersection){
				var dir = (intersection-d.pivot_ws).normalize();
				// sign( <dir1 x normal, dir2> ) * <dir1,dir2>
				d.currentAngle_deg = d.plane_ws.getNormal().cross(d.initialDir_ws).dot(dir).sign() *
						dir.dot(d.initialDir_ws).acos().radToDeg();

				onRotate(d.currentAngle_deg,new Geometry.Line3(d.pivot_ws,d.plane_ws.getNormal()));
			}
		};

		//! \see EditNodes.DraggableTrait
		node.onDraggingStop += fn(){
			var d = __EditNode_rotationData;
			onRotationStop(d.currentAngle_deg,new Geometry.Line3(d.pivot_ws,d.plane_ws.getNormal()));
		};
	};
}



/*! Allows to resize a Node if its projected size is outside a specific range.
	\param minSize = 60  enlarge the Node if the side length is smaller than this value
	\param maxSize = 300 shrink the Node if the side length is larger than this value

	Adds the following methods:
	>	self Node.adjustProjSize()

	\note The adjustProjSize() method has to be called repeatedly at a time when the frameContext
		is set with the proper projection matrix.
*/
EditNodes.AdjustableProjSizeTrait := new Traits.GenericTrait("EditNodes.AdjustableProjSizeTrait");
{
	var t = EditNodes.AdjustableProjSizeTrait;
	t.attributes.__NE_AdjSize_minSquared @(private) := 0;
	t.attributes.__NE_AdjSize_maxSquared @(private) := 0;

	t.attributes.adjustProjSize ::= fn(){
		var r = GLOBALS.frameContext.getProjectedRect( this );
		if(r.getWidth()*r.getHeight()<__NE_AdjSize_minSquared)
			this.scale(1.5);
		else if(r.getWidth()*r.getHeight()>__NE_AdjSize_maxSquared)
			this.scale(0.8);
	};

	t.onInit += fn(MinSG.Node node,Number min = 100,Number max = 300){
		(node->fn(min,max){
			this.__NE_AdjSize_minSquared = min*min;
			this.__NE_AdjSize_maxSquared = max*max;
		})(min,max);
	};
}

//---------------------------------------------------------------------------------

