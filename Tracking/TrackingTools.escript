/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013-2015 Claudius Jähn <claudius@uni-paderborn.de>
 *
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

static NS = new Namespace;

static rayCache = []; //segmentString, clock()+0.1, intersection

//!	Returns the intersection point of the scene with the given worldRay/segment
NS.querySceneIntersection := fn(Geometry.Segment3 worldSegment, _useCache=true){
	@(once) static rayCaster = new (Std.require('LibMinSGExt/RendRayCaster'));
	var segStr = ""+worldSegment;
	var now = clock();

	if(_useCache){
		foreach(rayCache as var arr){
			if(arr[0]==segStr && arr[1]<now){
				outln("cache!");
				return arr[2];
			}
		}
	}
	while(rayCache.count()>3)
		rayCache.popFront();

	var intersection = rayCaster.queryIntersection(frameContext, PADrend.getCurrentScene(), worldSegment.getFirstPoint(), worldSegment.getSecondPoint());
	if(!intersection)
		intersection = worldSegment.getSecondPoint();
	rayCache.pushBack( [segStr,now+0.1,intersection ] );
	return intersection;
};

//!	Returns the position of the device in world coordinates.
NS.roomPosToWorldPos := fn(Geometry.Vec3 roomPos){	return PADrend.getDolly().localPosToWorldPos( roomPos );	};
NS.roomDirToWorldDir := fn(Geometry.Vec3 roomDir){	return PADrend.getDolly().localDirToWorldDir( roomDir );	};

NS.roomSRTToWorldSRT := fn(Geometry.SRT roomSRT){
	var dolly = PADrend.getDolly();
	return new Geometry.SRT(	dolly.localPosToWorldPos(roomSRT.getTranslation()), 
								dolly.localDirToWorldDir(roomSRT.getDirVector()),
								dolly.localDirToWorldDir(roomSRT.getUpVector()),
								roomSRT.getScale() );
};

NS.worldPosToRoomPos:= fn(Geometry.Vec3 worldPos){	return PADrend.getDolly().worldPosToLocalPos( worldPos );	};
NS.worldDirToRoomDir:= fn(Geometry.Vec3 worldDir){	return PADrend.getDolly().worldDirToLocalDir( worldDir );	};


//!	Returns the normalized direction of the device in room coordinates.
NS.getDeviceRoomDir := fn(device){
	return device.getRoomTransformation().getDirVector();   												//!	\see Controller_Room6D_Trait
};

NS.getDeviceRoomPos := fn(device){
	return device.getRoomTransformation().getTranslation();   												//!	\see Controller_Room6D_Trait
};

//!	Returns the normalized direction of the device in world coordinates.
NS.getDeviceWorldDir := fn(device){
    return PADrend.getDolly().localDirToWorldDir( getDeviceRoomDir(device) );
};

NS.getDeviceWorldMatrix := fn(device){
	return PADrend.getDolly().getWorldTransformationMatrix() * new Geometry.Matrix4x4( device.getRoomTransformation() ); //!	\see Controller_Room6D_Trait
};

return NS;
