//
// dumpConfig.sqf
// Copyright (c) 2010 Denis Usenko, DenVdmj@gmail.com
// MIT-style license
//
// Modified by Pennyworth to write to file using ConfigDumpFileIO extension.

/*
======================================================================================

Dump config to the clipboard:

	[config HNDL, bool IncludeInheritedPropertiesFlag] call compile preprocessFileLineNumbers "dumpConfig.sqf"

This example put section CfgVehicles on the clipboard:

	[configFile >> "CfgVehicles"] call compile preprocessFileLineNumbers "dumpConfig.sqf"

This example will put on the clipboard class "RscDisplayArcadeUnit", all classes will contain all heritable properties, so you get a full and self-sufficient class, independent from the other classes.

	[configFile >> "RscDisplayArcadeUnit", true] call compile preprocessFileLineNumbers "dumpConfig.sqf"

More examples:

	[configFile >> "RscTitle", true] call compile preprocessFileLineNumbers "dumpConfig.sqf"
	[configFile >> "RscEdit", true] call compile preprocessFileLineNumbers "dumpConfig.sqf"
	[configFile >> "RscToolbox", true] call compile preprocessFileLineNumbers "dumpConfig.sqf"

Warning: don't attempt to get a large classes with switched on parameter "IncludeInheritedPropertiesFlag", eg don't do so:

	[configFile, true] call compile preprocessFileLineNumbers "dumpConfig.sqf"

Dump the entire config, it can take over ten seconds:

	[configFile] call compile preprocessFileLineNumbers "dumpConfig.sqf"

======================================================================================
*/

#define arg(x)		  (_this select (x))
#define argIf(x)		if(count _this > (x))
#define argIfType(x,t)  if(argIf(x)then{typeName arg(x) == (t)}else{false})
#define argSafe(x)	  argIf(x)then{arg(x)}
#define argOr(x,v)	  (argSafe(x)else{v})
#define push(a,v)	   (a)pushBack(v)

"ConfigDumpFileIO" callExtension format ["open:AiO.1.%1.%2.cpp", (productVersion select 2) % 100, productVersion select 3];

private _escapeString = {
	private _source = toArray _this;
	private _start = _source find 34;
	if(_start != -1) then {
		private _target = +_source;
		_target resize _start;
		for "_i" from _start to count _source - 1 do {
			private _charCode = _source select _i;
			push(_target, _charCode);
			if(_charCode isEqualTo 34) then {
				push(_target, _charCode);
			};
		};
		str toString _target;
	} else {
		str _this;
	};
};

private _collectInheritedProperties = {
	private _config = _this;
	private _propertyNameList = [];
	private _propertyNameLCList = [];
	while {
		private _className = configName _config;
		for "_i" from 0 to count _config - 1 do {
			private _propertyName = _config select _i;
			private _propertyNameLC = toLower configName _propertyName;
			if!(_propertyNameLC in _propertyNameLCList) then {
				push(_propertyNameList, _propertyName);
				push(_propertyNameLCList, _propertyNameLC);
			};
		};
		_className != "";
	} do {
		_config = inheritsFrom _config;
	};
	_propertyNameList;
};

private _dumpConfigTree = {
	private _includeInheritedProperties = argOr(1, false);
	private _specifyParentClass = argOr(2, !_includeInheritedProperties);

	private _result = [];
	private _indents = [""];
	private _depth = 0;
	
	private _pushLine = {
		if(_depth >= count _indents) then {
			_indents set [_depth, (_indents select _depth-1) + toString[9]];
		};
		_myString = (_indents select _depth) + (_this);
		"ConfigDumpFileIO" callExtension ("write:" +  _myString);
	};

	private _traverse = {
		private _confName = configName _this;
		if( isText _this ) exitwith {
			_confName + " = " + (getText _this call _escapeString) + ";" call _pushLine;
		};
		if( isNumber _this ) exitwith {
			_confName + " = " + str getNumber _this + ";" call _pushLine;
		};
		if( isArray _this ) exitwith {
			_confName + "[] = " + (getArray _this call _traverseArray) + ";" call _pushLine;
		};
		if( isClass _this ) exitwith {
			"class " + _confName + (
				configName inheritsFrom _this call {
					if( _this isEqualTo "" || !_specifyParentClass ) then { "" } else { ": " + _this }
				}
			) call _pushLine;
			"{" call _pushLine;
			if( _includeInheritedProperties ) then {
				_this = _this call _collectInheritedProperties;
			};
			_depth = _depth + 1;
			for "_i" from 0 to count _this - 1 do {
				_this select _i call _traverse
			};
			_depth = _depth - 1;
			"};" call _pushLine;
		};
	};
	
	private _traverseArray = {
		if(_this isEqualType []) exitwith {
			private _array = [];
			for "_i" from 0 to count _this - 1 do {
				push(_array, _this select _i call _traverseArray);
			};
			"{" + (_array joinString ", ") + "}";
		};
		if(_this isEqualType "") exitwith {
			_this call _escapeString;
		};
		str _this;
	};

	arg(0) call _traverse;
	
	"ConfigDumpFileIO" callExtension "close:yes";
	true
};

private _startTime = diag_tickTime;
private _finished = _this call _dumpConfigTree;
private _endTime = diag_tickTime;
hint format ["Ready\nNow get config from the ConfigDumpFileIO directory\ntime: %1", _endTime - _startTime];
false;
