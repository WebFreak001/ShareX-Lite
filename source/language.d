module sharex.language;

import std.string;

struct Language
{
	static string currentLang = "en";

	string[string] texts;

	this(string[string] content)
	{
		texts = content;
	}

	string opCall(string s)
	{
		s = s.toLower();
		if((s in texts) is null)
			return s;
		return texts[s];
	}

	string opIndex(string s)
	{
		s = s.toLower();
		if((s in texts) is null)
			return s;
		return texts[s];
	}

	string opDispatch(string s)()
	{
		s = s.toLower();
		if((s in texts) is null)
			return s;
		return texts[s];
	}
}

auto getLanguage(string code = "")
{
	if((code in lang) !is null)
		return lang[code];
	return lang[Language.currentLang];
}

Language[string] lang;

static this()
{
	lang =
	[
		"en": Language([
			"main.tools.capture": "Capture",
			"main.tools.capture.fullscreen": "Fullscreen",
			"main.tools.capture.window": "Window",
			"main.tools.capture.region": "Region",
			"main.tools.capture.objects": "Region (Objects)",
			"main.tools.upload": "Upload",
			"main.tools.upload.file": "File",
			"main.tools.upload.folder": "Folder",
			"main.tools.upload.clipboard": "From Clipboard",
			"main.tools.upload.url": "From URL",
			"main.tools.tools": "Tools",
			"main.tools.tools.colorpicker": "Color Picker",
			"main.tools.tools.screencolorpicker": "Screen Color Picker",
			"main.tools.tools.hashcheck": "Hash Check",
			"main.tools.tools.ruler": "Ruler",
			"main.tools.tools.indexfolder": "Index Folder",
			"main.tools.aftercapture": "After Capture",
			"main.tools.aftercapture.edit": "Open in Editor",
			"main.tools.aftercapture.copy": "Copy Image to Clipboard",
			"main.tools.aftercapture.save": "Save Image to File",
			"main.tools.aftercapture.upload": "Upload Image",
			"main.tools.aftercapture.delete": "Delete File locally",
			"main.tools.afterupload": "After Upload",
			"main.tools.afterupload.shortenurl": "Shorten URL",
			"main.tools.afterupload.copyurl": "Copy URL to Clipboard",
			"main.tools.afterupload.openurl": "Open URL",
			"main.tools.imageuploader": "Image Uploader",
			"main.tools.imageuploader.custom": "Custom",
			"main.tools.imageuploader.fileuploader": "File Uploader",
			"main.tools.textuploader": "Text Uploader",
			"main.tools.textuploader.custom": "Custom",
			"main.tools.textuploader.fileuploader": "File Uploader",
			"main.tools.fileuploader": "File Uploader",
			"main.tools.fileuploader.custom": "Custom",
			"main.tools.urlshortener": "URL Shortener",
			"main.tools.urlshortener": "Custom",
			"main.tools.settings.destination": "Destination Settings",
			"main.tools.settings.application": "Application Settings",
			"main.tools.settings.tasks": "Task Settings",
			"main.tools.history.openfolder": "Open Screenshot Folder",
			"main.tools.history.openviewer": "History",
			"main.tools.about": "About",
			"main.tools.debug": "Debug",
			"main.tools.debug.log": "Debug log",
			"main.tools.debug.test": "Test Services",
			"screenshot.open.url": "URL",
			"screenshot.open.shortened": "Shortened URL",
			"screenshot.open.thumbnail": "Thumbnail URL",
			"screenshot.open.deletion": "Deletion URL",
			"screenshot.open.file": "File",
			"screenshot.open.folder": "Folder",
			"screenshot.open": "Open",
			"screenshot.upload": "Upload",
			"screenshot.deletelocal": "Delete file locally",
			"screenshot.showresponse": "Show response...",
			"screenshot.clearlist": "Clear list",
		])
	];

}
