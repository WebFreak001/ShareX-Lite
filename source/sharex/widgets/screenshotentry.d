module sharex.widgets.screenshotentry;

import gtk.Box;
import gtk.Label;
import gtk.ProgressBar;
import gtk.Menu;
import gtk.MenuShell;
import gtk.MenuItem;
import gtk.SeparatorMenuItem;
import gtk.Widget;

import gdk.Event;

import std.conv;
import std.math;

import Clipboard = sharex.core.clipboard;
import sharex.core.programs;

import sharex.uploaders.uploader;

import i18n.text;

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
		if (progress > 1)
			progress = 1;
		if (progress < 0)
			progress = 0;
		_progress.setText(to!string(round(progress * 999) / 10) ~ "%");
		_progress.setFraction(progress);
	}

	void onDone(UploadEvent e)
	{
		writeln(e.url);
		url = e.url;
		thumbnailUrl = e.thumbnailUrl;
		deletionUrl = e.deletionUrl;
		shortenedUrl = e.shortenedUrl;
		_progress.setText("100%");
		_progress.setFraction(1.0);
	}

public:
	this(UploadJob* job)
	{
		super(Orientation.HORIZONTAL, 2);

		// https://i.imgur.com/1RQyXOp.png
		_menu = new Menu();
		Menu openMenu = new Menu();
		openMenu.append(new MenuItem(strings.screenshot_open_url, &onMenu, "openurl"));
		openMenu.append(new MenuItem(strings.screenshot_open_shortened, &onMenu, "openshorturl"));
		openMenu.append(new MenuItem(strings.screenshot_open_thumbnail, &onMenu, "openthumburl"));
		openMenu.append(new MenuItem(strings.screenshot_open_deletion, &onMenu, "opendeleteurl"));
		openMenu.append(new SeparatorMenuItem());
		openMenu.append(new MenuItem(strings.screenshot_open_file, &onMenu, "openfile"));
		openMenu.append(new MenuItem(strings.screenshot_open_folder, &onMenu, "openfolder"));
		MenuItem openItem = new MenuItem(strings.screenshot_open, &onMenu, "");
		openItem.setSubmenu(openMenu);
		_menu.append(openItem);

		Menu copyMenu = new Menu();
		copyMenu.append(new MenuItem(strings.screenshot_copy_url, &onMenu, "copyurl"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_shortened, &onMenu, "copyshorturl"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_thumbnail, &onMenu, "copythumburl"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_deletion, &onMenu, "copydeleteurl"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_file, &onMenu, "copyfile"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_image, &onMenu, "copyimage"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_text, &onMenu, "copytext"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_thumbnailfile, &onMenu, "copythumbnailfile"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_thumbnailimage, &onMenu, "copythumbnailimage"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_htmllink, &onMenu, "copyhtmllink"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_htmlimage, &onMenu, "copyhtmlimage"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_htmllinkedimage, &onMenu, "copyhtmllinkedimage"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_bblink, &onMenu, "copybblink"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_bbimage, &onMenu, "copybbimage"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_bblinkedimage, &onMenu, "copybblinkedimage"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_filepath, &onMenu, "copyfilepath"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_filename, &onMenu, "copyfilename"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_filenamewoext, &onMenu, "copyfilenamewoext"));
		copyMenu.append(new MenuItem(strings.screenshot_copy_folder, &onMenu, "copyfolder"));
		MenuItem copyItem = new MenuItem(strings.screenshot_copy, &onMenu, "");
		copyItem.setSubmenu(copyMenu);
		_menu.append(copyItem);

		_menu.append(new MenuItem(strings.screenshot_upload, &onMenu, "reupload"));
		_menu.append(new MenuItem(strings.screenshot_deletelocal, &onMenu, "deletefile"));
		_menu.append(new MenuItem(strings.screenshot_showresponse, &onMenu, "showresponse"));
		_menu.append(new MenuItem(strings.screenshot_clearlist, &onMenu, "clear"));
		_menu.showAll();

		_job = job;
		job.onProgress ~= &onProgress;
		job.onDone ~= &onDone;
		job.thread.start();

		packStart(new Label(job.title), true, true, 2);
		add(_progress = new ProgressBar());
		_progress.setShowText(true);
		_progress.setText("0%");
		_progress.setFraction(job.progress);
	}

	void onMenu(MenuItem item)
	{
		// Must exist and not have a submenu
		if (item && !item.getSubmenu())
		{
			std.stdio.writeln("Clicked ", item.getActionName());
			if (item.getActionName().length > 0) switch (item.getActionName())
			{
			case "openurl":
				if (url.length > 0)
					openURL(url);
				else
					std.stdio.writeln("URL empty"); // TODO: replace with debugger
				break;
			case "openshorturl":
				if (shortenedUrl.length > 0)
					openURL(shortenedUrl);
				else
					std.stdio.writeln("URL empty"); // TODO: replace with debugger
				break;
			case "openthumburl":
				if (thumbnailUrl.length > 0)
					openURL(thumbnailUrl);
				else
					std.stdio.writeln("URL empty"); // TODO: replace with debugger
				break;
			case "opendeleteurl":
				if (deletionUrl.length > 0)
					openURL(deletionUrl);
				else
					std.stdio.writeln("URL empty"); // TODO: replace with debugger
				break;
			case "openfile":
				break;
			case "openfolder":
				break;
			case "reupload":
				break;
			case "deletefile":
				break;
			case "showresponse":
				break;
			case "clear":
				break;
			default:
				throw new Exception("Not implemented action: " ~ item.getActionName());
			}
		}
	}

	bool onRMB(Event event, Widget widget)
	{
		uint button;
		if (event.getButton(button))
		{
			if (button == 3)
			{
				_menu.popup(null, null, null, null, button, event.getTime());
			}
		}
		return true;
	}
}
