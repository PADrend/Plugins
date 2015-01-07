/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2008-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2008-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[SceneAnalyzer] SceneAnalyzer/GASP.escript
 ** Globally Approximated Scene Property
 ** 2008-01-28
 **/

/*! AnnotationState ---|> MinSG.ScriptedState
	This state replaces the rendering parameters of a node by the value set in an external object's attribute.
	By configuring this external object, the rendering parameters are thereby changed automatically.	
*/
static AnnotationState = new Type( MinSG.ScriptedState );

AnnotationState.flagContainer := void;
AnnotationState.flagName := void;

//! (ctor)
AnnotationState._constructor ::= fn(_flagContainer,_flagName){
	this.setTempState(true); // don't save this state
	flagContainer = _flagContainer;
	flagName = _flagName;
};

//! ---|> MinSG.State
AnnotationState.doEnableState ::= fn(node,params){
	if(params.getFlag(MinSG.NO_GEOMETRY)){
		return MinSG.STATE_SKIP_RENDERING;
	}
	var flags = flagContainer.getAttribute(flagName)| MinSG.USE_WORLD_MATRIX;
	if(params.getFlags() == flags)
		return MinSG.STATE_OK;

	params.setFlags(flags);
	node.display(frameContext,params);
	return MinSG.STATE_SKIP_RENDERING;
};


// -------

static T = new Type; // GaSP GlobbalyApproximatedSceneProperty


// ---------------------------------------
// global rendering settings
//! (static)
T.gaspRenderingFlags ::= MinSG.USE_WORLD_MATRIX;
T.samplingPointRenderingFlags ::= MinSG.USE_WORLD_MATRIX;
T.delaunay2dRenderingFlags ::= MinSG.USE_WORLD_MATRIX;
T.delaunay3dRenderingFlags ::= MinSG.USE_WORLD_MATRIX;

T.gaspControlState ::= new AnnotationState(T,$gaspRenderingFlags);


// ---------------------------------------

// main data members
T.rootNode:=void; //!< The valuatedRegion-root node
T.sampleContainer:=void;  //!< A PointOctree storing position -> measured value
T.name @(init) := Std.DataWrapper; // filename
T.onNewRegions @(init) := Std.MultiProcedure;
T.directions:=void;

T.containerNode := void; //! A MinSG.ListNode containing all the valuatedRegion-rootNode, and the other nodes used for visualization.



/**
 * [ctor]
 * @param bbox Box.
 * @param xRes Number x-Resolution.
 * @param yRes Number y-Resolution.
 * @param zRes Number z-Resolution.
 * @param directions (optional) Array: directions of the cube used for evaluation.
 */
T._constructor::=fn(bbox,xRes,yRes,zRes,Array directions=[0,1,2,3,4,5]) {
    this.sampleContainer=new Geometry.PointOctree(bbox,1.0,10);
    this.directions=directions;

	this.containerNode = new MinSG.ListNode();
	this.containerNode.name := "GASPContainer";

    setRootNode(new MinSG.ValuatedRegionNode(bbox,xRes,yRes,zRes));	
};

T.display::=fn(MinSG.FrameContext frameContext,flags=0) {
    if (containerNode)
        containerNode.display(frameContext,flags);
};

/*! Store the information of the @p description as node attribute of the rootNode.
	If a value is void, the attribute is removed. */
T.applyDescription::=fn(Map description){
	foreach(description as var key,var value){
		if(value===void){
			rootNode.unsetNodeAttribute(key);
		}else{
			rootNode.setNodeAttribute(key, value.clone());
		}
	}
};

T.getDescription::=fn(){
	return rootNode.getNodeAttributes();
};

T.getRootNode::=fn(){
	return rootNode;
};

T.getContainerNode::=fn(){
	return containerNode;
};


T.setRootNode ::= fn(MinSG.ValuatedRegionNode newRoot){
	if(newRoot != rootNode){
		if(rootNode)
			MinSG.destroy(rootNode);
		
		rootNode = newRoot;
		containerNode += rootNode;
		rootNode += gaspControlState;
	}
};

// ----------------------
// --- Color calculations


/*! (internal)
 * @param colorProfile.values[] ascending list of values that correspond to colors.
 * @param colorProfile.colors[] the colors (and heights) according to the values.
 * @param colorProfile.dirCombineFunction[] 	
 * @return [r,g,b,a,height]
 */
T.calculateColor ::= fn(value,colorProfile){
	var i=0;
	while(i<colorProfile.values.count()-1 && colorProfile.values[i]<value){
		i++;
	}
	var minVal=i>0?colorProfile.values[i-1]:colorProfile.values[0];
	var minCol=i>0?colorProfile.colors[i-1]:colorProfile.colors[0];

	var maxVal=colorProfile.values[i];
	var maxCol=colorProfile.colors[i];

	var amount = value - minVal;
	var whole = maxVal - minVal;
	var ratio;
	if(whole ~= 0.0) {
		ratio = 1.0;
	} else {
		ratio = (amount / whole).clamp(0,1);
	}
	return [ (1.0 - ratio) * minCol[0] + ratio * maxCol[0],
			(1.0 - ratio) * minCol[1] + ratio * maxCol[1],
			(1.0 - ratio) * minCol[2] + ratio * maxCol[2],
			(1.0 - ratio) * minCol[3] + ratio * maxCol[3],
			(minCol.count()>4 && maxCol.count()>4) ? ((1.0 - ratio) *minCol[4] + ratio * maxCol[4]) : 1.0 ];
};

/**
 * Change the colors of a gasp node.
 *
 * @param cNode GASP node.
 * @param colorProfile.values[] ascending list of values that correspond to colors.
 * @param colorProfile.colors[] the colors (and heights) according to the values.
 * @param colorProfile.dirCombineFunction[] 
 */
T.recalculateColors ::= fn(cNode, colorProfile) {
    if(!cNode.isLeaf()) {
    	var children = MinSG.getChildNodes(cNode);
        foreach(children as var child) {
            if(child) {
                this.recalculateColors(child, colorProfile);
            }
        }
    } else {
    	cNode.clearColors();
    	var values = cNode.getValueAsNumbers();
    	if(colorProfile.dirCombineFunction){
            values=[ colorProfile.dirCombineFunction(values) ]; 
    	}

    	foreach(values as var value){
			var c=calculateColor(value,colorProfile);
			cNode.addColor(c[0], c[1], c[2], c[3]);
			cNode.setHeightScale(c[4]);
    	}
    }
};


// ----------------------
// --- Samples
T.getSampleContainer ::= fn(){
	return this.sampleContainer;
};

T.storeSample ::= fn(Geometry.Vec3 pos,value){
	this.sampleContainer.insert(pos,value);
};

T.getClosestSample ::= fn(Geometry.Vec3 pos){
	var points=this.sampleContainer.getClosestPoints(pos,1);
	return points.empty() ? false : points[0];
};

T.updateSampleVisualization ::= fn(colorProfile){

	if(containerNode.isSet($sampleVisualizationNode) && containerNode.sampleVisualizationNode){
		MinSG.destroy(containerNode.sampleVisualizationNode);
	}

	containerNode.sampleVisualizationNode := new MinSG.ListNode();
	var sampleVisualizationNode = containerNode.sampleVisualizationNode;

	sampleVisualizationNode += new AnnotationState(T,$samplingPointRenderingFlags);
	
//	sampleVisualizationNode += new MinSG.LightingState(PADrend.getDefaultLight());
	containerNode += sampleVisualizationNode;
	
	var mb = new Rendering.MeshBuilder;
	var samples = sampleContainer.collectPoints();
	out("\n",samples.count(),"\n");
	foreach(samples as var point){
		var position = point.pos;
		var value = point.data;
		if(value---|>Array)
			value = value[0];
		var cArr = calculateColor(value,colorProfile);
		mb.color(new Util.Color4f(cArr));
		var size=0.1*cArr[4];
		mb.addBox(new Geometry.Box(position,size,size,size));
	}
	sampleVisualizationNode.addChild(new MinSG.GeometryNode(mb.buildMesh()));

};


/*! A @p valueMappingFun can be used to extract a single value from an arbitrary result stored at the points.
*/
T.createDelaunay2d ::= fn(colorProfile){
	var samples = sampleContainer.collectPoints();
	var data = new Map;
	foreach(samples as var point){

		// switch z and y
		var pos = new Geometry.Vec2(point.pos.getX(), point.pos.getZ());
		var value = point.data;
		
		if(colorProfile.dirCombineFunction){
            value = colorProfile.dirCombineFunction(value); 
    	}
    	if(value---|>Array)
			value = value[0];
		data[pos] = new Util.Color4ub(new Util.Color4f(calculateColor(value,colorProfile)));
	}

	var t = new MinSG.Triangulation.Delaunay2d();
	foreach(data as var pos,var color){
//		out(pos);
		t.addPoint(pos, color);
	}

	if(containerNode.isSet($delaunayNode) && containerNode.delaunayNode){
		MinSG.destroy(containerNode.delaunayNode);
	}

	var vertexDescription = new Rendering.VertexDescription();
	vertexDescription.appendNormalByte();
	vertexDescription.appendColorRGBAByte();
	vertexDescription.appendPosition2D();

	var meshBuilder = new Rendering.MeshBuilder(vertexDescription);
	meshBuilder.normal(new Geometry.Vec3(0, 0, -1));
	t.generate( [meshBuilder] => fn(meshBuilder, pointA, pointB, pointC) {
		meshBuilder.color(pointA.data);
		meshBuilder.position2D(pointA.pos);
		meshBuilder.addVertex();
		meshBuilder.color(pointB.data);
		meshBuilder.position2D(pointB.pos);
		meshBuilder.addVertex();
		meshBuilder.color(pointC.data);
		meshBuilder.position2D(pointC.pos);
		meshBuilder.addVertex();
	});

	containerNode.delaunayNode := new MinSG.GeometryNode(meshBuilder.buildMesh());
	containerNode.delaunayNode.name := "2-D-Delaunay";
	
	containerNode += containerNode.delaunayNode;
	containerNode.delaunayNode += new AnnotationState(T,$delaunay2dRenderingFlags);
//	delaunayNode.addState(new MinSG.LightingState(PADrend.getDefaultLight()));
	containerNode.delaunayNode.rotateLocal_deg( 90,new Geometry.Vec3(1,0,0));
	NodeEditor.selectNode(containerNode.delaunayNode);
};

T.createDelaunay3d ::= fn(colorProfile){
	var samples = sampleContainer.collectPoints();
	var data = new Map();
	out("\na)",samples.count(),"\n");
	foreach(samples as var point){
		var value = point.data;
		if(value---|>Array)
			value = value[0];
			
		var pos = point.pos.clone();//new Geometry.Vec3(point.pos.getX().round(0.01),point.pos.getY().round(0.01),point.pos.getZ().round(0.01));
			
		data[pos] = new Util.Color4ub(new Util.Color4f(calculateColor(value,colorProfile)));
	}
	out("\nb)",data.count(),"\n");

	var t = new MinSG.Triangulation.Delaunay3d();
	foreach(data as var pos,var color){
//		out(pos);
		pos = pos*0.1; // scale to improve numerical robustness (???)
		t.addPoint(pos, color);
	}

	if(containerNode.isSet($delaunayNode) && containerNode.delaunayNode){
		MinSG.destroy(containerNode.delaunayNode);
	}

	var vertexDescription = new Rendering.VertexDescription();
	vertexDescription.appendNormalByte();
	vertexDescription.appendColorRGBAByte();
	vertexDescription.appendPosition3D();

	var meshBuilder = new Rendering.MeshBuilder(vertexDescription);
	t.generate( [meshBuilder] => fn(meshBuilder, tetrahedron, pointA, pointB, pointC, pointD) {
		var i;
		var j;
		var k;

		// pA cbd
		meshBuilder.normal(tetrahedron.getPlaneA().getNormal());
		meshBuilder.color(pointC.data);
		meshBuilder.position(pointC.pos);
		i = meshBuilder.addVertex();
		meshBuilder.color(pointB.data);
		meshBuilder.position(pointB.pos);
		j = meshBuilder.addVertex();
		meshBuilder.color(pointD.data);
		meshBuilder.position(pointD.pos);
		k = meshBuilder.addVertex();
		meshBuilder.addTriangle(i, j, k);

		// pB acd
		meshBuilder.normal(tetrahedron.getPlaneB().getNormal());
		meshBuilder.color(pointA.data);
		meshBuilder.position(pointA.pos);
		i = meshBuilder.addVertex();
		meshBuilder.color(pointC.data);
		meshBuilder.position(pointC.pos);
		j = meshBuilder.addVertex();
		meshBuilder.color(pointD.data);
		meshBuilder.position(pointD.pos);
		k = meshBuilder.addVertex();
		meshBuilder.addTriangle(i, j, k);

		// pC adb
		meshBuilder.normal(tetrahedron.getPlaneC().getNormal());
		meshBuilder.color(pointA.data);
		meshBuilder.position(pointA.pos);
		i = meshBuilder.addVertex();
		meshBuilder.color(pointD.data);
		meshBuilder.position(pointD.pos);
		j = meshBuilder.addVertex();
		meshBuilder.color(pointB.data);
		meshBuilder.position(pointB.pos);
		k = meshBuilder.addVertex();
		meshBuilder.addTriangle(i, j, k);

		// pD abc
		meshBuilder.normal(tetrahedron.getPlaneD().getNormal());
		meshBuilder.position(pointA.pos);
		meshBuilder.color(pointA.data);
		i = meshBuilder.addVertex();
		meshBuilder.color(pointB.data);
		meshBuilder.position(pointB.pos);
		j = meshBuilder.addVertex();
		meshBuilder.color(pointC.data);
		meshBuilder.position(pointC.pos);
		k = meshBuilder.addVertex();
		meshBuilder.addTriangle(i, j, k);
	});

	containerNode.delaunayNode := new MinSG.GeometryNode(meshBuilder.buildMesh());
	containerNode.delaunayNode.name := "3-D-Delaunay";
	containerNode += containerNode.delaunayNode;
	containerNode.delaunayNode += new AnnotationState(T,$delaunay3dRenderingFlags);
	containerNode.delaunayNode.scale( 10.0);
	NodeEditor.selectNode(containerNode.delaunayNode);
};

// ----------------------
// --- Value

T.getValueAtPosition::=fn(Geometry.Vec3 pos){
    return this.rootNode.getValueAtPosition(pos);
};
T.getDirectionalValue ::= fn(MinSG.AbstractCameraNode camera,measurementAperture=120){
	var cn = this.rootNode.getNodeAtPosition(camera.getWorldOrigin());
	if(cn){
		return (new MinSG.DirectionalInterpolator).calculateValue(renderingContext,cn,camera,measurementAperture);
	}else{
		return -1;
	}
};

/*! number gasp.getMinValue() */
T.getMinValue::=fn(){
    var f=fn(/*gaspNode*/ cNode){
        if(cNode.isLeaf())
            return cNode.getValueAsNumbers().min();
        var min;
        var children = MinSG.getChildNodes(cNode);
        foreach(children as var child) {
            if(child == void) continue;
            var newMin= thisFn(child);
            min= (min==void||newMin<min)?newMin:min;
        }
        return min;
    };
    return f(this.rootNode);
};

/*! number gasp.getMaxValue() */
T.getMaxValue::=fn(){
    var f=fn(/*gaspNode*/ cNode){
        if(cNode.isLeaf()){
//			print_r(cNode.getValueAsNumbers());
            return cNode.getValueAsNumbers().max();
        }
        var max;
        var children = MinSG.getChildNodes(cNode);
        foreach(children as var child) {
            if(child == void) continue;
            var newMax= thisFn(child);
            max= (max==void||newMax>max)?newMax:max;
        }
        return max;
    };
    return f(this.rootNode);
};

/*! number gasp.getAvgValue() */
T.getAvgValue::=fn(){
    var f=fn(/*gaspNode*/ cNode,result){
        if(cNode.isLeaf()){
            foreach(cNode.getValueAsNumbers() as var v){
                if(v===void) continue;
                result.size+=cNode.getSize();
                result.sum+=v*cNode.getSize();
            }
        }
        var children = MinSG.getChildNodes(cNode);
        foreach(children as var child) {
            if(child == void) continue;
            thisFn(child);
        }
    };
    var result=new ExtObject();
    result.size:=0;
    result.sum:=0;

	f(this.rootNode,result);
    
    if(result.size!=0)
        return result.sum/result.size;
    return void;
};

/*! number gasp.getVariance(e) */
T.getVariance::=fn(e){

    var f=fn(/*gaspNode*/ cNode,result){
        if(cNode.isLeaf()){
            foreach(cNode.getValueAsNumbers() as var v){
                if(v===void) continue;
                result.size+=cNode.getSize();
                result.sum+=(e-v)*(e-v)*cNode.getSize();
            }
        }
        var children = MinSG.getChildNodes(cNode);
        foreach(children as var child) {
            if(child == void) continue;
            thisFn(child);
        }
    };
    var result=new ExtObject;
    result.size:=0;
    result.sum:=0;
    
    f(this.rootNode,result);
    if(result.size!=0)
        return result.sum/result.size;
    return void;
};

return T;
// ----------------------------------------------------------------------------------------------------------
