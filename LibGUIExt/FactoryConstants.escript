/*
 * This file is part of the open source part of the
 * Platform for Algorithm Development and Rendering (PADrend).
 * Web page: http://www.padrend.de/
 * Copyright (C) 2013 Claudius Jähn <claudius@uni-paderborn.de>
 * 
 * PADrend consists of an open source part and a proprietary part.
 * The open source part of PADrend is subject to the terms of the Mozilla
 * Public License, v. 2.0. You should have received a copy of the MPL along
 * with this library; see the file LICENSE. If not, you can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */
/****
 **	[LibGUIExt] Factory_Constants.escript
 **/

GUI.ACTIONS := $ACTIONS;						//!	\see GUI_Manager.createDialog
GUI.BUTTON_SHAPE := 'buttonShape';
GUI.COLLAPSED := $COLLAPSED;					//!< TYPE_TREE, TYPE_COLLAPSIBLE_CONTAINER
GUI.COLOR := 'color';
GUI.CONTENTS := 'contents';
GUI.CONTEXT := 'context';
GUI.CONTEXT_ARRAY := $CONTEXT_ARRAY;
GUI.CONTEXT_MENU_PROVIDER := $CONTEXT_MENU_PROVIDER;
GUI.CONTEXT_MENU_WIDTH := $CONTEXT_MENU_WIDTH;
GUI.DATA_ATTRIBUTE := 'attr';
GUI.DATA_BIT := 'bit';
GUI.DATA_OBJECT := 'object';
GUI.DATA_REFRESH_GROUP := 'refreshGroup';
GUI.DATA_PROVIDER := 'dataProvider';
GUI.DATA_VALUE := 'value';
GUI.DATA_WRAPPER := 'dataWrapper';
GUI.DIR := 'dir';
GUI.DRAGGING_BUTTONS := $DRAGGING_BUTTONS;
GUI.DRAGGING_CONNECTOR := $DRAGGING_CONNECTOR;
GUI.DRAGGING_ENABLED := $DRAGGING_ENABLED;
GUI.DRAGGING_MARKER := $DRAGGING_MARKER;
GUI.ENDINGS := 'ending';
GUI.FILENAME := $FILENAME;						//!	\see GUI_Manager.createDialog
GUI.FILTER := $FILTER;
GUI.FLAGS := 'flags';	//
GUI.FONT := 'font';
GUI.HEADER := $HEADER;
GUI.HEIGHT := 'height';
GUI.ICON := 'icon';
GUI.ICON_COLOR := 'iconColor';
GUI.LABEL := 'label';
GUI.LAYOUT := 'layout';
GUI.LIST_ENTRY_HEIGHT := 'listEntryHeight';
GUI.MENU := 'menu';
GUI.MENU_CONTEXT := 'menuContext';
GUI.MENU_PROVIDER := 'menu';					//! \deprecated alias for GUI.MENU
GUI.MENU_WIDTH := 'menuWidth';
GUI.ON_ACCEPT := $ON_ACCEPT;					//!	\see GUI_Manager.createDialog
GUI.ON_CLICK := 'onClick';
GUI.ON_DATA_CHANGED := 'onDataChanged';
GUI.ON_DRAG := $ON_DRAG;
GUI.ON_DROP := $ON_DROP;
GUI.ON_FILES_CHANGED := 'ON_FILES_CHANGED';		//! \see GUI.FileDialog
GUI.ON_FOLDER_CHANGED := 'ON_FOLDER_CHANGED';		//! \see GUI.FileDialog
GUI.ON_INIT := 'onInit';
GUI.ON_MOUSE_BUTTON := $ON_MOUSE_BUTTON;
GUI.ON_START_DRAGGING := $ON_START_DRAGGING;
GUI.ON_STOP_DRAGGING := $ON_STOP_DRAGGING;
GUI.ON_WINDOW_CLOSED := $ON_WINDOW_CLOSED;
GUI.OPTIONS := 'options';
GUI.OPTIONS_PROVIDER := 'optionsProvider';
GUI.POSITION := 'extPosition';
GUI.PROPERTIES := $PROPERTIES;
GUI.PROVIDER := $PROVIDER;
GUI.PANEL_MARGIN := 'margin';
GUI.PANEL_PADDING := 'padding';
GUI.RANGE := 'range';
GUI.RANGE_FN_BASE := $RANGE_FN_BASE;
GUI.RANGE_FN := 'rangeFn';
GUI.RANGE_INV_FN := 'rangeInvFn';
GUI.RANGE_STEPS := 'steps';
GUI.RANGE_STEP_SIZE := $RANGE_STEP_SIZE;
GUI.REQUEST_MESSAGE := 'requestLabel';
GUI.SIZE := 'extSize';
GUI.SPACING := 'spacing';
GUI.TAB_CONTENT := $TAB_CONTENT;
GUI.TOOLTIP := 'tooltip';
GUI.TEXT_ALIGNMENT := 'textAlignment';
GUI.TYPE := 'type';
GUI.TYPE_BIT := 'bit';
GUI.TYPE_BOOL := 'bool';
GUI.TYPE_BUTTON := 'button';
GUI.TYPE_COLLAPSIBLE_CONTAINER := $TYPE_COLLAPSIBLE_CONTAINER;
GUI.TYPE_COLOR := 'color';
GUI.TYPE_COMPONENTS := $TYPE_COMPONENTS;
GUI.TYPE_CONTAINER := 'container';
GUI.TYPE_CRITICAL_BUTTON := 'criticalButton';
GUI.TYPE_FILE := 'fileSelector';
GUI.TYPE_FILE_DIALOG := $TYPE_FILE_DIALOG;		//!	\see GUI_Manager.createDialog
GUI.TYPE_FOLDER := $TYPE_FOLDER;
GUI.TYPE_FOLDER_DIALOG := $TYPE_FOLDER_DIALOG;	//!	\see GUI_Manager.createDialog
GUI.TYPE_ICON := 'icon';
GUI.TYPE_LIST := 'list';
GUI.TYPE_LABEL := 'label';
GUI.TYPE_MENU := 'menu';
GUI.TYPE_MENU_ENTRIES := $TYPE_MENU_ENTRIES;
GUI.TYPE_NEXT_COLUMN := 'nextColumn';
GUI.TYPE_NEXT_ROW := 'nextRow';
GUI.TYPE_NUMBER := 'number';
GUI.TYPE_PANEL := 'panel';
GUI.TYPE_POPUP_DIALOG := $TYPE_POPUP_DIALOG;	//!	\see GUI_Manager.createDialog
GUI.TYPE_RADIO := 'radio';
GUI.TYPE_RANGE := 'range';
GUI.TYPE_SELECT := 'select';
GUI.TYPE_TAB := $TYPE_TAB;
GUI.TYPE_TABBED_PANEL := $TYPE_TABBED_PANEL;
GUI.TYPE_TEXT := 'text';
GUI.TYPE_MULTILINE_TEXT := $TYPE_MULTILINE_TEXT;
GUI.TYPE_TREE := 'tree';
GUI.TYPE_TREE_GROUP := 'treeSubGroup';
GUI.TYPE_WINDOW := 'window';
GUI.WIDTH := 'width';

return GUI;
