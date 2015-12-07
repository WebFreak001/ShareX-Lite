module modules.selector.selection;

import modules.selector.region;

import modules.selector.wmregions;

import cairo.Context;
import cairo.ImageSurface;
import cairo.Pattern;

import gtk.DrawingArea;
import gtk.Widget;
import gtk.Window;
import gtk.MainWindow;
import gtk.Main;

import gdk.Pixbuf;
import gdk.Cairo;
import gdk.Event;
import gdk.Device;
import gdk.Screen;
import gdk.Window : GdkWindow = Window;

import std.string;
import std.math;

import core.thread;

Pixbuf captureAll()
{
	auto root = GdkWindow.getDefaultRootWindow();
	auto width = root.getWidth();
	auto height = root.getHeight();
	return root.getFromWindow(0, 0, width, height);
}

class Selection : MainWindow
{
	SelectionWidget preview;

	this(bool objects)
	{
		super("Capture");

		auto pixbuf = captureAll();

		preview = new SelectionWidget(pixbuf, this, objects);
		add(preview);
		addOnButtonPress(&preview.onButtonPress);
		addOnKeyPress(&preview.onButtonPress);
		addOnButtonRelease(&preview.onButtonRelease);
		addOnKeyRelease(&preview.onButtonRelease);
		addOnMotionNotify(&preview.onMouseMove);
		setDecorated(false);
		setKeepAbove(true);
		setGravity(GdkGravity.NORTH_WEST);
		fullscreen();
		showAll();
		move(0, 0);
		setDefaultSize(pixbuf.getWidth(), pixbuf.getHeight());
		setSizeRequest(pixbuf.getWidth(), pixbuf.getHeight());
		setResizable(false);
		stick();
	}

	@property ref auto onSelected() { return preview.onSelected; }
	@property ref auto success() { return preview.success; }
}

alias SelectionEvent = void delegate(Pixbuf, Region[]);

void fix(ref Region[] regions)
{
	foreach(ref region; regions)
	{
		region.fix();
	}
}

class SelectionWidget : DrawingArea
{
private:
	Pixbuf _img;
	Pattern _scaled;
	Window _window;
	bool _lmb;
	bool _fastCapture = false;
	Region[] _regions;
	size_t _selectedRegion;
	bool _move = false;
	Device _mouse;
	int _mx, _my;
	int _startX, _startY;
	int _time = 0;
	int _radius = 100;
	SelectionEvent _onSelected;
	Region[] _objects;
	bool stop = false;
	bool _success = false;

public:
	this(Pixbuf buf, Window window, bool objects)
	{
		super();
		_img = buf;
		_window = window;
		_mouse = getDisplay().getDeviceManager().getClientPointer();

		if(objects)
			new Thread({ _objects = getObjects(); }).start();

		ImageSurface scaled = ImageSurface.create(CairoFormat.RGB24, _img.getWidth(), _img.getHeight());
		auto ctx = Context.create(scaled);
		ctx.setSourcePixbuf(_img, 0, 0);
		ctx.rectangle(0, 0, _img.getWidth(), _img.getHeight());
		ctx.fill();
		ctx.destroy();

		_scaled = Pattern.createForSurface(scaled);
		_scaled.setFilter(CairoFilter.NEAREST);

		addOnDraw(&onDraw);
	}

	void finish()
	{
		stop = true;
		if(_onSelected !is null && _regions.length > 0)
		{
			_success = true;
			_onSelected(_img, _regions);
		}
		_window.close();
		Main.quit();
	}

	size_t getRegion(int x, int y)
	{
		foreach(i, region; _regions)
		{
			if(x >= region.x && x <= region.x + region.w &&
				y >= region.y && y <= region.y + region.h &&
				region.valid)
				return i;
		}
		return -1;
	}

	size_t getObject(int x, int y)
	{
		foreach(i, region; _objects)
		{
			if(x >= region.x && x <= region.x + region.w &&
				y >= region.y && y <= region.y + region.h &&
				region.valid)
				return i;
		}
		return -1;
	}

	bool onButtonRelease(Event event, Widget widget)
	{
		uint button;
		double x, y;
		if(event.getButton(button) && event.getCoords(x, y))
		{
			if(button == 1)
			{
				_lmb = false;
				if(abs(_startX - x) < 4 && abs(_startY - y) < 4)
				{
					size_t object;
					if((object = getObject(cast(int) round(x), cast(int) round(y))) != -1)
					{
						_regions ~= _objects[object];
					}
				}
				else
				{
					_regions.fix();
					_regions.removeTiny();
					if(_fastCapture)
					{
						finish();
					}
				}
			}
			if(button == 3)
			{
				int rx = cast(int) round(x);
				int ry = cast(int) round(y);
				_selectedRegion = getRegion(rx, ry);
				if(_selectedRegion == -1)
				{
					stop = true;
					_window.close();
					Main.quit();
				}
				else
				{
					_regions[_selectedRegion].w = 0;
					_regions.removeTiny();
				}
			}
			return false;
		}
		ushort key;
		if(event.getKeycode(key))
		{
			if(key == 9) // Escape
			{
				stop = true;
				_window.close();
				Main.quit();
			}
			if(key == 36) // Return
				finish();
			return false;
		}
		return true;
	}

	bool onButtonPress(Event event, Widget widget)
	{
		uint button;
		double x, y;
		if(event.getButton(button) && event.getCoords(x, y))
		{
			if(button == 1)
			{
				int rx = cast(int) round(x);
				int ry = cast(int) round(y);
				_startX = rx;
				_startY = ry;
				_selectedRegion = getRegion(rx, ry);
				if(_selectedRegion == -1)
				{
					_move = false;
					Region region;
					region.x = rx;
					region.y = ry;
					region.w = 0;
					region.h = 0;
					_regions ~= region;
					_selectedRegion = _regions.length - 1;
				}
				else
				{
					_move = true;
				}
				_lmb = true;
			}
			return false;
		}
		ushort key;
		if(event.getKeycode(key))
		{
			if(key == 111) // Up
			{
				Screen screen;
				int cx, cy;
				_mouse.getPosition(screen, cx, cy);
				_mouse.warp(screen, cx, cy - 1);
			}
			if(key == 113) // Left
			{
				Screen screen;
				int cx, cy;
				_mouse.getPosition(screen, cx, cy);
				_mouse.warp(screen, cx - 1, cy);
			}
			if(key == 116) // Down
			{
				Screen screen;
				int cx, cy;
				_mouse.getPosition(screen, cx, cy);
				_mouse.warp(screen, cx, cy + 1);
			}
			if(key == 114) // Right
			{
				Screen screen;
				int cx, cy;
				_mouse.getPosition(screen, cx, cy);
				_mouse.warp(screen, cx + 1, cy);
			}
			return false;
		}
		return true;
	}

	bool onMouseMove(Event event, Widget widget)
	{
		double x, y;
		if(event.getCoords(x, y))
		{
			int rx = cast(int) round(x);
			int ry = cast(int) round(y);

			_mx = rx;
			_my = ry;

			if(_lmb)
			{
				if(_move)
				{
					_regions[_selectedRegion].x = rx;
					_regions[_selectedRegion].y = ry;
				}
				else
				{
					_regions[_selectedRegion].w = rx - _regions[_selectedRegion].x;
					_regions[_selectedRegion].h = ry - _regions[_selectedRegion].y;
				}
			}
			return true;
		}
		return false;
	}

	bool onDraw(Scoped!Context context, Widget widget)
	{
		context.setAntialias(CairoAntialias.NONE);

		context.setSourcePixbuf(_img, 0, 0);
		context.rectangle(0, 0, _img.getWidth(), _img.getHeight());
		context.fill();

		context.setSourceRgba(0, 0, 0, 0.8);
		context.rectangle(0, 0, _img.getWidth(), _img.getHeight());
		context.fill();

		context.setSourcePixbuf(_img, 0, 0);

		foreach(region; _regions)
		{
			if(region.valid)
			{
				region = region.fixCopy();
				context.rectangle(region.x, region.y, region.w, region.h);
				context.fill();
			}
		}

		context.setSourceRgb(1, 1, 1);

		context.setLineWidth(1);
		context.setDash([8, 8], _time);

		auto object = getObject(_mx, _my);

		if(object != -1)
		{
			auto r = _objects[object];
			context.moveTo(r.x + 1, r.y + 1);
			context.lineTo(r.x + r.w, r.y + 1);
			context.lineTo(r.x + r.w, r.y + r.h);
			context.lineTo(r.x + 1, r.y + r.h);
			context.lineTo(r.x + 1, r.y + 1);
			context.stroke();
		}

		foreach(r; _regions)
		{
			if(r.valid)
			{
				r = r.fixCopy();
				context.moveTo(r.x + 1, r.y + 1);
				context.lineTo(r.x + r.w, r.y + 1);
				context.lineTo(r.x + r.w, r.y + r.h);
				context.lineTo(r.x + 1, r.y + r.h);
				context.lineTo(r.x + 1, r.y + 1);
				context.stroke();
			}
		}

		context.moveTo(_mx, 0);
		context.lineTo(_mx, _img.getHeight());
		context.stroke();

		context.moveTo(0, _my);
		context.lineTo(_img.getWidth(), _my);
		context.stroke();

		int magOffX = radius + 8;
		int magOffY = radius + 8;

		if(_mx + 8 + radius + radius > _img.getWidth())
			magOffX = -radius - 8;

		if(_my + 8 + radius + radius > _img.getHeight())
			magOffY = -radius - 8;

		context.arc(_mx + magOffX, _my + magOffY, radius, 0, 6.28318530718f);
		enum scale = 6;
		enum iScale = 1.0 / scale;
		context.scale(scale, scale);
		context.translate(-_mx * (1 - iScale) + magOffX * iScale, -_my * (1 - iScale) + magOffY * iScale);
		context.setSource(_scaled);
		context.fill();
		context.identityMatrix();

		context.setSourceRgb(1, 1, 1);
		context.setDash([scale, scale], magOffX);

		context.moveTo(_mx + magOffX - radius, _my + magOffY);
		context.lineTo(_mx + magOffX + radius, _my + magOffY);
		context.stroke();

		context.moveTo(_mx + magOffX, _my + magOffY - radius);
		context.lineTo(_mx + magOffX, _my + magOffY + radius);
		context.stroke();

		_time++;
		if(!stop)
			this.queueDraw();
		return true;
	}

	@property ref auto onSelected() { return _onSelected; }

	@property ref auto fastCapture() { return _fastCapture; }

	@property ref int radius() { return _radius; }

	@property bool success() { return _success; }
}
