module sharex.uploaders.default_;

import sharex.uploaders.uploader;
import sharex.config.general;
import sharex.core.imagegen;
import sharex.app;
import core.thread;

import std.path;
import std.file;
import std.regex;
import std.string;
import std.algorithm;
import std.traits;

auto doJob(alias fn, S...)(void delegate(UploadJob*) addJob, S args)
{
	auto job = fn(args);
	assert(job);
	addJob(job);
	return job;
}

alias uploadImage = doJob!(uploadImageImpl, Bitmap);
alias uploadImage = doJob!(uploadImageImpl, string);
alias uploadFile = doJob!(uploadFileImpl, string);
alias uploadText = doJob!(uploadTextImpl, string);
alias shortenURL = doJob!(shortenURLImpl, string);

string saveImage(Bitmap bmp)
{
	string f = createScreenshotPath("<auto>.png");
	if (!exists(f.dirName))
	{
		mkdirRecurse(f.dirName);
	}
	bmp.save(f);
	return f;
}

UploadJob* uploadImageImpl(Bitmap bmp)
{
	string f = createScreenshotPath("<auto>.png");
	if (!exists(f.dirName))
	{
		mkdirRecurse(f.dirName);
	}
	bmp.save(f);
	return uploadImageImpl(f);
}

UploadJob* uploadImageImpl(string file)
{
	foreach (name; generalConfig.data.uploaders.imageUploader)
	{
		UploadJob* job;
		if (name == ":special")
		{
			job = handleSpecialImpl("image", file);
		}
		else
		{
			job = uploaders[name].uploadImage(file);
		}
		if (job)
			return job;
		if (!generalConfig.data.uploaders.fallthroughServices)
			throw new Exception("Could not upload image");
	}
	if (!generalConfig.data.uploaders.fallbackToFileUploader)
		throw new Exception("Could not upload image");
	return uploadFileImpl(file);
}

UploadJob* uploadFileImpl(string file)
{
	foreach (name; generalConfig.data.uploaders.fileUploader)
	{
		UploadJob* job;
		if (name == ":special")
		{
			job = handleSpecialImpl("file", file);
		}
		else
		{
			job = uploaders[name].uploadFile(file);
		}
		if (job)
			return job;
		if (!generalConfig.data.uploaders.fallthroughServices)
			throw new Exception("Could not upload file");
	}
	throw new Exception("Could not upload file");
}

UploadJob* uploadTextImpl(string text)
{
	foreach (name; generalConfig.data.uploaders.textUploader)
	{
		UploadJob* job;
		if (name == ":special")
		{
			job = handleSpecialImpl("text", text);
		}
		else
		{
			job = uploaders[name].uploadText(text);
		}
		if (job)
			return job;
		if (!generalConfig.data.uploaders.fallthroughServices)
			throw new Exception("Could not upload text");
	}
	if (!generalConfig.data.uploaders.fallbackToFileUploader)
		throw new Exception("Could not upload image");
	string f = createScreenshotPath("<auto>.txt");
	if (!exists(f.dirName))
	{
		mkdirRecurse(f.dirName);
	}
	write(f, text);
	return uploadFileImpl(f);
}

UploadJob* shortenURLImpl(string url)
{
	foreach (name; generalConfig.data.uploaders.linkShortener)
	{
		UploadJob* job;
		if (name == ":special")
		{
			job = handleSpecialImpl("link", url);
		}
		else
		{
			job = uploaders[name].uploadText(url);
		}
		if (job)
			return job;
		if (!generalConfig.data.uploaders.fallthroughServices)
			throw new Exception("Could not shorten url");
	}
	throw new Exception("Could not shorten url");
}

UploadJob* handleSpecialImpl(string type, string data)
{
	foreach (key, value; generalConfig.data.uploaders.specialUploaders)
	{
		auto pos = key.indexOf(' ');
		string[] types = key[0 .. pos].split('/');
		auto r = regex(key[pos + 1 .. $]);
		if (types.canFind(type))
		{
			if (data.matchFirst(r))
			{
				throw new Exception("Special not implemented");
			}
		}
	}
	return null;
}
