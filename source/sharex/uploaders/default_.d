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

alias uploadImage = doJob!(uploadImageImpl, GeneralConfig.Data, Bitmap);
alias uploadImage = doJob!(uploadImageImpl, GeneralConfig.Data, string);
alias uploadFile = doJob!(uploadFileImpl, GeneralConfig.Data, string);
alias uploadText = doJob!(uploadTextImpl, GeneralConfig.Data, string);
alias shortenURL = doJob!(shortenURLImpl, GeneralConfig.Data, string);

string saveImage(Bitmap bmp)
{
	string f = createScreenshotPath("<auto>.png");
	if(!exists(f.dirName))
	{
		mkdirRecurse(f.dirName);
	}
	bmp.save(f);
	return f;
}

UploadJob* uploadImageImpl(GeneralConfig.Data config, Bitmap bmp)
{
	string f = createScreenshotPath("<auto>.png");
	if(!exists(f.dirName))
	{
		mkdirRecurse(f.dirName);
	}
	bmp.save(f);
	return uploadImageImpl(config, f);
}

UploadJob* uploadImageImpl(GeneralConfig.Data config, string file)
{
	foreach(name; config.imageUploader)
	{
		UploadJob* job;
		if(name == ":special")
		{
			job = handleSpecialImpl(config, "image", file);
		}
		else
		{
			job = uploaders[name].uploadImage(file);
		}
		if(job)
			return job;
		if(!config.fallthroughServices)
			throw new Exception("Could not upload image");
	}
	if(!config.fallbackToFileUploader)
		throw new Exception("Could not upload image");
	return uploadFileImpl(config, file);
}

UploadJob* uploadFileImpl(GeneralConfig.Data config, string file)
{
	foreach(name; config.fileUploader)
	{
		UploadJob* job;
		if(name == ":special")
		{
			job = handleSpecialImpl(config, "file", file);
		}
		else
		{
			job = uploaders[name].uploadFile(file);
		}
		if(job)
			return job;
		if(!config.fallthroughServices)
			throw new Exception("Could not upload file");
	}
	throw new Exception("Could not upload file");
}

UploadJob* uploadTextImpl(GeneralConfig.Data config, string text)
{
	foreach(name; config.textUploader)
	{
		UploadJob* job;
		if(name == ":special")
		{
			job = handleSpecialImpl(config, "text", text);
		}
		else
		{
			job = uploaders[name].uploadText(text);
		}
		if(job)
			return job;
		if(!config.fallthroughServices)
			throw new Exception("Could not upload text");
	}
	if(!config.fallbackToFileUploader)
		throw new Exception("Could not upload image");
	string f = createScreenshotPath("<auto>.txt");
	if(!exists(f.dirName))
	{
		mkdirRecurse(f.dirName);
	}
	write(f, text);
	return uploadFileImpl(config, f);
}

UploadJob* shortenURLImpl(GeneralConfig.Data config, string url)
{
	foreach(name; config.linkShortener)
	{
		UploadJob* job;
		if(name == ":special")
		{
			job = handleSpecialImpl(config, "link", url);
		}
		else
		{
			job = uploaders[name].uploadText(url);
		}
		if(job)
			return job;
		if(!config.fallthroughServices)
			throw new Exception("Could not shorten url");
	}
	throw new Exception("Could not shorten url");
}

UploadJob* handleSpecialImpl(GeneralConfig.Data config, string type, string data)
{
	foreach(key, value; config.specialUploaders)
	{
		auto pos = key.indexOf(' ');
		string[] types = key[0 .. pos].split('/');
		auto r = regex(key[pos + 1 .. $]);
		if(types.canFind(type))
		{
			if(data.matchFirst(r))
			{
				throw new Exception("Special not implemented");
			}
		}
	}
	return null;
}