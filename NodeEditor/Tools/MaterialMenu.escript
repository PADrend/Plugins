/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2011 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:NodeEditor] NodeEditor/Tools/MaterialMenu.escript
 **/

NodeEditorTools.registerMenues_MaterialTools := fn() {

	gui.registerComponentProvider('NodeEditor_NodeToolsMenu.material',fn(Array nodes){
		return nodes.empty() ? [] : [
			'----',
			{
				GUI.TYPE : GUI.TYPE_MENU,
				GUI.LABEL : "Material tools",
				GUI.MENU : 'NodeEditor_MaterialMenu',
				GUI.MENU_WIDTH : 150
			}
		];
	});
	
    // ----------------------------------------------------------
	gui.registerComponentProvider('NodeEditor_MaterialMenu',[
		"*Materials*",
		{
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Multiply all small shininess values (<3) by 10",
			GUI.ON_CLICK : fn() {
				var stateContainers = NodeEditor.getSelectedNodes().clone();
				
				while(!stateContainers.empty()){
					var stateContainer = stateContainers.popBack();
					foreach(stateContainer.getStates() as var s){
						if(s ---|>MinSG.MaterialState){
							var shininess = s.getShininess();
							if(shininess<3){
								out(":",shininess," -> ");
								s.setShininess(shininess*10);
								out(s.getShininess(),"\n");
								
							}
							out(":",shininess," ok.");
						}else if(s ---|>MinSG.GroupState){
							stateContainers+=s;
						}
					}
					if(stateContainer---|>MinSG.GroupNode){
						stateContainers.append( MinSG.getChildNodes(stateContainer) );
					}
				}
				gui.closeAllMenus();
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Reset ambient colors ...",
			GUI.ON_CLICK : fn() {
				var p = gui.createPopupWindow( 400, 140,"Reset ambient color" );
				var params = new ExtObject({ $factor:0.5,$color:1.0,$base:0.0});
				
				p.addOption({
					GUI.TYPE : GUI.TYPE_RANGE,
					GUI.RANGE : [0,1.0],
					GUI.RANGE_STEPS : 20,
					GUI.LABEL : "Ambient = Diffuse * ",
					GUI.DATA_OBJECT : params,
					GUI.DATA_ATTRIBUTE : $factor
				});
				p.addOption({
					GUI.TYPE : GUI.TYPE_RANGE,
					GUI.RANGE : [0,1.0],
					GUI.RANGE_STEPS : 20,
					GUI.LABEL : "Saturation ",
					GUI.DATA_OBJECT : params,
					GUI.DATA_ATTRIBUTE : $color
				});			
				p.addOption({
					GUI.TYPE : GUI.TYPE_RANGE,
					GUI.RANGE : [0,1.0],
					GUI.RANGE_STEPS : 20,
					GUI.LABEL : "Base brightness ",
					GUI.DATA_OBJECT : params,
					GUI.DATA_ATTRIBUTE : $base
				});
				
				p.addAction("Execute",(fn(params){
					foreach(NodeEditor.getSelectedNodes() as var n){
						var states=MinSG.collectStates(n,MinSG.MaterialState);
						foreach(states as var state){
							var diff = state.getDiffuse();
							var a = diff.a();
							var brightness = (diff.r() + diff.g() + diff.b())/3;
							var c =  (diff*params.color + new Util.Color4f(brightness,brightness,brightness,1.0)*(1-params.color)) * params.factor;
							c += new Util.Color4f(params.base,params.base,params.base,1.0);
							c.a(a);
							
							state.setAmbient(c);
							out(".");
						}
					}
					return true;
				}).bindLastParams(params));
				p.addAction("Close");
			   p.init();
			},
			GUI.TOOLTIP : "Sets the ambient value of MaterialStates acoridng to their Diffuse value.\n"+
			"(makes some imported scenes shinier)"
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Set all material alpha to 1.0",
			GUI.ON_CLICK : fn() {
				var states=MinSG.collectStates(NodeEditor.getSelectedNode(),MinSG.MaterialState);
				foreach(states as var state){
					var c=state.getAmbient();
					state.setAmbient(new Util.Color4f(c.r(), c.g(), c.b(), 1.0));

					c=state.getDiffuse();
					state.setDiffuse(new Util.Color4f(c.r(), c.g(), c.b(), 1.0));

					c=state.getSpecular();
					state.setSpecular(new Util.Color4f(c.r(), c.g(), c.b(), 1.0));

					out(state,"\n");
				}
			}
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Export color properties",
			GUI.ON_CLICK : fn() {
				fileDialog("Export color properties","./",".matProp", fn(filename){
					out("Export color values to \"",filename,"\"...");
					var states=MinSG.collectStates(NodeEditor.getSelectedNode(),MinSG.MaterialState);
					var m=new Map();
					foreach(states as var state){
						var id=PADrend.getSceneManager().getNameOfRegisteredState(state);
						if(!id)
							continue;
						m[id]={
							'ambient' : state.getAmbient().toArray(),
							'diffuse' : state.getDiffuse().toArray(),
							'specular' : state.getSpecular().toArray(),
							'shininess' : state.getShininess(),
						};
					}
					out(IO.filePutContents(filename,toJSON(m)),"\n");
				});
			},
			GUI.TOOLTIP : "Export the color values of all registered Material-States (of the current subtree)"
		},
		{
			GUI.TYPE : GUI.TYPE_BUTTON, 
			GUI.LABEL : "Import color properties",
			GUI.ON_CLICK : fn() {
				fileDialog("Import color properties","./",".matProp", fn(filename){
					out("Import color values from \"",filename,"\"...\n");
					var s=IO.fileGetContents(filename);
					if(!s){
						out(false);
						return;
					}
					var m=parseJSON(s);
					foreach(m as var id,var colors){
						var state=PADrend.getSceneManager().getRegisteredState(id);
						if(!state){
							out("No node width id ",id,"\n");
							continue;
						}
						try{
							state.setAmbient(new Util.Color4f(colors['ambient']));
							state.setDiffuse(new Util.Color4f(colors['diffuse']));
							state.setSpecular(new Util.Color4f(colors['specular']));
							state.setShininess(colors['shininess']);
							out("Found new color for ",id,"\n");
						}catch(e){
							Runtime.warn(e);
						}

					}
				});
			},
			GUI.TOOLTIP : "Import the color values of registered Material-States"
		}
	]);
};

// ------------------------------------------------------------------------------

