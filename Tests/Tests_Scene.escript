/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2015 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:Tests] Test/Tests_SCene.escript
 **/

var plugin = new Plugin({
		Plugin.NAME : 'Tests/Tests_SCene',
		Plugin.DESCRIPTION : 'Creates a default scene with many cubes',
		Plugin.VERSION : 0.1,
		Plugin.AUTHORS : "Claudius",
		Plugin.OWNER : "All",
		Plugin.REQUIRES : [ 'Tests' ],
		Plugin.EXTENSION_POINTS : []
});

plugin.init @(override) :=fn(){
	module.on('PADrend/gui', this->fn(gui){
		gui.register('Tests_TestsMenu.generatedScenes',{
			GUI.TYPE : GUI.TYPE_BUTTON,
			GUI.LABEL : "Generated test scenes",
			GUI.ON_CLICK : this->fn() {
				execute();
			}
		});
	});
    return true;
};


//! (internal)
plugin.execute:=fn(){
	

	var p=gui.createPopupWindow( 300,300,"Scene test");

	p.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "27k cubes ",
		GUI.ON_CLICK : this->fn(){ createCubeScene(30); },
		GUI.TOOLTIP : "30*30*30 cubes (cloned geometry nodes)"
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "27k cubes with many materials",
		GUI.ON_CLICK : this->fn(){ createMaterialCubeScene(30); },
		GUI.TOOLTIP : "30*30*30 cubes (cloned geometry nodes), each having a different material state"
	});
	p.addOption({
		GUI.TYPE : GUI.TYPE_BUTTON,
		GUI.LABEL : "27k cubes with few materials",
		GUI.ON_CLICK : this->fn(){ createFewMaterialsCubeScene(30,3); },
		GUI.TOOLTIP : "30*30*30 cubes (cloned geometry nodes), each having one of three different material states"
	});
	p.addOption({
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"Cube of cubes",
		GUI.TOOLTIP		:	"Small, colored cubes that result in a large cube with side length two.",
		GUI.ON_CLICK	:	[this]=>fn(plugin) {
								var config = new ExtObject({
									$count	:	2
								});
								
								var dialog = gui.createPopupWindow(300, 90);
								dialog.addOption({
									GUI.TYPE			:	GUI.TYPE_RANGE,
									GUI.LABEL			:	"Count",
									GUI.TOOLTIP			:	"Number of cubes on each edge. Count cubed cubes will be created.",
									GUI.RANGE			:	[2, 10],
									GUI.RANGE_STEPS		:	8,
									GUI.DATA_OBJECT		:	config,
									GUI.DATA_ATTRIBUTE	:	$count
								});
								dialog.addAction("Generate Scene", [config, plugin]=>fn(config, plugin) {
									plugin.createCubeOfCubesScene(config.count);
								});
								dialog.addAction("Cancel");
								dialog.init();
							}
	});
	p.addOption({
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"Grid of cubes",
		GUI.TOOLTIP		:	"Grid of small cubes, whose size is determined by a normal distributed random variable.",
		GUI.ON_CLICK	:	[this]=>fn(plugin) {
								var config = new ExtObject({
									$count			:	5,
									$sizeMean		:	1.0,
									$sizeVariance	:	0.1
								});
								
								var dialog = gui.createPopupWindow(300, 120);
								dialog.addOption({
									GUI.TYPE			:	GUI.TYPE_RANGE,
									GUI.LABEL			:	"Count",
									GUI.TOOLTIP			:	"Number of cubes on each edge. Count cubed cubes will be created.",
									GUI.RANGE			:	[2, 10],
									GUI.RANGE_STEPS		:	8,
									GUI.DATA_OBJECT		:	config,
									GUI.DATA_ATTRIBUTE	:	$count
								});
								dialog.addOption({
									GUI.TYPE			:	GUI.TYPE_RANGE,
									GUI.LABEL			:	"Size Mean",
									GUI.TOOLTIP			:	"Mean of the normal distribution that is used to determine the size of the cubes.",
									GUI.RANGE			:	[0.1, 2.0],
									GUI.RANGE_STEPS		:	19,
									GUI.DATA_OBJECT		:	config,
									GUI.DATA_ATTRIBUTE	:	$sizeMean
								});
								dialog.addOption({
									GUI.TYPE			:	GUI.TYPE_RANGE,
									GUI.LABEL			:	"Size Variance",
									GUI.TOOLTIP			:	"Variance of the normal distribution that is used to determine the size of the cubes.",
									GUI.RANGE			:	[0.01, 0.5],
									GUI.RANGE_STEPS		:	49,
									GUI.DATA_OBJECT		:	config,
									GUI.DATA_ATTRIBUTE	:	$sizeVariance
								});
								dialog.addAction("Generate Scene", [config, plugin]=>fn(config, plugin) {
									plugin.createGridOfCubesScene(config.count, config.sizeMean, config.sizeVariance);
								});
								dialog.addAction("Cancel");
								dialog.init();
							}
	});
	p.addOption({
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"Sphere of cubes",
		GUI.TOOLTIP		:	"Sphere of small cubes, whose position is determined by a normal distributed random variable.",
		GUI.ON_CLICK	:	[this]=>fn(plugin) {
								var config = new ExtObject({
									$count			:	1000,
									$posVariance	:	50
								});
								
								var dialog = gui.createPopupWindow(300, 120);
								dialog.addOption({
									GUI.TYPE			:	GUI.TYPE_RANGE,
									GUI.LABEL			:	"Count",
									GUI.TOOLTIP			:	"Overall number of cubes.",
									GUI.RANGE			:	[100, 10000],
									GUI.RANGE_STEPS		:	99,
									GUI.DATA_OBJECT		:	config,
									GUI.DATA_ATTRIBUTE	:	$count
								});
								dialog.addOption({
									GUI.TYPE			:	GUI.TYPE_RANGE,
									GUI.LABEL			:	"Position Variance",
									GUI.TOOLTIP			:	"Variance of the normal distribution that is used to determine the position of the cubes.",
									GUI.RANGE			:	[1, 100],
									GUI.RANGE_STEPS		:	99,
									GUI.DATA_OBJECT		:	config,
									GUI.DATA_ATTRIBUTE	:	$posVariance
								});
								dialog.addAction("Generate Scene", [config, plugin]=>fn(config, plugin) {
									plugin.createSphereOfCubesScene(config.count, config.posVariance);
								});
								dialog.addAction("Cancel");
								dialog.init();
							}
	});
	p.addOption({
		GUI.TYPE		:	GUI.TYPE_BUTTON,
		GUI.LABEL		:	"Sphere of cubes (death star)",
		GUI.TOOLTIP		:	"Sphere of small cubes, whose position is determined by a normal distributed random variable.",
		GUI.ON_CLICK	:	[this]=>fn(plugin) {
								var config = new ExtObject({
									$count			:	2000,
									$posVariance	:	10
								});
								
								var dialog = gui.createPopupWindow(300, 120);
								dialog.addOption({
									GUI.TYPE			:	GUI.TYPE_RANGE,
									GUI.LABEL			:	"Count",
									GUI.TOOLTIP			:	"Overall number of cubes.",
									GUI.RANGE			:	[100, 10000],
									GUI.RANGE_STEPS		:	99,
									GUI.DATA_OBJECT		:	config,
									GUI.DATA_ATTRIBUTE	:	$count
								});
								dialog.addOption({
									GUI.TYPE			:	GUI.TYPE_RANGE,
									GUI.LABEL			:	"Position Variance",
									GUI.TOOLTIP			:	"Variance of the normal distribution that is used to determine the position of the cubes.",
									GUI.RANGE			:	[1, 100],
									GUI.RANGE_STEPS		:	99,
									GUI.DATA_OBJECT		:	config,
									GUI.DATA_ATTRIBUTE	:	$posVariance
								});
								dialog.addAction("Generate Scene", [config, plugin]=>fn(config, plugin) {
									plugin.createSphereOfCubes2Scene(config.count, config.posVariance);
								});
								dialog.addAction("Cancel");
								dialog.init();
							}
	});
	p.addAction( "close" );
	p.init();

};

plugin.createCubeScene := fn(num,cubeAnnotator=fn(cube,x,y,z){}){
	var root=new MinSG.ListNode();
	root.name:="Test_Scene: generated scene.";
	
	var mb = new Rendering.MeshBuilder();
	mb.color(new Util.Color4f(1,1,1,1));
	mb.addBox(new Geometry.Box(new Geometry.Vec3(0,0,0),0.5,0.5,0.5));
	var cube=new MinSG.GeometryNode(mb.buildMesh());
	var cScale = 1.0/num;
	var rotScale = 180/num;
	
	for(var x=0;x<num;++x){
		var nx = new MinSG.ListNode();
		nx.setRelPosition(new Geometry.Vec3(x*2,0,0));
//		nx.rotateLocal_deg(x*rotScale,new Geometry.Vec3(1,0,0));
		for(var y=0;y<num;++y){
			var ny = new MinSG.ListNode();
			ny.setRelPosition(new Geometry.Vec3(0,y*2,0));
//			ny.rotateLocal_deg(y*rotScale,new Geometry.Vec3(0,1,0));
			for(var z=0;z<num;++z){
				var c = cube.clone();
				c.setRelPosition(new Geometry.Vec3(0,0,z*2));
				c.rotateLocal_deg(z*rotScale,new Geometry.Vec3(0,0,1));
				cubeAnnotator(c,x,y,z);
				ny.addChild(c);
			}
			nx.addChild(ny);
		}
		root.addChild(nx);
	}
	PADrend.registerScene(root);
	PADrend.selectScene(root);
};

plugin.createMaterialCubeScene := fn(num){
	createCubeScene(num,[1.0/num]=>fn(cScale, cube,x,y,z){
		var mat = new MinSG.MaterialState();					
		mat.setDiffuse( new Util.Color4f(x*cScale,y*cScale,z*cScale) );
		mat.setAmbient( new Util.Color4f(z*cScale,x*cScale,y*cScale) );
		mat.setSpecular( new Util.Color4f(y*cScale,z*cScale,x*cScale) );
		cube.addState(mat);
	});
	
};

plugin.createFewMaterialsCubeScene := fn(num,numMaterials){

	var r = new Math.RandomNumberGenerator(17); // create deterministic pseudo-random numbers
	
	var materials = [];
	for(var i=0;i<numMaterials;++i){
		var mat = new MinSG.MaterialState();	
		mat.setDiffuse( new Util.Color4f(r.uniform(0,1),r.uniform(0,1),r.uniform(0,1)) );
		mat.setAmbient(  new Util.Color4f(r.uniform(0,1),r.uniform(0,1),r.uniform(0,1)) );
		mat.setSpecular( new Util.Color4f(r.uniform(0,1),r.uniform(0,1),r.uniform(0,1)) );
		materials+=mat;
	}
	createCubeScene(num,[materials ,r]=>fn(materials,r, cube,x,y,z){
		cube.addState(materials[r.equilikely(0,materials.count()-1)]);
	});
};

plugin.createCubeOfCubesScene := fn(Number count) {
	var overallCount = count * count * count;
	var scene = new MinSG.ListNode();
	scene.name := "Test_Scene: Cube of " + overallCount + " (" + count + " cubed) cubes";

	var sideLength = 2 / count;

	for(var x = -1 + sideLength / 2; x < 1; x += sideLength) {
		for(var y = -1 + sideLength / 2; y < 1; y += sideLength) {
			for(var z = -1 + sideLength / 2; z < 1; z += sideLength) {
				var meshBuilder = new Rendering.MeshBuilder();
				meshBuilder.color(new Util.Color4f(0.5 + x / 2, 0.5 + y / 2, 0.5 + z / 2, 1));
				meshBuilder.addBox(new Geometry.Box(new Geometry.Vec3(x, y, z), sideLength, sideLength, sideLength));
				scene.addChild(new MinSG.GeometryNode(meshBuilder.buildMesh()));
			}
		}
	}

	PADrend.registerScene(scene);
	PADrend.selectScene(scene);
};

plugin.createGridOfCubesScene := fn(Number count, Number sizeMean, Number sizeVariance) {
	var overallCount = count * count * count;
	var scene = new MinSG.ListNode();
	scene.name := "Test_Scene: Grid of " + overallCount + " (" + count + " cubed) cubes (mean=" + sizeMean + ", variance=" + sizeVariance + ")";

	var generator = new Math.RandomNumberGenerator(17);
	var maxIndex = (count - 1);
	var posOffset = new Geometry.Vec3(maxIndex / 2, maxIndex / 2, maxIndex / 2);

	for(var x = 0; x < count; ++x) {
		for(var y = 0; y < count; ++y) {
			for(var z = 0; z < count; ++z) {
				var meshBuilder = new Rendering.MeshBuilder();
				meshBuilder.color(new Util.Color4f(x / maxIndex, y / maxIndex, z / maxIndex, 1));
				var size = generator.normal(sizeMean, sizeVariance);
				meshBuilder.addBox(new Geometry.Box((new Geometry.Vec3(x, y, z) - posOffset) * 2, size, size, size));
				scene.addChild(new MinSG.GeometryNode(meshBuilder.buildMesh()));
			}
		}
	}

	PADrend.registerScene(scene);
	PADrend.selectScene(scene);
};

plugin.createSphereOfCubesScene := fn(Number overallCount, Number posVariance) {
	var scene = new MinSG.ListNode();
	scene.name := "Test_Scene: Sphere of " + overallCount + " cubes (variance=" + posVariance + ")";

	var generator = new Math.RandomNumberGenerator(42);

	for(var i = 0; i < overallCount; ++i) {
		var meshBuilder = new Rendering.MeshBuilder();
		meshBuilder.color(new Util.Color4f(1, 1, 1, 1));
		var x = generator.normal(0, posVariance);
		var y = generator.normal(0, posVariance);
		var z = generator.normal(0, posVariance);
		meshBuilder.addBox(new Geometry.Box(new Geometry.Vec3(x, y, z), 1, 1, 1));
		scene.addChild(new MinSG.GeometryNode(meshBuilder.buildMesh()));
	}

	PADrend.registerScene(scene);
	PADrend.selectScene(scene);
};

plugin.createSphereOfCubes2Scene := fn(Number overallCount, Number posVariance) {
	var scene = new MinSG.ListNode;
	scene.name := "Test_Scene: Death Star of " + overallCount + " cubes (variance=" + posVariance + ")";

	var generator = new Math.RandomNumberGenerator(42);

	var deathRayShpere = new Geometry.Sphere(new Geometry.Vec3(posVariance*1.25,0,0),0.5*posVariance );

	for(var i = 0; i < overallCount; ++i) {
		var d = 1.0 -  generator.normal(0, 1.0).pow(3).abs();
		if(d<0)
			d = 1.0;


		var dir = (new Geometry.Vec3( generator.normal(0, 1),generator.normal(0, 1),generator.normal(0, 1))).normalize();
		var pos = dir*posVariance * d ;
		if(!deathRayShpere.isOutside(pos)){
			++overallCount;
			continue;
		}

		var meshBuilder = new Rendering.MeshBuilder();
		meshBuilder.color( (new Util.Color4f(1, 1, 1, 1))*generator.normal(d, 0.2).abs() );
		meshBuilder.addBox(new Geometry.Box(new Geometry.Vec3(0,0,0), 1, 1, 1));
		var n = new MinSG.GeometryNode(meshBuilder.buildMesh());

		scene.addChild(n);

		
		
		n.setRelPosition(pos);

		n.rotateToWorldDir( (new Geometry.Vec3(generator.normal(0, posVariance*0.1),generator.normal(0, posVariance*0.1),generator.normal(0, posVariance*0.1)))-pos );
		n.scale( generator.normal(1.0,0.1) );

	}

	PADrend.registerScene(scene);
	PADrend.selectScene(scene);
};

// ---------------------------------------------------------
return plugin;
