/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:TMSim'] Spielerei/TMSim/Objects.escript
 ** 2010-05 Claudius
 **/
declareNamespace($TMSim);

var objects=new Map();

//----------------------------------------------------------------------------
//----------------------------------------------------------------------------

/*! Buffer ---|> TMSim.BaseObject */
var t=new Type(TMSim.BaseObject);
t.name='buffer';

t.slots:=void;
t.capacity:=void;

t._constructor::=fn(){
	var inPort=createPort("in",{
				'pos'	:	'west',
				'tooltip'	:	"Token input",
				'label' : 	"->"});
	inPort.receiveToken::=fn(token){
		return obj.receiveToken(token);
	};
	createPort("out",{
				'pos'	:	'east',
				'tooltip'	:	"Token output",
				'requiredInterface' : ['receiveToken'],
				'label' : 	"->"});
	slots=[];
	capacity=4;
};
t.configPanel::=void;


t.receiveToken::=fn(TMSim.Token token){
	if(slots.size()>=capacity) // full
		return false;

	//token.setPath();
	slots+=token;
	schedule(1);

	// move
	var srt=token.getRelTransformationSRT();
	srt.setTranslation( getNode().getWorldBB().getCenter()+new Geometry.Vec3(0,0.5+0.2*slots.size(),0) );
	token.moveTo( srt,1 );

	statusText="("+slots.size()+")";
	refresh();
	return true;
};

/*! ---|>TMSim.BaseObject */
t.step::=fn(duration){
	var connections=getPort('out').connections;
	if(connections.empty()){
		statusText="( ! )";
		refresh();
		return;
	}
	if(!slots.empty()){
		// try to pass over to one free output
		foreach(connections as var connection ){
			if(slots.empty())
				break;
			var p=connection.getOtherPort(getPort('out'));
			var t=slots.back();

			// can pass token?
			if(p.receiveToken(t)){
				slots.popBack();
				out(getName(),": Token passed over \n");
				statusText="("+slots.size()+")";
				refresh();

			}
			p.obj.addToNotifyList(this);
	//			statusText="(waiting)";
//				refresh();

	//			out(getName(),": ...waiting... \n");

		}
	}
	if(slots.size()<capacity){
		notify();
	}

};

/*! ---|> TMSim.BaseObject */
t.reset::=fn(){
	slots=[];
};

objects[t.getName()] = t;

//----------------------------------------------------------------------------


/*! Painter ---|> TMSim.BaseObject */
t=new Type(TMSim.BaseObject);
t.name='painter';

t.slot:=void;
t.transportationTime:=0;

t._constructor::=fn(){
	var inPort=createPort("in",{
				'pos'	:	'west',
				'tooltip'	:	"Token input",
				'label' : 	"->"});
	inPort.receiveToken::=fn(token){
		return obj.receiveToken(token);
	};
	createPort("out",{
				'pos'	:	'east',
				'tooltip'	:	"Token output",
				'requiredInterface' : ['receiveToken'],
				'label' : 	"->"});
};
t.configPanel::=void;


t.receiveToken::=fn(TMSim.Token token){
	if(slot) // full
		return false;

	//token.setPath();
	slot=token;

	// colorize
	var n=token.getNode();
	var color=n.getAttribute("color");
	if(!color){
		color=new MinSG.MaterialState();
		n.addState(color);
	}
	color.setAmbient(new Util.Color4f(Rand.uniform(0,1),Rand.uniform(0,1),Rand.uniform(0,1)));
	color.setDiffuse(new Util.Color4f(Rand.uniform(0,1),Rand.uniform(0,1),Rand.uniform(0,1)));
	color.setSpecular(new Util.Color4f(Rand.uniform(0,1),Rand.uniform(0,1),Rand.uniform(0,1)));

	transportationTime = 5;
	schedule(transportationTime);

	// move
	var srt=token.getRelTransformationSRT();
	srt.setTranslation( getNode().getWorldBB().getCenter()+new Geometry.Vec3(0,0.5,0) );
	token.moveTo( srt,transportationTime );

	statusText="("+slot.getName()+")";
	refresh();
	out(getName()+ ": Token received ... \n");
	return true;
};

/*! ---|>TMSim.BaseObject */
t.step::=fn(duration){
	if(!slot){ // empty?
		notify();
		return;
	}
	transportationTime-=duration;
	if(transportationTime>0){ // not finished yet
		return;
	}
	var connections=getPort('out').connections;
	if(connections.empty()){
		statusText="( ! )";
		refresh();
		return;
	}
	// try to pass over to one free output
	foreach(connections as var connection ){
		var p=connection.getOtherPort(getPort('out'));
		// can pass token?
		if(p.receiveToken(slot)){
			transportationTime=0;
			slot=void;
			out(getName(),": Token passed over \n");
			statusText="";
			refresh();

			schedule(1);
			return;
		}else{
			p.obj.addToNotifyList(this);
			statusText="(waiting)";
			refresh();

//			out(getName(),": ...waiting... \n");
		}
	}
};

/*! ---|> TMSim.BaseObject */
t.reset::=fn(){
	slot=void;
	transportationTime=0;
};


objects[t.getName()] = t;

//----------------------------------------------------------------------------

/*! Source ---|> TMSim.BaseObject */
t=new Type(TMSim.BaseObject);
t.name='source';
t._constructor::=fn(){
	createPort("out",{
				'pos'	:	'east',
				'tooltip'	:	"Token output",
				'requiredInterface' : ['receiveToken'],
				'label' : 	"->",
				'maxConnections' 	: 	1});
};
t.creationSpeed:=3;
t.configPanel::=void;

/*! ---|> TMSim.BaseObject */
t.createConfigPanel::=fn(){
	var p=(this->(getType().getBaseType().createConfigPanel))();
	p.creationSpeedSlider:=gui.createExtSlider( [100,15],[1.0,10.0],10 );
	p.creationSpeedSlider.setData(this.creationSpeed);
	p.creationSpeedSlider.obj:=this;
	p.creationSpeedSlider.onDataChanged = fn(data){
		this.obj.creationSpeed=getData();
		this.obj.refresh();
	};
	p.add(gui.createLabel("Speed:"));
	p.add(p.creationSpeedSlider);
	p.nextRow();
	return p;
};
t.slot:=void;
t.productionTime:=0;


t.createNewToken::=fn(){
	var root = getProject().getSceneRootNode();
	var token = new TMSim.Token("Token");
	token.init(getProject());
	var srt=token.getRelTransformationSRT();
	srt.setTranslation( getNode().getWorldBB().getCenter() );
	token.setPosition( srt );

	srt=token.getRelTransformationSRT();
	srt.setTranslation( getNode().getWorldBB().getCenter()+new Geometry.Vec3(0,0.6,0) );
	token.moveTo( srt,creationSpeed );

	return token;
};

/*! ---|>TMSim.BaseObject */
t.step::=fn(duration){
	if(!slot){ // start producing
		out(getName(),": Begin production... \n");
		productionTime=creationSpeed;
		slot = createNewToken();
		schedule(productionTime);
		statusText="(working)";
		refresh();
		return;
	}
	productionTime-=duration;
	if(productionTime>0){ // not finished yet
		return;
	}
	// notify that a new token is available
	notify();
	var connection=getPort('out').connections[0];

	if(connection){
		var p=connection.getOtherPort(getPort('out'));
		// can pass token?
		if(p.receiveToken( slot )){
			productionTime=0;
			slot=void;
			out(getName(),": ...finished. \n");
			step(0);
		}else{
			p.obj.addToNotifyList(this);
			out(getName(),": ...waiting... \n");
			statusText="(waiting)";
		refresh();

		}
	}else {
		out(getName(),": No output connected :-( ");
		statusText="( ! )";
		refresh();

	}
};

/*! ---|> TMSim.BaseObject */
t.reset::=fn(){
	slot=void;
	productionTime=0;
};

objects[t.getName()] = t;

//----------------------------------------------------------------------------

/*! Drain ---|> TMSim.BaseObject */
t=new Type(TMSim.BaseObject);
t.name='drain';
t.tokens:=void;
t.times:=void;
t._constructor::=fn(){
	var inPort=createPort("in",{
				'pos'	:	'west',
				'tooltip'	:	"Token input",
				'label' : 	"->"});
	inPort.receiveToken:=fn(token){
		return obj.receiveToken(token);
	};
	tokens=[];
	times=[];
};
t.configPanel::=void;

t.receiveToken::=fn(TMSim.Token token){
	tokens.pushBack(token);
	token.makePhysical();

	var disposalTime=500;
	var now=getProject().getTime();
	times.pushBack(now);

	while(!times.empty() && times.front()+disposalTime < now){
		var token=tokens.popFront();
		out(token.getNode().getWorldOrigin());

		token.destroy();
		times.popFront();
		out(getName()+ ": Token received and thrown away!\n");
	}

	return true;
};

objects[t.getName()] = t;

//----------------------------------------------------------------------------

/*! Transport ---|> TMSim.BaseObject */
t=new Type(TMSim.BaseObject);
t.name='transport';

t.slot:=void;
t.transportationTime:=0;

t._constructor::=fn(){
	var inPort=createPort("in",{
				'pos'	:	'west',
				'tooltip'	:	"Token input",
				'label' : 	"->"});
	inPort.receiveToken:=fn(token){
		return obj.receiveToken(token);
	};
	createPort("out",{
				'pos'	:	'east',
				'tooltip'	:	"Token output",
				'requiredInterface' : ['receiveToken'],
				'label' : 	"->"});
};
t.configPanel::=void;


t.receiveToken::=fn(TMSim.Token token){
	if(slot) // full
		return false;

	//token.setPath();
	slot=token;
	transportationTime = 5;
	schedule(transportationTime);

	// move
	var srt=token.getRelTransformationSRT();
	srt.setTranslation( getNode().getWorldBB().getCenter()+new Geometry.Vec3(1,0.5,0) );
	token.moveTo( srt,transportationTime );

	statusText="("+slot.getName()+")";
	refresh();
	out(getName()+ ": Token received ... \n");
	return true;
};

/*! ---|>TMSim.BaseObject */
t.step::=fn(duration){
	if(!slot){ // empty?
		notify();
		return;
	}
	transportationTime-=duration;
	if(transportationTime>0){ // not finished yet
		return;
	}
	var connections=getPort('out').connections;
	if(connections.empty()){
		statusText="( ! )";
		refresh();
		return;
	}
	// try to pass over to one free output
	foreach(connections as var connection ){
		var p=connection.getOtherPort(getPort('out'));
		// can pass token?
		if(p.receiveToken(slot)){
			transportationTime=0;
			slot=void;
			out(getName(),": Token passed over \n");
			statusText="";
			refresh();

			schedule(1);
			return;
		}else{
			p.obj.addToNotifyList(this);
			statusText="(waiting)";
			refresh();

//			out(getName(),": ...waiting... \n");
		}
	}
};

/*! ---|> TMSim.BaseObject */
t.reset::=fn(){
	slot=void;
	transportationTime=0;
};


/*! ---|> TMSim.BaseObject */
t.createNode:=fn(){
	var n=new MinSG.ListNode();
	n.obj:=this;
	n.name:="";
	n.refresh:=fn(){
		this.name=obj.getName();
	};

	var ctxt=new AMCContext(n);

	var band_l = 2;
	var band_h = 0.8;
	var band_w = 0.5;
	var band_d = 0.01; // materialst�rke der seitenteile
	var band_dy = 0.1;


	var reel_detail = 10;
	var reel_r = 0.03;
	var reel_l = band_w*0.9;
	var reelm_detail = 5;
	var reelm_r = reel_r*0.3;
	var reelm_l = (band_w+band_d)*1.01;

	var reel_dist = reelm_r*0.3;


	// materials
	var m=new AMCMaterial("steel");
	m.setMaterial(new Util.Color4f(0.5,0.5,0.7,1.0),new Util.Color4f(0.5,0.4,0.7,1.0),new Util.Color4f(0.3,0.5,1.0,1.0),0.5);
//	m.setTexture("./Data/texture/stone1.bmp");

	m=new AMCMaterial("rubber");
	m.setMaterial(new Util.Color4f(0.7,0.4,0.3,1.0),new Util.Color4f(0.9,0.4,0.3,1.0),new Util.Color4f(0.2,0.1,0.1,1.0),0.6);


	{ // add band-geometry
		ctxt.openGroup();

		ctxt.setTranslation( 0 , band_h-band_dy*0.5, (band_w - band_d) *0.5); // seitenteil 1
		ctxt.addBox(band_l, band_dy,band_d);
		ctxt.buildMesh(false);

		ctxt.setTranslation( 0 , band_h-band_dy*0.5, -(band_w - band_d) *0.5); // seitenteil 2
		ctxt.cloneLast();

		ctxt.setTranslation( (band_l-band_d)*0.5 , band_h-band_dy+band_d*0.5, 0);
		ctxt.addBox(band_d, band_d,band_w-band_d);
		ctxt.buildMesh(false);

		ctxt.setTranslation( -(band_l-band_d)*0.5 , band_h-band_dy+band_d*0.5, 0);
		ctxt.cloneLast();

		// legs
		ctxt.setTranslation( (band_l-band_dy)*0.5, 		(band_h-band_dy)*0.5, 	(band_w - band_d) *0.5);
		ctxt.addBox(band_dy, band_h-band_dy,band_d);
		ctxt.buildMesh(false);

		ctxt.setTranslation( -(band_l-band_dy)*0.5, 	(band_h-band_dy)*0.5, 	(band_w - band_d) *0.5);
		ctxt.cloneLast();

		ctxt.setTranslation( (band_l-band_dy)*0.5, 		(band_h-band_dy)*0.5, 	-(band_w - band_d) *0.5);
		ctxt.cloneLast();

		ctxt.setTranslation( -(band_l-band_dy)*0.5, 	(band_h-band_dy)*0.5, 	-(band_w - band_d) *0.5);
		ctxt.cloneLast();

		ctxt.mergeGroup();
		ctxt.assignMaterial("steel");

		ctxt.closeGroup();
	}

	{// now for the reels
		ctxt.openGroup();

		// calc reel count
		// length of n reels = (reel_r*2+reel_dist)*n - reel_dist
		var max_reels = (band_l+reel_dist)/(reel_r*2+reel_dist);

		ctxt.reset();
		ctxt.setTranslation(-band_l/2+reel_r,	band_h-reel_r*0.5,	0); // reset for reels
		ctxt.rotate(90,new Geometry.Vec3(0,1,0));
		ctxt.addCylinder(reel_detail,reel_r,reel_l); // rolle
		ctxt.buildMesh(false);

		for(var i = 1; i < max_reels; ++i){
			ctxt.translate(reel_r*2+reel_dist,0,0);
			ctxt.cloneLast();
		}
		ctxt.reset();
		ctxt.setTranslation(-band_l/2+reel_r,	band_h-reel_r*0.5,	0); // reset for reels
		ctxt.rotate(90,new Geometry.Vec3(0,1,0));
		ctxt.addCylinder(reelm_detail,reelm_r,reelm_l); // rollenmitte
		ctxt.buildMesh(false);
		for(var i = 1; i < max_reels; ++i){
			ctxt.translate(reel_r*2+reel_dist,0,0);
			ctxt.cloneLast();
		}
		ctxt.mergeGroup();
		ctxt.assignMaterial("rubber");

		ctxt.closeGroup();
	}
	ctxt.closeGroup();

	return n;
};


objects[t.getName()] = t;

//----------------------------------------------------------------------------


// ---------------------------------------------------------
return objects;
