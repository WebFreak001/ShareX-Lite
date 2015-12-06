module sharex.core.history;

import std.datetime;
import std.path;
import std.file;
import std.json;

import sharex.uploaders.uploader;

void appendHistory(string file, UploadType type, string host, string url, string thumb = "", string deletion = "")
{
	if(!screenshotDirectory.exists)
		mkdirRecurse(screenshotDirectory);

	JSONValue entry = [
		"file": JSONValue(file),
		"type": JSONValue(cast(int) type),
		"host": JSONValue(host),
	];
	if(url.length > 0)
		entry["url"] = JSONValue(url);
	if(thumb.length > 0)
		entry["thumb"] = JSONValue(thumb);
	if(deletion.length > 0)
		entry["deletion"] = JSONValue(deletion);

	createHistoryFilename.write("," ~ entry.toString());
	// Fast write hack. Add [] on reading!
}
