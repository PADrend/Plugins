/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2012-2014 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

/*! Binds the component's background color (and optionally border color) to a DataWarpper.
	\param bgColor		A Std.DataWrapper with an Array of four floats representing the background color.
	\param lineColor	(optional)	A Std.DataWrapper with an Array of four floats representing the line color.
	
	Adds no public methods to the component.
	
	\note Internally uses a RectShape. For this to be visibile, the component's GUI.BORDER-flag
		has to be enabled!
*/
var t = new Std.Traits.GenericTrait("GUI.AdjustableBackgroundColorTrait"); 

t.attributes._backgroundProperty @(private) := void;
t.attributes._bgColor @(private) := GUI.NO_COLOR;
t.attributes._lineColor @(private) := GUI.NO_COLOR;
t.attributes._refreshBGColor @(private) := fn(){
	this._backgroundProperty.setShape(this.getGUI()._createRectShape(_bgColor, _lineColor, true));
};

t.onInit += fn(GUI.Component component,Std.DataWrapper bgColor,[Std.DataWrapper,void] lineColor=void){
	component._backgroundProperty := new GUI.ShapeProperty(GUI.PROPERTY_COMPONENT_BACKGROUND_SHAPE,GUI.NULL_SHAPE);
	component.addProperty(component._backgroundProperty);
	
	bgColor.onDataChanged += component->fn(values){
		if(this.isDestroyed())
			return $REMOVE;
		this._bgColor = new Util.Color4f(values);
		this._refreshBGColor();
	};
	bgColor.forceRefresh();
	if(lineColor){
		lineColor.onDataChanged += component->fn(values){
			if(this.isDestroyed())
				return $REMOVE;
			this._lineColor = new Util.Color4f(values);
			this._refreshBGColor();
		};
		lineColor.forceRefresh();
	}
};

return t;
