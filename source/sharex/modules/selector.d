module sharex.modules.selector;

import sharex.region;

import sharex.core.imagegen;

import std.bitmanip;
import std.typecons;
import std.process;

import core.thread;

enum path = "./selector";

private Bitmap* processCapture(string[] args, bool allowRegions = true)
{
	std.stdio.writeln("Starting");
	auto pipes = pipeProcess([path] ~ args);
	Region[] regions;
	ubyte[8] longBytes;
	ubyte[4] intBytes;
	// rawRead waits
	auto b = pipes.stdout.rawRead(longBytes);
	std.stdio.writeln("Done");
	std.stdio.writeln(b);
	if (b.length < 8)
		return null;
	std.stdio.writeln("Not Null");
	auto regionCount = bigEndianToNative!ulong(b[0 .. 8]);
	regions.length = cast(size_t) regionCount;
	for (size_t i = 0; i < regions.length; i++)
	{
		int x, y, w, h;
		x = bigEndianToNative!int(pipes.stdout.rawRead(intBytes)[0 .. 4]);
		y = bigEndianToNative!int(pipes.stdout.rawRead(intBytes)[0 .. 4]);
		w = bigEndianToNative!int(pipes.stdout.rawRead(intBytes)[0 .. 4]);
		h = bigEndianToNative!int(pipes.stdout.rawRead(intBytes)[0 .. 4]);
		regions[i] = Region(x, y, w, h);
	}

	int w, h;
	w = bigEndianToNative!int(pipes.stdout.rawRead(intBytes)[0 .. 4]);
	h = bigEndianToNative!int(pipes.stdout.rawRead(intBytes)[0 .. 4]);

	ubyte[] dataBuf;
	dataBuf.length = w * h * 3;
	ubyte[] data = pipes.stdout.rawRead(dataBuf);
	assert(dataBuf.length == data.length, "Failed to screenshot");

	auto raw = new Bitmap(data, w, h);
	if (allowRegions)
	{
		std.stdio.writeln("Cutting");
		auto cutted = cutBitmap(*raw, regions);
		std.stdio.writeln("Cutted");
		return new Bitmap(cutted.rgb_pixels, cutted.width, cutted.height);
	}
	else
	{
		return raw;
	}
}

void initModule()
{
	auto pipes = pipeProcess([path, "version"], Redirect.stdout);
	wait(pipes.pid);
	ubyte[4] intBytes;
	auto ver = bigEndianToNative!int(pipes.stdout.rawRead(intBytes)[0 .. 4]);
	assert(ver == 1, "Invalid version for selector module!");
}

Bitmap* captureFullscreen()
{
	return processCapture(["fullscreen"], false);
}

Bitmap* captureRegion()
{
	return processCapture(["region"]);
}

Bitmap* captureObjects()
{
	return processCapture(["objects"]);
}
