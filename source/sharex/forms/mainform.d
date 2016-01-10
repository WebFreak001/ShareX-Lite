module sharex.forms.mainform;

import gtk.MainWindow;
import gtk.Window;
import gtk.Box;
import gtk.Button;
import gtk.ListBox;
import gtk.ButtonBox;
import gtk.Frame;
import gtk.Label;
import gtk.ComboBoxText;
import gtk.Separator;
import gtk.Widget;
import gtk.Menu;
import gtk.MenuShell;
import gtk.MenuItem;
import gtkc.gtktypes : GtkMenu, GtkAllocation;

import gdk.Event;
import gdk.Pixbuf;

import i18n.text;

import sharex.region;

import derelict.sdl2.sdl;
import derelict.sdl2.mixer;

import sharex.widgets.screenshotentry;

import Selector = sharex.modules.selector;
import Workflow = sharex.workflow.workflow;

import sharex.forms.about;

import sharex.uploaders.uploader;
import sharex.uploaders.imgur;
import sharex.uploaders.default_;

import sharex.config.config;

import sharex.core.paths;
import sharex.core.imagegen;

import std.stdio;
import std.string;
import std.path;
import file = std.file;

import core.thread;

struct PositionEvent
{
	MainForm form;
	Button button;
}

extern (C) void positionMenu(GtkMenu* menu, int* outx, int* outy, int* pushIn, void* userData)
{
	PositionEvent* evt = cast(PositionEvent*) userData;
	int x, y;
	int winX, winY;
	GtkAllocation size;
	evt.form.getPosition(winX, winY);
	evt.button.getAllocation(size);
	evt.button.translateCoordinates(evt.form, 0, 0, x, y);
	x += size.width + winX;
	y += winY + 24; // offset menu y by +24
	writeln("X: ", x, " Y: ", y);
	*outx = x;
	*outy = y;
}

class MainForm : MainWindow
{
private:
	Mix_Chunk* screenshotSound;
	ListBox screenshots;
	bool selecting;
	Bitmap selectedBitmap;

public:
	this()
	{
		super("ShareX Lite");
		setDefaultSize(800, 0);
		addComponents();
		showAll();

		Selector.initModule();

		DerelictSDL2.load();
		DerelictSDL2Mixer.load();

		Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);

		screenshotSound = Mix_LoadWAV("res/capture.wav");
		if (!screenshotSound)
			writeln("Failed to load screenshot sound!\n", Mix_GetError().fromStringz());
		Mix_AllocateChannels(1);

	}

	Bitmap* captureFullscreen()
	{
		return Selector.captureFullscreen();
	}

	Bitmap* captureRegion()
	{
		scope (exit)
			std.stdio.writeln("Focus back");
		return Selector.captureRegion();
	}

	Bitmap* captureRegionObjects()
	{
		return Selector.captureObjects();
	}

	void saveScreenshot(Bitmap bmp)
	{
		string f = createScreenshotPath("<auto>.png");
		if (!file.exists(f.dirName))
		{
			file.mkdirRecurse(f.dirName);
		}
		bmp.save(f);
	}

	void addJob(UploadJob* job)
	{
		auto entry = new ScreenshotEntry(job);
		screenshots.insert(entry, -1);
		screenshots.showAll();
	}

private:
	void processSelection(Pixbuf image, Region[] regions)
	{
		selecting = false;
		selectedBitmap = createBitmap(image, regions);
	}

	void processBitmap(Bitmap bmp)
	{
		if (Mix_PlayChannel(0, screenshotSound, 0) == -1)
			writeln("Failed to play screenshot sound!\n", Mix_GetError().fromStringz());

		/*auto job = imgur.uploadImage(bmp);
		auto entry = new ScreenshotEntry(job);
		screenshots.insert(entry, -1);
		screenshots.showAll();*/
	}

	void btnCapture_changed(MenuItem item)
	{
		if (item && !item.getSubmenu())
		{
			if (item.getActionName().length > 0)
			{
				GeneralConfig config = cast(GeneralConfig) configProviders["general"];
				config.load();
				auto data = config.data;
				auto addJob = &this.addJob;
				switch (item.getActionName())
				{
				case "fullscreen":
					new Thread({ auto bmp = *captureFullscreen(); uploadImage(addJob, data, bmp); }).start();
					break;
				case "region":
					new Thread({ uploadImage(addJob, data, *captureRegion()); }).start();
					break;
				case "objects":
					new Thread({ uploadImage(addJob, data, *captureRegionObjects()); }).start();
					break;
				default:
					throw new Exception("Not Implemented");
				}
			}
		}
	}

	void btnWorkflow_changed(MenuItem item)
	{
		if (item && !item.getSubmenu())
		{
			if (item.getActionName().length > 0)
			{
				Workflow.workflows[item.getActionName()].run();
			}
		}
	}

	void btnUpload_changed(MenuItem item)
	{
		throw new Exception("Not Implemented");
	}

	void cbDebug_changed(ComboBoxText cb)
	{
		processBitmap(Bitmap([255, 255, 255, 255], 1, 1));
	}

	void btnAbout_click(Button sender)
	{
		new About().run();
	}

	bool onScreenshotRMB(Event event, Widget widget)
	{
		double x, y;
		if (event.getCoords(x, y))
			if (screenshots.getRowAtY(cast(int) y) && screenshots.getRowAtY(cast(int) y).getChild())
				if (cast(ScreenshotEntry) screenshots.getRowAtY(cast(int) y).getChild())
					(cast(ScreenshotEntry) screenshots.getRowAtY(cast(int) y).getChild()).onRMB(event, widget);
		return false;
	}

	Menu buildMenu(string[] names, string[] identifiers, void delegate(MenuItem) callback)
	{
		Menu menu = new Menu();
		assert(names.length == identifiers.length, "Texts and identifiers don't match!");
		foreach (i, name; names)
			menu.append(new MenuItem(name, callback, identifiers[i]));
		menu.showAll();
		return menu;
	}

	void linkMenu(Button button, Menu menu)
	{
		button.addOnClicked((btn) { menu.popup(null, null, &positionMenu, cast(void*) new PositionEvent(this, button), 1, 0); });
	}

	void addComponents()
	{
		Box main = new Box(Orientation.HORIZONTAL, 0);

		Box toolPanel = new Box(Orientation.VERTICAL, 8);

		Box uploadPanel = new Box(Orientation.VERTICAL, 0);
		Box settingsPanel = new Box(Orientation.VERTICAL, 0);
		Box miscPanel = new Box(Orientation.VERTICAL, 0);

		// https://dl.dropboxusercontent.com/u/14076298/ShareX/2015/09/c4fH7nEkeR.mp4
		Button btnCapture = new Button(strings.main_tools_capture);
		linkMenu(btnCapture, buildMenu([strings.main_tools_capture_fullscreen, strings.main_tools_capture_window, // TODO: Needs to be a submenu listing open windows
		strings.main_tools_capture_region,
			strings.main_tools_capture_objects,], ["fullscreen", "", "region", "objects"], &btnCapture_changed));

		uploadPanel.add(btnCapture);

		auto btnUpload = new Button(strings.main_tools_upload);
		linkMenu(btnUpload, buildMenu([strings.main_tools_upload_file, strings.main_tools_upload_folder, strings.main_tools_upload_clipboard,
			strings.main_tools_upload_url], ["file", "folder", "clipboard", "url"], &btnUpload_changed));
		uploadPanel.add(btnUpload);

		auto btnTools = new Button(strings.main_tools_tools);
		linkMenu(btnTools, buildMenu([strings.main_tools_tools_colorpicker, strings.main_tools_tools_screencolorpicker, strings.main_tools_tools_hashcheck,
			strings.main_tools_tools_ruler, strings.main_tools_tools_indexfolder], ["colorpicker", "screencolorpicker", "hashcheck", "ruler", "indexfolder"], &btnUpload_changed));
		uploadPanel.add(btnTools);

		auto btnWorkflows = new Button(strings.main_tools_workflows);
		string[] workflows;
		foreach (name, handler; Workflow.workflows)
			workflows ~= name;
		linkMenu(btnWorkflows, buildMenu(workflows, workflows, &btnWorkflow_changed));
		uploadPanel.add(btnWorkflows);

		toolPanel.add(uploadPanel);
		toolPanel.add(new Separator(Orientation.HORIZONTAL));

		auto btnAfterCapture = new Button("After Capture");
		linkMenu(btnAfterCapture, buildMenu(["Open in Editor", "Copy Image to Clipboard", "Save Image to File", "Upload Image", "Delete File locally"], ["",
			"", "", "", ""], &btnUpload_changed));
		settingsPanel.add(btnAfterCapture);

		auto btnAfterUpload = new Button("After Upload");
		linkMenu(btnAfterUpload, buildMenu(["Shorten URL", "Copy URL to clipboard", "Open URL"], ["", "", ""], &btnUpload_changed));
		settingsPanel.add(btnAfterUpload);

		settingsPanel.add(new Button("Destination Settings"));
		settingsPanel.add(new Button("Application Settings"));
		settingsPanel.add(new Button("Task Settings"));

		toolPanel.add(settingsPanel);
		toolPanel.add(new Separator(Orientation.HORIZONTAL));

		miscPanel.add(new Button("Open Screenshots Folder"));
		miscPanel.add(new Button("History"));
		Button btnAbout = new Button("About");
		btnAbout.addOnClicked(&btnAbout_click);
		miscPanel.add(btnAbout);

		auto btnDebug = new Button("Debug");
		linkMenu(btnDebug, buildMenu(["Debug log", "Test Services"], ["log", "test-services"], &btnUpload_changed));
		miscPanel.add(btnDebug);

		toolPanel.add(miscPanel);

		screenshots = new ListBox();
		screenshots.addOnButtonPress(&onScreenshotRMB);

		Frame screenshotPanel = new Frame(screenshots, "Screenshots");
		main.packStart(toolPanel, false, false, 2);
		main.packEnd(screenshotPanel, true, true, 2);

		add(main);
	}
}
