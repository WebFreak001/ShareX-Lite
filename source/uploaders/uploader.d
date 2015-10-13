module sharex.uploaders.uploader;

import sharex.imagegen;

public import sharex.core.paths;

public import std.net.curl;
import std.stdio : writeln;
import std.file;
import std.path;
import std.digest.sha;
import std.conv : to;
import std.random;
import std.datetime;
import std.format;
import std.string;

import core.thread;

alias UploadDone = void delegate(UploadEvent);
alias HTTPDone = void delegate(string);
alias ProgressChange = void delegate(float);
alias HTTPHeaders = void delegate(HTTP);

void uploadHTTP(string path, string url, HTTP.Method method, string formName, HTTPHeaders headers, ProgressChange onProgress, HTTPDone onDone) in
{
	assert(onProgress !is null, "onProgress can't be null!");
	assert(onDone !is null, "onDone can't be null!");
}
body
{
	string boundary = "--------" ~ sha1Of(to!string(uniform(0, int.max))).toHexString().idup ~ sha1Of(to!string(uniform(0, int.max))).toHexString().idup;

	string data = "";
	string file = path.baseName;
	string extension = file.extension;
	data ~= "--" ~ boundary ~ "\r\n";
	data ~= "Content-Disposition: form-data; name=\"" ~ formName ~ "\"; filename=\"" ~ file ~ "\"\r\n";
	data ~= "Content-Type: image/png\r\n\r\n";
	data ~= cast(ubyte[]) read(path);
	data ~= "\r\n--" ~ boundary ~ "--\r\n\r\n";

	auto conn = HTTP();
    conn.url = url;
    conn.method = method;
	conn.setUserAgent("ShareXLite/1.0.0");

	string received;
	conn.onReceive = (ubyte[] data) {
		received ~= (cast(char[]) data).idup;
		return data.length;
	};
	conn.onProgress = (size_t dltotal, size_t dlnow, size_t ultotal, size_t ulnow) {
		onProgress((ulnow + dlnow) / cast(float) (ultotal + dltotal));
		return 0;
	};

	conn.contentLength = data.length;
	conn.setPostData(data, "multipart/form-data; boundary=" ~ boundary);

	headers(conn);

    conn.perform();

	onDone(received);
}

enum UploadType : ubyte
{
	text,
	image,
	file,
	url
}

struct UploadEvent
{
	bool success;

	string response;

	string url;
	string thumbnailUrl;
	string deletionUrl;
	string shortenedUrl;
}

struct UploadJob
{
	UploadDone onDone;
	ProgressChange onProgress;
	Thread thread;

	string previewFile;
	string title;
	string url;
	string thumbnailUrl;
	string deletionUrl;
	float progress;
}

interface Uploader
{
	@property bool canUploadImage();
	@property bool canUploadFile();
	@property bool canUploadText();

	UploadJob* uploadImage(Bitmap bmp);
	UploadJob* uploadImage(string file);

	UploadJob* uploadFile(string file);

	UploadJob* uploadText(string text);
}

static Uploader[] uploaders;
