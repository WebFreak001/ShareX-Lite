module sharex.core.paths;

import std.datetime;
import std.string;
import std.path;

@property string personalDirectory() nothrow
{
	version (Posix)
	{
		return expandTilde("~/.sharex");
	}
	else
	{
		// TODO: Implement on other platforms
		static assert(0);
	}
}

@property string screenshotDirectory() nothrow
{
	return buildPath(personalDirectory, "screenshots");
}

@property string historyDirectory() nothrow
{
	return buildPath(personalDirectory, "history");
}

@property string scriptsDirectory() nothrow
{
	return buildPath(personalDirectory, "scripts");
}

@property string uploadersDirectory() nothrow
{
	return buildPath(personalDirectory, "uploaders");
}

@property string configDirectory() nothrow
{
	return personalDirectory;
}

string createHistoryFilename()
{
	auto time = Clock.currTime();
	return buildPath(screenshotDirectory, format("%04d-%02d.json", time.year, time.month));
}

string createScreenshotPath(string name)
{
	auto time = Clock.currTime();
	string base = name.stripExtension.strip.replace(" ", "");
	if (base == "<auto>")
		base = "";
	else
		base ~= "_";
	string ext = name.extension;
	// screenshots/YEAR-MONTH/PREFIX_YEAR-MONTH-DAY_HOUR-MINUTE-SECOND.EXTENSION
	return buildPath(screenshotDirectory, format("%04d-%02d", time.year, time.month), format("%s%04d-%02d-%02d_%02d-%02d-%02d%s", base, time.year, time.month,
		time.day, time.hour, time.minute, time.second, ext));
}
