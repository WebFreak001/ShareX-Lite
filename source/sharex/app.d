module sharex.app;

import gtk.Main;
import gdk.Threads;

import std.file;
import std.path;
import std.conv;
import std.stdio;
import std.getopt;

import sharex.forms.mainform;
import sharex.core.paths;

import sharex.script.provider;

import Config = sharex.config.config;

static MainForm mainForm;

void main(string[] args)
{
	string script;
	bool nogui = false;
	auto result = getopt(args,
		"s|script", "A script to be executed on Launch", &script,
		"nogui", "Start sharex without a GUI", &nogui);

	if(result.helpWanted)
	{
		defaultGetoptPrinter("ShareX-Lite - cross platform sharex tool", result.options);
		return;
	}

	writeln("Reading config from ", configDirectory);
	Config.load();
	scope (exit)
		Config.save();

	Main.init(args);
	mainForm = new MainForm();
	if(script != null)
	{
		run(script);
	}
	if(!nogui)
	{
		Main.run();
	}
}
