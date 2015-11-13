module sharex.core.clipboard;

import sharex.core.imagegen;

import gdk.Pixbuf;

import gtk.Clipboard;

void setText(string text)
{
	Clipboard.get(null).setText(text, cast(int) text.length);
}

void setImage(Bitmap bmp)
{
	Clipboard.get(null).setImage(bmp.toPixbuf());
}

void setImage(Pixbuf buf)
{
	Clipboard.get(null).setImage(buf);
}
