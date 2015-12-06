module sharex.config.general;

import sharex.config.config;
import sharex.core.paths;

import file = std.file;
import std.path;

import std.json;
import painlessjson;

shared static this()
{
	configProviders["general"] = new GeneralConfig();
}

class GeneralConfig : IConfig
{
private:
	string path;

public:
	struct Data
	{
		string[] imageUploader = [":special", "imgur", "imageshack", "tinypic", "flickr", "photobucket", "picasa"];
		string[] textUploader = [":special", "pastebin", "gist", "paste2", "slexy", "pastee.org", "paste.ee", "hastebin"];
		string[] fileUploader = [":special", "dropbox", "googledrive", "onedrive", "copy", "box", "mega", "mediafire"];
		bool fallbackToFileUploader = true;
		string[] linkShortener = [":special", "goo.gl", "bit.ly", "is.gd", "v.gd"];
		bool fallthroughServices = true;
		string[][string] specialUploaders;
	}
	
	Data data;

	this()
	{
		path = buildPath(configDirectory, "general.json");
		load();
	}

	void load()
	{
		if(!file.exists(path))
		{
			save();
		}
		else
		{
			string content = file.readText(path);
			data = fromJSON!Data(parseJSON(content));
			if(data.specialUploaders is null)
			{
				data.specialUploaders = [
					"image/file .gif": ["gfycat"],
					"image/file .ogg": ["videobin"],
					`link ^https?://(www\.)?youtube\.com/watch?v=`: ["youtu.be"]
				];
			}
		}
	}

	void save()
	{
		if(data.specialUploaders is null)
		{
			data.specialUploaders = [
				"image/file .gif": ["gfycat"],
				"image/file .ogg": ["videobin"],
				`link ^https?://(www\.)?youtube\.com/watch?v=`: ["youtu.be"]
			];
		}
		file.write(path, data.toJSON.toPrettyString);
	}
}
