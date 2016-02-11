module sharex.uploaders.imgur;

import sharex.uploaders.uploader;
import sharex.core.imagegen;
import sharex.core.history;

import std.net.curl;
import std.file;
import std.path;
import std.json;

import tinyevent;

import core.thread;

enum ImgurHostName = "imgur";

shared static this()
{
	uploaders[ImgurHostName] = new ImgurUploader();
}

class ImgurUploader : Uploader
{
	@property bool canUploadImage()
	{
		return true;
	}

	@property bool canUploadFile()
	{
		return false;
	}

	@property bool canUploadText()
	{
		return false;
	}

	UploadJob* uploadImage(Bitmap bmp)
	{
		string f = createScreenshotPath("<auto>.png");
		if (!exists(f.dirName))
		{
			mkdirRecurse(f.dirName);
		}
		bmp.save(f);
		return uploadImage(f);
	}

	UploadJob* uploadImage(string file)
	{
		UploadJob* job = new UploadJob();

		job.previewFile = file;
		job.title = file.baseName;

		job.thread = new Thread(() {
			try
			{
				uploadHTTP(file, "https://api.imgur.com/3/image", HTTP.Method.post, "image", [(HTTP conn) {
					conn.addRequestHeader("Authorization", "Client-ID 0ffffa8ef2b13fc");
				}], [(float progress) { job.onProgress.emit(progress); job.progress = progress; }], [(string content) {
					writeln(content);
					UploadEvent event;
					event.success = true;

					event.response = content;

					try
					{
						JSONValue response = parseJSON(content);

						// {"data":{"error":"Imgur is over capacity. Please try again.","request":"\/3\/image","method":"POST"},"success":false,"status":<number>}
						if (response["success"].type != JSON_TYPE.TRUE)
							throw new Exception(response["data"]["error"].str());

						event.url = response["data"]["link"].str();
						event.deletionUrl = "https://imgur.com/delete/" ~ response["data"]["deletehash"].str();
					}
					catch (Throwable e)
					{
						event.success = false;
						debug throw e;
					}

					job.url = event.url;
					job.thumbnailUrl = event.thumbnailUrl;
					job.deletionUrl = event.deletionUrl;

					appendHistory(file, UploadType.image, ImgurHostName, event.url, event.thumbnailUrl, event.deletionUrl);

					job.onDone.emit(event);
				}]);
			}
			catch (Throwable e)
			{
				writeln(e);
				job.onError.emit(e);
			}
		});

		return job;
	}

	UploadJob* uploadFile(string file)
	{
		throw new Exception("Can't upload files on imgur");
	}

	UploadJob* uploadText(string text)
	{
		throw new Exception("Can't upload text on imgur");
	}
}
