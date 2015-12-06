module modules.selector.region;

import std.format;

struct Region
{
	int x, y, w, h;

	void fix()
	{
		if(w < 0)
		{
			x += w;
			w = -w;
		}
		if(h < 0)
		{
			y += h;
			h = -h;
		}
	}

	Region fixCopy()
	{
		Region copy = Region(x, y, w, h);
		copy.fix();
		return copy;
	}

	@property bool valid()
	{
		return w >= 5 && h >= 5;
	}

	string toString() const
	{
		return format("(%s,%s %sx%s)", x, y, w, h);
	}
}

void removeTiny(ref Region[] regions)
{
	Region[] fixed;
	foreach(ref region; regions)
	{
		if(region.valid)
			fixed ~= region;
	}
	regions = fixed;
}
