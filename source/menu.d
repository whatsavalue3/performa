import dgui;
import mapeditor;
import client;

class MenuPanel : Panel
{
	Textbox console;
	this()
	{
		//new Button(this,"Map editor",&LaunchMapEditor);
		//new Button(this,"Launch Server",&LaunchServer);
		console = new Textbox(this);
		new Button(this,"Submit",&SubmitCmd);
	}
	
	
	void LaunchMapEditor()
	{
		mainpanel = new MapEditor();
	}
	
	override void PerformLayout()
	{
		PositionChildren();
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
	}
}
