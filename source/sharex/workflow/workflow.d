module sharex.workflow.workflow;

import Script = sharex.script.provider;
import sharex.core.paths;

import file = std.file;
import std.path;
import std.stdio;
import std.string;

class Workflow
{
private:
	string file;

public:
	this(string file)
	{
		this.file = file;
	}

	void run()
	{
		writeln("Starting script ", file);
		Script.run(file);
	}
}

static Workflow[string] workflows;

shared static this()
{
	if(!file.exists(scriptsDirectory))
	{
		file.mkdirRecurse(scriptsDirectory);
	}

	foreach(entry; file.dirEntries(scriptsDirectory, file.SpanMode.shallow, false))
	{
		workflows[entry.baseName.stripExtension] = new Workflow(entry);
	}
}
