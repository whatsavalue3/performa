import dgui;
import mapeditor;
import server;

class MenuPanel : Panel
{
	this()
	{
		new Button(this,"Map editor",&LaunchMapEditor);
		new Button(this,"Launch Server",&LaunchServer);
	}
	
	
	void LaunchMapEditor()
	{
		mainpanel = new MapEditor();
	}
	
	override void PerformLayout()
	{
		PositionChildren();
	}
	
	void LaunchServer()
	{
		sv.Listen(2323);
		server.LoadMap();
	}
}
