/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2010-2013 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2009-2013,2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[Plugin:GASP] GASP/GASPManager.escript
 ** Static factories and registry for GASPs and CSamplers.
 **/

static T = new ExtObject;

static Listener = Std.require('LibUtilExt/deprecated/Listener');
static GASP = module('./GASP');
static CSampler = module('./Sampling/CSampler');

// -----------------------------------------------------------
// ---  Default values
T.defaultBB:=[
    "0,0.5,0   ,32 ,1 ,32",
//    "/*pp_slice*/ -50,30,80   ,240 ,0.1 ,240",
    "/*pp_slice*/ -50,30,80   ,300 ,0.1 ,300",
    "/*pp_mod*/ -85,124,67   ,300 ,300 ,300",
    "1,0.5,-2   ,23 ,0.1 ,23",
    "0,0.2,0   ,32 ,0.1 ,32",
    "0,0,0   ,32 ,1 ,32"];

T.defaultResolutions:=[
    "1024,1,1024", 
    "64,1,64", 
    "128,1,128",
    "48,48,48", // TEMP!
    "64,64,64", // TEMP!
    "256,256,256" // TEMP!
    ];

// -----------------------------------------------------------
// --- GASP registry
T.selectedGASP @(private) := false;
T.registeredGASPs:=[];
T.onGASPChanged := new Std.MultiProcedure; // fn(gasp)
T.onGASPListChanged := new MultiProcedure; // fn( Array )



//! (static)
T.getSelectedGASP:=fn(){
    return selectedGASP;
};

//! (static)
T.getGASPs:=fn(){
    return registeredGASPs;
};

//! (static)
T.registerGASP:=fn(c){
    registeredGASPs += c;
    if(!selectedGASP)
        selectGASP(c);
    this.onGASPListChanged(registeredGASPs);
};

//! (static)
T.selectGASP:=fn([GASP,void] c){
	if(c!=selectedGASP){
		if(selectedGASP)
			PADrend.getRootNode() -= selectedGASP.getContainerNode();
		selectedGASP = c;
		if(selectedGASP)
			PADrend.getRootNode() += selectedGASP.getContainerNode();
		this.onGASPChanged(c);
	}
};

//! (static)
T.removeGASPs:=fn(Array removeList){
    selectGASP(void);
    print_r(removeList);
    var a=[];
    foreach(registeredGASPs as var c){
         if( !removeList.contains(c)){
            a.pushBack(c);
         }
    }
    registeredGASPs.swap(a);
    this.onGASPListChanged(registeredGASPs);
};


// -----------------------------------------------------------
// --- GASP handling

/**
 * [static] [Factory] Create a new GASP.
 *
 * @param params Creation String: "(cx,cy,cz, wx,wy,wz), resX,resY,resZ"
 * @return Resulting gasp. 
 */
T.createGASP:=fn(String params){
    var s="new GASP(new Geometry.Box"+params+");";
    out(s,"\n");
    var c;
    try {
        c = eval(s,{$GASP:GASP});
        if(! (c ---|> GASP)){
        	throw("No gasp created!");
        }
    } catch (e) {
        Runtime.warn(e);
        return void;
    }
	c.applyDescription( {
		"parameter":params,
		"time":Util.createTimeStamp()} );
	c.name( "GASP(" + params + ")");

	
    return c;
};

/*! [static] [Factory] */
T.load := fn(filename){
	var start = clock();
	out("Load gasp: ",filename,"\n");
    var a = MinSG.SceneManagement.loadMinSGFile( PADrend.getSceneManager(),filename);
    out("\nDone. ",(clock()-start)," sek\n");
    if ( (!a) || a.empty() ) {
        return void;
    }
    var gaspNode=a[0];
    if(! (gaspNode ---|> MinSG.ValuatedRegionNode) )
        return void;
        
    // create
	var constructionParameters = gaspNode.getNodeAttribute('parameter');
	if(!constructionParameters){
		constructionParameters = "(0,0,0, 32,1,32),1024,1,1024";
	}
	var c = createGASP(constructionParameters);

    c.setRootNode(gaspNode);
    c.applyDescription( {"filename":filename} );
    c.name(filename);

	// load sample points
	var sampleString = c.rootNode.getNodeAttribute("_samples");
	if(sampleString){
		try{
			var samples=parseJSON(sampleString);
			foreach(samples as var sample){
				var pos=sample[0];
				c.storeSample( new Geometry.Vec3(pos[0],pos[1],pos[2]),sample[1]);
			}
			out("#Samples:",samples.count(),"\n");

		}catch(e){
			Runtime.warn(e);
		}
		c.rootNode.unsetNodeAttribute("_samples");
	}
//    var ma=gaspNode.getNodeAttribute('measurementAperture');
//    if(ma){
//        c.measurementAperture=ma;
//    }
	registerGASP(c);
	return c;
};

/*! [static] helper for multiview loading */
T.selectByFileName := fn(fileName){
	out("Select gasp with file name '"+fileName+"'.\n");
	if(!fileName || fileName == ""+void){
		this.selectGASP(void);
		return void;
	}
	if(getSelectedGASP() && getSelectedGASP().name() == fileName)
		return getSelectedGASP();
		
	foreach(this.registeredGASPs as var c){
		if( c.name() == fileName){
			this.selectGASP(c);
			return c;
		}
	}
	// try loading
	if(IO.isFile(fileName)){
		var c = this.load(fileName);
		if(c){
			this.selectGASP(c);
			return c;
		}
	}
	Runtime.warn("Could not select gasp with file name '"+name+"'.");
};

/*! [static] */
T.save:=fn(GASP gasp, filename, Bool storeSamples=true){
	out("Save GASP \"",filename,"\"...");
	
	if(storeSamples){
		var samples = gasp.sampleContainer.collectPoints();
		var sExport = [];
		foreach(samples as var sample)
			sExport+= [ [sample.pos.getX(),sample.pos.getY(),sample.pos.getZ()], sample.data ];
		
		gasp.rootNode.setNodeAttribute("_samples",toJSON(sExport,false));
	}
	
	var b=MinSG.SceneManagement.saveMinSGFile( PADrend.getSceneManager(),filename,[gasp.rootNode]);

	if(storeSamples){
		gasp.rootNode.unsetNodeAttribute("_samples");
	}
	gasp.name(filename);
	onGASPListChanged(registeredGASPs);
	return b;
};

/**
 * [static] [Factory] Combine several gasps into a new one.
 *
 * @param gasps[] gasps to combine.
 * @param combineFunction fn(values...) { return combinedValues; }
 * @return Resulting gasp.
 */
T.combineGASPs := fn(Array gasps,combineFunction) {
    foreach(gasps as var c)
        assert(c ---|> GASP, __FILE__ + __LINE__);

	var c1Node = gasps[0].rootNode;

	var result = new GASP(c1Node.getBB(), c1Node.getXResolution(), c1Node.getYResolution(), c1Node.getZResolution()); //dummy
	var rNode = result.rootNode;

    var cNodes=[];
    foreach(gasps as var c){
        cNodes.pushBack(c.rootNode);
    }
    out("\n>>",__LINE__,"\n");
    
	T.combineNodes(cNodes,combineFunction, rNode);
    out("\n>>",__LINE__,"\n");

	{   // set infos
        var names=[];
        foreach(gasps as var c)
			names.pushBack(c.name());
        result.name="Combine("+names.implode(",")+")";
        var i=0;
        foreach(gasps as var c){
            result.rootNode.setNodeAttribute("["+i+"]",c.rootNode.getNodeAttributes());
            i++;
        }
        var min = result.getMinValue();
        var max = result.getMaxValue();
//        result.applyDescription( {
//				"value_range":""+min+", "+max,
//				"value_avg":""+result.getAvgValue(),
//				"value_standard_deviation(0)":""+result.getVariance(0).sqrt(),
//				"combine_expr":""+combineExpression
//		});

	}
	registerGASP(result);
	return result;
};
/**
 * [static] (internal) Recursively compute the combination of several gasp nodes.
 *
 * @param cNodes gasp nodes.
 * @param combineFunction combining function
 * @param rNode Resulting gasp node.
 */
T.combineNodes := fn(Array cNodes, combineFunction, MinSG.ValuatedRegionNode rNode) {
	var allNodesAreLeafs = true;
	foreach(cNodes as var cn)
        allNodesAreLeafs = allNodesAreLeafs & cn.isLeaf();

out("\n>>",__LINE__,"\n");

	if(allNodesAreLeafs) {
			out("\n>>",__LINE__,"\n");
		// Only leaves have an array of values.
		assert(rNode.isLeaf(), __FILE__ + __LINE__);

		// If both arrays have the same number of values, compare each value.
		var numValues=cNodes[0].getValue().count();
		var allNodesHaveSameNumberOfValues=true;
        foreach(cNodes as var cn)
            allNodesHaveSameNumberOfValues=allNodesHaveSameNumberOfValues& (numValues==cn.getValue().count());

		if(allNodesHaveSameNumberOfValues) {
			var newValues = [];
			for(var i = 0; i < numValues; ++i) {
			    var v=[];
                foreach(cNodes as var cn)
                    v.pushBack(cn.getValue()[i]);

			    var newValue=combineFunction(v); // e.g. v[0]-v[1]
			    newValues.pushBack(newValue);
            }
			rNode.setValue(newValues);
		} else { // else if number of values are different -> only use maximum
            var v=[];
            foreach(cNodes as var cn)
                v.pushBack(cn.getValue().max());

            var newValue=combineFunction(v); // e.g. v[0]-v[1]
            rNode.setValue([newValue]);
		}
		return;
	} else {
		out("\n>>",__LINE__,"\n");
		// Split the resulting node if one of the nodes has children.
		if(rNode.isLeaf()) {
			rNode.splitUp(rNode.getXResolution()>1 ? 2 : 1, rNode.getYResolution()>1 ? 2 : 1, rNode.getZResolution()>1 ? 2 : 1);
		}
	}
	
out("\n>>",__LINE__,"\n");

	for(var i = 0; i < 8; i++) {
		if(rNode.getChild(i) != void) {
			var cComps=[];
			// If one of the gasps has no children, use the parent to compare.
            foreach(cNodes as var cn){
                if(cn.getChild(i) != void)
                    cComps.pushBack(cn.getChild(i));
                else
                    cComps.pushBack(cn);
            }
			this.combineNodes(cComps, combineFunction, rNode.getChild(i));
		}
	}
};



// -----------------------------------------------------------
// --- CSampler handling

T.selectedCSampler := new Std.DataWrapper;
T.registeredCSamplers:=[];


//! (static)
T.getCSampler:=fn(){
    return this.selectedCSampler();
};

//! (static)
T.getCSamplerList:=fn(){
    return registeredCSamplers;
};

//! (static)
T.registerCSampler:=fn(CSampler c){
    registeredCSamplers+=c;
    if(!selectedCSampler())
        selectCSampler(c);
};

//! (static)
T.selectCSampler:=fn(c){
	this.selectedCSampler(c);
};

// ----------------------------------------------------------------------------

//! (static)
T.executeSampling:=fn(){
	getCSampler().execute(PADrend.getCurrentScene(),
						Std.require('Evaluator/EvaluatorManager').getSelectedEvaluator(),
						this.getSelectedGASP());
};

// ----------------------------------------------------------------------------

//////
//////// screenshots
//////// todo: move to ????????????????????????????????????????????????????????????
//////
///////**
////// *
////// */
//////GASP.makeScreenshot:=fn(camera){
//////
//////    var cam=camera.clone();
//////
//////    var rect=new Geometry.Rect(0,0,renderingContext.getWindowWidth(),renderingContext.getWindowHeight());
//////    cam.setViewport(rect);
//////
//////    frameContext.setCamera(cam);
//////    renderingContext.clearScreen(PADrend.bgColor);
//////    GL.disable(GL.LIGHTING); // FIXME: Use renderingContext
//////    sceneRoot.display(frameContext,PADrend.getRenderingFlags());
////////		rootNode.display(frameContext,PADrend.getRenderingFlags());
//////    this.display(frameContext);
//////
//////
//////    var filename=Screenshot.directory+"gasp_"+(GASP.screenshotNr++)+".bmp";
//////    var tex=Rendering.createTextureFromScreen();
//////    var b=Rendering.saveTexture(renderingContext,tex,filename);
//////    out("Screenshot:",filename," : ",tex,"\t",(b?"ok.":"\afailed!"),"\n");
//////};

return T;
