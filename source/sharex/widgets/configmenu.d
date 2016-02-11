module sharex.widgets.configmenu;

import gtk.Menu;
import gtk.CheckMenuItem;

import tinyevent;

private template ConfigMenuCtor(alias Name, alias Description, T...)
{
	enum line = "_" ~ Name ~ " = new CheckMenuItem(`" ~ Description ~ "`);
	             _" ~ Name ~ ".addOnToggled((btn) { onChange.emit(btn); });
	             append(_" ~ Name ~ ");";
	static if (T.length == 0)
		enum ConfigMenuCtor = line;
	else static if (T.length == 1)
		static assert(0, "Invalid ConfigMenu values");
	else
		enum ConfigMenuCtor = line ~ "\n" ~ ConfigMenuCtor!T;
}

private template ConfigMenuBody(alias Name, alias Description, T...)
{
	enum line = "private CheckMenuItem _" ~ Name ~ ";
	             public bool " ~ Name ~ "() @property { return _" ~ Name ~ ".getActive(); }
	             public void " ~ Name ~ "(bool val) @property { _" ~ Name ~ ".setActive(val); }
	             public CheckMenuItem " ~ Name ~ "Item() @property { return _" ~ Name ~ "; }";
	static if (T.length == 0)
		enum ConfigMenuBody = line;
	else static if (T.length == 1)
		static assert(0, "Invalid ConfigMenu values");
	else
		enum ConfigMenuBody = line ~ "\n" ~ ConfigMenuBody!T;
}

class ConfigMenu(T...) : Menu
{
	static assert(T.length > 1, "ConfigMenu must have at least one pair of name/description");

	mixin(ConfigMenuBody!T);
	
	this()
	{
		super();
		mixin(ConfigMenuCtor!T);
		showAll();
	}
	
	Event!CheckMenuItem onChange;
}
