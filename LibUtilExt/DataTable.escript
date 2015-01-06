/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2011 Benjamin Eikel <benjamin@eikel.org>
 * Copyright (C) 2010-2012,2015 Claudius Jähn <claudius@uni-paderborn.de>
 * Copyright (C) 2010 Paul Justus
 * Copyright (C) 2010 Ralf Petring <ralf@petring.net>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	 plugins/Util/DataTable.escript
 **  2010-03-17 - Claudius
 **  2010-03-31 - Paul Justus - besides lexicographical key-sorting(auto), numerical key-sorting is possible now
 **                             \see exportSVG and exportCSV
 **/
/*! Class for storing and exporting experimental data.
	Example:

	// 1. collect some data - each data row in a seperate map
	var m1 = new Map;
	var m2 = new Map;
	var m3 = new Map;
	for(var i = 0;i<5;i+=0.5){
		m1[i] = i;
		m2[i] = i*i;
		m3[i] = i*i*i;
	}
	// 2. create the dataTable with the unit of the x axis
	var dataTable = new DataTable("x");

	// 3. add the data rows with a description, a unit for the y axis and a
	//    html-coded color
	dataTable.addDataRow( "linear","y",m1,"#888888" );
	dataTable.addDataRow( "quadratic","y",m2,"#ff0000" );
	dataTable.addDataRow( "cubic","y",m3,"#00ff00" );

	// 4. export into a file
	dataTable.exportCSV("1.csv");
	dataTable.exportSVG("1.svg");


	"1.csv" (formatting adapted for demonstration)
	
	x		linear	quadratic	cubic
	0		0		0			0
	0.5		0.5		0.25		0.125
	1		1		1			1
	1.5		1.5		2.25		3.375
	2		2		4			8
	2.5		2.5		6.25		15.625
	3		3		9			27
	3.5		3.5		12.25		42.875
	4		4		16			64
	4.5		4.5		20.25		91.125
	

*/
static T = new Type;

/*! [ctor] */
T._constructor := fn( String unitX ){
	this.unitX := unitX;
	this.dataRows := [];
	this.templateFile := "resources/Diagrams/diagram-template.svg";
};

T.addDataRow := fn( String description,String unitY, Collection data, String color = "#888888"){
	this.dataRows += new T.DataRow(description, unitY, data, color) ;
};

/*! Export data to csv-file */
T.exportCSV := fn(String filename, String delimiter = "\t", sortnumerical = true){
	var m = new Map;
	var descriptions=[unitX];
	foreach( dataRows as var dataRowIndex,var row){
		descriptions.pushBack(row.description);
		foreach( row.data as var x,var y){
			var l = m[x];
			if(!l){
				l=[];
				m[x]=l;
				l.pushBack(x);
			}
			l.pushBack(y);
		}
	}
	var s = descriptions.implode(delimiter)+"\n";
	if (!sortnumerical) { // don't sort numerically (lexicographical sorting is done automatically)
		foreach(m as var l)
			s+=l.implode(delimiter)+"\n";
	} else {
	var key;
		// get and sort keys numerically first
		var keys = [];
		foreach (m as key, var value)
			keys += key;
		keys.sort();

		// put data into the string s now
		foreach (keys as key)
			s+=m[key].implode(delimiter)+"\n";
	}

	out("Exporting csv ",filename," ... ");
	var success = Util.saveFile( filename , s  );
	out(success,"\n");
//				out(s);
	return success;
};

/*! Export data to dynamic svg-file */
T.exportSVG := fn(String filename, sortnumerical = true){
	var s="\n";
	foreach( dataRows as var row){
	var key;
		var x=[];
		var y=[];
		foreach(row.data as key,var value){ // get only the keys first
			x+=key;
		}

		if (sortnumerical) // sort numerically if needed
			x.sort();

		// now get the data belonging to the keys
		foreach(x; as key)
			y += row.data[key];

		s+="d.addDataRow(new DataRow("+
			"'" + row.description +"',"+
			"'" + unitX + "',"+
			"'" + row.unitY + "',"+
			"[" + x.implode(",") + "],"+
			"[" + y.implode(",") + "],"+
			"{'color':'"+row.color+"'}));\n";
	}
	var s2 = Util.loadFile(this.templateFile);
//				s2.replace("$Data$", s);
	s2 = s2.replaceAll( {"$Data$": s});
	out("Exporting svg ",filename," ... ");
	var success = Util.saveFile( filename , s2  );
	out(success,"\n");
//	out(s2);
	return success;
};

//! (internal)
T.DataRow ::= new Type;
T.DataRow._constructor := fn( String description,String unitY, Collection data, String color = "#ff0000"){
	this.description := description;
	this.unitY := unitY;
	this.data := data.clone();
	this.color := color;
};


return T;
