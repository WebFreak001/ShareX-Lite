module sharex.core.history;

import std.datetime;
import std.path;
import std.file;
import std.json;

import painlessjson;

import sharex.uploaders.uploader;

struct HistoryEntry
{
	string file;
	UploadType type;
	string host;
	string url = "";
	string thumb = "";
	string deletion = "";
}

void appendHistory(string file, UploadType type, string host, string url, string thumb = "", string deletion = "")
{
	if (!historyDirectory.exists)
		mkdirRecurse(historyDirectory);

	HistoryEntry entry;

	entry.file = file;
	entry.type = type;
	entry.host = host;

	if (url.length > 0)
		entry.url = url;
	if (thumb.length > 0)
		entry.thumb = thumb;
	if (deletion.length > 0)
		entry.deletion = deletion;

	immutable historyFile = createHistoryFilename;
	if (historyFile.exists)
		historyFile.append(",\n" ~ entry.toJSON.toString());
	else
		historyFile.write(entry.toJSON.toString());
	// Fast write hack. Add [] on reading!
}

HistoryEntry[] readHistory(ubyte month, short year)
{
	if (!historyDirectory.exists)
		return [];
	immutable file = createHistoryFilename(month, year);
	if (!file.exists)
		return [];
	return fromJSON!(HistoryEntry[])(parseJSON("[" ~ file.readText ~ "]"));
}
