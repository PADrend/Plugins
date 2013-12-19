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
 **	[Plugin:Tools_GamePadConfig] Tools/GamePadConfig.escript
 ** 2010-02 Claudius
 **/

declareNamespace($Tools);

//!  ---|> Plugin
Tools.GamePadConfig := new Plugin({
		Plugin.NAME : 'Tools/GamePadConfig',
		Plugin.DESCRIPTION : "Configurate the game pad's options with the gamepad.",
		Plugin.VERSION : 0.2,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : ['PADrend','GUITools/OSD'],
		Plugin.EXTENSION_POINTS : [ ]
});

var plugin = Tools.GamePadConfig;

plugin.options := [];
plugin.currentOption := 0;


plugin.Option := new Type;
plugin.Option._constructor ::= fn(String _name,textProvider,action,allowHiddenActivation=true){
	this.name := _name;
	this.onButton := action;
	this.textProvider := textProvider;
	this.allowHiddenActivation := allowHiddenActivation;
};
plugin.Option.getMessage ::= fn(){
	return name + "\n" + (this.textProvider ? this.textProvider() : "");
};

/*! ---|> Plugin
	Plugin initialization.	*/
plugin.init @(override) := fn() {

	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_Init', this->this.ex_Init);
	}

	this.addOption("Speed",fn(){ return "< "+PADrend.getCameraMover().getSpeed() + " >"; },fn(value){
		if( (value & Util.UI.MASK_HAT_LEFT) > 0){
			PADrend.getCameraMover().setSpeed( PADrend.getCameraMover().getSpeed()*0.5);
			return true;
		}else if( (value & Util.UI.MASK_HAT_RIGHT) > 0){
			PADrend.getCameraMover().setSpeed( PADrend.getCameraMover().getSpeed()*2);
			return true;
		}
		return false;
	});

	this.addOption("Reset camera  >",false,fn(value){
        if( (value & Util.UI.MASK_HAT_RIGHT) > 0){
			PADrend.getDolly().setSRT(new Geometry.SRT());
			PADrend.getDolly().setWorldPosition(PADrend.getCurrentScene().getWorldBB().getCenter());
			PADrend.Navigation.getCameraMover().reset();
		}
		return true;
	},false);

	return true;
};

/*! Add an option to the gamePad-hud.	
	@param getTextFun may be false	
*/
plugin.addOption @(public) := fn(p...){	options += new this.Option(p...);	};

//!	[ext:PADrend_Init]
plugin.ex_Init:=fn() {
	var gamepads = PADrend.HID.getDevicesByTraits( HID.ControllerHatTrait  ); //! \see HID.ControllerHatTrait
	foreach(gamepads as var gamepad){
		
		//! \see HID.ControllerHatTrait
		gamepad.registerHatListener(0,this->fn(hatId,value){
			var OSD = Util.requirePlugin('GUITools/OSD');
			if( (value & Util.UI.MASK_HAT_UP) > 0){
				if(OSD.isActive())
					currentOption = (++currentOption)%options.count();
			}else if( (value & Util.UI.MASK_HAT_DOWN) > 0){
				if(OSD.isActive()){
					--currentOption;
					if(currentOption<0)
						currentOption = options.count()-1;
				}
			}else{
				var action = options[currentOption];
				if(!action){
					return $CONTINUE;
				}else if(OSD.isActive()){
					action.onButton(value);
				}else if(action.allowHiddenActivation){
					action.onButton(value);
					return $BREAK;
				}
			}
			OSD.message( "("+(currentOption+1)+"/"+options.count()+")\n"+options[currentOption].getMessage() );
			return $BREAK;
		});
	}
	return false;
};

return plugin;
// ------------------------------------------------------------------------------
