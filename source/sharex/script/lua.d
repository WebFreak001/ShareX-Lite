module sharex.script.lua;

import core.thread;
import std.process;
import std.stdio;
import std.functional;

import Clipboard = sharex.core.clipboard;

import Selector = sharex.modules.selector;

import sharex.config.config;
import sharex.script.provider;
import sharex.uploaders.default_;
import sharex.core.imagegen;
import sharex.uploaders.uploader;
import sharex.app;

import luad.all;

shared static this()
{
	scriptProviders[".lua"] = new LuaProvider();
}

Pid spawnShellLua(string command)
{
	return spawnShell(command);
}

void spawnShellWaitLua(string command)
{
	auto pid = spawnShell(command);
	wait(pid);
}

void luaSleep(long millis)
{
	import core.thread : Thread;
	import core.time : dur;

	Thread.sleep(dur!"msecs"(millis));
}

private string handleJob(UploadJob* job)
{
	bool isDone = false;
	UploadEvent evnt;
	job.onDone ~= (ev) { isDone = true; evnt = ev; };
	while (!isDone)
	{
		Thread.sleep(50.msecs);
	}
	if (!evnt.success)
		throw new Exception(evnt.response);
	std.stdio.writeln("Finished: ", evnt.url);
	return evnt.url;
}

private void dummyJob(UploadJob* job)
{
}

class LuaProvider : IScriptProvider
{
	void run(string file)
	{
		GeneralConfig config = cast(GeneralConfig) configProviders["general"];
		config.load();
		auto data = config.data;
		auto addJob = toDelegate(&dummyJob);
		if(mainForm !is null)
			addJob = &mainForm.addJob;
		new Thread({
			try
			{
				writeln("Setting up script ", file);
				auto lua = new LuaState;
				lua.openLibs();

				lua["captureFullscreen"] = () {
					auto bmp = Selector.captureFullscreen();
					if (bmp is null)
					{
						lua.doString("error('User Abort')");
						assert(0);
					}
					return cast(size_t) bmp;
				};
				lua["captureRegion"] = () {
					auto bmp = Selector.captureRegion();
					if (bmp is null)
					{
						lua.doString("error('User Abort')");
						assert(0);
					}
					return cast(size_t) bmp;
				};
				lua["captureObjects"] = () {
					auto bmp = Selector.captureObjects();
					if (bmp is null)
					{
						lua.doString("error('User Abort')");
						assert(0);
					}
					return cast(size_t) bmp;
				};
				lua["uploadImage"] = (size_t ptr) {
					if (ptr == 0)
						throw new Exception("Bitmap null");
					return handleJob(uploadImage(&mainForm.addJob, *(cast(Bitmap*) ptr)));
				};
				lua["uploadImage"] = (string path) { return handleJob(uploadImage(addJob, path)); };
				lua["uploadFile"] = (string path) { return handleJob(uploadFile(addJob, path)); };
				lua["uploadText"] = (string path) { return handleJob(uploadText(addJob, path)); };
				lua["shortenURL"] = (string path) { return handleJob(shortenURL(addJob, path)); };

				lua["saveImage"] = (size_t ptr) { if (ptr == 0)
					throw new Exception("Bitmap null"); return saveImage(*(cast(Bitmap*) ptr)); };

				lua["copyText"] = &Clipboard.setText;
				lua["copyImage"] = (size_t ptr) { if (ptr == 0)
					return; Clipboard.setImage(*(cast(Bitmap*) ptr)); };

				lua["sleep"] = &luaSleep;
				lua["run"] = &spawnShellLua;
				lua["runWait"] = &spawnShellWaitLua;
				lua["wait"] = &wait;
				lua["openURL"] = &browse;

				writeln("Running script ", file);

				lua.doFile(file);
			}
			catch (Exception e)
			{
				writeln("Exception in script ", file);
				writeln(e);
			}
		}).start();
	}
}

/+

simple.lua

-- Example Workflow
sleep(0.5)
bitmap = captureObjects()
copyImage(bitmap)
path = saveScreenshot(bitmap)
pid = run("gimp " .. path)
wait(pid)
url = uploadImage(path)
url = shortenURL(url)
copyText(url)
popup(bitmap)
openURL(url)

+/
