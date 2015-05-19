/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
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

static GASPManager = Std.module('SceneAnalyzer/GlobalGASPManager');

var plugin = new Plugin({
		Plugin.NAME : 'SceneAnalyzer/ValueAnalysis',
		Plugin.DESCRIPTION : 'Analyze sampling values.',
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "Claudius",
		Plugin.VERSION : 0.1,
		Plugin.REQUIRES : ['SceneAnalyzer','PADrend','PADrend/GUI'],
		Plugin.EXTENSION_POINTS : [	]
});

plugin.init @(override) := fn(){
	Util.registerExtension('PADrend_Init',this->this.ex_Init);
	return true;
};

//! [ext:PADrend_Init]
plugin.ex_Init := fn(...){
	gui.register('SceneAnalyzer_Tabs.90_V-Analyzer',fn(){
		var page=gui.createPanel(100,100,GUI.AUTO_LAYOUT);

		var settings = new ExtObject({
				$numBuckets : Std.DataWrapper.createFromEntry( PADrend.configCache,'SceneAnalyzer.ValuaAnalysis.numBuckets',20 ),
		});

		page += [ 
			"*gasp value histogram (singleValue)*",	GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_RANGE,
				GUI.DATA_WRAPPER : settings.numBuckets,
				GUI.RANGE : [1,50],
				GUI.LABEL : "#buckets",
				GUI.ON_DATA_CHANGED : fn(data){	out(data,"\t");	},

			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Show histogram",
				GUI.ON_CLICK : [settings]=>fn(settings){
					showWaitingScreen();
					var c = GASPManager.getSelectedGASP();
					if(!c){
						Runtime.warn("No gasp selected.");
						return;
					}
					var distribution = new Map();
					
					var max = false;
					var sizeFactor = 1 / c.getRootNode().getSize();
					
					foreach( MinSG.collectLeafNodes( c.getRootNode() ) as var region ){
						var value = region.getValueAsNumber();
						if(!distribution[value])
							distribution[value] = 0;
						distribution[value] += region.getSize()*sizeFactor;
						if(!max || value>max)
							max = value;
					}
					var buckets = new Array();
					buckets.resize(settings.numBuckets()+1,0);
					
					var bucketSize = max / settings.numBuckets();
					out(max,"\n");
					out(settings.numBuckets(),"\n");
					out(bucketSize,"\n");
					
	//					return;
					foreach(distribution as var value, var amount){
	//					out(value,":",amount," ");
						buckets[(value/bucketSize).floor()]+=amount;
					}
					
					
					var scale = (70/buckets.max());
					print_r(buckets);
					foreach(buckets as var key,var value){
						out((key*bucketSize).round(0.1),"\t|",("#"*(value*scale)),"\n");
					
					}

	//settings
				},
				GUI.WIDTH : 150
			},
			GUI.NEXT_ROW,
			{
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.LABEL : "Export weighted values",
				GUI.ON_CLICK : [settings]=>fn(settings){
					var c = GASPManager.getSelectedGASP();
					if(!c){
						Runtime.warn("No gasp selected.");
						return;
					}
					var distribution = new Map();
					
	//				var max = false;
					var sizeFactor = 1 / c.getRootNode().getSize();
					
					foreach( MinSG.collectLeafNodes( c.getRootNode() ) as var region ){
						var value = region.getValueAsNumber();
						if(!distribution[value])
							distribution[value] = 0;
						distribution[value] += region.getSize()*sizeFactor;
	//					if(!max || value>max)
	//						max = value;
					}
					var dataTable = new (Std.module('LibUtilExt/DataTable'))("value");
					dataTable.addDataRow( "weight","y",distribution);
					dataTable.exportCSV("1.csv",",");
					PADrend.message("Data exported.");

				}
			},
			GUI.NEXT_ROW,
			"*sampled delaunay 2d*",	GUI.NEXT_ROW,
			GUI.NEXT_ROW,
			"*sampled delaunay 3d*",	GUI.NEXT_ROW,
			
		];
	return [{
			GUI.TYPE : GUI.TYPE_TAB,
			GUI.TAB_CONTENT : page,
			GUI.LABEL : "V-Anaylsis"
		}];
	});
};
//plugin.generateFilename @(private) := fn(){
//	settings.shotCounter( settings.shotCounter()+1 );
//	var date = Util.createTimeStamp();
//	return settings.folder() + "/" + settings.filename().replaceAll({
//							'${date}':date, 
//							'${time}':time().toIntStr() , 
//							'${counter}' : settings.shotCounter().format(0,false,3) });
//
//};

// ---------------------------------------------------------
return plugin;
