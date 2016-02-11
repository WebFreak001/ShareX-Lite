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

static GeneralConfig generalConfig()
{
	return cast(GeneralConfig) configProviders["general"];
}

class GeneralConfig : IConfig
{
private:
	string path;

public:
	struct Data
	{
		struct Uploaders
		{
			string[] imageUploader = [":special", "imgur", "imageshack", "tinypic", "flickr", "photobucket", "picasa"];
			string[] textUploader = [":special", "pastebin", "gist", "paste2", "slexy", "pastee.org", "paste.ee", "hastebin"];
			string[] fileUploader = [":special", "dropbox", "googledrive", "onedrive", "copy", "box", "mega", "mediafire"];
			string[] linkShortener = [":special", "goo.gl", "bit.ly", "is.gd", "v.gd"];
			string[][string] specialUploaders;
			bool fallbackToFileUploader = true;
			bool fallthroughServices = true;
		}

		Uploaders uploaders;

		struct AfterCapture
		{
			bool openInEditor = false;
			bool copyImage = true;
			bool saveImage = true;
			bool uploadImage = true;
			bool deleteFile = false;
		}

		AfterCapture afterCapture;

		struct AfterUpload
		{
			bool shortenURL = false;
			bool copyURL = true;
			bool openURL = false;
		}

		AfterUpload afterUpload;

		struct Editors
		{
			string imageEditor;
		}

		Editors editors;
	}

	Data data;

	this()
	{
		path = buildPath(configDirectory, "general.json");
		load();
	}

	void load()
	{
		if (!file.exists(path))
		{
			save();
		}
		else
		{
			string content = file.readText(path);
			data = fromJSON!Data(parseJSON(content));
			if (data.uploaders.specialUploaders is null)
			{
				data.uploaders.specialUploaders = ["image/file \\.gif$" : ["gfycat"], "image/file \\.ogg$" : ["videobin"], `link ^https?://(www\.)?youtube\.com/watch?v=` : ["youtu.be"]];
			}
		}
	}

	void save()
	{
		if (data.uploaders.specialUploaders is null)
		{
			data.uploaders.specialUploaders = ["image/file \\.gif$" : ["gfycat"], "image/file \\.ogg$" : ["videobin"], `link ^https?://(www\.)?youtube\.com/watch?v=` : ["youtu.be"]];
		}
		file.mkdirRecurse(path.dirName);
		file.write(path, data.toJSON.toPrettyString);
	}
}
