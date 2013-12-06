/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2012 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
GLOBALS.TicTacToe := new Plugin({
			Plugin.NAME	: 'Spielerei/TicTacToe',
			Plugin.VERSION : 0.1,
			Plugin.DESCRIPTION : "Tac Tac Toe\nAn incomplete implementation as a first task for escript newbies",
			Plugin.AUTHORS : "Ralf",
			Plugin.OWNER : "All",
			Plugin.REQUIRES : ['PADrend/GUI','PADrend/Serialization','PADrend/CommandHandling']
});

//! ---|> Plugin
TicTacToe.init:=fn(){

     { // Register ExtensionPointHandler:
     	registerExtension('PADrend_Init',this->fn(){
			gui.registerComponentProvider('Spielerei.ticTacToe',{
				GUI.LABEL:"Tic Tac Toe",
				GUI.ON_CLICK:fn() {
					if(!TicTacToe.window)
						TicTacToe.startGame();
					else
						TicTacToe.window.setEnabled(true);
				},
				GUI.TOOLTIP : "An incomplete implementation as a first task for escript newbies"
			});
		});
    }

    return true;
};

TicTacToe.buttonSize := 100;

TicTacToe.getCircleIcon := fn(Bool winning = false){
	if(winning)
		return gui.create({
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.FLAGS : GUI.AUTO_MAXIMIZE,
			GUI.ICON : __DIR__ + "/resources/gold_letter_O.png"
		});
	else
		return gui.create({
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.FLAGS : GUI.AUTO_MAXIMIZE,
			GUI.ICON : __DIR__ + "/resources/gray_letter_O.png"
		});
};
TicTacToe.getCrossIcon :=fn(Bool winning = false){
	if(winning)
		return gui.create({
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.FLAGS : GUI.AUTO_MAXIMIZE,
			GUI.ICON : __DIR__ + "/resources/gold_letter_X.png"
		});
	else
		return gui.create({
			GUI.TYPE : GUI.TYPE_ICON,
			GUI.FLAGS : GUI.AUTO_MAXIMIZE,
			GUI.ICON : __DIR__ + "/resources/gray_letter_X.png"
		});
};

TicTacToe.window := void;
TicTacToe.panel := void;

TicTacToe.startGame := fn(){
	window = gui.create({
		GUI.TYPE : GUI.TYPE_WINDOW,
		GUI.LABEL : "Tic Tac Toe",
		GUI.WIDTH : 500,
		GUI.HEIGHT : 500,
		GUI.POSITION : [100,100]
	});
	panel = gui.create({
		GUI.TYPE : GUI.TYPE_CONTAINER,
		GUI.FLAGS : GUI.AUTO_MAXIMIZE
	});
	window += panel;

	for(var i=0;i<3;++i){
		for(var j=0;j<3;++j){
			var button = gui.create({
				GUI.TYPE : GUI.TYPE_BUTTON,
				GUI.SIZE : [GUI.WIDTH_REL|GUI.HEIGHT_REL , 0.33 ,0.33 ],
				GUI.POSITION : [GUI.POS_X_REL|GUI.REFERENCE_X_LEFT|GUI.ALIGN_X_LEFT|GUI.POS_Y_REL|GUI.REFERENCE_Y_TOP|GUI.ALIGN_Y_TOP, i*0.33,j*0.33],
				GUI.LABEL : "",
				GUI.ON_CLICK : (fn(Number x, Number y){ var f = TicTacToe.getField(x,y); f->f.onClick();}).bindLastParams(i,j)
			});
			fields[i][j] = new Field(i,j,button);
			panel += button;
		}
	}
};

TicTacToe.fields := [[void, void, void],[void, void, void],[void, void, void]];

TicTacToe.Field := new Type();
TicTacToe.Field.button := void;
TicTacToe.Field.content := void;

TicTacToe.Field.xPos := void;
TicTacToe.Field.yPos := void;
TicTacToe.Field.winning := void;

TicTacToe.Field._constructor ::= fn(Number x, Number y, GUI.Button b){
	xPos = x;
	yPos = y;
	winning = false;
	button = b;
	setContent(TicTacToe.EMPTY);
};

/*!
 * Alles BIS HIER bitte nicht direkt benutzen
 */

TicTacToe.Field.setContent ::= fn([TicTacToe.CROSS, TicTacToe.CIRCLE, TicTacToe.EMPTY] c){
	button.clear();
	content = c;
	if(content == TicTacToe.CROSS)
		button.add(TicTacToe.getCrossIcon(winning));
	else if(content == TicTacToe.CIRCLE)
		button.add(TicTacToe.getCircleIcon(winning));
};
TicTacToe.Field.setWinning := fn(Bool b){
	winning = b;
	setContent(getContent());
};
TicTacToe.Field.isWinning ::= fn(){
	return winning;
};
TicTacToe.Field.getContent ::= fn(){ return content; };

TicTacToe.Field.getXPos ::= fn(){ return xPos; };
TicTacToe.Field.getYPos ::= fn(){ return yPos; };

TicTacToe.getField := fn([0,1,2] x, [0,1,2] y){
	return fields [x][y];
};

TicTacToe.EMPTY := 0;
TicTacToe.CROSS := 1;
TicTacToe.CIRCLE := 2;

/*!
 * BIS HIER hin den code bitte unverändert lassen
 */

TicTacToe.activePlayer := TicTacToe.CROSS;

TicTacToe.clear := fn(){
	for(var i=0;i<=2;++i)
		for(var j=0;j<=2;j++){
			getField(i,j).setWinning(false);
			getField(i,j).setContent(EMPTY);
		}
};

TicTacToe.checkGameEnding := fn(TicTacToe.Field f){
	var result = false;

	var p = f.getContent();

	if(getField(0,f.getYPos()).getContent() == p && getField(1,f.getYPos()).getContent() == p && getField(2,f.getYPos()).getContent() == p){
		getField(0,f.getYPos()).setWinning(true);
		getField(1,f.getYPos()).setWinning(true);
		getField(2,f.getYPos()).setWinning(true);
		result = true;
	}
	if(getField(f.getXPos(),0).getContent() == p && getField(f.getXPos(),1).getContent() == p && getField(f.getXPos(),2).getContent() == p){
		getField(f.getXPos(),0).setWinning(true);
		getField(f.getXPos(),1).setWinning(true);
		getField(f.getXPos(),2).setWinning(true);
		result = true;
	}
	if(f.getXPos() == f.getYPos() && getField(0,0).getContent() == p && getField(1,1).getContent() == p && getField(2,2).getContent() == p){
		getField(0,0).setWinning(true);
		getField(1,1).setWinning(true);
		getField(2,2).setWinning(true);
		result = true;
	}
	if(f.getXPos() + f.getYPos() == 2 && getField(2,0).getContent() == p && getField(1,1).getContent() == p && getField(0,2).getContent() == p){
		getField(2,0).setWinning(true);
		getField(1,1).setWinning(true);
		getField(0,2).setWinning(true);
		result = true;
	}

	if(!result)
		for(var i=0;i<=2;++i)
			for(var j=0;j<=2;++j)
				if(getField(i,j).getContent()==EMPTY)
					return false;
		
	return true;
};

TicTacToe.Field.onClick ::= fn(){
	if(TicTacToe.activePlayer == TicTacToe.EMPTY){
		TicTacToe.clear();
		TicTacToe.activePlayer = TicTacToe.CROSS;
	}
	else if(getContent() == TicTacToe.EMPTY){
		setContent(TicTacToe.activePlayer);
		if(TicTacToe.checkGameEnding(this)){
			TicTacToe.activePlayer = TicTacToe.EMPTY;
		}
		else{
			TicTacToe.activePlayer ^= 3;
		}
	}
	else
		outln("not allowed");
};



/*!
 * AB HIER den code bitte unverändert lassen
 */

return TicTacToe;
