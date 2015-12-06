module modules.selector.main;

import std.bitmanip;
import std.string;
import std.stdio;

import gtk.Main;

import modules.selector.region;

import modules.selector.selection;

import gtk.Main;
import gdk.Pixbuf;

class NotImplementedException : Exception {
	public this(string msg = "Not implemented yet!", string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
		super(msg, file, line, next);
	}
}

void main(string[] args)
{
	assert(args.length > 1, "Not enough args");
	Region[] regions;
	Pixbuf image;
	bool success = true;
	SelectionEvent handleSelection = (img, reg)
	{
		image = img;
		regions = reg;
	};
	switch(args[1].toLower)
	{
	case "version":
		stdout.rawWrite(nativeToBigEndian!int(1));
		return;
	case "region":
		Main.init(args);
		auto sel = new Selection(false);
		sel.onSelected = handleSelection;
		Main.run();
		success = sel.success;
		break;
	case "objects":
		Main.init(args);
		auto sel = new Selection(true);
		sel.onSelected = handleSelection;
		Main.run();
		success = sel.success;
		break;
	case "fullscreen":
		Main.init(args);
		image = captureAll();
		break;
	case "window":
		throw new NotImplementedException();
	default:
		throw new NotImplementedException();
	}

	if(!success)
		return;

	stdout.rawWrite(nativeToBigEndian(cast(ulong) regions.length));
	foreach(region; regions)
	{
		stdout.rawWrite(nativeToBigEndian(region.x));
		stdout.rawWrite(nativeToBigEndian(region.y));
		stdout.rawWrite(nativeToBigEndian(region.w));
		stdout.rawWrite(nativeToBigEndian(region.h));
	}
	stdout.rawWrite(nativeToBigEndian(cast(int) image.getWidth()));
	stdout.rawWrite(nativeToBigEndian(cast(int) image.getHeight()));
	stdout.rawWrite(cast(ubyte[])(image.getPixels()[0 .. image.getWidth() * image.getHeight() * 3]));
}
