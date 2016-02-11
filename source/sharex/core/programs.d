module sharex.core.programs;

import std.process;

alias openURL = browse;

void openFolder(string folder)
{
	version(OSX)
	{
		spawnProcess(["open", folder]);
	}
	else version(linux)
	{
		spawnProcess(["xdg-open", folder]);
	}
	else version(Windows)
	{
		spawnProcess(["explorer", folder]);
	}
	else static assert(0, "Not implemented openFolder for this platform");
}

void openFile(string file)
{
	version(OSX)
	{
		spawnProcess(["open", file]);
	}
	else version(linux)
	{
		spawnProcess(["xdg-open", file]);
	}
	else version(Windows)
	{
		spawnShell(file);
	}
	else static assert(0, "Not implemented openFile for this platform");
}