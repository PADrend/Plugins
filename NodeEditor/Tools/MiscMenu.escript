/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Mouns R. Husan Almarrani
 * Copyright (C) 2011-2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/Tools/MiscMenu.escript
 **/

NodeEditorTools.registerMenues_MiscTools := fn() {
	
	gui.registerComponentProvider('NodeEditor_NodeToolsMenu.~misc',fn(Array nodes){
		return nodes.empty() ? [] : [
			'----',
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Misc tools",
				GUI.MENU : 'NodeEditor_MiscToolsMenu',
				GUI.MENU_WIDTH : 150
			}
		];
	});
	
	gui.registerComponentProvider('NodeEditor_MiscToolsMenu.helper',[
		'----',
		"*Helper*",
		{
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Register all GeometryNodes",
			GUI.ON_CLICK	:	fn() {
									foreach(NodeEditor.getSelectedNodes() as var node) {
										PADrend.getSceneManager().registerGeometryNodes(node);
									}
								},
			GUI.TOOLTIP		:	"Register all GeometryNodes below the selected nodes at the SceneManager.\nIf a node has no identifier, a random one is generated."
		},

		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Convert to billboard",
			GUI.ON_CLICK : fn() {
				var nodes = NodeEditor.getSelectedNodes();
				out("\nCreating billboards: [");
				foreach(nodes as var node){
					var states=node.getStates();
					var bb=node.getBB();
					// find lower center
					var pos=node.getSRT() * ((bb.getCorner( Geometry.CORNER_xyz ) + bb.getCorner( Geometry.CORNER_XyZ )) * 0.5);
					var width=[bb.getExtentX(),bb.getExtentZ()].max()*node.getSRT().getScale();
					var height=bb.getExtentY()*node.getSRT().getScale();
					var billboard=new MinSG.BillboardNode( new Geometry.Rect(-width*0.5,0,width,height),false,true);
					foreach(states as var state)
						billboard.addState(state);
					billboard.setRelPosition(pos);
					node.getParent().addChild(billboard);
					MinSG.destroy(node);
					out(".");
				}
				out("]\n");
				NodeEditor.selectNode(void);
			},
			GUI.TOOLTIP : "Remove the selected node and insert a billboard at \nthat position having the same states."
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Print Node Info",
			GUI.ON_CLICK : fn() {
				foreach(NodeEditor.getSelectedNodes() as var node){
					NodeEditorTools.printNodeInfo(node);
				}
			},
			GUI.TOOLTIP : "Print node info depending on the node type."
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Remove node attributes",
			GUI.ON_CLICK : fn() {
				foreach(NodeEditor.getSelectedNodes() as var node){
					node.removeNodeAttributes();
				}
			},
			GUI.TOOLTIP : "Print node info depending on the node type."
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "GraphViz export ...",
			GUI.ON_CLICK : fn(){
				fileDialog("Export for GraphViz", PADrend.getDataPath(), ".dot",
					fn(fileName) {
						MinSG.GraphVizOutput.treeToFile(NodeEditor.getSelectedNode(),
														PADrend.getSceneManager(),
														new Util.FileName(fileName));
					};
				);
			},
			GUI.TOOLTIP :  "Export the selected sub graph as GraphViz DOT file."

		}
	]);
	
	gui.registerComponentProvider('NodeEditor_MiscToolsMenu.experiments',[
		'----',
		"*Experiments/Tests*"
	]);
	gui.registerComponentProvider('NodeEditor_MiscToolsMenu.experiments_experimentalBehaviors',[
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "New Behaviors [2013-07]",
			GUI.ON_CLICK : fn() {
				var b = new MinSG.SimplePhysics2;
				foreach( NodeEditor.getSelectedNodes() as var node)
					PADrend.getSceneManager().getBehaviourManager().startNodeBehavior(b,node);
			}
		}
	]);

	if(MinSG.isSet($ParticleSystemNode)){
		gui.registerComponentProvider('NodeEditor_MiscToolsMenu.experimentsParticles',[
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Particles: Burn!",
				GUI.ON_CLICK : fn() {
					foreach(NodeEditor.getSelectedNodes() as var node){
						// our new particle system, per default it allows 1000 particles at a time.
						// that's enough for us.
						// but we could increase or decrease it using setMaxParticleCount anytime.
						var psn = new MinSG.ParticleSystemNode();
						// we have to register all created behaviours so they are executed
						var bMgr = PADrend.getSceneManager().getBehaviourManager();

						// every particle system needs exactly ONE particle animator.
						// it takes care of moving the particles, collecting particles etc.
						// all other affectors/emitters only set forces, impacting the particles.
						bMgr.registerBehaviour(new MinSG.ParticleAnimator(psn));

						var nodeBB = node.getWorldBB();
						var particleWidth = nodeBB.getExtentMax();

						// to really get particles, someone needs to create them. this is the job
						// of the emitter. a particle system may have more than one emitter - but
						// most will only have one.
						var emitter = new MinSG.ParticlePointEmitter(psn);
						// just some values - have a look at ParticleEmitter for possible settings
						emitter.setMinLife(0.6);
						emitter.setMaxLife(1.5);
						emitter.setMinSpeed(0.1);
						emitter.setMaxSpeed(0.5);
						emitter.setMinColor(new Util.Color4f(1, 0.5, 0, 1));
						emitter.setMaxColor(new Util.Color4f(1, 0.7, 0, 1));
						emitter.setMinWidth(0.3 * particleWidth);
						emitter.setMaxWidth(0.7 * particleWidth);
						emitter.setDirection(PADrend.getWorldUpVector());
						emitter.setDirectionVarianceAngle(40);

						// this sets where the particles should spawn. per default they spawn
						// at the position of the particle system node - but we can set any
						// other node. in this case: the selected node.
						emitter.setSpawnNode(node);
						bMgr.registerBehaviour(emitter);

						// to get the effect of particles/flames being lighter than air, we
						// add a constant force pulling particles upwards 1 unit/second.
						var affector = new MinSG.ParticleGravityAffector(psn);
						affector.setGravity(new Geometry.Vec3(0, 1, 0));
						bMgr.registerBehaviour(affector);

						// the fade out affector applies a linear fade out of the alpha
						// channel of the particle color.
						bMgr.registerBehaviour(new MinSG.ParticleFadeOutAffector(psn));

						// render a quad facing the camera for each particle
						psn.setRenderer(MinSG.ParticleSystemNode.BILLBOARD_RENDERER);

						// we don't want solid quads to be rendered, so we add a default
						// particle texture and some additive blending.
						var blendState = new MinSG.BlendingState();
						blendState.setBlendEquation(Rendering.BlendEquation.FUNC_ADD);
						blendState.setBlendFuncSrc(Rendering.BlendFunc.SRC_ALPHA);
						blendState.setBlendFuncDst(Rendering.BlendFunc.ONE);
						blendState.setBlendDepthMask(false);
						psn.addState(blendState);

						var textureState = new MinSG.TextureState();
						var t=Rendering.createTextureFromFile(Util.requirePlugin('LibRenderingExt').getBaseFolder() + "/resources/texture/particle.png");
						if(t)
							textureState.setTexture(t);
						psn.addState(textureState);

						PADrend.getCurrentScene().addChild(psn);
						NodeEditor.selectNode(psn);

						if(MinSG.isSet($SoundEmittingBehaviour)){
							var noise = Sound.createNoise(700,10000);
							var b = new MinSG.SoundEmittingBehaviour(node);
							b.getSource().enqueueBuffer(noise);
							b.getSource().setLooping(true);
							b.getSource().setGain(0.1);
							PADrend.getSceneManager().getBehaviourManager().registerBehaviour(b);
						}
					}
				},
				GUI.TOOLTIP : "Add predefined particle system to the scene. Works properly for registered nodes only."
			}
		]);
	}
	
	if(MinSG.isSet($SoundEmittingBehaviour)){
		gui.registerComponentProvider('NodeEditor_MiscToolsMenu.experimentsSound',[
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Sound: Make some noise!",
				GUI.ON_CLICK : fn() {
	//	        	var noise = Sound.createNoise(4400,10000);
					var noise = Sound.createRectangleSound(80,4400,10000);
					foreach(NodeEditor.getSelectedNodes() as var node){
						var b = new MinSG.SoundEmittingBehaviour(node);
						b.getSource().enqueueBuffer(noise);
						b.getSource().enqueueBuffer(noise);
						b.getSource().enqueueBuffer(noise);
						b.getSource().enqueueBuffer(noise);
						b.getSource().enqueueBuffer(noise);
						b.getSource().enqueueBuffer(noise);

						PADrend.getSceneManager().getBehaviourManager().registerBehaviour(b);
					}

				}
			}
		]);
	}
	
	gui.registerComponentProvider('NodeEditor_MiscToolsMenu.experimentsOnClick',[
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "OnClick: Make interactive",
			GUI.TOOLTIP : "Demo for the PADrend.NodeInteraction functionality",
			GUI.ON_CLICK : fn() {
				var n = NodeEditor.getSelectedNode();
				out("The selected node can now be dragged around.\n");
				// simply add an onClick function
				n.onClick := fn(evt){
					out("Huhu!!! Drag me around!\n");
					registerExtension('PADrend_UIEvent',this->fn(evt){
						if(evt.type==Util.UI.EVENT_MOUSE_BUTTON && !evt.pressed){
							out("This is a nice place. I think I will stay here.\n");
							return Extension.REMOVE_EXTENSION;
						}else if(evt.type == Util.UI.EVENT_MOUSE_MOTION){
							this.moveRel(new Geometry.Vec3(evt.deltaX, 0, evt.deltaY) * 0.02);
						}
						return Extension.CONTINUE;
					});
				};
			}
		}
	]);
	
	gui.registerComponentProvider('NodeEditor_MiscToolsMenu.experimentsScriptedTests',[
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "ScriptedState test",
			GUI.TOOLTIP : "Demo for MinSG.ScriptedState.\nAdds the BOUNDING_BOXES flag when rendering \nthe attached node.",
			GUI.ON_CLICK : fn() {
				PADrend.message("The node has now bounding boxes.");
				var n = NodeEditor.getSelectedNode();

				var BBState = new Type( MinSG.ScriptedState );
				BBState.doEnableState ::= fn(node,params){
					if(params.getFlag(MinSG.BOUNDING_BOXES))
						return MinSG.STATE_OK;
					params.setFlag(MinSG.BOUNDING_BOXES | MinSG.USE_WORLD_MATRIX);
					node.display(frameContext,params);
					return MinSG.STATE_SKIP_RENDERING;
				};
				var state = new BBState();
				if( state---|>BBState ){
					out("Great magic is performed to make this possible!\n");
				}
				n+=state;
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "ScriptedNodeRendererState test",
			GUI.TOOLTIP : "Demo for MinSG.ScriptedNodeRendererState.\nRandomly skips rendered nodes.",
			GUI.ON_CLICK : fn() {
				PADrend.message("The nodes should now flicker...");
				var n = NodeEditor.getSelectedNode();

				var Renderer = new Type( MinSG.ScriptedNodeRendererState );
				Renderer._constructor ::= fn()@(super(MinSG.FrameContext.DEFAULT_CHANNEL)){};
				Renderer.displayNode @(override) ::= fn(node,params){
					if(Rand.equilikely(0,10)>8){
						return MinSG.FrameContext.NODE_HANDLED;
					}else{
						return MinSG.FrameContext.PASS_ON;
					}
				};
				n+=new Renderer();
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "ScriptedNodeBehaviour test (old)",
			GUI.TOOLTIP : "Demo for MinSG.ScriptedNodeBehaviour.",
			GUI.ON_CLICK : fn() {
				var Rotator = new Type(MinSG.ScriptedNodeBehaviour);
				Rotator._printableName @(override) ::= $Rotator;
				Rotator.duration @(private) := void;
				Rotator.endTime @(private) := void;

				//! (ctor)
				Rotator._constructor ::= fn(node,Number _duration)@(super(node)){	duration = _duration;	};
				//! ---|> ScriptedNodeBehaviour
				Rotator.onInit @(override) ::= fn(){
					PADrend.message("Round and round it goes.");
					endTime = getCurrentTime()+duration;
				};

				//! ---|> ScriptedNodeBehaviour
				Rotator.doExecute @(override) ::= fn(){
					if(getCurrentTime()>endTime){
						PADrend.message("Thats enough!");
						return  MinSG.AbstractBehaviour.FINISHED;
					}
					getNode().rotateLocal_deg(getTimeDelta()*100,PADrend.getWorldUpVector());
					return MinSG.AbstractBehaviour.CONTINUE;
				};
//					var r = new Rotator(3);
//				info(r) ;

				foreach(NodeEditor.getSelectedNodes() as var node){
					PADrend.getSceneManager().getBehaviourManager().registerBehaviour( new Rotator(node,3) );
				}
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "ScriptedBehavior test (new)",
			GUI.TOOLTIP : "Demo for MinSG.ScriptedBehavior.",
			GUI.ON_CLICK : fn() {
				var Rotator = new Type(MinSG.ScriptedBehavior);
				Rotator._printableName @(override) ::= $Rotator;
				Rotator.duration @(private) := void;
				Rotator.endTime @(private) := void;

				//! (ctor)
				Rotator._constructor ::= fn(Number _duration)@(super()){	duration = _duration;	};
				
				//! ---|> ScriptedBehavior
				Rotator.doPrepareBehaviorStatus @(override) ::= fn(status){
					outln("1. prepare (",status.getReferencedNode(),")");
				};

				//! ---|> ScriptedBehavior
				Rotator.doBeforeInitialExecute @(override) ::= fn(status){
					status.endTime := status.getCurrentTime() + this.duration;
					outln("2. start (",status.getReferencedNode(),")");
				};
				
				//! ---|> ScriptedNodeBehaviour
				Rotator.doExecute @(override) ::= fn(status){
					if(status.getCurrentTime()>status.endTime){
						return  MinSG.Behavior.FINISHED;
					}
					status.getReferencedNode().rotateLocal_deg(status.getTimeDelta()*100,PADrend.getWorldUpVector());
					return MinSG.Behavior.CONTINUE;
				};
				
				//! ---|> ScriptedNodeBehaviour
				Rotator.doFinalize @(override) ::= fn(status){
					outln("3. finish (",status.getReferencedNode(),")");
				};
				
				var behavior = new Rotator(3);

				foreach(NodeEditor.getSelectedNodes() as var node){
					PADrend.getSceneManager().getBehaviourManager().startNodeBehavior( behavior, node );
				}
				
				
				var SimpleBehavior = new Type(MinSG.ScriptedBehavior);
				{
					var T = SimpleBehavior;
					T._printableName @(override) ::= $SimpleBehavior;
					T.fun := void;
					T.it := void;

					//! (ctor)
					T._constructor ::= fn(_fun){	this.fun = _fun;	};
					
					//! ---|> ScriptedNodeBehaviour
					T.doExecute @(override) ::= fn(status){
						if(!this.it){
							this.it = this.fun(status);
							return this.it ? MinSG.Behavior.CONTINUE : MinSG.Behavior.FINISHED;
						}else{
							if(it.end())
								return MinSG.Behavior.FINISHED;
							this.it.next();
						}
					};
				}

				var b = new SimpleBehavior(
					fn(status){
						var node = status.getReferencedNode();
						var end = status.getCurrentTime() + 10;
						while(status.getCurrentTime() < end){
							node.rotateLocal_deg(status.getTimeDelta()*100,PADrend.getWorldUpVector());
							yield;
						}
					}
				);
				
				foreach(NodeEditor.getSelectedNodes() as var node){
					PADrend.getSceneManager().getBehaviourManager().startNodeBehavior( b,node );
				}
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "ScriptedStateBehaviour test  (old)",
			GUI.TOOLTIP : "Demo for MinSG.ScriptedStateBehaviour.",
			GUI.ON_CLICK : fn() {

				var Fader = new Type(MinSG.ScriptedStateBehaviour);
				Fader._printableName @(override) ::= $Rotator;
				Fader.duration @(private) := void;
				Fader.startTime @(private) := void;
				Fader.endTime @(private) := void;
				Fader.node @(private) := void;

				//! (ctor)
				Fader._constructor ::= fn(_node,Number _duration)
						@(super(new MinSG.BlendingState())){
					node = _node;
					duration = _duration;
				};

				//! ---|> ScriptedStateBehaviour
				Fader.onInit @(override) ::= fn(){
					PADrend.message("Fade away.");
					startTime = getCurrentTime();
					endTime = getCurrentTime()+duration;
					node += getState();
				};

				//! ---|> ScriptedStateBehaviour
				Fader.doExecute @(override) ::= fn(){
					if(getCurrentTime()>endTime){
						PADrend.message("Thats enough!");
						node -= getState();
						return  MinSG.AbstractBehaviour.FINISHED;
					}
					getState().setBlendConstAlpha( 1.0 - (getCurrentTime()-startTime) /duration );
					return MinSG.AbstractBehaviour.CONTINUE;
				};

				foreach(NodeEditor.getSelectedNodes() as var node){
					PADrend.getSceneManager().getBehaviourManager().registerBehaviour( new Fader(node,5) );
				}
			}
		}
	]);

	gui.registerComponentProvider('NodeEditor_MiscToolsMenu.experimentsSpecularTexture', [
		{
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Test Specular Texture",
			GUI.TOOLTIP		:	"Test for normal mapping and specular mapping",
			GUI.ON_CLICK	:	fn() {
									var meshBuilder = new Rendering.MeshBuilder();
									meshBuilder.normal(new Geometry.Vec3(0, 1, 0));

									meshBuilder.position(new Geometry.Vec3(100, 0, 100));
									meshBuilder.texCoord0(new Geometry.Vec2(1, 1));
									var a = meshBuilder.addVertex();
									meshBuilder.position(new Geometry.Vec3(100, 0, -100));
									meshBuilder.texCoord0(new Geometry.Vec2(1, -1));
									var b = meshBuilder.addVertex();
									meshBuilder.position(new Geometry.Vec3(-100, 0, -100));
									meshBuilder.texCoord0(new Geometry.Vec2(-1, -1));
									var c = meshBuilder.addVertex();
									meshBuilder.position(new Geometry.Vec3(-100, 0, 100));
									meshBuilder.texCoord0(new Geometry.Vec2(-1, 1));
									var d = meshBuilder.addVertex();
									meshBuilder.addQuad(a, b, c, d);

									var plane = meshBuilder.buildMesh();
									Rendering.calculateTangentVectors(plane, "sg_TexCoord0", "sg_Tangent");

									var geometry = new MinSG.GeometryNode(plane);

									var shaderPath = Util.requirePlugin('LibRenderingExt').getBaseFolder() + "/resources/shader/universal2/";
									var sfn = [
										shaderPath + "sgHelpers.sfn",
										shaderPath + "shading_normalMapped.sfn",
										shaderPath + "texture.sfn",
										shaderPath + "color_mapping.sfn",
										shaderPath + "shadow_disabled.sfn",
										shaderPath + "effect_disabled.sfn"
									];
									var vs = sfn.clone();
									vs += shaderPath + "universal.vs";
									var fs = sfn.clone();
									fs += shaderPath + "universal.fs";
									var shaderState = new MinSG.ShaderState();
									MinSG.initShaderState(shaderState, vs, [], fs);
									geometry.addState(shaderState);

									var materialState = new MinSG.MaterialState;
									materialState.setAmbient(new Util.Color4f(0.3, 0.3, 0.3, 1.0));
									materialState.setDiffuse(new Util.Color4f(0.7, 0.7, 0.7, 1.0));
									materialState.setSpecular(new Util.Color4f(1.0, 1.0, 1.0, 1.0));
									materialState.setShininess(5.0);
									geometry.addState(materialState);

									var textureState = new MinSG.TextureState;
									textureState.setTexture(Rendering.createTextureFromFile(PADrend.getDataPath() + "texture/sandstone_texture_diffuse.png"));
									geometry.addState(textureState);

									var normalMapState = new MinSG.TextureState;
									normalMapState.setTexture(Rendering.createTextureFromFile(PADrend.getDataPath() + "texture/sandstone_texture_normal.png"));
									normalMapState.setTextureUnit(2);
									geometry.addState(normalMapState);

									var specularMapState = new MinSG.TextureState;
									specularMapState.setTexture(Rendering.createTextureFromFile(PADrend.getDataPath() + "texture/sandstone_texture_specular.png"));
									specularMapState.setTextureUnit(3);
									geometry.addState(specularMapState);

									var uniformState = new MinSG.ShaderUniformState;
									uniformState.setUniform('sg_normalMap', Rendering.Uniform.INT, [2]);
									uniformState.setUniform('sg_normalMappingEnabled', Rendering.Uniform.BOOL, [true]);
									uniformState.setUniform('sg_specularMap', Rendering.Uniform.INT, [3]);
									uniformState.setUniform('sg_specularMappingEnabled', Rendering.Uniform.BOOL, [true]);
									geometry.addState(uniformState);

									PADrend.getCurrentScene().addChild(geometry);
								}
		}
	]);

	// ???????????????????????????????????????????????????????????????????????????????????????????????????????
	gui.registerComponentProvider('NodeEditor_MiscToolsMenu.experimentsColorCubes',[
		{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "test color cube build",
			GUI.ON_CLICK : fn() {
				var node = NodeEditor.getSelectedNode();
				var hasColorCube = MinSG.ColorCube.hasColorCube(node);
				if (hasColorCube) out("has color cube");
				else out("has no color cubes");

				if (!hasColorCube)
					MinSG.ColorCube.buildColorCubes(GLOBALS.frameContext, node, 1, 1);
			}
		}
	]);
	// -------------------------------------
};

// ---------------------------------------------------------------------------------------------
