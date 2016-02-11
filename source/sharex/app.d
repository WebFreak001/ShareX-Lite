module sharex.app;

import gtk.Main;
import gdk.Threads;

import std.file;
import std.path;
import std.conv;
import std.stdio;

import sharex.forms.mainform;
import sharex.core.paths;

import Config = sharex.config.config;

static MainForm mainForm;

void main(string[] args)
{
	writeln("Reading config from ", configDirectory);
	Config.load();
	scope (exit)
		Config.save();
	Main.init(args);
	mainForm = new MainForm();
	Main.run();
}
