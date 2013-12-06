/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2013 Lars Bueker
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
// ------------------------------------------------------------------------------------------
load(__DIR__+"/../BoardGame.escript");
out("\n","-"*70,"\n");

var checkers = new Game.BoardGame();

// register models
checkers.registerModel( "plate",checkers.createBox(0.9,0.1,0.9) );
checkers.registerModel( "cube",checkers.createBox(0.5,0.5,0.5) );

/*! ---|> BoardGame
	Called then the game is started. */
checkers.onStart = fn(){
	clear();
	for(var x=0;x<8;++x){
		for(var y=0;y<8;++y){
			var field = createField(x,y);
			field.addModel("plate");
			if( (x+y)%2 == 0){
				field.setColor(1.2,1.2,1.2);
			}else {
				field.setColor(0.2,0.2,0.2);
				//! ---|> GameObject
				field.onClick = fn(){
					if(empty()&&getGame().getSelectedObject()---|>Game.Stone ){
						getGame().getSelectedObject().moveToField(this);
					}
				};
				
				if(y>2 && y<5)
					continue;
				var stone = createStone(field);
				stone.addModel("cube");
				if(y<=3)
					stone.setColor(1.1,1.1,1.1);
				else
					stone.setColor(0.1,0.1,0.1);
				//! ---|> GameObject
				stone.onClick = fn(){
					getGame().selectObject(this);
				};
			}
		}
	}
};

checkers.start();


out("\n","-"*70,"\n");


