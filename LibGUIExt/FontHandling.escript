/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011-2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2011-2013 Claudius JÃ¤hn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[PADrend] LibGUIExt/FontHandling.escript
 **/


GUI.FONT_ID_SYSTEM := $FONT_ID_SYSTEM;
GUI.FONT_ID_DEFAULT := $FONT_ID_DEFAULT;
GUI.FONT_ID_HEADING := $FONT_ID_HEADING;
GUI.FONT_ID_LARGE := $FONT_ID_LARGE;
GUI.FONT_ID_XLARGE := $FONT_ID_XLARGE;
GUI.FONT_ID_HUGE := $FONT_ID_HUGE;
GUI.FONT_ID_TOOLTIP := $FONT_ID_TOOLTIP;
GUI.FONT_ID_WINDOW_TITLE := $FONT_ID_WINDOW_TITLE;


//! (internal) Apply the entries of the font registry as global font where necessary.
GUI.GUI_Manager._applyDefaultFonts ::= fn(){
	var registry = getFontRegistry();
	if(registry[GUI.FONT_ID_DEFAULT])
		this.setDefaultFont(GUI.PROPERTY_DEFAULT_FONT, registry[GUI.FONT_ID_DEFAULT] );
	if(registry[GUI.FONT_ID_TOOLTIP])
		this.setDefaultFont(GUI.PROPERTY_TOOLTIP_FONT, registry[GUI.FONT_ID_TOOLTIP] );	
	if(registry[GUI.FONT_ID_WINDOW_TITLE])
		this.setDefaultFont(GUI.PROPERTY_WINDOW_TITLE_FONT, registry[GUI.FONT_ID_WINDOW_TITLE] );
};

/*!	Creates a GUI.BitmapFont from a (specialized) image file.
	@note image files can be created with "EnOrmous Bitmap Font Creator" and Gimp (for adding alpha channel).
	@see http://sourceforge.net/projects/bitmapfont/	*/
GUI.GUI_Manager.createBitmapFont ::= fn(filename,
									chars = " !\"#$%&'()*+,-./0123456789:;<=>?@ ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"){ // '
    var image=gui.loadImage(filename);
    if(!image) return false;

    var fontHeight=image.getHeight()-2;
    var font=new GUI.BitmapFont(image,fontHeight);
    var reader = image.createPixelAccessor();

    var imageW=image.getWidth();
    var imageX=0;
    for(var i=0;i<chars.length();i++){
		while(reader.readColor4f(imageX, 0).a() < 0.999) {
			imageX++;

			if(imageX >= imageW) {
				Runtime.warn("The image file for the bitmap font creation has an invalid format.");
				return false;
			}
		}
        var startX=imageX;
		while(reader.readColor4f(imageX, 0).a() >= 0.999) {
			imageX++;
			
			if(imageX >= imageW) {
				Runtime.warn("The image file for the bitmap font creation has an invalid format.");
				return false;
			}
		}
        var endX = imageX;
        font.addGlyph( ord(chars[i]),
					endX-startX, fontHeight, 		// dimensions
					new Geometry.Vec2(startX,1),	// texture offset
					new Geometry.Vec2(0,0), 		// screen offset
					endX-startX);					// xAdvance
    }
//    out("Created font: ",filename,"\n");
    return font;
};

/*! Load a font created with "Bitmap Font Generator v1.12a by Andreas Jönsson (www.AngelCode.com)"
	\note Only fonts with one page (image file) are supported.
	\note Export options: BitDepth '32bit', Preset 'White Text with alpha', FileFormat 'XML', Textures 'png'
	\note Recommended font options: Match char height 'enabled', font smoothing 'enabled', supersampling 'disabled', charset 'utf8'
	\note if a xml-parser warning '</font>' occurs, the broken 'kernings' tag has to be removed by hand. */
GUI.GUI_Manager.createBitmapFontFromFNT ::= fn(filename){
	static XML_Utils = Std.require('LibUtilExt/XML_Utils');
	
	var font;
	var lineHeight = 10;
	var fontInfo = XML_Utils.loadXML(filename);
	foreach(fontInfo[XML_Utils.XML_CHILDREN] as var m){
		var type = m[XML_Utils.XML_NAME];
		if(type=='info'){
//			out("face:\t",m[XML_Utils.XML_ATTRIBUTES]['face'],"\n");
		}else if(type=='common'){
			lineHeight = m[XML_Utils.XML_ATTRIBUTES]['lineHeight'];
		}else if(type=='pages'){
			if(m[XML_Utils.XML_CHILDREN].count()!=1){
				throw new Exception("Only fonts with one page are currently supported.");
			}
			var bitmapFile = m[XML_Utils.XML_CHILDREN][0][XML_Utils.XML_ATTRIBUTES]['file'];
			
			// add path extracted from filename
			bitmapFile = filename.substr(0,filename.rFind("/")+1)+bitmapFile;
			
			var image=gui.loadImage(bitmapFile);
			if(!image)
				throw new Exception("Could not load font bitmap '"+bitmapFile+"'");
			font = new GUI.BitmapFont(image,lineHeight);
		}else if(type=='chars'){
			if(!font)
				throw new Exception("No bitmap info found in '"+filename+"'");
			foreach(m[XML_Utils.XML_CHILDREN] as var charInfo){
				if(!charInfo[XML_Utils.XML_NAME]=='char')
					continue;
				var attr = charInfo[XML_Utils.XML_ATTRIBUTES];
				var unicode = 0+attr['id'];
				font.addGlyph( unicode, 
					attr['width'],attr['height'],
					new Geometry.Vec2( attr['x'],attr['y']  ), // texture offset
					new Geometry.Vec2( attr['xoffset'],attr['yoffset'] ), // screen offset
					attr['xadvance']);  //xAdvance					
			}
			
		}
//		out(" ##### ",type,"\n");
	}
	return font;
};

/*! Get a Font by its registered name or by its filename (or, if a font is given as parameter, simply return it).
	If a filename is given, the font is loaded and registerd with its filename as name, so that each font file is loaded only once.
	\example gui.getFont( GUI.FONT_ID_DEFAULT );
	\example gui.getFont( "./resources/Fonts/DejaVu_Sans_10.fnt" );	*/
GUI.GUI_Manager.getFont ::= fn([String,Identifier,GUI.AbstractFont] nameOrFilename){
	if(nameOrFilename---|>GUI.AbstractFont) // already a font given? return it.
		return nameOrFilename;
	var font = getFontRegistry()[nameOrFilename];
	if(font)
		return font;
	if(nameOrFilename.toString().endsWith(".png")){
		try{
			font = createBitmapFont(nameOrFilename);
		}catch(e){
			Runtime.warn(e);
		}
	}else if(nameOrFilename.toString().endsWith(".fnt")){
		try{
			font = createBitmapFontFromFNT(nameOrFilename);
		}catch(e){
			Runtime.warn(e);
		}
	}
	if(font){
		registerFont(nameOrFilename,font);
		return font;
	}else{
		Runtime.warn("Font not found '"+nameOrFilename+"'");
		return void;
	}
};

//! (internal)
GUI.GUI_Manager.getFontRegistry ::= fn(){
	if(!isSet($_fontRegistry))
		this._fontRegistry := new Map();
	return _fontRegistry;
};

//! (internal) Called once by GUI.init()
GUI.GUI_Manager.initDefaultFonts ::= fn(){
	this.registerFonts( {
			GUI.FONT_ID_SYSTEM : getDefaultFont(GUI.PROPERTY_DEFAULT_FONT), // backup for the default system-font
			GUI.FONT_ID_DEFAULT : getDefaultFont(GUI.PROPERTY_DEFAULT_FONT),
			GUI.FONT_ID_HEADING : getDefaultFont(GUI.PROPERTY_WINDOW_TITLE_FONT),
			GUI.FONT_ID_TOOLTIP :  getDefaultFont(GUI.PROPERTY_TOOLTIP_FONT), 
			GUI.FONT_ID_LARGE : getDefaultFont(GUI.PROPERTY_WINDOW_TITLE_FONT),
			GUI.FONT_ID_HUGE : getDefaultFont(GUI.PROPERTY_WINDOW_TITLE_FONT),
			GUI.FONT_ID_XLARGE : getDefaultFont(GUI.PROPERTY_WINDOW_TITLE_FONT),
			GUI.FONT_ID_WINDOW_TITLE : getDefaultFont(GUI.PROPERTY_WINDOW_TITLE_FONT),
	});
};

/*! Register a font by the given name at the font registry.
	\note The font may be given by name, filename or as font object (\see getFont(...) 
	\note (inernal) If a default font is changed (e.g. PROPERTY_DEFAULT_FONT) it is automatically applied as property.
	\attention Fonts should only be changed *BEFORE* they are used for the first time! Otherwise, the behavior is undefined.	*/
GUI.GUI_Manager.registerFont ::= fn( [String,Identifier] name, idOrFileOrFont){
	var f = getFont(idOrFileOrFont);
	if(f){
		getFontRegistry()[name] = getFont(f);
		_applyDefaultFonts();	
	}
};

/*! Register a map of fonts by the given names (keys of the map) at the font registry.
	\note The fonts may be given by name, filename or as font object (\see getFont(...) */
GUI.GUI_Manager.registerFonts ::= fn( Map fonts){
	foreach(fonts as var name,var idOrFileOrFont){
		var f = getFont(idOrFileOrFont);
		if(f)
			getFontRegistry()[name] = getFont(f);
	}
		
	_applyDefaultFonts();
};

