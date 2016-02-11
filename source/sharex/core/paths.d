module sharex.core.paths;

import std.datetime;
import std.string;
import std.path;
import standardpaths;

@property string personalDirectory() nothrow
{
	return buildPath(writablePath(StandardPath.config), "sharex");
}

@property string screenshotDirectory() nothrow
{
	return buildPath(writablePath(StandardPath.pictures), "sharex");
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
	return buildPath(historyDirectory, format("%04d-%02d.json", time.year, time.month));
}

string createHistoryFilename(ubyte month, short year)
{
	return buildPath(historyDirectory, format("%04d-%02d.json", year, month));
}

string createScreenshotPath(string name)
{
	auto time = Clock.currTime();
	string base = name.stripExtension.strip;
	if (base == "<auto>")
		base = "";
	else
		base ~= "_";
	string ext = name.extension;
	// screenshots/YEAR-MONTH/PREFIX_YEAR-MONTH-DAY_HOUR-MINUTE-SECOND.EXTENSION
	return buildPath(screenshotDirectory, format("%04d-%02d", time.year, time.month), format("%s%04d-%02d-%02d %02d-%02d-%02d%s", base, time.year, time.month,
		time.day, time.hour, time.minute, time.second, ext).replace(" ", "_"));
}
