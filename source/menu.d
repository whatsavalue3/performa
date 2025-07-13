import dguiw;
import mapeditor;
import client;

class MenuPanel : RootPanel
{
	Textbox console;
	this()
	{
		//new Button(this,"Map editor",&LaunchMapEditor);
		//new Button(this,"Launch Server",&LaunchServer);
		auto window = new Window(this, false);
		auto content = new Panel(window);
		console = new Textbox(content, &SubmitCmd);
		Button b = new Button(content,"Submit",&SubmitCmd);
		console.width = 256;
		console.height = 16;
		b.width = 64;
		b.height = 16;
		b.x = 256;
	}
	
	
	void LaunchMapEditor()
	{
		//mainpanel = new MapEditor();
	}
	
	//void LaunchServer()
	//{
		//ms.Listen(2324);
		//sv.Listen(2323);
		//server.LoadMap();
	//}
	
	void SubmitCmd()
	{
		client.Exec(console.text);
		console.text = "";
	}
}
