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
**	[Plugin:Tools_FrameAnalyzer] Tools/FrameAnalyzer.escript
**  2008-09-02
**/
var plugin=new Plugin({
		Plugin.NAME : 'Tools_FrameAnalyzer',
		Plugin.DESCRIPTION : "Visualizes the operations during the rendering of a frame in a chart.",
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
			gui.register('PADrend_MainWindowTabs.30_FrameAnalyzer',this->createMainWindowTab);
		});
	}
	{
		this.frameStatImageWidth:=500;
		this.frameStatImageHeight:=150;
		this.timeRange:=50.0;
		this.frameStatImage:=void;
		this.timeAutoRange:=false;
		this.frameStatChart:=new MinSG.StatChart(this.frameStatImageWidth,this.frameStatImageHeight,this.timeRange);
		this.guiRefreshGroup := new GUI.RefreshGroup();
	}
	return true;
};

plugin.createMainWindowTab @(private) := fn() {

	var page = gui.create({
		GUI.TYPE		:	GUI.TYPE_PANEL,
		GUI.SIZE		:	GUI.SIZE_MAXIMIZE
	});

	{
		page += "*Frame Analyzer*";
		page++;
		page += {
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Enable",
			GUI.ON_CLICK	:	PADrend.frameStatistics -> PADrend.frameStatistics.enableEvents,
			GUI.SIZE		:	[GUI.WIDTH_REL, 0.46, 0]
		};
		page += {
			GUI.TYPE		:	GUI.TYPE_BUTTON,
			GUI.LABEL		:	"Disable",
			GUI.ON_CLICK	:	PADrend.frameStatistics -> PADrend.frameStatistics.disableEvents,
			GUI.SIZE		:	[GUI.WIDTH_REL, 0.46, 0]
		};
		page++;

		this.frameStatImage=gui.createImage(frameStatImageWidth,frameStatImageHeight,GUI.LOWERED_BORDER);
		page+=frameStatImage;
		gui.enableMouseButtonListener(frameStatImage);
		frameStatImage.plugin := this;
		frameStatImage.onMouseButton := frameStatImage -> fn(buttonEvent){
			if(buttonEvent.pressed)
				this.setTooltip("" + ((buttonEvent.x - getAbsPosition().getX()) * this.plugin.timeRange / this.getWidth()) +" ms");
		};
		frameStatImage.setTooltip("Click to show the time at mouse pointer's position");
		
	}
	page++;
	{
		page += {
			GUI.TYPE				:	GUI.TYPE_BOOL,
			GUI.LABEL				:	"Auto range",
			GUI.DATA_OBJECT			:	this,
			GUI.DATA_ATTRIBUTE		:	$timeAutoRange,
			GUI.SIZE				:	[GUI.WIDTH_ABS, 100, 0]
		};
		page += {
			GUI.TYPE				:	GUI.TYPE_RANGE,
			GUI.RANGE				:	[0.1, 200],
			GUI.LABEL				:	"Time range (ms)",
			GUI.DATA_OBJECT			:	this,
			GUI.DATA_ATTRIBUTE		:	$timeRange,
			GUI.DATA_REFRESH_GROUP	:	guiRefreshGroup,
			GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
		};
		page++;
		page += "----";
	}
	page++;
	{
		for(var i=0;i<this.frameStatChart.getRowCount();i++){
			var description = this.frameStatChart.getDescription(i);
			if(description == "") {
				continue;
			}

			page += {
				GUI.TYPE				:	GUI.TYPE_RANGE,
				GUI.LABEL				:	description,
				GUI.RANGE				:	[0, 7],
				GUI.RANGE_FN_BASE		:	10,
				GUI.DATA_VALUE			:	this.frameStatChart.getRange(i),
				GUI.ON_DATA_CHANGED		:	[i, this.frameStatChart]=>fn( type, chart,data) {
												chart.setRange(type, data);
											},
				GUI.SIZE				:	[GUI.WIDTH_FILL_ABS, 10, 0]
			};
			page++;
		}
	}
	return {
		GUI.TYPE : GUI.TYPE_TAB,
		GUI.TAB_CONTENT : page,
		GUI.LABEL : "Analyzer"
	};
};
/**
* [ext:PADrend_AfterRendering]
*/
plugin.ex_afterRendering:=fn(...) {
	if(!PADrend.frameStatistics.areEventsEnabled())
		return;
	
	if(timeAutoRange){
		var d = PADrend.frameStatistics.getValue(PADrend.frameStatistics.getFrameDurationCounter());
		this.timeRange = d*1.05;
		this.guiRefreshGroup.refresh();
	}
	
	this.frameStatChart.setTimeRange(timeRange);
	this.frameStatChart.update(PADrend.frameStatistics);
	frameStatImage.updateData(this.frameStatChart.getBitmap());
};

return plugin;
// ------------------------------------------------------------------------------
