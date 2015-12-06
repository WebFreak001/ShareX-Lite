module sharex.core.imagegen;

import sharex.region;

import std.algorithm;

import imageformats;

import gdk.Pixbuf;

struct Bitmap
{
	ubyte[] rgb_pixels;
	int width, height;

	this(ubyte[] pixels, int w, int h)
	{
		rgb_pixels = pixels;
		width = w;
		height = h;
	}

	void create()
	{
		rgb_pixels.length = width * height * 3;
	}

	Pixbuf toPixbuf()
	{
		return new Pixbuf(rgb_pixels, false);
	}

	Pixbuf toPixbufCopy()
	{
		return new Pixbuf(rgb_pixels, true);
	}

	void set(int x, int y, ubyte r, ubyte g, ubyte b)
	{
		if(x >= width || y >= height || x < 0 || y < 0)
			return;
		rgb_pixels[(x + y * width) * 3 + 0] = r;
		rgb_pixels[(x + y * width) * 3 + 1] = g;
		rgb_pixels[(x + y * width) * 3 + 2] = b;
	}

	ubyte[3] get(int x, int y)
	{
		if(x >= width || y >= height || x < 0 || y < 0)
			return cast(ubyte[3]) [0, 0, 0];
		return cast(ubyte[3]) rgb_pixels[(x + y * width) * 3 .. (x + y * width) * 3 + 3][0 .. 3];
	}

	void copyRow(in Bitmap source, int sourceX, int sourceY, int destX, int destY, int destW)
	{
		if(sourceY < 0 || sourceY >= source.height || destY < 0 || destY >= height)
			return;
		int sourceW = destW;
		if(sourceX < 0)
		{
			sourceW += sourceX;
			sourceX = 0;
		}
		if(destX < 0)
		{
			destW += destX;
			destX = 0;
		}
		if(destX + destW >= width)
			destW = width - destX - 1;
		if(sourceX + sourceW >= source.width)
			sourceW = source.width - sourceX - 1;
		if(sourceW > destW)
			sourceW = destW;
		rgb_pixels[(destX + destY * width) * 3 .. (destX + destY * width + destW) * 3 + 3] = 0;
		rgb_pixels[(destX + destY * width) * 3 .. (destX + destY * width + sourceW) * 3 + 3]
			= source.rgb_pixels[(sourceX + sourceY * source.width) * 3 .. (sourceX + sourceY * source.width + sourceW) * 3 + 3];
	}
}

void save(Bitmap bitmap, string file)
{
	imageformats.write_image(file, bitmap.width, bitmap.height, bitmap.rgb_pixels, ColFmt.RGB);
}

Bitmap cutBitmap(Bitmap raw, Region[] regions)
{
	if(regions.length == 0)
		return raw;
	int minX, minY, maxX, maxY;
	minX = regions[0].x;
	minY = regions[0].y;
	maxX = regions[0].x + regions[0].w;
	maxY = regions[0].y + regions[0].h;

	foreach(region; regions)
	{
		minX = min(minX, region.x);
		minY = min(minY, region.y);
		maxX = max(maxX, region.x + region.w);
		maxY = max(maxY, region.y + region.h);
	}

	Bitmap bmp;

	bmp.width = maxX - minX;
	bmp.height = maxY - minY;
	bmp.create();

	foreach(region; regions)
	{
		region.fix();
		for(int y = region.y; y < region.y + region.h; y++)
		{
			// Fast copy
			bmp.copyRow(raw, region.x, y, region.x - minX, y - minY, region.w);
		}
	}

	return bmp;
}

Bitmap createBitmap(Pixbuf img, Region[] regions)
{
	auto raw = Bitmap(cast(ubyte[])(img.getPixels()[0 .. img.getWidth() * img.getHeight() * 3]), img.getWidth(), img.getHeight());
	return cutBitmap(raw, regions);
}
