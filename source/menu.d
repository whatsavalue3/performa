import dgui;

class MenuPanel : Panel
{
	this(Panel p)
	{
		super(p);
		new Button(this,"Map editor",&LaunchMapEditor);
	}
	
	
	void LaunchMapEditor()
	{
		
	}
}