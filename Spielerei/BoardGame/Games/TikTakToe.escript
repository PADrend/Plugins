/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012 Claudius Jähn <claudius@uni-paderborn.de>
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

var tikTakToe = new Game.BoardGame();

// add additional data members
tikTakToe.activePlayerId := void; //!< store the id of the active player
tikTakToe.spareField := void; //!< store the field where new stones appear

// register models
tikTakToe.registerModel( "plate",tikTakToe.createBox(0.9,0.1,0.9) );
tikTakToe.registerModel( "cube",tikTakToe.createBox(0.5,0.5,0.5) );
tikTakToe.registerModel( "button",tikTakToe.createBox(0.1,0.1,0.1) );

//! test for the winning conditions
tikTakToe.testWin := fn(){
	var winSituations = [ 
		[ [0,0],[1,0],[2,0] ], [ [0,1],[1,1],[2,1] ], [ [0,2],[1,2],[2,2] ],
		[ [0,0],[0,1],[0,2] ], [ [1,0],[1,1],[1,2] ], [ [2,0],[2,1],[2,2] ], 
		[ [0,0],[1,1],[2,2] ], [ [2,0],[1,1],[0,2] ]  ];
	foreach(winSituations as var situation){
		var winningPlayer;
		foreach(situation as var positions){
			var stone = getField(positions[0],positions[1]).getStone();
			if(!stone) {// field is empty
				winningPlayer = void;
				break;
			}else if(!winningPlayer){ // first position to test
				winningPlayer = stone.playerId;
			}else if(winningPlayer != stone.playerId){ // different
				winningPlayer = void;
				break;
			}
		}
		if(winningPlayer){
			message("Player ",winningPlayer," has won the match!");
			return;
		}
	}
	// check for draw
	foreach(getFields() as var field){
		if(field.empty()) // still one field empty
			return;
	}
	message("Draw!");
};

//! Create a new stone on the spare field
tikTakToe.createNewStone := fn(){
	var stone = createStone(spareField);
	stone.addModel("cube");
	
	if(activePlayerId==0){
		stone.playerId := 0;
		stone.setColor(1,0,0);
		activePlayerId = 1;
	}else{
		stone.playerId := 1;
		stone.setColor(0,1,0);
		activePlayerId = 0;
	}
};

/*! ---|> BoardGame
	Called then the game is started. */
tikTakToe.onStart = fn(){
	
	// remove all fields
	clear();

	// set active player 0
	activePlayerId = 0;
	
	// Create the spare field that contains the new stones
	spareField = createField(-1,-1);
	spareField.addModel("plate");
	spareField.setColor(0.5,0.5,0.5);

	/*! ---|> Stone
		Called whenever the field's stone changes... */
	spareField.onStoneChanged = fn(newStone){
		if(empty()) // if now empty -> create a new stone
			getGame().createNewStone();
	};
	

	// create a reset button field
	var resetField = createField(3,-1);
	resetField.addModel("button");
	resetField.setColor(0.1,0.1,0.5);
	
	//! ---|> GameObject
	resetField.onClick = fn(){
		getGame().start();
	};
	
	// create fields
	for(var x=0;x<3;++x){
		for(var y=0;y<3;++y){
			var field = createField(x,y);
			field.addModel("plate");
			field.setColor(1.2,1.2,1.2);
			
			//! ---|> GameObject
			field.onClick = fn(){
				if(empty()){
					var stone = getGame().spareField.getStone();
					if(stone){
						stone.moveToField(this);
					}
					getGame().testWin();
				}
			};
		}
	}
	createNewStone();
};


tikTakToe.start();
out("\n","-"*70,"\n");



