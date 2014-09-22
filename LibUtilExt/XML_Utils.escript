/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2012 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
// static N = new Namespace;
 
static XML_Utils = new Namespace;

XML_Utils.XML_NAME := $name;
XML_Utils.XML_ATTRIBUTES := $attributes;
XML_Utils.XML_CHILDREN := $children;
XML_Utils.XML_DATA := $data;

/*! Convert a map consisting of the constants defined above into a XML formatted string. */
XML_Utils.generateXML := fn(Map root, String header = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"){
	var worker = new ExtObject({
		$tagToString : fn(Map m,level){
			var s = "\t"*level;
			
			var name = m[XML_Utils.XML_NAME];
			if(name){
				s+="<"+name+attributesToString(m);
				var children = m[XML_Utils.XML_CHILDREN];
				var data = m[XML_Utils.XML_DATA];
				if( (children && !children.empty()) || data){
					s+=">\n";
					if(data)
						s+="\t"*(level+1)+data+"\n";
					if(children){
						foreach(children as var c){
							s+=tagToString(c,level+1);
						}
					}
					s+="\t"*level+"</"+name+">\n";
				}else{
					s+="/>\n";
				}
			}else{ // root node
				var children = m[XML_Utils.XML_CHILDREN];
				if(children && !children.empty()){
					foreach(children as var c)
						s+=tagToString(c,level);
				}
			}
			return s;
		},
		$attributesToString : fn(Map m){
			var s="";
			var attributes = m[XML_Utils.XML_ATTRIBUTES];
			if(attributes){
				foreach(attributes as var key,var value){
					s+=" "+key+"=\""+value.replaceAll({'"':'&quot;'})+"\"";
				}
			}
			return s;
		}
	});

	return header+worker.tagToString(root,0);
};

/*! Load and parse a XML-file and return its content as a map using the constants defined above.
	\note This is probably not very efficient; consider this when parsing large files. 
	\note The <?...?> tags are ignored!
	\example
		<?xml version="1.0"?>
		<scene>
			<attribute name="tags" type="json" >  foo  </attribute>
			<attribute name="thing" value="bar" />
		</scene>

	---->

		{
			XML_Utils.XML_NAME : "scene",
			XML_Utils.XML_ATTRIBUTES : new Map,
			XML_Utils.XML_CHILDREN : [{
				XML_Utils.XML_NAME : "attribute",
				XML_Utils.XML_ATTRIBUTES : {	"name" : "tags", "type" : "json" },
				XML_Utils.XML_DATA : "foo"
			},{
				XML_Utils.XML_NAME : "attribute",
				XML_Utils.XML_ATTRIBUTES : {	"name" : "thing", "value" : "bar" }
			}]
		}

	*/
XML_Utils.loadXML := fn(filename){
	var root = {
		XML_Utils.XML_CHILDREN : []
	};
	var context = new ExtObject({
		$openTags : [root]
	});
	
	var reader = new Util.MicroXMLReader;
	
	//! ---|> MicroXMLReader
	reader.data @(override) := context->fn(tag,data){
		if(!data.empty())
			openTags.back()[XML_Utils.XML_DATA] = data;
		return true;
	};
	//! ---|> MicroXMLReader
	reader.enter @(override) := context->fn(tag){
		var m = {
			XML_Utils.XML_NAME : tag.name,
			XML_Utils.XML_ATTRIBUTES : tag.attributes
		};

		var current = openTags.back();
		if(!current[XML_Utils.XML_CHILDREN]){
			current[XML_Utils.XML_CHILDREN] = [];
		}
		current[XML_Utils.XML_CHILDREN] += m;

		openTags.pushBack(m);
		return true;		
	};
	//! ---|> MicroXMLReader	
	reader.leave @(override) := context->fn(tag){
		openTags.popBack();
		return true;		
	};	

	var success = reader.parse( filename );
	if(!success)
		throw new Exception("Could not parse xml file '"+filename+"'");
	if(root[XML_Utils.XML_CHILDREN].count()!=1)
		throw new Exception("Invalid number of root tags:"+root[XML_Utils.XML_CHILDREN].count()+" (should be 1)");
	return root[XML_Utils.XML_CHILDREN][0];
};

//! Save a XML file.
XML_Utils.saveXML := fn(filename,Map root){
	if(!Util.saveFile(filename,XML_Utils.generateXML(root)))
		throw new Exception("Could not save xml file '"+filename+"'");
};

Util.loadXML := XML_Utils.loadXML;
Util.generateXML := XML_Utils.generateXML;
Util.saveXML := XML_Utils.saveXML;

return XML_Utils;
