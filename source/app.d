import gtk.Main;

import sharex.selection;
import sharex.forms.mainform;

void main(string[] args)
{
	Main.init(args);
	new MainForm(); // Magically working because of MainWindow
	Main.run();
}
