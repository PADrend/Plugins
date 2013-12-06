/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
**	[Plugin:Tools_FrameStats] Tools/FrameStats.escript
**  2008-09-02
**/
var plugin=new Plugin({
		Plugin.NAME : 'Tools_FrameStats',
		Plugin.DESCRIPTION : "Visualizes the frame statistics in a chart.",
		Plugin.VERSION : 1.0,
		Plugin.AUTHORS : "",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [],
		Plugin.EXTENSION_POINTS : []
});

/**
* Plugin initialization.
* ---|> Plugin
*/
plugin.init @(override) := fn() {

	{ // Register ExtensionPointHandler:
		registerExtension('PADrend_AfterRendering',this->this.ex_afterRendering);
		registerExtension('PADrend_Init',this->fn(){
			gui.registerComponentProvider('PADrend_MainWindowTabs.30_FrameStats',this->createMainWindowTab);
		});
	}
	this.imageWidth:=480;
	this.imageHeight:=150;
	this.image:=void;
	this.enabled:=false;
	this.lastTime:=void;
	this.pps:=10;
	this.tick:=0;

	this.pos:=0;

	var Stat = new Type;
	Stat._constructor ::= fn(Array scaleRange, Number scale, Util.Color4f color, Bool doDisplay) {
		this.scaleRange := scaleRange;
		this.scale := scale;
		this.color := color;
		this.doDisplay := doDisplay;
	};
	this.Stat := Stat;

	PADrend.Serialization.registerType( Stat, "Tools.FrameStats.Stat" )
		.addDescriber( fn(ctxt,obj,Map d){
			d['scaleRange'] = ctxt.createDescription( obj.scaleRange);
			d['scale'] = ctxt.createDescription( obj.scale);
			d['color'] = ctxt.createDescription( obj.color);
			d['doDisplay'] = ctxt.createDescription( obj.doDisplay);
		})
		.setFactory( fn(ctxt,type,Map d){
			return new type(
				ctxt.createObject( d['scaleRange']), 
				ctxt.createObject( d['scale']),
				ctxt.createObject( d['color']),
				ctxt.createObject( d['doDisplay'])
			);
		});

	var defaultStats = {
		"frame duration"				:	new Stat([1, 1000],			500,	new Util.Color4f(1.0, 0.0, 0.0, 1.0), true),
		"triangles rendered"			:	new Stat([1.0e+5, 1.0e+7],	1.0e+5,	new Util.Color4f(0.0, 1.0, 0.0, 1.0), true),
		"geometry nodes rendered"		:	new Stat([1000, 10000],		5000,	new Util.Color4f(0.5, 0.5, 1.0, 1.0), true),
		"occ. tests started"			:	new Stat([1, 1000],			100,	new Util.Color4f(1.0, 0.0, 1.0, 1.0), true),
		"I/O rate read"					:	new Stat([1, 500],			100,	new Util.Color4f(0.0, 0.7, 0.7, 1.0), true),
		"I/O rate write"				:	new Stat([1, 500],			100,	new Util.Color4f(0.0, 1.0, 1.0, 1.0), true)
	};
	this.stats := PADrend.deserialize(PADrend.configCache.getValue('Tools.FrameStats.Stats', PADrend.serialize(defaultStats)));
	
	return true;
};

plugin.createMainWindowTab @(private) := fn() {
	var panel = gui.create({
		GUI.TYPE		:	GUI.TYPE_PANEL,
		GUI.SIZE		:	GUI.SIZE_MAXIMIZE
	});
	rebuildGUI(panel);
	return {
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.TAB_CONTENT : panel,
		GUI.LABEL : "FStats"
	};
};

plugin.rebuildGUI := fn(panel) {
	panel.clear();
	panel += "*Frame Statistics*";
	panel++;
	panel += {
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"Enable",
		GUI.ON_CLICK	:	this -> fn() {
								enabled = true;
							},
		GUI.SIZE		:	[GUI.WIDTH_REL, 0.23, 0]
	};
	panel += {
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"Disable",
		GUI.ON_CLICK	:	this -> fn() {
								enabled = false;
								lastTime = void;
							},
		GUI.SIZE		:	[GUI.WIDTH_REL, 0.23, 0]
	};
	panel += {
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"Reset",
		GUI.ON_CLICK	:	this -> fn() {
								lastTime = void;
								pos = 0;
								if(image) {
									image.createPixelAccessor().fill(0, 0, image.getImageWidth(), image.getImageHeight(), new Util.Color4f(0, 0, 0, 0));
									image.dataChanged();
								}
							},
		GUI.SIZE		:	[GUI.WIDTH_REL, 0.23, 0]
	};
	panel += {
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"Refresh GUI",
		GUI.ON_CLICK	:	[this,panel] -> fn() {
								this[0].rebuildGUI(this[1]);
							},
		GUI.SIZE		:	[GUI.WIDTH_REL, 0.23, 0]
	};
	panel++;
	if(!this.image) {
		this.image = gui.createImage(imageWidth, imageHeight, GUI.LOWERED_BORDER);
	}
	panel += image;
	panel++;
	panel += {
		GUI.TYPE			:	GUI.TYPE_RANGE,
		GUI.LABEL			:	"Pixels per second",
		GUI.RANGE			:	[1, 50],
		GUI.RANGE_STEPS		:	49,
		GUI.DATA_OBJECT		:	this,
		GUI.DATA_ATTRIBUTE	:	$pps,
		GUI.SIZE			:	[GUI.WIDTH_FILL_ABS, 10, 0]
	};
	panel++;
	panel += "----";
	panel++;
	var statRefreshGroup = new GUI.RefreshGroup();
	for(var counter = 0; counter < PADrend.frameStatistics.getNumCounters(); ++counter) {
		var description = PADrend.frameStatistics.getDescription(counter);
		var unit = PADrend.frameStatistics.getUnit(counter);
		var stat = stats[description];
		if(!stat) {
			stat = new Stat([1, 1000], 500, new Util.Color4f(1.0, 0.0, 1.0, 1.0), false);
			stats[description] = stat;
		}
		panel += {
			GUI.TYPE				:	GUI.TYPE_BOOL,
			GUI.LABEL				:	"",
			GUI.TOOLTIP				:	"Display this counter in the diagram",
			GUI.DATA_OBJECT			:	stat,
			GUI.DATA_ATTRIBUTE		:	$doDisplay,
			GUI.DATA_REFRESH_GROUP	:	statRefreshGroup
		};
		panel += {
			GUI.TYPE				:	GUI.TYPE_MENU,
			GUI.LABEL				:	"###",
			GUI.TOOLTIP				:	"Change the color of this counter in the diagram",
			GUI.MENU				:	[
											{
												GUI.TYPE				:	GUI.TYPE_COLOR,
												GUI.LABEL				:	"###",
												GUI.DATA_OBJECT			:	stat,
												GUI.DATA_ATTRIBUTE		:	$color,
												GUI.DATA_REFRESH_GROUP	:	statRefreshGroup
											}
										],
			GUI.WIDTH				:	25,
			GUI.MENU_WIDTH			:	150,
			GUI.COLOR				:	stat.color
		};
		panel += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.LABEL				:	description + " [" + unit + "]",
			GUI.RANGE				:	stat.scaleRange,
			GUI.DATA_OBJECT			:	stat,
			GUI.DATA_ATTRIBUTE		:	$scale,
			GUI.DATA_REFRESH_GROUP	:	statRefreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		panel++;
	}
	statRefreshGroup += (fn(stats) {
		PADrend.configCache.setValue('Tools.FrameStats.Stats', PADrend.serialize(stats));
	}).bindLastParams(stats);
};


//!	[ext:PADrend_AfterRendering]
plugin.ex_afterRendering := fn(...) {
	if(!enabled || !image) {
		return;
	}

	var pixels = image.createPixelAccessor();
	var xRes = pixels.getWidth();
	var yRes = pixels.getHeight();

	var duration = lastTime ? clock() - lastTime : 0;
	lastTime = clock();

	var oldPos = pos;
	var newPos = pos + duration * pps;
	if(newPos >= xRes) {
		newPos = 0;
		pixels.fill(oldPos + 1, 0, xRes - oldPos.floor(), yRes, new Util.Color4f(0, 0, 0, 0.5));
		pixels.fill(newPos, 0, 1, yRes, new Util.Color4f(0.1, 0.1, 0.1, 1));
	} else if(newPos.floor() > oldPos.floor()) {
		pixels.fill(oldPos + 1, 0, newPos.floor() - oldPos.floor(), yRes, new Util.Color4f(0, 0, 0, 0.8));
		pixels.fill(newPos + 1, 0, 1, yRes, new Util.Color4f(0.7, 0.7, 0.7, 1));
		if(clock() - tick > 5) {
			pixels.fill(newPos, 0, 1, yRes, new Util.Color4f(0.6, 0.6, 0.6, 1));
			tick = clock();
		}
	}
	pos = newPos;

	for(var counter = 0; counter < PADrend.frameStatistics.getNumCounters(); ++counter) {
		var description = PADrend.frameStatistics.getDescription(counter);
		var stat = stats[description];
		if(!stat) {
			stat = new Stat([1, 1000], 500, new Util.Color4f(1.0, 0.0, 1.0, 1.0), false);
			stats[description] = stat;
		}
		if(stat.doDisplay) {
			var value = PADrend.frameStatistics.getValue(counter);

			value = (yRes - (yRes / stat.scale) * value).clamp(0, yRes - 1); // normalize

			if(value < yRes - 1) {
				var oldColor = pixels.readColor4f(pos, value + 1) ;
				pixels.writeColor(pos, value + 1, new Util.Color4f(oldColor, stat.color , 0.7));
			}
			pixels.writeColor(pos, value, stat.color);
		}
	}

	image.dataChanged();
};

return plugin;
// ------------------------------------------------------------------------------
