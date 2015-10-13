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

import gdk.Event;
import gdk.Pixbuf;

import sharex.region;
import sharex.imagegen;
import sharex.language;

import derelict.sdl2.sdl;
import derelict.sdl2.mixer;

import sharex.widgets.screenshotentry;

import sharex.forms.selection;
import sharex.forms.about;

import sharex.uploaders.uploader;
import sharex.uploaders.imgur;

import std.stdio;
import std.string;

class MainForm : MainWindow
{
private:
	Mix_Chunk* screenshotSound;
	ListBox screenshots;
	ImgurUploader imgur;

public:
	this()
	{
		super("ShareX Lite");
		setDefaultSize(800, 480);
		addComponents();
		showAll();

		DerelictSDL2.load();
		DerelictSDL2Mixer.load();

		Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 1024);

		screenshotSound = Mix_LoadWAV("res/capture.wav");
		if(!screenshotSound)
			writeln("Failed to load screenshot sound!\n", Mix_GetError().fromStringz());
		Mix_AllocateChannels(1);

		imgur = new ImgurUploader();
	}

	void captureFullscreen()
	{
		auto pixbuf = captureAll();
		processBitmap(Bitmap(cast(ubyte[]) pixbuf.getPixels()[0 .. pixbuf.getWidth() * pixbuf.getHeight() * 3], pixbuf.getWidth(), pixbuf.getHeight()));
	}

	void captureRegion()
	{
		Selection selection = new Selection();
		selection.onSelected = &processSelection;
	}

private:
	void processSelection(Pixbuf image, Region[] regions)
	{
		processBitmap(createBitmap(image, regions));
	}

	void processBitmap(Bitmap bmp)
	{
		if(Mix_PlayChannel(0, screenshotSound, 0) == -1)
			writeln("Failed to play screenshot sound!\n", Mix_GetError().fromStringz());

		auto job = imgur.uploadImage(bmp);
		auto entry = new ScreenshotEntry(job);
		screenshots.insert(entry, -1);
		screenshots.showAll();
	}

	void cbCapture_changed(ComboBoxText cb)
	{
		if(cb.getActiveText() != getLanguage["main.tools.capture"])
		{
			if(cb.getActiveText() == getLanguage["main.tools.capture.fullscreen"])
				captureFullscreen();
			else if(cb.getActiveText() == getLanguage["main.tools.capture.region"])
				captureRegion();
			else
				throw new Exception("Not Implemented");
			cb.setActiveText(getLanguage["main.tools.capture"]);
		}
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
		if(event.getCoords(x, y))
			if(screenshots.getRowAtY(cast(int) y) && screenshots.getRowAtY(cast(int) y).getChild())
				if(cast(ScreenshotEntry) screenshots.getRowAtY(cast(int) y).getChild())
					(cast(ScreenshotEntry) screenshots.getRowAtY(cast(int) y).getChild()).onRMB(event, widget);
		return false;
	}

	void addComponents()
	{
		Box main = new Box(Orientation.HORIZONTAL, 0);

		Box toolPanel = new Box(Orientation.VERTICAL, 8);

		Box uploadPanel = new Box(Orientation.VERTICAL, 0);
		Box settingsPanel = new Box(Orientation.VERTICAL, 0);
		Box miscPanel = new Box(Orientation.VERTICAL, 0);

		// https://dl.dropboxusercontent.com/u/14076298/ShareX/2015/09/c4fH7nEkeR.mp4
		ComboBoxText cbCapture = new ComboBoxText(false);
		cbCapture.insertText(-1, getLanguage["main.tools.capture"]);
		cbCapture.insertText(-1, getLanguage["main.tools.capture.fullscreen"]);
		cbCapture.insertText(-1, getLanguage["main.tools.capture.window"]);
		cbCapture.insertText(-1, getLanguage["main.tools.capture.region"]);
		cbCapture.insertText(-1, getLanguage["main.tools.capture.objects"]);
		cbCapture.setActiveText(getLanguage["main.tools.capture"]);
		cbCapture.addOnChanged(&cbCapture_changed);

		uploadPanel.add(cbCapture);

		ComboBoxText cbUpload = new ComboBoxText(false);
		cbUpload.insertText(-1, getLanguage["main.tools.upload"]);
		cbUpload.insertText(-1, getLanguage["main.tools.upload.file"]);
		cbUpload.insertText(-1, getLanguage["main.tools.upload.folder"]);
		cbUpload.insertText(-1, getLanguage["main.tools.upload.clipboard"]);
		cbUpload.insertText(-1, getLanguage["main.tools.upload.url"]);
		cbUpload.setActiveText(getLanguage["main.tools.upload"]);
		uploadPanel.add(cbUpload);

		ComboBoxText cbTools = new ComboBoxText(false);
		cbTools.insertText(-1, getLanguage["main.tools.tools"]);
		cbTools.insertText(-1, getLanguage["main.tools.tools.colorpicker"]);
		cbTools.insertText(-1, getLanguage["main.tools.tools.screencolorpicker"]);
		cbTools.insertText(-1, getLanguage["main.tools.tools.hashcheck"]);
		cbTools.insertText(-1, getLanguage["main.tools.tools.ruler"]);
		cbTools.insertText(-1, getLanguage["main.tools.tools.indexfolder"]);
		cbTools.setActiveText(getLanguage["main.tools.tools"]);
		uploadPanel.add(cbTools);

		toolPanel.add(uploadPanel);
		toolPanel.add(new Separator(Orientation.HORIZONTAL));

		ComboBoxText cbAfterCapture = new ComboBoxText(false);
		cbAfterCapture.insertText(-1, "After Capture");
		cbAfterCapture.insertText(-1, "Open in Editor");
		cbAfterCapture.insertText(-1, "Copy Image to Clipboard");
		cbAfterCapture.insertText(-1, "Save Image to File");
		cbAfterCapture.insertText(-1, "Upload Image");
		cbAfterCapture.insertText(-1, "Delete File locally");
		cbAfterCapture.setActiveText("After Capture");
		settingsPanel.add(cbAfterCapture);

		ComboBoxText cbAfterUpload = new ComboBoxText(false);
		cbAfterUpload.insertText(-1, "After Upload");
		cbAfterUpload.insertText(-1, "Shorten URL");
		cbAfterUpload.insertText(-1, "Copy URL to clipboard");
		cbAfterUpload.insertText(-1, "Open URL");
		cbAfterUpload.setActiveText("After Upload");
		settingsPanel.add(cbAfterUpload);

		ComboBoxText cbImageUploader = new ComboBoxText(false);
		cbImageUploader.insertText(-1, "Image Uploader");
		cbImageUploader.insertText(-1, "Imgur");
		cbImageUploader.insertText(-1, "Custom");
		cbImageUploader.insertText(-1, "File Uploader");
		cbImageUploader.setActiveText("Image Uploader");
		settingsPanel.add(cbImageUploader);

		ComboBoxText cbTextUploader = new ComboBoxText(false);
		cbTextUploader.insertText(-1, "Text Uploader");
		cbTextUploader.insertText(-1, "Pastebin");
		cbTextUploader.insertText(-1, "Custom");
		cbTextUploader.insertText(-1, "File Uploader");
		cbTextUploader.setActiveText("Text Uploader");
		settingsPanel.add(cbTextUploader);

		ComboBoxText cbFileUploader = new ComboBoxText(false);
		cbFileUploader.insertText(-1, "File Uploader");
		cbFileUploader.insertText(-1, "FTP");
		cbFileUploader.insertText(-1, "Custom");
		cbFileUploader.setActiveText("File Uploader");
		settingsPanel.add(cbFileUploader);

		ComboBoxText cbUrlShortener = new ComboBoxText(false);
		cbUrlShortener.insertText(-1, "URL Shortener");
		cbUrlShortener.insertText(-1, "bit.ly");
		cbUrlShortener.insertText(-1, "goo.gl");
		cbUrlShortener.insertText(-1, "Custom");
		cbUrlShortener.setActiveText("URL Shortener");
		settingsPanel.add(cbUrlShortener);

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

		ComboBoxText cbDebug = new ComboBoxText(false);
		cbDebug.insertText(-1, "Debug");
		cbDebug.insertText(-1, "Debug log");
		cbDebug.insertText(-1, "Test Services");
		cbDebug.setActiveText("Debug");
		cbDebug.addOnChanged(&cbDebug_changed);
		miscPanel.add(cbDebug);

		toolPanel.add(miscPanel);

		screenshots = new ListBox();
		screenshots.addOnButtonPress(&onScreenshotRMB);

		Frame screenshotPanel = new Frame(screenshots, "Screenshots");
		main.packStart(toolPanel, false, false, 2);
		main.packEnd(screenshotPanel, true, true, 2);

		add(main);
	}
}
