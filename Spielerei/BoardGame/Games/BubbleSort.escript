/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2012-2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
// ---------------------------------------------------------------------------------------------
load(__DIR__+"/../BoardGame.escript");
out("\n","-"*70,"\n");

var bubbleSort = new Game.BoardGame();

// add additional data members
bubbleSort.values := void; //! store an array of values
bubbleSort.magicField := void; //! invisible field used to temporarily store stones

// register models
bubbleSort.registerModel( "plate",bubbleSort.createBox(0.9,0.1,0.9) );
bubbleSort.registerModel( "cube",bubbleSort.createBox(0.5,0.5,0.5) );

//! check if stones are sorted.
bubbleSort.checkSorting := fn(){
	var max=false;
	for(var x=0;x<values.count();++x){
		var value = getField(x,0).getStone().value;
		if(max && value<max )
			return;
		max = value;
	}
	PADrend.message("Sorted :-) ");
};

/*! ---|> BoardGame
	Called then the game is started. */
bubbleSort.onStart = fn(){
	clear();

	values = [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0];
	
	// permutate
	for(var i=0;i<values.count();++i){
		var rand = Rand.equilikely(0,values.count()-1);
		var tmp = values[i];
		values[i] = values[rand];
		values[rand] = tmp;	
	}


	// create fields and stones
	magicField = createField(-1,0);
	foreach(values as var x,var value){
		var field = createField(x,0);
		field.addModel("plate");
		field.setColor(x*0.1,0,1-x*0.1);
		
		var stone = createStone(field);
		stone.addModel("cube");
		stone.value := value;
		stone.setColor(value,0,1-value);
		stone.scale(value*0.5+0.5);
		
		//! ---|> GameObject
		stone.onClick = fn(){
			getGame().initParticleEmitter(this,1);
			if( getGame().getSelectedObject()---|>Game.Stone ){
				var stone2=getGame().getSelectedObject();
				if( stone2==this){
					getGame().selectObject(void);
					return;
				}else if( (stone2.getX()-this.getX()).abs()==1 ){
					var field1 = this.getField();
					var field2 = stone2.getField();
					this.moveToField(getGame().magicField);
					stone2.moveToField(field1);
					this.moveToField(field2);
					getGame().checkSorting();
					return;
				}
			}
			getGame().selectObject(this);
		};
	}
};

bubbleSort.start();


out("\n","-"*70,"\n");




