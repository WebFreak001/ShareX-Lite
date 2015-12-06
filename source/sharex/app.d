module sharex.app;

import gtk.Main;
import gdk.Threads;

import std.file;
import std.path;
import std.conv;
import std.stdio;

import sharex.forms.mainform;

import Config = sharex.config.config;

static MainForm mainForm;

void main(string[] args)
{
	try
	{
		threadsInit();
		chdir(thisExePath.dirName);
		Config.load();
		scope(exit)
			Config.save();
		Main.init(args);
		mainForm = new MainForm();
		Main.run();
	}
	catch(Exception e)
	{
		writeln("Program crashed with exception");
		writeln(e);
	}
}
