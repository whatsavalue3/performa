import dgui;
import mapeditor;

class MenuPanel : Panel
{
	this()
	{
		new Button(this,"Map editor",&LaunchMapEditor);
	}
	
	
	void LaunchMapEditor()
	{
		mainpanel = new MapEditor();
	}
	
	override void PerformLayout()
	{
		PositionChildren();
	}
}
