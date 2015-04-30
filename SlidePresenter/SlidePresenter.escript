/*
 * This file is part of the proprietary part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2014 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * For the proprietary part of PADrend all rights are reserved.
 */

var T = new Type;

T.folder @(init,private) := DataWrapper;
T.window @(private) := void;
T.files @(private) := void;
T.activeImage @(private) := void;
T.configId @(private) := void;
T.windowRect @(private) := void;
T.fullscreen @(private) := void;
T.stretch @(private) := void;

T.slideNr @(private,init) := DataWrapper;

static FADE_TIME = 0.2;

static fadeIn = fn( icon ){
	PADrend.planTask(0, [icon] => fn(icon){
		var start = clock();
		var prop;
		while(!icon.isDestroyed()){
			var t = clock()-start;
			if(prop)
				icon.removeProperty( prop);

			if(t>FADE_TIME || icon.isSet($__fadingOut))
				break;
			prop = new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR,new Util.Color4f( 1,1,1, t/FADE_TIME));
			icon.addProperty(prop);
			yield 0;
		}
	});
};
static fadeOut = fn( icon ){
	PADrend.planTask(0, [icon] => fn(icon){
		var start = clock();
		while(clock()-start < FADE_TIME)
			yield 0;
		
		start = clock();
		var prop;
		icon.__fadingOut := true;
		while(!icon.isDestroyed()){
			var t = clock()-start;
			if(prop)
				icon.removeProperty( prop);

			if(t>FADE_TIME)
				break;
			prop = new GUI.ColorProperty(GUI.PROPERTY_ICON_COLOR,new Util.Color4f( 1,1,1,1.0-t/FADE_TIME));
			icon.addProperty(prop);
			yield 0;
		}
		icon.destroy();
	});
};

T._constructor ::= fn(DataWrapper windowRect, DataWrapper folder, DataWrapper fullscreen,DataWrapper stretch){
	this.windowRect = windowRect;
	this.slideNr(1);
	this.folder = folder;
	this.folder.onDataChanged += this -> fn(p){ this.files = void; this.slideNr(0); };
	this.fullscreen = fullscreen;
	this.fullscreen.onDataChanged += this -> fn(...){	this.close();	};
	this.stretch = stretch;
	
	this.slideNr.onDataChanged += this -> fn(Number slideNr){
		// init files and window
		this.init();
		
		// correct slide nr
		var nr2 = slideNr.clamp(1,this.files.count());
		if(!this.files.empty()&& nr2!=slideNr){
			this.slideNr(nr2);
			return;
		}

		// show slide
		var f = this.files[slideNr-1];
		if(f){
			this.window.setTitle( "("+slideNr+"/"+this.files.count()+")" );
			PADrend.message( "("+slideNr+"/"+this.files.count()+")" );
			if(this.activeImage){
				fadeOut(this.activeImage);
//					this.activeImage.destroy();
				this.activeImage = void;
			}else this.window.destroyContents();
			
			if(f.endsWith('.eSlide')){
				try{
					var entries = load( (new Util.FileName(f)).getPath());
					foreach(entries as var e)
						this.window += e;
				}catch(e){
					Runtime.warn("SlidePresenter: Error loading eSlide '"+f+"'\n"+e);
				}
			}else{
				var img = gui.loadImage(f);
				if(img){
					var iw = img.getWidth();	
					var ih = img.getHeight();
					var scale = [ (this.window.getHeight()/ih).clamp(0,1), (this.window.getWidth()/iw).clamp(0,1)].min();
					
					var c = gui.create(
						this.stretch() ? 

							{
								GUI.TYPE : GUI.TYPE_ICON,
								GUI.ICON : gui.createIcon( img.getImageData(), new Geometry.Rect(0,0,iw,ih) ),
								GUI.POSITION : [-2,-2],
								GUI.SIZE : [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS,-2,-2],
								GUI.TOOLTIP : f
							}
						:
							{
								GUI.TYPE : GUI.TYPE_ICON,
								GUI.ICON : gui.createIcon( img.getImageData(), new Geometry.Rect(0,0,iw,ih) ),
								GUI.POSITION : [GUI.POS_X_ABS|GUI.REFERENCE_X_CENTER|GUI.ALIGN_X_CENTER|
									GUI.POS_Y_ABS|GUI.REFERENCE_Y_CENTER|GUI.ALIGN_Y_CENTER, 0,0],
								GUI.SIZE : [iw*scale,ih*scale],
								GUI.TOOLTIP : f
			//						GUI.ICON_COLOR : new Util.Color4f(1,1,0,0.1)
							}
					);
					
					this.activeImage = c;
					fadeIn(c);
					
					this.window += c;
				}
			}
			
		}else{
			PADrend.message("No slide #"+slideNr);
		}
		
	};
};
T.close ::= fn(){
	if(this.window){
		this.activeImage && this.activeImage.destroy();
		this.activeImage = void;
		this.window.destroy();
		this.window = void;
		gui.closeAllMenus();
	}
};
T.getSlideNrWrapper ::= fn(){	return this.slideNr;	};
T.getSlideCount ::= fn(){
	this.init();
	return this.files.count();
};
T.goTo ::= fn(Number n){
	this.init();
	this.slideNr( n<=this.files.count() ? n : this.files.count() );
};
T.goToPrev ::= fn(){
	this.init();
	this.slideNr( this.slideNr()>1 ? this.slideNr()-1 : 1);
};

T.goToNext ::= fn(){
	this.init();
	this.slideNr( this.slideNr()<this.files.count() ? this.slideNr()+1 : this.files.count());
};
T.isOpen ::= fn(){
	return this.window && !this.window.isDestroyed();
};

T.show ::= fn(){
	this.slideNr.forceRefresh();
};

T.slideAction ::= fn(){
	this.init();
	var f = this.files[this.slideNr()-1];
	if(f){
		var scriptFile = (new Util.FileName(f)).getPath() + ".escript";
		if(IO.isFile(scriptFile)){
			outln("Loading '",scriptFile,"'...");
			load( scriptFile );
		}else{
			outln("No slide action found: '",scriptFile,"'.");
		}
	}
};

T.init ::= fn(){
	if(!this.window || this.window.isDestroyed()){
		this.window = gui.create({
			GUI.TYPE : GUI.TYPE_WINDOW,
			GUI.FLAGS : GUI.ONE_TIME_WINDOW | GUI.HIDDEN_WINDOW,
			GUI.LABEL : "Slides",
			GUI.SIZE : this.fullscreen() ? [GUI.WIDTH_FILL_ABS|GUI.HEIGHT_FILL_ABS,0,0] : [320,200],
			GUI.POSITION : this.fullscreen() ? [0,-15] : [100,100],
			GUI.CONTEXT_MENU_PROVIDER : [this,this.slideNr,this.folder,this.fullscreen,this.stretch] => fn(slidePresenter,slideNr,folder,fullscreen,stretch){
				return [
					{
						GUI.TYPE : GUI.TYPE_CONTAINER,
						GUI.LAYOUT : GUI.LAYOUT_FLOW,
						GUI.CONTENTS : [
							{
								GUI.TYPE : GUI.TYPE_BUTTON,
								GUI.ICON : "#LeftSmall",
								GUI.WIDTH : 15,
								GUI.ON_CLICK : [1] => slidePresenter->slidePresenter.goTo,
								GUI.TOOLTIP : "Go to first slide."
							},
							{
								GUI.TYPE : GUI.TYPE_BUTTON,
								GUI.ICON : "#LeftSmall",
								GUI.WIDTH : 15,
								GUI.ON_CLICK : slidePresenter->slidePresenter.goToPrev,
								GUI.TOOLTIP : "Go to previous slide."
							},
							{
								GUI.TYPE : GUI.TYPE_NUMBER,
								GUI.DATA_WRAPPER : slideNr,
								GUI.WIDTH : 80,
								GUI.TOOLTIP : "Current slide nr."
							},
							{
								GUI.TYPE : GUI.TYPE_BUTTON,
								GUI.ICON : "#RightSmall",
								GUI.WIDTH : 15,
								GUI.ON_CLICK : slidePresenter->slidePresenter.goToNext,
								GUI.TOOLTIP : "Go to next slide."
							},
							{
								GUI.TYPE : GUI.TYPE_BUTTON,
								GUI.ICON : "#DestroySmall",
								GUI.WIDTH : 15,
								GUI.ON_CLICK : slidePresenter->slidePresenter.close,
								GUI.TOOLTIP : "Close"
							},

						]
					},
					'----',
					{
						GUI.TYPE : GUI.TYPE_TEXT,
						GUI.DATA_WRAPPER : folder,
						GUI.TOOLTIP : "The slides' location (.png-files)."
					},
					{
						GUI.TYPE : GUI.TYPE_BOOL,
						GUI.LABEL : "Fullscreen",
						GUI.DATA_WRAPPER : fullscreen,
					},
					{
						GUI.TYPE : GUI.TYPE_BOOL,
						GUI.LABEL : "Stretch",
						GUI.DATA_WRAPPER : stretch,
					},
					'----',
				];
			}
		});
		if(!this.fullscreen()){
			//! \see GUI.StorableRectTrait
			Std.Traits.addTrait(this.window, Std.module('LibGUIExt/Traits/StorableRectTrait'), this.windowRect);
		}
	}
	if(!this.files){
		
		this.files = Util.getFilesInDir( this.folder(),[".png",".jpg",".JPG",".PNG",".eSlide"], true ); // scan recursively
	}

};

return T;
// ------------------------------------------------------------------------------
