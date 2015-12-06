module sharex.forms.about;

import gtk.Dialog;
import gtk.AboutDialog;

class About : AboutDialog
{
	this()
	{
		super();

		setProgramName("ShareX Lite");
		setWebsite("https://getsharex.com/Lite");
		setAuthors(["WebFreak001"]);
		addCreditSection("Special Thanks to", ["Jaex"]);
		setVersion("1.0.0");
		setCopyright("Copyright 2015");
		setLicenseType(License.GPL_3_0);

		addOnResponse(&onResponse);
	}

	void onResponse(int i, Dialog d)
	{
		close();
	}
}
