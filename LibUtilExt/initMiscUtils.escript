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
 **	[LibUtilExt] Misc_Utils.escript
 **
 **  Various generic! helper functions
 **/

// ----------------
// --- Alias functions (shortcuts)

//! e.g. out( max(1,5,23,4)); -> 23
GLOBALS.max:=fn(params...){
	Runtime.warn("Deprecated GLOBALS.max(...); use [...].max() instead.");
    return params.max();
};

// ----------------
// --- File functions

Util.getFilesInDir := fn(String dir,[Array,String] endings,recursively = false){
    if(! (endings---|>Array))
        endings=[endings];
    var f;
    try{
        f=Util.dir(dir,Util.DIR_FILES | (recursively ? Util.DIR_RECURSIVE : 0));
//		print_r(f);
		if(!f)
			return [];
    }catch(e){
        Runtime.warn(e);
        return [];
    }
	f.filter([endings] => fn(endings, name){
		foreach(endings as var e)
			if(name.endsWith(e)) return true;
		return false;
	});	
    return f;
};

GLOBALS.getFilesInDir :=  Util.getFilesInDir; // deprecated alias

// ----------------
// --- Command line parsing
/**
 * Parses command line parameters.
 * @param args Command line parameter
 * @return map of values
 * @example ["foo=\"1"," + ","1=2\""] -> { [foo] : "1  +  1=2" }
 */
Util.parseArgs := fn(Array args){
    var s=args.implode(" ");
    var outside=true;
    var s2="";
    for(var i=0;i<s.length();i++){
        var c=s.substr(i,1);
        if(outside && c==' ')
            s2+='�1';
        else if(outside && c=='=')
            s2+='�=';
        else if(c=='"')
            outside=!outside;
        else
            s2+=c;
    }
    var m=new Map;
    var a=s2.split('�1');
    foreach(a as var key,var value){
        var v=value.split('�=');
        if(v[0].beginsWith("--"))
            m[v[0].substr(2)]=v[1];
        else if(v.size()>1)
            m[v[0]]=v[1];
        else m[key]=value;
    }
    return m;
};

GLOBALS.parseArgs :=  Util.parseArgs; // deprecated alias

// -----------------------------------------------------------------

/*! open file via call to the operating-system */
Util.openOS:=fn(String path){
	if(path.beginsWith("file://")){
		path=path.substr(7);
	}
	var os=getOS();
	if(os=="WINDOWS"){
		return system("start "+ path.replaceAll({'/':'\\'}));
	} else if(os == "LINUX") {
		return system("if [ -x /usr/bin/xdg-open ]; then /usr/bin/xdg-open '" + path + "'; fi");
	} else if(os == "MAC OS") {
		return system("open " + path);
	}else{
		out("openOS (",__FILE__,":",__LINE__,") is currently not implemented for " + os + ".");
		return void;
	}
};
return true;
