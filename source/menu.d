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
		auto content = new Box(window);
		content.padding_top = 64;
		content.padding_bottom = 64;
		content.padding_left = 64;
		content.padding_right = 64;
		console = new Textbox(content, &SubmitCmd);
		new Button(content,"Submit",&SubmitCmd);
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
