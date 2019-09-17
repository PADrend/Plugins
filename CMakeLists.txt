#
# This file is part of the open source part of the
# Platform for Algorithm Development and Rendering (PADrend).
# Web page: http://www.padrend.de/
# Copyright (C) 2013 Benjamin Eikel <benjamin@eikel.org>
# Copyright (C) 2015-2019 Sascha Brandt <sascha@brandt.graphics>
# 
# PADrend consists of an open source part and a proprietary part.
# The open source part of PADrend is subject to the terms of the Mozilla
# Public License, v. 2.0. You should have received a copy of the MPL along
# with this library; see the file LICENSE. If not, you can obtain one at
# http://mozilla.org/MPL/2.0/.
#
cmake_minimum_required(VERSION 3.1.0)
project(PADrendPlugins VERSION 1.1.0)

# Set up install directories
include(GNUInstallDirs)

# Install all files into a data directory
install(
	DIRECTORY ./
	DESTINATION ${CMAKE_INSTALL_DATADIR}/PADrend/plugins
	COMPONENT data
	PATTERN ".svn" EXCLUDE
	PATTERN ".git" EXCLUDE
)
