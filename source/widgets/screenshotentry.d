module sharex.widgets.screenshotentry;

import gtk.Box;
import gtk.Label;
import gtk.ProgressBar;
import gtk.Menu;
import gtk.MenuItem;
import gtk.SeparatorMenuItem;
import gtk.Widget;

import gdk.Event;

import std.conv;
import std.math;

import sharex.uploaders.uploader;
import sharex.language;

class ScreenshotEntry : Box
{
private:
	UploadJob* _job;
	ProgressBar _progress;
	Menu _menu;

	string url;
	string thumbnailUrl;
	string deletionUrl;
	string shortenedUrl;

	void onProgress(float progress)
	{
		if(progress > 1)
			progress = 1;
		if(progress < 0)
			progress = 0;
		_progress.setText(to!string(round(progress * 1000) / 10) ~ "%");
		_progress.setFraction(progress);
	}

	void onDone(UploadEvent e)
	{
		writeln(e.url);
		url = e.url;
		thumbnailUrl = e.thumbnailUrl;
		deletionUrl = e.deletionUrl;
		shortenedUrl = e.shortenedUrl;
	}

public:
	this(UploadJob* job)
	{
		super(Orientation.HORIZONTAL, 2);

		// https://i.imgur.com/1RQyXOp.png
		_menu = new Menu();
		Menu openMenu = new Menu();
		openMenu.append(new MenuItem(getLanguage["screenshot.open.url"]));
		openMenu.append(new MenuItem(getLanguage["screenshot.open.shortened"]));
		openMenu.append(new MenuItem(getLanguage["screenshot.open.thumbnail"]));
		openMenu.append(new MenuItem(getLanguage["screenshot.open.deletion"]));
		openMenu.append(new SeparatorMenuItem());
		openMenu.append(new MenuItem(getLanguage["screenshot.open.file"]));
		openMenu.append(new MenuItem(getLanguage["screenshot.open.folder"]));
		MenuItem openItem = new MenuItem(getLanguage["screenshot.open"]);
		openItem.setSubmenu(openMenu);
		_menu.append(openItem);
		_menu.append(new MenuItem(getLanguage["screenshot.upload"]));
		_menu.append(new MenuItem(getLanguage["screenshot.deletelocal"]));
		_menu.append(new MenuItem(getLanguage["screenshot.showresponse"]));
		_menu.append(new MenuItem(getLanguage["screenshot.clearlist"]));
		_menu.showAll();

		_job = job;
		job.onProgress = &onProgress;
		job.onDone = &onDone;
		job.thread.start();

		packStart(new Label(job.title), true, true, 2);
		add(_progress = new ProgressBar());
		_progress.setShowText(true);
		_progress.setText("0%");
		_progress.setFraction(job.progress);
	}

	bool onRMB(Event event, Widget widget)
	{
		uint button;
		std.stdio.writeln("Event");
		if(event.getButton(button))
		{
			std.stdio.writeln(button);
			if(button == 3)
			{
				std.stdio.writeln("Open");
				_menu.popup(null, null, null, null, button, event.getTime());
			}
		}
		return true;
	}
}
