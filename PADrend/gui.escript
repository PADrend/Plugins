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

/*! Module used to register gui components:
	\code
		Std.require.on('PADrend/gui',fn(gui){
			gui.register('ComponentId.id2',["foo","bar"]);
		});
		// OR
		module.on('PADrend/gui'fn(gui){
			gui.register('ComponentId.id2',["foo","bar"]);
		});
	\endcode
	
	\note Do only require this module is it is assured that the gui has been initialized.
*/

if(!__injectedGUIObject)
	Runtime.exception("PADrend/gui: Module required before gui has been created!");

return __injectedGUIObject;
