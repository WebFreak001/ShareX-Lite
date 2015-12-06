module modules.selector.wmregions;

import modules.selector.region;

import std.string;

version(Posix)
{
	import x11.Xlib;
	import x11.Xatom;
	import X = x11.X;
}

Region[] getObjects()
{
	Region[] regions;
	version(Posix)
	{
		auto display = XOpenDisplay(cast(char*) ":0".toStringz);
		if(!display)
			return [];
		auto root = XDefaultRootWindow(display);
		if(!root)
			return [];

		X.Atom actual_type;
		int actual_format;
		ulong num_items, bytes_after;
		uint num_children;
		X.Window* result, children_return;
		X.Window child, root_return, parent;

		XGetWindowProperty(display, root, XInternAtom(display, "_NET_CLIENT_LIST_STACKING", false), 0, 32768, false, XA_WINDOW, &actual_type, &actual_format, &num_items, &bytes_after, cast(ubyte**) &result);

		XWindowAttributes info;
		int x, y, igarbage;
		uint w, h, border, garbage;

		for(int i = cast(int) num_items - 1; i >= 0; i--)
		{
			XTranslateCoordinates(display, result[i], root, 0, 0, &x, &y, &child);
			XGetWindowAttributes(display, result[i], &info);

			if(info.depth > 0 && info.c_class == X.InputOutput)
			{
				XQueryTree(display, result[i], &root_return, &parent, &children_return, &num_children);
				XGetGeometry(display, parent, &root_return, &igarbage, &igarbage, &w, &h, &border, &garbage);
				// This includes the border now
				regions ~= Region(x - info.x, y - info.y, w, h);
			}
		}

		XFree(result);
	}
	else
	{
		// TODO: Implement getting windows on other platforms
		static assert(0);
	}
	regions.removeTiny();
	return regions;
}
