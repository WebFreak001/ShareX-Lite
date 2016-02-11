module sharex.script.provider;

public import sharex.script.lua;

import std.path;
import std.stdio;
import std.string;

interface IScriptProvider
{
	void run(string file);
}

static __gshared IScriptProvider[string] scriptProviders;

static void run(string file)
{
	foreach (extension, provider; scriptProviders)
	{
		if (file.extension.toLower == extension.toLower)
		{
			writeln("Found provider");
			provider.run(file);
			return;
		}
	}
	throw new Exception("No handler found for extension " ~ file.extension.toLower);
}
