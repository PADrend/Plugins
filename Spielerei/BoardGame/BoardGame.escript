/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

out("\n","-"*70,"\n");

GLOBALS.Game := new Namespace;

// ----------------------------------------------------------------

/*! GameObject
	Base object for all objects used in a game.	*/
Game.GameObject := new Type;
var GameObject = Game.GameObject;
GameObject._node := void;
GameObject._myGame := void;
GameObject._x := 0;
GameObject._y := 0;

GameObject._printableName ::= $GameObject;

//! (ctor)
GameObject._constructor ::= fn([Game.BoardGame,void] myGame){
	_node = new MinSG.ListNode();
	_node._gameObj := this;
	_myGame = myGame;
};


/*! Add the model with the given modelId to this GameObject.
	\note The modelId has to be registered at the current boardGame by registerModel(...) */
GameObject.addModel ::= fn(modelId,[Geometry.Vec3,void] position=void){
	var model = getGame().createModel(modelId);
	model._gameObj := this;
	foreach(MinSG.collectLeafNodes(model) as var n)
		n.onClick := this->fn(evt){	onClick();	};
	_node += model;
	if(position)
		_node.moveRel(position);
};
GameObject.destroy ::= fn(){
	if(getGame() && getGame().getSelectedObject() == this)
		getGame().selectObject(void);
	try{
		onDestruction();
	}catch(e){
		Runtime.warn(e);
	}
	onClick = fn(){};
	
	registerExtension('PADrend_AfterFrame',_node->fn(...){
		var start = Util.Timer.now();
		var blending = new MinSG.BlendingState();
		this += blending;
		
		while(true){
			var d = (Util.Timer.now()-start)/1.0;
			if(d>=1.0)
				break;
			blending.setBlendConstAlpha(1-d);
			yield;
		}
		
		MinSG.destroy(this);
		return Extension.REMOVE_EXTENSION;	
	});
};

//! Get the BoardGame
GameObject.getGame ::= fn(){
	return _myGame;
};
//! Get the internal MinSG.Node
GameObject.getNode ::= fn(){
	return _node;
};
//! Get the position of the internal MinSG.Node as Geometry.Vec3
GameObject.getNodePosition ::= fn(){
	return _node.getRelPosition();
};
//! Get the x position on the board
GameObject.getX ::= fn(){
	return _x;
};
//! Get the y position on the board
GameObject.getY ::= fn(){
	return _y;
};


/*! ---o
	This function is called whenever a model of this gameObject is clicked at. */
GameObject.onClick := fn(){
	out(this," has been clicked!\n");
};

/*! ---o
	This function is called when the object is destroyed. */
GameObject.onDestruction ::= fn(){
};

//! (internal)
GameObject.registerChild ::= fn(Game.GameObject child){
	_node += child.getNode();
};
//! Change the object's size
GameObject.scale ::= fn(factor){
	_node.scale(factor);
};
//! Rotate the object's node around th up-axis
GameObject.rotate ::= fn(deg){
	_node.rotateLocal_deg(deg, new Geometry.Vec3(0,1,0));
};
//! Set the object's color (0..1 red ,0..1 green,0..1 blue)
GameObject.setColor ::= fn(r,g,b){
	if(!this.isSet($_materialState) || !_materialState){
		this._materialState := new MinSG.MaterialState();
		_node += _materialState;
	}
	_materialState.setAmbient( new Util.Color4f(r*0.5,g*0.5,b*0.5,1.0));
	_materialState.setDiffuse( new Util.Color4f(r,g,b,1.0));
};
//! (internal) Change the internal MinSG.Node's position
GameObject.setNodePosition ::= fn(Geometry.Vec3 pos){
	_node.setRelPosition(pos);
};
//! Change the position of the object on the board.
GameObject.setPosition ::= fn(x,y){
	_x = x;
	_y = y;
	setNodePosition(new Geometry.Vec3(x,0,y));
};


// --------------------------------------------------------------------
Game.BoardGame := new Type(Game.GameObject);

var BoardGame = Game.BoardGame;
BoardGame._printableName ::= $BoardGame;

BoardGame._modelRegistry := void; //@(init)
BoardGame._fields := void;
BoardGame._selectedObject := void;
BoardGame._selectionHighlightState := void;

//! (ctor)
BoardGame._constructor ::= fn()@(super(void)){
	_modelRegistry = new Map();
	getNode().name := "BoardGame";
	
	// disable backface culling
	var cfs = new MinSG.CullFaceState();
	cfs.setCullingEnabled(false);
	getNode() += cfs;
	
	_fields = new Map();
	_selectionHighlightState = new MinSG.ScriptedState();
	_selectionHighlightState.doEnableState = fn(node,params){
		if (!isActive())
			return MinSG.STATE_SKIPPED;
			
		if(params.getFlag(MinSG.BOUNDING_BOXES))
			return MinSG.STATE_OK;
		params.setFlag(MinSG.BOUNDING_BOXES | MinSG.USE_WORLD_MATRIX);
		node.display(frameContext,params);
		return MinSG.STATE_SKIP_RENDERING;
	};
};

BoardGame.clear ::= fn(){
	foreach(_fields as var f){
		if(f)
			f.destroy();
	}
	_fields.clear();
};

BoardGame.clearStones ::= fn(){
	foreach(_fields as var f){
		if(f && !f.empty())
			f.getStone().destroy();
	}
};

/*! Create and return a BoardGame.Field-Object at the given position. */
BoardGame.createField ::= fn(x,y){
	if(getField(x,y)){
		Runtime.warn("Field already exists at ("+x+","+y+")");
		return void;
	}
	var field = new Game.Field(this);
	registerChild(field);
	field.setPosition(x,y);
	_fields[""+x+","+y] = field;
	return field;
};

//! internal helper
BoardGame.createBox ::= fn(wx,wy,wz){
	var mb = new Rendering.MeshBuilder();
	mb.color(new Util.Color4f( 1,1,1,1));
	mb.addBox(new Geometry.Box(new Geometry.Vec3(0.0,wy*0.5,0.0),wx,wy,wz));
	var b = new MinSG.GeometryNode(mb.buildMesh());
	b.rotateLocal_deg(0.001,new Geometry.Vec3(1,0,0));
	return b;
};

/*! Get a MinSG.Node from the modelRegistry by modelId.
	The modelRegistry is filled while initializing a level.	*/
BoardGame.createModel ::= fn(modelId){
	var entry = _modelRegistry[modelId];
	if(!entry){
		Runtime.warn("Unknown model: " + modelId);
		return createBox(0.9);
	}
	if(!entry[1]){
		var filename = entry[0];
		var node = void;
		out("Loading model:",filename,"\n");
		if(filename.endsWith(".minsg") || filename.endsWith(".dae") ){
			node = PADrend.getSceneManager().loadScene(filename);
		}else {
			node = MinSG.loadModel(filename);
		}
		if(!node){
			Runtime.warn("Could not load model: "+filename+" ("+modelId+")");
			node = createBox(0.9,0.9,0.9);
		}
		entry[1] = node;
	}
	return entry[1].clone();
};

/*! Create a BoardGame.Stone-Object on the given Field.
	\note The field has to be empty! */
BoardGame.createStone ::= fn(Game.Field field){
	if(!field.empty()){
		Runtime.warn("Can't create a Stone on an occupied field.");
		return void;
	}
	var stone = new Game.Stone(this);
	registerChild(stone);
	stone.setPosition(field.getX(),field.getY());
	field.setStone(stone);
	return stone;
};

//! Returns the field at the given position and void if no field exists at the given position. 
BoardGame.getField ::= fn(x,y){
	return _fields[""+x+","+y];
};

//! Returns the fields.
BoardGame.getFields ::= fn(){
	return _fields;
};

//! Returns the currently selected Game.GameObject or void if none is selected.
BoardGame.getSelectedObject ::= fn(){
	return _selectedObject;
};

/*! Output a message.
	\note can have arbitrary many parameters */
BoardGame.message ::= fn(p...){
	PADrend.message(p.implode(""));
};

/*! ---o
	Called when the game is started.
	\note all fields should already exist.
	\note the initial stones can (or should) be created here */
BoardGame.onStart ::= fn(){

};

//! Start the game
BoardGame.start ::= fn(){
	PADrend.registerScene(this.getNode());
	PADrend.selectScene(this.getNode());
	message("Game started.");
	onStart();
};

/*! Register a model with the given modelId.
	@param modelId The model's id
	@param file The name of a model's file ( '.minsg' or '.mmf') or a MinSG.Node	*/
BoardGame.registerModel ::= fn(String modelId,[String,MinSG.Node] model){
	if(model---|>MinSG.Node)
		_modelRegistry[modelId] = ["?",model];
	else
		_modelRegistry[modelId] = [model,void];
};

/*! Select an Game.GameObject or unselect by passing void.
	\note The selected object is highlighted and can be highlighted calling getSelectedObject(). */
BoardGame.selectObject ::= fn( [Game.GameObject,void] obj){
	if(_selectedObject)
		_selectedObject.getNode() -= _selectionHighlightState;
	_selectedObject = obj;
	if(_selectedObject)
		_selectedObject.getNode() += _selectionHighlightState;
	// onSelectionChanged ???
};


BoardGame.initParticleEmitter ::= fn(Game.GameObject obj, Number duration,red=2,green=0,blue=0){

	// create particle node
	var particleNode = new MinSG.ParticleSystemNode;
	var mat = new MinSG.MaterialState;
	mat.setAmbient(new Util.Color4f(red,green,blue));
	particleNode += mat;
	// render a quad facing the camera for each particle
	particleNode.setRenderer(MinSG.ParticleSystemNode.BILLBOARD_RENDERER);

	// we don't want solid quads to be rendered, so we add a default
	// particle texture and some additive blending.
	var blendState = new MinSG.BlendingState;
	blendState.setBlendEquation(Rendering.BlendEquation.FUNC_ADD);
	blendState.setBlendFuncSrc(Rendering.BlendFunc.SRC_ALPHA);
	blendState.setBlendFuncDst(Rendering.BlendFunc.ONE);
	blendState.setBlendDepthMask(false);
	particleNode.addState(blendState);

	var textureState = new MinSG.TextureState;
	var t = Rendering.createTextureFromFile("./resources/Particles/particle.png");
	if(t)
		textureState.setTexture(t);
	particleNode.addState(textureState);

	PADrend.getCurrentScene().addChild(particleNode);	
	
	
	
	// register behaviors
	var bMgr = PADrend.getSceneManager().getBehaviourManager();

	// emitter
	var emitter = new MinSG.ParticlePointEmitter(particleNode);
	emitter.setMinLife(0.6);
	emitter.setMaxLife(1.5);
	emitter.setMinSpeed(0.1);
	emitter.setMaxSpeed(0.5);
	emitter.setMinColor(new Util.Color4f(1, 0.5, 0, 1));
	emitter.setMaxColor(new Util.Color4f(1, 0.7, 0, 1));
	emitter.setMinWidth(0.3 * obj.getNode().getWorldBB().getExtentMax());
	emitter.setMaxWidth(0.7 * obj.getNode().getWorldBB().getExtentMax());
	emitter.setDirection(new Geometry.Vec3(0,1,0));
	emitter.setDirectionVarianceAngle(40);
	emitter.setSpawnNode(obj.getNode());
	bMgr.registerBehaviour(emitter);

	PADrend.planTask(duration,fn(manager,behavior){		manager.removeBehaviour(behavior);	}.bindLastParams(bMgr,emitter));
	
	var animator = new MinSG.ParticleAnimator(particleNode);
	bMgr.registerBehaviour(animator);

	var affector = new MinSG.ParticleGravityAffector(particleNode);
	affector.setGravity(new Geometry.Vec3(0, 1, 0));
	bMgr.registerBehaviour(affector);

	var fader = new MinSG.ParticleFadeOutAffector(particleNode);
	bMgr.registerBehaviour(fader);


	PADrend.planTask(duration*3,fn(manager,behaviors,particleNode){	
		foreach(behaviors as var b)
			manager.removeBehaviour(b);
			MinSG.destroy(particleNode);
		
	}.bindLastParams(bMgr,[animator,affector,fader],particleNode));




	// the fade out affector applies a linear fade out of the alpha
	// channel of the particle color.

	

};


// ----------------------------------------

// ---|> GameObject
Game.Field := new Type(Game.GameObject);

var Field = Game.Field;
Field._printableName ::= $Field;
Field._stone := void;

//! (ctor)
Field._constructor ::= fn(Game.BoardGame game)@(super(game)){
};

//! Returns true iff there is no Stone on this field.
Field.empty ::= fn(){
	return !_stone;
};

//! Returns the stone currently on this field.
Field.getStone ::= fn(){
	return _stone;
};

//! ---|> GameObject
Field.onDestruction ::= fn(){
	if(!empty()){
		var s = _stone;
		_stone = void;
		s.destroy();
		getGame()._fields[""+getX()+","+getY()] = void; // not so nice...
	}
};

/*! (internal) Set a stone on this field.
	\note Should not be called directly: Eighter create a stone directly on the field (game.createStone(field)),
			or move it to the field (stone.moveToField(field)).	*/
Field.setStone ::= fn( [Game.Stone,void] newStone ){
	if(newStone!=_stone){
		if(newStone && newStone._field){
			 newStone._field.setStone(void);
		}
		_stone = newStone;
		if(_stone)
			_stone._field = this;
		onStoneChanged(_stone);
	}
};

/*! ---o
	Called when a stone is changed. */
Field.onStoneChanged := fn([Game.Stone,void] stone){
	// ...
};

// ----------------------------------------

// ---|> GameObject
Game.Stone := new Type(Game.GameObject);
var Stone=Game.Stone;
Stone._printableName ::= $Stone;

Stone._field := void;
Stone._targetPosition := void;
Stone._sourcePosition := void;
Stone._animationStart := void;

//! (ctor)
Stone._constructor ::= fn(Game.BoardGame game)@(super(game)){
};

//! Returns the field, the stone is located at.
Stone.getField ::= fn(){
	return _field;
};

//! ---|> GameObject
Stone.onDestruction ::= fn(){
	if(getField()){
		getField().setStone(void);
		_field = void;
	}
};

/*! Move this stone to the given field.
	\note You have to check if the target field is empty! */
Stone.moveToField ::= fn(Game.Field field){
	if(!field.empty() && field.getStone()!=this){
		Runtime.warn("Can't move to occupied field!");
		return;
	}
	field.setStone(this);

	_x = field.getX();
	_y = field.getY();

	if(!_targetPosition){
		registerExtension('PADrend_AfterFrame',this->fn(...){
			var d = (Util.Timer.now()-_animationStart)/1.0;
			if(d>=1.0){
				setNodePosition(_targetPosition);
				_targetPosition = false;
				return Extension.REMOVE_EXTENSION;	
			}
			setNodePosition( Geometry.interpolateCubicBezier(_sourcePosition,
												_sourcePosition+new Geometry.Vec3(0,1,0),
												_targetPosition+new Geometry.Vec3(0,1,0),
												_targetPosition,d) );

			return Extension.CONTINUE;
		
		});
	}
	_animationStart = Util.Timer.now();
	_sourcePosition = getNodePosition();
	_targetPosition = new Geometry.Vec3(getX(),0,getY());

};
		

