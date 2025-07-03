Command[string] commands;

mixin template RegisterCmd()
{
	static this()
	{
		commands[name] = new typeof(this)();
	}
}

class Command
{
	static string name;
	
	void Call(string[] args)
	{
		
	}
}