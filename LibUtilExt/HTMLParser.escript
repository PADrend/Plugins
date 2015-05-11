/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2015 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! Simple parser for html. Tries to interpret 'sloppy' html without warnings.
	- some tags are closed automatically (img,hr,br,meta)
	- all tags and attribute names are converted to lower-case
	
	
	\code
		var HTML = Std.require('LibUtilExt/HTMLParser');
		outln( HTML.parse("<p>text<BR>bla<IMG Src=foo.png></p>") == [
			{
				HTML.TAG_TYPE : HTML.TAG_TYPE_NORMAL_TAG,
				HTML.TAG_NAME : "p",
				HTML.TAG_CHILDREN : [
					"text",
					{
						HTML.TAG_TYPE : HTML.TAG_TYPE_NORMAL_TAG,
						HTML.TAG_NAME : "br",
					},
					"bla",
					{
						HTML.TAG_TYPE : HTML.TAG_TYPE_NORMAL_TAG,
						HTML.TAG_NAME : "img",
						HTML.TAG_ATTRIBUTES : {
							"src" : "foo.png"
						}
					},
				]
			}
		]);
	\endcode
*/

static SELF_CLOSING_TAGS = { 'br':true,'img':true,'hr':true ,"meta":true};
static WHITE_SPACES = { ' ':true,'\t':true,'\n':true };
static INVALID_NAME_CHARS = { ' ':true,'\t':true,'\n':true,'=':true,'>':true,'/':true,'"':true,"'":true,"!":true,"?":true};
static UNESCAPE_RULES ={
		"quot": 34, "amp": 38, "apos": 39, "lt": 60, "gt": 62,
		"nbsp" : 160, "iexcl" : 161, "cent" : 162, "pound" : 163, "curren" : 164, "yen" : 165, "brvbar" : 166, 
		"sect" : 167, "uml" : 168, "copy" : 169, "ordf" : 170, "laquo" : 171, "not" : 172, "shy" : 173, 
		"reg" : 174, "macr" : 175, "deg" : 176, "plusmn" : 177, "sup2" : 178, "sup3" : 179, "acute" : 180, 
		"micro" : 181, "para" : 182, "middot" : 183, "cedil" : 184, "sup1" : 185, "ordm" : 186, "raquo" : 187, 
		"frac14" : 188, "frac12" : 189, "frac34" : 190, "iquest" : 191, "Agrave" : 192, "Aacute" : 193, 
		"Acirc" : 194, "Atilde" : 195, "Auml" : 196, "Aring" : 197, "AElig" : 198, "Ccedil" : 199, "Egrave" : 200, 
		"Eacute" : 201, "Ecirc" : 202, "Euml" : 203, "Igrave" : 204, "Iacute" : 205, "Icirc" : 206, "Iuml" : 207, 
		"ETH" : 208, "Ntilde" : 209, "Ograve" : 210, "Oacute" : 211, "Ocirc" : 212, "Otilde" : 213, "Ouml" : 214, 
		"times" : 215, "Oslash" : 216, "Ugrave" : 217, "Uacute" : 218, "Ucirc" : 219, "Uuml" : 220, "Yacute" : 221, 
		"THORN" : 222, "szlig" : 223, "agrave" : 224, "aacute" : 225, "acirc" : 226, "atilde" : 227, "auml" : 228, 
		"aring" : 229, "aelig" : 230, "ccedil" : 231, "egrave" : 232, "eacute" : 233, "ecirc" : 234, "euml" : 235, 
		"igrave" : 236, "iacute" : 237, "icirc" : 238, "iuml" : 239, "eth" : 240, "ntilde" : 241, "ograve" : 242, 
		"oacute" : 243, "ocirc" : 244, "otilde" : 245, "ouml" : 246, "divide" : 247, "oslash" : 248, "ugrave" : 249, 
		"uacute" : 250, "ucirc" : 251, "uuml" : 252, "yacute" : 253, "thorn" : 254, "yuml" : 255, "OElig" : 338, 
		"oelig" : 339, "Scaron" : 352, "scaron" : 353, "Yuml" : 376, "fnof" : 402, "circ" : 710, "tilde" : 732, 
		"Alpha" : 913, "Beta" : 914, "Gamma" : 915, "Delta" : 916, "Epsilon" : 917, "Zeta" : 918, "Eta" : 919, 
		"Theta" : 920, "Iota" : 921, "Kappa" : 922, "Lambda" : 923, "Mu" : 924, "Nu" : 925, "Xi" : 926, 
		"Omicron" : 927, "Pi" : 928, "Rho" : 929, "Sigma" : 931, "Tau" : 932, "Upsilon" : 933, "Phi" : 934, 
		"Chi" : 935, "Psi" : 936, "Omega" : 937, "alpha" : 945, "beta" : 946, "gamma" : 947, "delta" : 948, 
		"epsilon" : 949, "zeta" : 950, "eta" : 951, "theta" : 952, "iota" : 953, "kappa" : 954, "lambda" : 955, 
		"mu" : 956, "nu" : 957, "xi" : 958, "omicron" : 959, "pi" : 960, "rho" : 961, "sigmaf" : 962, "sigma" : 963, 
		"tau" : 964, "upsilon" : 965, "phi" : 966, "chi" : 967, "psi" : 968, "omega" : 969, "thetasym" : 977, 
		"upsih" : 978, "piv" : 982, "ensp" : 8194, "emsp" : 8195, "thinsp" : 8201, "zwnj" : 8204, "zwj" : 8205, 
		"lrm" : 8206, "rlm" : 8207, "ndash" : 8211, "mdash" : 8212, "lsquo" : 8216, "rsquo" : 8217, "sbquo" : 8218, 
		"ldquo" : 8220, "rdquo" : 8221, "bdquo" : 8222, "dagger" : 8224, "Dagger" : 8225, "bull" : 8226, 
		"hellip" : 8230, "permil" : 8240, "prime" : 8242, "Prime" : 8243, "lsaquo" : 8249, "rsaquo" : 8250, 
		"oline" : 8254, "frasl" : 8260, "euro" : 8364, "image" : 8465, "weierp" : 8472, "real" : 8476, "trade" : 8482, 
		"alefsym" : 8501, "vlarr" : 8592, "uarr" : 8593, "rarr" : 8594, "darr" : 8595, "harr" : 8596, "crarr" : 8629, 
		"lArr" : 8656, "uArr" : 8657, "rArr" : 8658, "dArr" : 8659, "hArr" : 8660, "forall" : 8704, "part" : 8706, 
		"exist" : 8707, "empty" : 8709, "nabla" : 8711, "isin" : 8712,"vnotin" : 8713, "ni" : 8715, "prod" : 8719, 
		"sum" : 8721, "minus" : 8722, "lowast" : 8727, "radic" : 8730, "prop" : 8733, "infin" : 8734, "ang" : 8736, 
		"and" : 8743, "or" : 8744, "cap" : 8745, "cup" : 8746, "int" : 8747, "there4" : 8756, "sim" : 8764, 
		"cong" : 8773, "asymp" : 8776, "ne" : 8800, "equiv" : 8801, "le" : 8804, "ge" : 8805, "sub" : 8834, 
		"sup" : 8835, "nsub" : 8836, "sube" : 8838, "supe" : 8839, "oplus" : 8853, "otimes" : 8855, "perp" : 8869, 
		"sdot" : 8901, "lceil" : 8968, "rceil" : 8969, "lfloor" : 8970, "rfloor" : 8971, "lang" : 9001, "rang" : 9002, 
		"loz" : 9674, "spades" : 9824, "clubs" : 9827, "hearts" : 9829, "diams" : 9830
};

		
static unescape = fn(s){
	if(!s.contains('&'))
		return s;
	var s2 = "";
	var index = 0;
	foreach(s.split('&') as var part){
		var parts2 = part.split(';');
		if(parts2.count()<2)
			s2 += part;
		else {
			var escapedChar = parts2.popFront();
			var escapedCharLC = escapedChar.toLower();;
			if(escapedCharLC.beginsWith('#x')){
				escapedChar = chr(0+ ("0x"+escapedCharLC.substr(2)) );
			}else if(escapedChar.beginsWith('#')){
				escapedChar = chr(0+escapedChar.substr(1));
			}else{
				var c2 = UNESCAPE_RULES[escapedChar];
				if(c2)
					escapedChar = chr(c2);
				else
					escapedChar = "&"+escapedChar+";"; // no valid rule found
			}
			s2+= escapedChar+parts2.implode(";");
		}
	}
	return s2;
};

static readName = fn(s,index){
	var c;
	while((c=s[index])&&WHITE_SPACES[c])
		++index;

	var start = index;

	c = s[index];
	while(c && !INVALID_NAME_CHARS[c]){
		++index;
		c = s[index];
	}
	return [index,s.substr(start,index-start)];
};
static readAttributes = fn(s,index){
	var attr = new Map;
	while(true){
		[index,var key] = readName(s,index);
		if(key.empty())
			break;
		key = key.toLower(); // convert to lower-case
		
//		++index;
		var c;
		while((c=s[index])&&WHITE_SPACES[c])
			++index;
		if(c=='='){
			++index;
			while((c=s[index])&&WHITE_SPACES[c])
				++index;
			[index,attr[key]] = readQuotedString(s,index);
		}else // attribute without value
			attr[key] = "DEFINED";
	}
	return [index,attr];
};
static readQuotedString = fn(s,index){
	var marker = s[index];
	if(marker!='"'&&marker!="'"){ // value is not quoted, e.g.: value=4
		return readName(s,index); 
	}
	++index; // step marker
	var end = index;
	while(true){
		end = s.find(marker,end);
		if(!end){
			end = s.length();
			break;
		}
		if( s[end-1]!="\\" || s[end-2]=="\\") // end marker found (not escaped)
			break;
		++end;
	}
	return [end+1,unescape(s.substr(index,end-index))];
	
};
static HTML = new Namespace;
HTML.TAG_ATTRIBUTES := "attributes";
HTML.TAG_NAME := "name";
HTML.TAG_CHILDREN := "children";
HTML.TAG_TYPE := "type";
HTML.TAG_TYPE_NORMAL_TAG := "tag";
HTML.TAG_TYPE_COMMENT := "comment";
HTML.TAG_TYPE_PREPROCESSING := "preprocessing";
HTML.TAG_TYPE_DOCTYPE := "doctype";
HTML.TAG_TYPE_CDATA := "cdata";
HTML.TAG_DATA := "data";

static createTag = fn(String name,Map attributes){
	var tag = {
		HTML.TAG_TYPE : HTML.TAG_TYPE_NORMAL_TAG,
		HTML.TAG_NAME : name
	};
	if(!attributes.empty())
		tag[HTML.TAG_ATTRIBUTES] = attributes;
	return tag;
};
static createComment = fn(String text){
	return {
		HTML.TAG_TYPE : HTML.TAG_TYPE_COMMENT,
		HTML.TAG_DATA : text
	};
};
static createDoctype = fn(String text){
	return {
		HTML.TAG_TYPE : HTML.TAG_TYPE_DOCTYPE,
		HTML.TAG_DATA : text
	};
};
static createCData = fn(String text){
	return {
		HTML.TAG_TYPE : HTML.TAG_TYPE_CDATA,
		HTML.TAG_DATA : text
	};
};

static createPreprocessingTag = fn(String name,Map attributes){
	var tag = {
		HTML.TAG_TYPE : HTML.TAG_TYPE_PREPROCESSING,
		HTML.TAG_NAME : name
	};
	if(!attributes.empty())
		tag[HTML.TAG_ATTRIBUTES] = attributes;
	return tag;
};
static addChild = fn(Map tag,child){
	var children = tag[HTML.TAG_CHILDREN];
	if(!children)
		tag[HTML.TAG_CHILDREN] = children = [];
	children += child;
};

HTML.parse := fn(String s){
	var root = createTag("DOCUMENT", new Map);
	var openTags = [root];

	var index = 0;
	var s_lc = s.toLower();
	while(index && index<s.length()){
		var c = s[index];
		if(!c){
			break;
		}else if(c!='<'){ // read text
			var end = s.find('<',index+1);
			if(!end)
				end = s.length();
		
			addChild(openTags.back(), unescape(s.substr(index,end-index))); 
			index = end;
		}else if(s_lc.beginsWith("<![cdata[",index)){
			index += 9;
			var end = s.find(']]>',index);
			if(!end)
				end = s.length();
			addChild(openTags.back(), createCData(s.substr(index,end-index)));
			index = end+3;
		}else if(s.beginsWith("<!--",index)){ // read comment
			var end = s.find('-->',index+1);
			if(!end)
				end = s.length();
			addChild(openTags.back(), createComment( s.substr(index+4,end-index-4) ));
			index = end+3;
		}else if(s_lc.beginsWith("<!doctype",index)){ // read doctype
			index += 9;
			var end = s.find('>',index);
			if(!end)
				end = s.length();

			addChild(openTags.back(), createDoctype(s.substr(index,end-index).trim()));
			index = end+1;
		}else if(s.beginsWith("<?",index)){ // read processing instruction <?
			index += 2; // step <?
			[index, var tagName] = readName(s,index);
			[index, var attributes] = readAttributes(s,index);
			addChild(openTags.back(), createPreprocessingTag(tagName,attributes));
			index = s.find('?>',index);
			if(index)
				index+=2;
		}else { //read normal tag
			++index; // step <
			if(s[index]=='/'){ // closing tag
				++index; // step /
				[index, var tagName] = readName(s,index);
				tagName = tagName.toLower();
			
				index = s.find('>',index);
				if(index)
					++index;
				if(SELF_CLOSING_TAGS[tagName]){ // invalid closing tag... ignore
					continue;
				}
				var popCount = 0;
				for(var i=openTags.count()-1; i>0; --i){
					++popCount;
					if( openTags[i][HTML.TAG_NAME] == tagName ){
						break;
					}
				}else{
					popCount = 0;
//					outln("Info: Closed tag that was never opened. '"+tagName+"'",openTags.back()[HTML.TAG_NAME]);
				}

				while(popCount-- >0)
					openTags.popBack();
			}else{
				[index, var tagName] = readName(s,index);
				tagName = tagName.toLower();

				// read attributes
				[index, var attributes] = readAttributes(s,index);
				var tag = createTag(tagName,attributes);
				addChild(openTags.back(), tag);
				
				index = s.find('>',index);
				if(!index || (!SELF_CLOSING_TAGS[tagName] && s[index-1] != '/')){ // no self-closing tag?
					openTags += tag;
					if(tagName=='script'){ // don't escape inside script tag
						var end = s_lc.find('</script>',index);
						if(!end)
							end = s.length();
						addChild(tag, s.substr(index+1,end-index-1));
						index = end-1;
					}
				}

				if(index)
					++index;
			}
		}
	}
	return root[HTML.TAG_CHILDREN] ? root[HTML.TAG_CHILDREN] : [];
};

return HTML;

