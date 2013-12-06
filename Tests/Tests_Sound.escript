/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */


/****
 **	[Plugin:Tests] Test/Tests_Sound.escript
 **/

var plugin = new Plugin({
		Plugin.NAME : 'Tests/Tests_Sound',
		Plugin.DESCRIPTION : 'For testing sounds...',
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [ 'Tests' ],
		Plugin.EXTENSION_POINTS : []
});

//!	---|> Plugin
plugin.init:=fn(){
	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_Init', this->fn(){
			gui.registerComponentProvider('Tests_TestsMenu.soundTests',{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Sound Tests",
				GUI.ON_CLICK : this->execute
			});
		});
    }
    return true;
};


//! (internal)
plugin.execute:=fn(){
	Sound.initSoundSystem();
	

	var p=gui.createPopupWindow( 300,300,"Tones...");

	var Tone = new Type();
	Tone.samplingFrequency ::= 44000; // samples / seconds
	Tone._constructor ::= fn(name,frequency,duration){
		this.name:=name;
		this.frequency:=frequency; // 1 / seconds
		this.duration:=duration;
		var pulseLength = samplingFrequency / frequency;
		var buffer = Sound.createRectangleSound(pulseLength,samplingFrequency,duration*samplingFrequency );
		this.source := Sound.createSource();
		source.enqueueBuffer(buffer);
		source.setGain(0.1);
	};
	Tone.play ::= fn(){
		source.play();
	};
	Tone.stop ::= fn(){
		source.stop();
	};
	
	
	var tones = [
		new Tone("c",264*0.5,1.25),	new Tone("d",297*0.5,1.25),	new Tone("e",330*0.5,1.15),	new Tone("f",352*0.5,1.15),
		new Tone("g",396*0.5,1.15),	new Tone("a",440*0.5,1.15),	new Tone("h",495*0.5,1.15),
		new Tone("c",264,1.15),	new Tone("d",297,1.15),	new Tone("e",330,1.15),	new Tone("f",352,1.15),	
		new Tone("g",396,1.15),	new Tone("a",440,1.15),	new Tone("h",495,1.15),	new Tone("c",528,1.15)
	];
	foreach(tones as var t)
	p.addOption( {
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : t.name+"("+t.frequency+")",
				GUI.ON_MOUSE_BUTTON : t->fn(evt){
					if(evt.pressed)
							play();
					else 
							stop();
				}
				
				}
				
				);
	p.addAction( "ok" );
	p.init();

};





// ---------------------------------------------------------
return plugin;
