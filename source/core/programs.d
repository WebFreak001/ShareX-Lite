module sharex.core.programs;

version(Posix)
{
	import std.process;
	import core.thread;

	void openURL(string url)
	{
		new Thread({
			version(OSX)
			{
				auto pid = spawnProcess(["open", url]);
				if(wait(pid) != 0)
				{
					throw new Exception("Could not open URL");
				}
			}
			else
			{
				auto pid = spawnProcess(["xdg-open", url]);
				assert(!wait(pid), "Please install xdg-open");
			}
		}).start();
	}
}
else version(Windows)
{
	import core.sys.windows.windows;

extern(Windows)
	void openURL(string url)
	{
		new Thread({
			ShellExecute(null, "start", url, null, null, SW_SHOWNORMAL);
		}).start();
	}
}
else
{
	static assert(0);
}
