/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tools_EObjectInfo] Tools/EObjectInfo.escript
 ** 2009-07-20
 **/
var plugin = new Plugin({
		Plugin.NAME : 'Tools_EObjectInfo',
		Plugin.DESCRIPTION : "EObjectInfo: Tool for displaying attributes for EScript-Objects.",
		Plugin.VERSION : 1.1,
		Plugin.AUTHORS : "Claudius Jaehn",
		Plugin.LICENSE : "Mozilla Public License, v. 2.0",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend/EventLoop'],
		Plugin.EXTENSION_POINTS : []
});


plugin.init @(override) := fn(){
	registerExtension('PADrend_Init', this->fn(){
		gui.registerComponentProvider('Tools_DebugWindowTabs.eObjInfo',	fn(){
			return {
				GUI.TYPE : GUI.TYPE_TAB,
				GUI.TAB_CONTENT :  createObjInfoGUI("GLOBALS"),
				GUI.LABEL : "EObj Info",
			};
		});
	});
    return true;
};

static createObjInfoGUI = fn(String command){
	var handler = new ExtObject;

	var w = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
//		GUI.LAYOUE : GUI.LAYOUT_TIGHT_FLOW
	});

	var commandPanel=gui.createPanel(1,1,GUI.AUTO_LAYOUT|GUI.RAISED_BORDER);
	commandPanel.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
				GUI.WIDTH_REL|GUI.HEIGHT_ABS,
				new Geometry.Vec2(0,0),new Geometry.Vec2(1.0,40) );
	w+=commandPanel;
	var infoPanel=gui.createPanel(1,1,GUI.AUTO_LAYOUT);
	infoPanel.setExtLayout(
				GUI.POS_X_ABS|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|
				GUI.POS_Y_ABS|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP|
				GUI.WIDTH_REL|GUI.HEIGHT_ABS,
				new Geometry.Vec2(0,40),new Geometry.Vec2(1.0,-40) );
	w+=infoPanel;
	handler.infoPanel:=infoPanel;

	var tf=gui.create({
		GUI.TYPE : GUI.TYPE_TEXT,
		GUI.LABEL : "Object expression:",
		GUI.DATA_VALUE : "GLOBALS",
		GUI.OPTIONS : ["GLOBALS","Geometry","GUI","MinSG","Model","PADrend","Util"],
		GUI.TOOLTIP : "EScript expression for the object you want to examine.",
		GUI.SIZE : [GUI.WIDTH_ABS|GUI.HEIGHT_ABS , -100 ,15 ]
	});
	
	commandPanel+=tf;
	handler.tf:=tf;

	handler.examine:=fn(){
		infoPanel.clear();
		var command=tf.getData();

		// get object
		var obj=void;
		Runtime.setTreatWarningsAsError(true);
		try{
			obj=eval("("+command+");");
		}catch(e){
			infoPanel+=e.toString();
			Runtime.setTreatWarningsAsError(false);
			return;
		}
		Runtime.setTreatWarningsAsError(false);

		// show general info
		var s=obj.toDbgString();
		if(s.length()>500)
			s=s.substr(0,500)+"...";
		var infoText = ""+info.get(obj);
		if(infoText.length()>1100){
			infoText = infoText.substr(0,infoText.find("\n",500) ) + "\n\n...\n\n" + infoText.substr( infoText.find("\n",infoText.length()-500) );
		}
		infoPanel+={
			GUI.TYPE : GUI.TYPE_LABEL,
			GUI.LABEL : s,
			GUI.TOOLTIP : infoText
		};
		infoPanel.nextRow(5);
		infoPanel+="----";
		infoPanel.nextRow(5);

		// type info
		infoPanel+="Type name:";
		infoPanel.nextColumn();
		var b=gui.createButton(100,15,obj.getTypeName());
		b.handler := this;
		b.command := command+".getType()";
		b.onClick = fn(){
			handler.open(command);
		};
		b.setTooltip(command+".getBaseType()\nOpen the type object of this object...");
		infoPanel+=b;
		if(obj---|>Type){
			b=gui.createButton(100,15,"Open base type");
			b.handler := this;
			b.command := command+".getBaseType()";
			b.onClick = fn(){
				handler.open(command);
			};
			b.setTooltip(command+".getBaseType()\nOpen base type of this type object...");
			infoPanel+=b;
		}else if(obj---|>Delegate){
			infoPanel++;
			infoPanel+={
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Object",
				GUI.WIDTH : 150,
				GUI.ON_CLICK : [command+".getObject()"] => this->fn(command){open(command);},
				GUI.TOOLTIP : ".getObject()"
			};
			infoPanel+=obj.getObject().toDbgString();
			infoPanel++;
			infoPanel+={
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Function",
				GUI.WIDTH : 150,
				GUI.ON_CLICK : [command+".getFunction()"] => this->fn(command){open(command);},
				GUI.TOOLTIP : ".getFunction()"
			};
			infoPanel+=obj.getFunction().toDbgString();

		}
		infoPanel.nextRow();


		// attributes
		var attr=new Map();
		if(obj---|>Type){
			attr["Type attributes:"]=obj.getTypeAttributes();
			attr["Object attributes:"]=obj.getObjAttributes();
		}else {
			attr["Object attributes:"]=obj._getAttributes();
		}
		foreach(attr as var category,var attribs){
			infoPanel.nextRow(5);
			infoPanel+="----";
			infoPanel.nextRow(5);
			infoPanel+=category;
			infoPanel.nextRow();
			foreach(attribs as var key,var value){
				var b=gui.createButton(150,15,key);
				b.handler := this;
				b.command := command+"."+key;
				b.onClick = fn(){
					handler.open(command);
				};
				b.setTooltip(b.command);
				infoPanel+=b;

				var s=value.toDbgString();
				if(s.length()>48)
					s=s.substr(0,48)+"...";
				infoPanel.nextColumn();
				infoPanel+=s;
				infoPanel.nextRow();
			}
		}
	};
	handler.open:=fn(String key){
		tf.setData(key);
		examine();
	};
	handler.back:=fn(){
		var pos=tf.getData().rFind(".");
		if(pos){
			tf.setData(tf.getData().substr(0,pos));
			examine();
		}

	};

	commandPanel+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL :"examine",
		GUI.ON_CLICK : handler->handler.examine,
		GUI.WIDTH : 50,
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT, -25,0]		
	};
	commandPanel+={
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "<-",
		GUI.ON_CLICK : handler->handler.back,
		GUI.TOOLTIP : "Strip the last part after the last dot",
		GUI.WIDTH : 20,
		GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_RIGHT|GUI.ALIGN_X_RIGHT, -5,0]		

	};
	return w;

};


return plugin;
// ------------------------------------------------------------------------------
