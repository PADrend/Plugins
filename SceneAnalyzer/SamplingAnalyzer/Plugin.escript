/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:GASP] GASP/SamplingTester/plugin.escript
 **/

/***
 **  ---|> Plugin
 **/
var plugin = new Plugin({
		Plugin.NAME : 'SceneAnalyzer/SamplingTester',
		Plugin.DESCRIPTION : 'Analyze sampling distributions.',
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "Claudius",
		Plugin.VERSION : 0.1,
		Plugin.REQUIRES : ['SceneAnalyzer','PADrend','PADrend/GUI'],
		Plugin.EXTENSION_POINTS : [	]
});

static GASPManager = Std.require('SceneAnalyzer/GlobalGASPManager');

plugin.init @(override) := fn(){
	Util.registerExtension('PADrend_Init',this->this.ex_Init);
	return true;
};

plugin.ex_Init := fn(){

	gui.register('SceneAnalyzer_Tabs.90_SamplingAnalyzer',fn(){
		var page=gui.createPanel(100,100,GUI.AUTO_LAYOUT);
		var parameters = new ExtObject( { $dhNumDistBuckets:2000,
										$dhNumAngleBuckets:360, 
										$dhNumClosestPointBuckets:2000, 
										$dhNumPixelBuckets:1024, 
										});
		page += [ 
			"*Distance Histogram*", GUI.NEXT_ROW,
			{	
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "Number of buckets",
				GUI.DATA_OBJECT : parameters,
				GUI.DATA_ATTRIBUTE : $dhNumDistBuckets		
			},	GUI.NEXT_ROW,
			{	
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "create",
				GUI.ON_CLICK : parameters->fn(){
					showWaitingScreen();
					var c = GASPManager.getSelectedGASP();
					if(!c){
						Runtime.warn("No gasp selected.");
						return;
					}
					var positions = [];
					foreach(c.sampleContainer.collectPoints() as var point)
						positions+=point.pos;
					var histogram = MinSG.SamplingAnalysis.createDistanceHistogram(positions,this.dhNumDistBuckets);

					var dataTable = new (Std.require('LibUtilExt/DataTable'))("dist");
					var data = new Map();
					var scale = histogram.maxValue/histogram.buckets.count();
					foreach( histogram.buckets as var idx,var amount){
						data[idx*scale] = amount;
					}
					dataTable.addDataRow( "Distribution of distances","count", data,"#FF0000");
					dataTable.exportSVG(c.name()+"_dHist.svg");
					dataTable.exportCSV(c.name()+"_dHist.csv");
	//				print_r(histogram._getAttributes());
				},
				GUI.WIDTH : 150
			},	
			GUI.NEXT_ROW, "----", GUI.NEXT_ROW,
			"*Angle Histogram*",	GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "Number of buckets",
				GUI.DATA_OBJECT : parameters,
				GUI.DATA_ATTRIBUTE : $dhNumAngleBuckets		
			},	GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "create",
				GUI.ON_CLICK : parameters->fn(){
					showWaitingScreen();
					var c = GASPManager.getSelectedGASP();
					if(!c){
						Runtime.warn("No gasp selected.");
						return;
					}
					var positions = [];
					foreach(c.sampleContainer.collectPoints() as var point)
						positions+=point.pos;
					var histogram = MinSG.SamplingAnalysis.createAngleHistogram(positions,this.dhNumAngleBuckets);
	//				print_r(result._getAttributes());
					var dataTable = new (Std.require('LibUtilExt/DataTable'))("dist");
					var data = new Map;
					var scale = histogram.maxValue/histogram.buckets.count();
					foreach( histogram.buckets as var idx,var amount){
						data[idx*scale] = amount;
					}
					dataTable.addDataRow( "Distribution of angles","count", data,"#0000FF");
					dataTable.exportSVG(c.name()+"_angHist.svg");
					dataTable.exportCSV(c.name()+"_angHist.csv");

				},
				GUI.WIDTH : 150
			},
			GUI.NEXT_ROW, "----", GUI.NEXT_ROW,
			"*Closest point distance histogram*",	GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "Number of buckets",
				GUI.DATA_OBJECT : parameters,
				GUI.DATA_ATTRIBUTE : $dhNumClosestPointBuckets		
			},	GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "create",
				GUI.ON_CLICK : parameters->fn(){
					showWaitingScreen();
					var c = GASPManager.getSelectedGASP();
					if(!c){
						Runtime.warn("No gasp selected.");
						return;
					}
					var positions = [];
					foreach(c.sampleContainer.collectPoints() as var point)
						positions+=point.pos;
					var histogram = MinSG.SamplingAnalysis.createClosestPointDistanceHistogram(positions,this.dhNumClosestPointBuckets);
	//				print_r(result._getAttributes());
					var dataTable = new (Std.require('LibUtilExt/DataTable'))("dist");
					var data = new Map;
					var scale = histogram.maxValue/histogram.buckets.count();
					foreach( histogram.buckets as var idx,var amount){
						data[idx*scale] = amount;
					}
					dataTable.addDataRow( "Distribution of closest points","count", data,"#FF0000");
					dataTable.exportSVG(c.name()+"_cpDistHist.svg");
					dataTable.exportCSV(c.name()+"_cpDistHist.csv");

				},
				GUI.WIDTH : 150
			},
			GUI.NEXT_ROW, "----", GUI.NEXT_ROW,
			"*Closest point distance histogram*",	GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Save minimal distances",
				GUI.ON_CLICK : fn(){
					showWaitingScreen();
					var c = GASPManager.getSelectedGASP();
					if(!c){
						Runtime.warn("No gasp selected.");
						return;
					}
					var dataTable = new (Std.require('LibUtilExt/DataTable'))("dist");
					var data = new Map;
					foreach(c.sampleContainer.collectPoints() as var pointNr,var point){
						var pos = point.pos;
						var closestPoints = c.sampleContainer.getClosestPoints(pos, 2);
						if(closestPoints.count()<2)
							continue;
						
						data[pointNr] = [ pos.distance(closestPoints[0].pos), pos.distance(closestPoints[1].pos) ].max();
					}
					dataTable.addDataRow( "minDist","index", data,"#FF0000");
					dataTable.exportCSV(c.name()+"_minDist.csv");

				},
				GUI.WIDTH : 150
			},
			GUI.NEXT_ROW, "----", GUI.NEXT_ROW,
			"*2d distance histogram*",	GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_NUMBER,
				GUI.LABEL : "Number of buckets",
				GUI.DATA_OBJECT : parameters,
				GUI.DATA_ATTRIBUTE : $dhNumPixelBuckets		
			},	GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "create",
				GUI.ON_CLICK : parameters->fn(){
					showWaitingScreen();
					var c = GASPManager.getSelectedGASP();
					if(!c){
						Runtime.warn("No gasp selected.");
						return;
					}
					var positions = [];
					foreach(c.sampleContainer.collectPoints() as var point)
						positions+=point.pos;
					var bitmap = MinSG.SamplingAnalysis.create2dDistanceHistogram(positions,this.dhNumPixelBuckets);
					
					Rendering.saveTexture( renderingContext, Rendering.createTextureFromBitmap(bitmap),c.name()+"_distHist.png" );

				},
				GUI.WIDTH : 150
			},
			GUI.NEXT_ROW, "----", GUI.NEXT_ROW,
			
		];
		return [{
			GUI.TYPE : GUI.TYPE_TAB,
			GUI.TAB_CONTENT : page,
			GUI.LABEL : "S-Anaylsis"
		}];
	});

};


// ---------------------------------------------------------
return plugin;
