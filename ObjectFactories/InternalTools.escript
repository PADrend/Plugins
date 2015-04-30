/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static tools = new Namespace;

tools.registerNodeWithUniqueId := fn(MinSG.Node node,String prefix){
	var id = tools.getUniqueNodeId(prefix);
	PADrend.getSceneManager().registerNode(id,node);
	return id;
};
tools.registerStateWithUniqueId := fn(MinSG.State state,String prefix){
	var id = tools.getUniqueStateId(prefix);
	PADrend.getSceneManager().registerState(id,state);
	return id;
};

tools.getUniqueStateId := fn(String prefix){
	var sm = PADrend.getSceneManager();
	var max = 99;
	while(true){
		for(var i=0;i<10;++i){
			var id = prefix + "_" + Rand.equilikely(10,max);
			if(!sm.getRegisteredState(id))
				return id;
		}
		max *= 10;
	}
};tools.getUniqueNodeId := fn(String prefix){
	var sm = PADrend.getSceneManager();
	var max = 99;
	while(true){
		for(var i=0;i<10;++i){
			var id = prefix + "_" + Rand.equilikely(10,max);
			if(!sm.getRegisteredState(id))
				return id;
		}
		max *= 10;
	}
};

tools.addSimpleMaterial := fn(MinSG.Node node,r,g,b,a=1.0){
	var mat = new MinSG.MaterialState;
	var c = new Util.Color4f(r,g,b,a);
	mat.setAmbient( c );
	mat.setDiffuse( c );
	mat.setSpecular( new Util.Color4f(0,0,0,1) );
	node+=mat;
	return mat;
};


tools.planInit := fn(callback){
	PADrend.planTask(0, [NodeEditor.getSelectedNodes()] => callback);
};


tools.createRelativeNodeQuery := fn(MinSG.Node source,MinSG.Node target){
	@(once) static TreeQuery = Std.module('LibMinSGExt/TreeQuery');
	return TreeQuery.createRelativeNodeQuery(PADrend.getSceneManager(),source,target);
};

return tools;
