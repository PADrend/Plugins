/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2017-2018 Sascha Brandt <sascha@brandt.graphics>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */
static mesh_sphere = Rendering.loadMesh(__DIR__ + "/../resources/meshes/sphere_10k.mmf");

static SurfelGenerator = Std.module("BlueSurfels/SurfelGenerator");
static sampler = new (Std.module("BlueSurfels/Sampler/GreedyCluster"));
sampler.setTargetCount(10000);

static surfelRenderer = new MinSG.SurfelRenderer;
surfelRenderer.addSurfelStrategy(new MinSG.BlueSurfels.FixedSizeStrategy);

static TS = new Namespace;
TS.scenes := [];
TS.getScenes := fn() { return scenes; };
TS.addScene := fn(name, generator) {
  TS.scenes += new ExtObject({
    $name : name,
    $generate : generator,
  });
};

TS.addScene("Unit Sphere", fn() {
  var origNode = new MinSG.GeometryNode(mesh_sphere);
  SurfelGenerator.createSurfelsForNode(origNode, sampler);
  PADrend.getCurrentScene() += origNode;
  PADrend.getCurrentScene() += surfelRenderer;
});

TS.addScene("Line of Spheres", fn() {
  var origNode = new MinSG.GeometryNode(mesh_sphere);
  SurfelGenerator.createSurfelsForNode(origNode, sampler);
  
  for(var i=0; i<12; ++i) {
    var node = MinSG.Node.createInstance(origNode);
    node.setWorldOrigin(new Geometry.Vec3(0,0,-4*i));
    PADrend.getCurrentScene() += node;
  }
  
  PADrend.getCurrentScene() += surfelRenderer;
});

TS.addScene("Row of Spheres", fn() {
  var origNode = new MinSG.GeometryNode(mesh_sphere);
  SurfelGenerator.createSurfelsForNode(origNode, sampler);
  
  for(var i=0; i<12; ++i) {
    var node = MinSG.Node.createInstance(origNode);
    node.setWorldOrigin(new Geometry.Vec3(4*(i-5),0,0));
    PADrend.getCurrentScene() += node;
  }
  
  PADrend.getCurrentScene() += surfelRenderer;
});

TS.addScene("Cluster of Spheres", fn() {
  var origNode = new MinSG.GeometryNode(mesh_sphere);
  SurfelGenerator.createSurfelsForNode(origNode, sampler);
  
  var mesh = Rendering.createIcosahedron();
  var posAcc = Rendering.PositionAttributeAccessor.create(mesh);
  for(var i = 0; i<mesh.getVertexCount(); ++i){
    var pos = posAcc.getPosition(i);    
    var node = MinSG.Node.createInstance(origNode);
    node.setWorldOrigin(pos);
    PADrend.getCurrentScene() += node;
  }
  
  PADrend.getCurrentScene() += surfelRenderer;
});

TS.addScene("Sphere in Sphere", fn() {
  var origNode = new MinSG.GeometryNode(mesh_sphere);
  SurfelGenerator.createSurfelsForNode(origNode, sampler);
  
  for(var i=1; i>=0; --i){
    var s = 2.pow(i);    
    var node = MinSG.Node.createInstance(origNode);
    node.setScale(s);
    PADrend.getCurrentScene() += node;
  }
  
  PADrend.getCurrentScene() += surfelRenderer;
});

TS.addScene("Sphere in Sphere^12", fn() {
  var origNode = new MinSG.GeometryNode(mesh_sphere);
  SurfelGenerator.createSurfelsForNode(origNode, sampler);
  
  for(var i=2; i>=-9; --i){
    var s = 2.pow(i);    
    var node = MinSG.Node.createInstance(origNode);
    node.setScale(s);
    PADrend.getCurrentScene() += node;
  }
  
  PADrend.getCurrentScene() += surfelRenderer;
});

TS.addScene("Random Spheres in Plane", fn() {
  var origNode = new MinSG.GeometryNode(mesh_sphere);
  SurfelGenerator.createSurfelsForNode(origNode, sampler);
  
  var scale = 1000;
  for(var i=0; i<10000; ++i) {
    var node = MinSG.Node.createInstance(origNode);
    var pos = new Geometry.Vec3(Rand.uniform(0,1), 0, Rand.uniform(0,1));
    node.setWorldOrigin(pos * scale);
    PADrend.getCurrentScene() += node;
  }
  
  PADrend.getCurrentScene() += surfelRenderer;
});

return TS;
