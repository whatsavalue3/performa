import dguiw;
import bindbc.sdl;
import std.math;
import std.stdio;
import std.algorithm;
import game;
import math;
import rendering;
import client;
import packet;
import std.conv;



class MapPreview : Panel
{
	long selected = -1;
	long selectededge = -1;
	long selectedsector = -1;
	long selectedentity = -1;
	long selectedmodel = -1;
	bool selectedview = false;
	long selectedaction = -1;
	long grid = 8;
	float skew = 0.0f;
	float rot = 0.0f;
	float3 right = ~float3([1.0f,-1.0f,0.0f]);
	float3 up = ~float3([1.0f,1.0f,0.5f]);
	float3 pos = float3([0.0f,0.0f,0.0f]);
	float scale = 1.0f;
	
	float2 Project(float3 p)
	{
		p = (p-pos)*scale;
		return float2([p*right+width/2,p*up+height/2]);
	}
	
	float2 ProjectOffset(float3 p)
	{
		//p = p*scale;
		return float2([p*right,p*up]);
	}
	
	this(Panel p)
	{
		super(p);
	}
	
	void DrawEdge(SDL_Renderer* renderer, Edge edge, bool selected)
	{
		float2 start2 = g.verts[edge.start];
		float2 end2 = g.verts[edge.end];
		
		
		if(selected)
		{
			if(edge.hidden)
			{
				SDL_SetRenderDrawColor(renderer, 32, 64, 127, 255);
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, 64, 127, 255, 255);
			}
		}
		else if(edge.hidden)
		{
			SDL_SetRenderDrawColor(renderer, 64, 64, 64, 255);
		}
		else
		{
			SDL_SetRenderDrawColor(renderer, 255, 127, 64, 255);
		}
		
		float2 start = Project(float3([start2[0],start2[1],-edge.offset]));
		float2 end = Project(float3([end2[0],end2[1],-edge.offset]));
		
		DGUI_DrawLine(renderer,cast(int)(start[0]),cast(int)(start[1]),cast(int)(end[0]),cast(int)(end[1]));
		
		start = Project(float3([start2[0],start2[1],edge.height-edge.offset]));
		end = Project(float3([end2[0],end2[1],edge.height-edge.offset]));
		
		DGUI_DrawLine(renderer,cast(int)(start[0]),cast(int)(start[1]),cast(int)(end[0]),cast(int)(end[1]));
		
		start = Project(float3([start2[0],start2[1],edge.height/2-edge.offset]));
		end = Project(float3([end2[0],end2[1],edge.height/2-edge.offset]));
		
		DGUI_DrawLine(renderer,cast(int)(start[0]),cast(int)(start[1]),cast(int)(end[0]),cast(int)(end[1]));
		
		start = Project(float3([start2[0],start2[1],-edge.offset]));
		end = Project(float3([start2[0],start2[1],edge.height-edge.offset]));
		
		DGUI_DrawLine(renderer,cast(int)(start[0]),cast(int)(start[1]),cast(int)(end[0]),cast(int)(end[1]));
		
		start = Project(float3([end2[0],end2[1],-edge.offset]));
		end = Project(float3([end2[0],end2[1],edge.height-edge.offset]));
		
		DGUI_DrawLine(renderer,cast(int)(start[0]),cast(int)(start[1]),cast(int)(end[0]),cast(int)(end[1]));
	}
	
	override void DrawContent(SDL_Renderer* renderer)
	{
		if(viewent >= g.entities.length)
		{
			return;
		}
		
		right = float3([cos(rot/90.0f),-sin(rot/90.0f),0.0f]);
		up = float3([sin(rot/90.0f)*cos(skew/90.0f),cos(rot/90.0f)*cos(skew/90.0f),sin(skew/90.0f)]);
		
		SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
		DGUI_FillRect(renderer, 0, 0, width, height);
		
		
		
		
		foreach(i, sector; g.sectors)
		{
			if(sector.deleted)
			{
				continue;
			}
			foreach(j, wall1; sector.edges)
			{
				Edge edge1 = g.edges[wall1];
				if(edge1.deleted)
				{
					continue;
				}
				float2 start1 = Project(float3([g.verts[edge1.start][0],g.verts[edge1.start][1],sector.low]));
				float2 end1 = Project(float3([g.verts[edge1.end][0],g.verts[edge1.end][1],sector.low]));
				float2 point1 = (start1+end1)*0.5f;
				float2 start1top = Project(float3([g.verts[edge1.start][0],g.verts[edge1.start][1],sector.high]));
				float2 end1top = Project(float3([g.verts[edge1.end][0],g.verts[edge1.end][1],sector.high]));
				float2 point1top = (start1top+end1top)*0.5f;
				
				float2 normvis = g.EdgeNormalVis(edge1)*0.25f;
				float2 norm = ProjectOffset(float3([normvis[0],normvis[1],0.0f]));
				if(i == selectedsector)
				{
					SDL_SetRenderDrawColor(renderer, 255, 0, 255, 255);
				}
				else
				{
					SDL_SetRenderDrawColor(renderer, 127, 127, 255, 255);
				}
				DGUI_DrawLine(renderer,cast(int)(point1[0]),cast(int)(point1[1]),cast(int)(point1[0]+norm[0]),cast(int)(point1[1]+norm[1]));
				
				if(i == selectedsector)
				{
					SDL_SetRenderDrawColor(renderer, 255, 64, 0, 255);
				}
				else
				{
					SDL_SetRenderDrawColor(renderer, 64, 255, 64, 255);
				}
				foreach(wall2; j..sector.edges.length)
				{
					Edge edge2 = g.edges[sector.edges[wall2]];
					if(edge2.deleted)
					{
						continue;
					}
					
					float2 start2 = Project(float3([g.verts[edge2.start][0],g.verts[edge2.start][1],sector.low]));
					float2 end2 = Project(float3([g.verts[edge2.end][0],g.verts[edge2.end][1],sector.low]));
					
					float2 point2 = (start2+end2)*0.5f;
					DGUI_DrawLine(renderer,cast(int)(point1[0]),cast(int)(point1[1]),cast(int)(point2[0]),cast(int)(point2[1]));
					//DGUI_DrawLine(renderer,cast(int)(end1[0]+width/2),cast(int)(end1[1]+height/2),cast(int)(end2[0]+width/2),cast(int)(end2[1]+height/2));
				}
				foreach(wall2; j..sector.edges.length)
				{
					Edge edge2 = g.edges[sector.edges[wall2]];
					if(edge2.deleted)
					{
						continue;
					}
					
					float2 start2 = Project(float3([g.verts[edge2.start][0],g.verts[edge2.start][1],sector.high]));
					float2 end2 = Project(float3([g.verts[edge2.end][0],g.verts[edge2.end][1],sector.high]));
					
					float2 point2 = (start2+end2)*0.5f;
					DGUI_DrawLine(renderer,cast(int)(point1top[0]),cast(int)(point1top[1]),cast(int)(point2[0]),cast(int)(point2[1]));
					//DGUI_DrawLine(renderer,cast(int)(end1[0]+width/2),cast(int)(end1[1]+height/2),cast(int)(end2[0]+width/2),cast(int)(end2[1]+height/2));
				}
			}
		}
		
		foreach(i, edge; g.edges)
		{
			if(edge.deleted)
			{
				continue;
			}
			DrawEdge(renderer,edge,false);
		}
		if(selectededge != -1)
		{
			DrawEdge(renderer,g.edges[selectededge],true);
		}
		
		foreach(i, vert; g.verts)
		{
			if(i == selected)
			{
				SDL_SetRenderDrawColor(renderer, 96, 192, 255, 255);
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
			}
			
			float2 pos = Project(float3([vert[0],vert[1],0.0f]));
			DGUI_DrawPoint(renderer,cast(int)(pos[0]+1),cast(int)(pos[1]));
			DGUI_DrawPoint(renderer,cast(int)(pos[0]  ),cast(int)(pos[1]+1));
			DGUI_DrawPoint(renderer,cast(int)(pos[0]  ),cast(int)(pos[1]-1));
			DGUI_DrawPoint(renderer,cast(int)(pos[0]-1),cast(int)(pos[1]));
		}
		
		
		
		foreach(i, entity; g.entities)
		{
			if(i == selectedentity)
			{
				SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, cast(ubyte)(clamp(entity.color[0]*255,0.0f,255.0f)), cast(ubyte)(clamp(entity.color[1]*255,0.0f,255.0f)), cast(ubyte)(clamp(entity.color[2]*255,0.0f,255.0f)), 255);
			}
			float2 dir = float2([sin(entity.rot),-cos(entity.rot)]);
			float2 eoff = ProjectOffset(float3([dir[0],dir[1],0.0f]));
			float2 eoffp = ProjectOffset(float3([dir[1],-dir[0],0.0f]));
			float2 epos = Project(entity.pos);
			
			DGUI_DrawLine(renderer,cast(int)(epos[0]),cast(int)(epos[1]),cast(int)(epos[0]+eoff[0]*12-eoffp[0]*4),cast(int)(epos[1]+eoff[1]*12-eoffp[1]*4));
			DGUI_DrawLine(renderer,cast(int)(epos[0]),cast(int)(epos[1]),cast(int)(epos[0]+eoff[0]*12+eoffp[0]*4),cast(int)(epos[1]+eoff[1]*12+eoffp[1]*4));
		}

	}
	
	override void MouseMoved(int cx, int cy, int rx, int ry, bool covered)
	{
		if(covered)
		{
			return;
		}
		if(selected != -1)
		{
			if(DGUI_IsButtonPressed(MouseButton.Left))
			{
				float2 screenpos = float2([cx - width/2,cy - height/2]);
				float2 r = float2([right[0],right[1]])*scale;
				float2 u = float2([up[0],up[1]])*scale;
				//(r*screenpos[0] + u*screenpos[0])*(1.0/(r*r))
				//
				float2 hpos = (r*screenpos[0])*(1.0/(r*r)) + (u*(screenpos[1]+up[2]*pos[2]*scale))*(1.0/(u*u));
				hpos[0] += pos[0];
				hpos[1] += pos[1];
				
				mc.SendPacket(Packet3SetVert(vertid:selected,pos:float2([round(hpos[0]/grid)*grid,round(hpos[1]/grid)*grid])));
				//g.verts[selected][0] = round((cx - width/2)/grid)*grid;
				//g.verts[selected][1] = round((cy - height/2)/grid)*grid;
			}
		}
		if(DGUI_IsButtonPressed(MouseButton.Middle))
		{
			if(inputHandler.shift > 0)
			{
				pos = pos - (right*rx + up*ry)*(1.0f/scale);
			}
			else
			{
				skew += ry;
				rot -= rx;
			}
		}
	}
	
	
	
	override void MousePressed(int cx, int cy, MouseButton button, bool covered)
	{	
		if(covered)
		{
			return;
		}
	
		if(button == MouseButton.Left)
		{
			selected = -1;
			selectededge = -1;
			selectedentity = -1;
			
			foreach(i, vert; g.verts)
			{
				float2 pos = Project(float3([vert[0],vert[1],0.0f]));
				float dist = (abs(pos[0]-cx) + abs(pos[1]-cy));
				if(dist < 12)
				{
					selected = i;
					return;
				}
			}
			
			foreach(i, edge; g.edges)
			{
				if(edge.deleted)
				{
					continue;
				}
				float2 start2 = g.verts[edge.start];
				float2 end2 = g.verts[edge.end];
				float2 start = Project(float3([start2[0],start2[1],edge.height/2-edge.offset]));
				float2 end = Project(float3([end2[0],end2[1],edge.height/2-edge.offset]));
				
				float lx = cx-start[0];
				float ly = cy-start[1];
				float endx = end[0]-start[0];
				float endy = end[1]-start[1];
				float endlen = sqrt(endx*endx+endy*endy);
				float normx = endx/endlen;
				float normy = endy/endlen;
				float forward = normx*lx + normy*ly;
				float side = abs(normx*ly - normy*lx);
				if(forward > 0 && forward < endlen && side < 4)
				{
					selectededge = i;
					return;
				}
			}
			
			float2 presspos = float2([cx,cy]);
			
			foreach_reverse(i, sector; g.sectors)
			{
				if(sector.deleted)
				{
					continue;
				}
				
				foreach(j, edgeindex; sector.edges)
				{
					Edge edge = g.edges[edgeindex];
					if(edge.deleted)
					{
						continue;
					}
					float2 start = Project(float3([g.verts[edge.start][0],g.verts[edge.start][1],sector.low]));
					float2 end = Project(float3([g.verts[edge.end][0],g.verts[edge.end][1],sector.low]));
					float2 point1 = (start+end)*0.5f;
					
					foreach(wall2; j..sector.edges.length)
					{
						Edge edge2 = g.edges[sector.edges[wall2]];
						if(edge2.deleted)
						{
							continue;
						}
						
						float2 start2 = Project(float3([g.verts[edge2.start][0],g.verts[edge2.start][1],sector.low]));
						float2 end2 = Project(float3([g.verts[edge2.end][0],g.verts[edge2.end][1],sector.low]));
						float2 point2 = (start2+end2)*0.5f;
						
						float2 l = presspos-point1;
						float2 diff = point2-point1;
						float diffl = *diff;
						float2 norm = diff*(1.0f/diffl);
						float forward = l*norm;
						float side = abs(norm[1]*l[0] - norm[0]*l[1]);
						if(forward > 0 && forward < diffl && side < 4)
						{
							if(selectedsector == i)
							{
								selectedsector = -1;
							}
							else
							{
								selectedsector = i;
							}
							return;
						}
						//DGUI_DrawLine(renderer,cast(int)(end1[0]+width/2),cast(int)(end1[1]+height/2),cast(int)(end2[0]+width/2),cast(int)(end2[1]+height/2));
					}
				}
			}
			
			foreach(i, entity; g.entities)
			{
				float2 epos = Project(entity.pos);
				if(*(epos - presspos) < 8)
				{
					selectedentity = i;
					return;
				}
			}
		}
		else if(button == MouseButton.Right)
		{
			if(selected != -1)
			{
				foreach(i, vert; g.verts)
				{
					float2 pos = Project(float3([vert[0],vert[1],0.0f]));
					float dist = (abs(pos[0]-(cx)) + abs(pos[1]-(cy)));
					if(dist < 8)
					{
						mc.SendPacket(Packet4AddEdge(edge:Edge(start:selected, end:i, height:4.0f, offset:2.0f, texture:1, deleted:false)));
						return;
					}
				}
			}
			foreach(i, edge; g.edges)
			{
				if(edge.deleted)
				{
					continue;
				}
				float2 start2 = g.verts[edge.start];
				float2 end2 = g.verts[edge.end];
				float2 start = Project(float3([start2[0],start2[1],edge.height/2-edge.offset]));
				float2 end = Project(float3([end2[0],end2[1],edge.height/2-edge.offset]));
				
				float lx = cx-start[0];
				float ly = cy-start[1];
				float endx = end[0]-start[0];
				float endy = end[1]-start[1];
				float endlen = sqrt(endx*endx+endy*endy);
				float normx = endx/endlen;
				float normy = endy/endlen;
				float forward = normx*lx + normy*ly;
				float side = abs(normx*ly - normy*lx);
				if(forward > 0 && forward < endlen && side < 4)
				{
					if(inputHandler.shift > 0)
					{
						ExtrudeEdge(i,cx,cy);
					}
					else
					{
						SubdivideEdge(i,cx,cy);
					}
					return;
				}
			}
		}
	}
	
	void SubdivideEdge(ulong edge, int cx, int cy)
	{
		mc.SendPacket(Packet2AddVert());
		
		mc.SendPacket(Packet27SetEdge(edgeindex:edge,start:g.edges[edge].start,end:g.verts.length));
		Edge newedge = g.edges[edge];
		newedge.start = g.verts.length;
		mc.SendPacket(Packet4AddEdge(edge:newedge));
		
		float2 screenpos = float2([cx - width/2,cy - height/2]);
		float2 r = float2([right[0],right[1]])*scale;
		float2 u = float2([up[0],up[1]])*scale;
		float2 hpos = (r*screenpos[0])*(1.0/(r*r)) + (u*(screenpos[1]+up[2]*pos[2]*scale))*(1.0/(u*u));
		hpos[0] += pos[0];
		hpos[1] += pos[1];
		
		mc.SendPacket(Packet3SetVert(vertid:g.verts.length,pos:float2([round(hpos[0]/grid)*grid,round(hpos[1]/grid)*grid])));
		foreach(i, sector; g.sectors)
		{
			foreach(edgeindex; sector.edges)
			{
				if(edgeindex == edge)
				{
					mc.SendPacket(Packet6SetEdgeSector(sector:i,edge:g.edges.length));
					//sector.edges ~= g.edges.length;
					break;
				}
			}
		}
	}
	
	void ExtrudeEdge(ulong edge, int cx, int cy)
	{
		Edge newedge = g.edges[edge];
		mc.SendPacket(Packet2AddVert());
		mc.SendPacket(Packet5AddSector());
		mc.SendPacket(Packet9SectorHeight(sector:g.sectors.length,low:-newedge.offset,high:newedge.height-newedge.offset));
		
		
		//mc.SendPacket(Packet27SetEdge(edgeindex:edge,start:g.edges[edge].start,end:g.verts.length));
		newedge.start = g.verts.length;
		mc.SendPacket(Packet4AddEdge(edge:newedge));
		mc.SendPacket(Packet6SetEdgeSector(edge:g.edges.length,sector:g.sectors.length));
		
		newedge = g.edges[edge];
		newedge.end = g.verts.length;
		mc.SendPacket(Packet4AddEdge(edge:newedge));
		mc.SendPacket(Packet6SetEdgeSector(edge:g.edges.length+1,sector:g.sectors.length));
		
		newedge.end = g.edges[edge].start;
		newedge.start = g.edges[edge].end;
		mc.SendPacket(Packet4AddEdge(edge:newedge));
		mc.SendPacket(Packet6SetEdgeSector(edge:g.edges.length+2,sector:g.sectors.length));
		foreach(i, sector; g.sectors)
		{
			foreach(edgeindex; sector.edges)
			{
				if(edgeindex == edge)
				{
					mc.SendPacket(Packet7SetEdgePortal(edge:g.edges.length+2,sector:i));
					mc.SendPacket(Packet8ToggleVis(edge:g.edges.length+2,hidden:true));
					break;
				}
			}
		}
		
		float2 screenpos = float2([cx - width/2,cy - height/2]);
		float2 r = float2([right[0],right[1]])*scale;
		float2 u = float2([up[0],up[1]])*scale;
		float2 hpos = (r*screenpos[0])*(1.0/(r*r)) + (u*(screenpos[1]+up[2]*pos[2]*scale))*(1.0/(u*u));
		hpos[0] += pos[0];
		hpos[1] += pos[1];
		
		mc.SendPacket(Packet3SetVert(vertid:g.verts.length,pos:float2([round(hpos[0]/grid)*grid,round(hpos[1]/grid)*grid])));
		mc.SendPacket(Packet7SetEdgePortal(edge:edge,sector:g.sectors.length));
		mc.SendPacket(Packet8ToggleVis(edge:edge,hidden:true));
	}

	override void WheelMoved(int x, int y, int sx, int sy)
	{
		if(!InBounds(x, y))
		{
			return;
		}
		
		if(sy < 0)
		{
			scale *= 0.5f;
		}
		else if(sy > 0)
		{
			scale *= 2f;
		}
	}
}

class Toolbar : Panel
{
	this(Panel p)
	{
		super(p);
	}
	
	override void Layout()
	{
		LayoutVertically(2, true);
	}
}

class ModelList : Panel
{
	MapPreview preview;
	this(Panel p)
	{
		super(p);
	}
	
	override void DrawContent(SDL_Renderer* renderer)
	{
		foreach(i, model; g.models)
		{
			if(i == preview.selectedmodel)
			{
				SDL_SetRenderDrawColor(renderer, 255, 128, 0, 255);
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
			}
			DGUI_DrawText(renderer, 0, cast(int)(i*16), to!string(i));
		}
	}
	
	override void MousePressed(int cx, int cy, MouseButton button, bool covered)
	{	
		if(covered)
		{
			return;
		}
		int insidey = cy/16;
		if(insidey < 0 || insidey >= g.models.length)
		{
			return;
		}
		preview.selectedmodel = insidey;
	}
}

class ActionPanel : Panel
{
	struct ActionEntry
	{
		uint type;
		string name;
		bool floaty = false;
		void delegate() arg1;
		void delegate() arg2;
	}
	
	ulong actionindex = 0;
	
	Textbox textboxx;
	Textbox textboxy;
	
	void SetVert()
	{
		Action* action = &g.actions[actionindex];
		action.arg1 = (cast(ActionList)parent).preview.selected;
	}
	
	void SetSector()
	{
		Action* action = &g.actions[actionindex];
		action.arg1 = (cast(ActionList)parent).preview.selectedsector;
	}
	
	void SetEdge()
	{
		Action* action = &g.actions[actionindex];
		action.arg1 = (cast(ActionList)parent).preview.selectededge;
	}
	
	void SetModel()
	{
		Action* action = &g.actions[actionindex];
		action.arg1 = (cast(ActionList)parent).preview.selectedmodel;
	}
	
	void SetAction()
	{
		Action* action = &g.actions[actionindex];
		action.arg1 = (cast(ActionList)parent).preview.selectedaction;
	}
	
	void SetEntity()
	{
		Action* action = &g.actions[actionindex];
		action.arg1 = (cast(ActionList)parent).preview.selectedentity;
	}
	
	ActionEntry[] actionentries;
	
	this(Panel p)
	{
		actionentries = [
			ActionEntry(3,"Set Vert", true, arg1: &SetVert),
			ActionEntry(6,"Set Edge Sector", arg1: &SetEdge, arg2: &SetSector),
			ActionEntry(7,"Set Edge Portal", arg1: &SetEdge, arg2: &SetSector),
			ActionEntry(8,"Set Edge Hidden", arg1: &SetEdge),
			ActionEntry(9,"Set Sector Low High", true, arg1: &SetSector),
			ActionEntry(10,"Set Edge Offset Height", true, arg1: &SetEdge),
			ActionEntry(14,"Set Entity Model", arg1: &SetEntity, arg2: &SetModel),
			ActionEntry(16,"Add To Model", arg1: &SetModel, arg2: &SetSector),
			//ActionEntry(17,"Set Entity Behavior", &SetEntity,),
			ActionEntry(21,"Set Action Type", arg1: &SetAction),
			ActionEntry(19,"Set Action Arg1", arg1: &SetAction),
			ActionEntry(20,"Set Action Arg2", arg1: &SetAction),
			ActionEntry(20,"Set Action Arg2", true, arg1: &SetAction),
		];
	
		super(p);
		Button up = (new Button(this,"^",&IncreaseType));
		up.height = 16;
		up.width = 8;
		Button down = (new Button(this,"v",&DecreaseType));
		down.height = 16;
		down.width = 8;
		up.x = 8;
		down.x = 16;
		down.y = 32;
		up.y = 32;
		Button select = (new Button(this,"s",&Select));
		select.height = 16;
		select.width = 8;
		select.y = 32;
		Button set = (new Button(this,"Set",&Set));
		set.x = 64;
		set.y = 32;
		textboxx = new Textbox(this,&FloatArg2);
		textboxx.x = 128;
		textboxx.y = 16;
		textboxx.width = 32;
		textboxy = new Textbox(this,&FloatArg2);
		textboxy.x = 128+32;
		textboxy.y = 16;
		textboxy.width = 32;
	}
	
	void FloatArg2()
	{
		Action* action = &g.actions[actionindex];
		try
		{
			action.arg2_f = parse!float(textboxx.text);
			action.arg3_f = parse!float(textboxy.text);
			textboxx.text = to!string(action.arg2_f);
			textboxy.text = to!string(action.arg3_f);
			mc.SendPacket(Packet20SetActionArg2(action:actionindex, val:action.arg2_u));
		}
		catch(Exception e)
		{
		
		}
	}
	
	void IncreaseType()
	{
		Action* action = &g.actions[actionindex];
		foreach(entry; actionentries)
		{
			if(entry.type > action.type)
			{
				action.type = entry.type;
				mc.SendPacket(Packet21SetActionType(action:actionindex, val:action.type));
				UpdateEntry(entry);
				return;
			}
		}
		action.type = actionentries[0].type;
		mc.SendPacket(Packet21SetActionType(action:actionindex, val:action.type));
		UpdateEntry(actionentries[0]);
	}
	
	void DecreaseType()
	{
		Action* action = &g.actions[actionindex];
		foreach_reverse(entry; actionentries)
		{
			if(entry.type < action.type)
			{
				action.type = entry.type;
				mc.SendPacket(Packet21SetActionType(action:actionindex, val:action.type));
				UpdateEntry(entry);
				return;
			}
		}
		action.type = actionentries[$-1].type;
		mc.SendPacket(Packet21SetActionType(action:actionindex, val:action.type));
		UpdateEntry(actionentries[0]);
	}
	
	void UpdateEntry(ActionEntry entry)
	{
		textboxx.hidden = !entry.floaty;
		textboxy.hidden = !entry.floaty;
	}
	
	void Select()
	{
		(cast(ActionList)parent).preview.selectedaction = actionindex;
	}
	
	void Set()
	{
		Action action = g.actions[actionindex];
		foreach(entry; actionentries)
		{
			if(entry.type == action.type)
			{
				entry.arg1();
				break;
			}
		}
	}
	
	override void DrawContent(SDL_Renderer* renderer)
	{
		if((cast(ActionList)parent).preview.selectedaction == actionindex)
		{
			SDL_SetRenderDrawColor(renderer, 255, 128, 0, 255);
		}
		else
		{
			SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
		}
		Action action = g.actions[actionindex];
		foreach(entry; actionentries)
		{
			if(entry.type == action.type)
			{
				DGUI_DrawText(renderer, 0, 16, to!string(actionindex));
				DGUI_DrawText(renderer, 0, 0, entry.name);
				DGUI_DrawText(renderer, 128-24, 16, to!string(action.arg1));
				break;
			}
		}
	}
	
	override void Layout()
	{
		width = 256;
		height = 48;
	}
}

class ActionList : Panel
{
	MapPreview preview;

	
	
	this(Panel p)
	{
		super(p);
	}
	
	override void Layout()
	{
		LayoutVertically(0,true);
		if(g.actions.length == children.length)
		{
			return;
		}
		foreach_reverse(child; children)
		{
			child.destroy();
		}
		foreach(i, action; g.actions)
		{
			(new ActionPanel(this)).actionindex = i;
		}
		width = 256;
	}
}

class TriggerPanel : Panel
{
	ulong triggerindex = 0;
	
	class Inner : Panel
	{
		this(Panel p)
		{
			super(p);
		}
		
		override void Layout()
		{
			LayoutVertically(0,true);
			Trigger* trigger = &g.triggers[(cast(TriggerPanel)parent).triggerindex];
			if(trigger.action.length == children.length)
			{
				return;
			}
			foreach_reverse(child; children)
			{
				child.destroy();
			}
			foreach(i, action; trigger.action)
			{
				Panel container = new Panel(this);
				(new PtrLabel!(ulong)(container, &trigger.action[i]));
				(new UserdataButton!(ulong)(container, "s", &SetSelected, i)).x = 80;
				(new UserdataButton!(ulong)(container, "-", &RemoveTriggerAction, i)).x = 96;
				container.Stretch();
			}
			width = 96;
			
		}
		
		void RemoveTriggerAction(ulong i)
		{
			mc.SendPacket(Packet25RemoveTriggerAction(trigger:triggerindex,actionindex:i));
		}
		
		void SetSelected(ulong i)
		{
			mc.SendPacket(Packet24SetTriggerAction(trigger:triggerindex,actionindex:i,action:(cast(TriggerList)(parent.parent)).preview.selectedaction));
		}
	}

	
	Inner inner;
	Button add;
	Button set;
	
	this(Panel p)
	{
		super(p);
		inner = new Inner(this);
		add = new Button(this,"Add Action",&AddAction);
		set = new Button(this,"Set Entity",&SetEntity);
	}
	
	void AddAction()
	{
		mc.SendPacket(Packet23AddToTrigger(trigger:triggerindex));
	}
	
	void SetEntity()
	{
		mc.SendPacket(Packet26SetEntityTrigger(entity:(cast(TriggerList)parent).preview.selectedentity,trigger:triggerindex));
	}
	
	override void Layout()
	{
		add.y = inner.height;
		set.y = add.y+add.height;
		Stretch();
	}

	
}

class TriggerList : Panel
{
	MapPreview preview;
	
	this(Panel p)
	{
		super(p);
	}
	
	override void Layout()
	{
		LayoutVertically(0,true);
		if(g.triggers.length == children.length)
		{
			return;
		}
		foreach_reverse(child; children)
		{
			child.destroy();
		}
		foreach(i, trigger; g.triggers)
		{
			(new TriggerPanel(this)).triggerindex = i;
		}
		width = 256;
	}
}

class MapEditor : RootPanel
{
	MapPreview preview;
	Window viewport_window;
	ViewportPanel viewport;
	Toolbar toolbar;
	Textbox texname;
	Textbox mapname;
	
	this()
	{
		preview = new MapPreview(this);
		toolbar = new Toolbar(this);
		viewport_window = new Window(this);
		viewport = new ViewportPanel(viewport_window);
		new Button(toolbar, "Add Vertex", &AddVertex);
		new Button(toolbar, "Toggle Visibility", &ToggleVis);
		new Button(toolbar, "Increase Height", &IncH);
		new Button(toolbar, "Decrease Height", &DecH);
		new Button(toolbar, "Increase Offset", &IncO);
		new Button(toolbar, "Decrease Offset", &DecO);
		new Button(toolbar, "Create Sector", &CreateSector);
		new Button(toolbar, "Add To Sector", &AddToSector);
		new Button(toolbar, "Increase Top", &IncT);
		new Button(toolbar, "Decrease Top", &DecT);
		new Button(toolbar, "Increase Floor", &IncF);
		new Button(toolbar, "Decrease Floor", &DecF);
		mapname = new Textbox(toolbar);
		mapname.text = "map.mp";
		new Button(toolbar, "Save Map", &SaveMap);
		new Button(toolbar, "Load Map", &LoadMap);
		new Button(toolbar, "Delete", &Delete);
		new Button(toolbar, "Link", &Link);
		texname = new Textbox(toolbar);
		new Button(toolbar, "Set Texture", &SetTexture);
		new Button(toolbar, "Create Model", &CreateModel);
		new Button(toolbar, "Add To Model", &AddToModel);
		new Button(toolbar, "Fisheye Toggle", &FisheyeToggle);
		new Button(toolbar, "Add Entity", &AddEntity);
		new Button(toolbar, "Set Entity Model", &SetEntityModel);
		(new ModelList(toolbar)).preview = preview;
		new Button(toolbar, "Increase Behavior", &IncreaseEntityBehavior);
		new Button(toolbar, "Decrease Behavior", &DecreaseEntityBehavior);
		new Button(toolbar, "Create Action", &CreateAction);
		(new ActionList(toolbar)).preview = preview;
		new Button(toolbar, "Create Trigger", &CreateTrigger);
		(new TriggerList(toolbar)).preview = preview;
		//new ButtonSwitch(toolbar, ["All Sectors", "Current Sector", "Single Sector"], &SwitchViewMode);
	}
	
	void CreateTrigger()
	{
		mc.SendPacket(Packet22CreateTrigger());
	}
	
	override void Layout()
	{
		preview.width = width-256;
		preview.height = height;
		toolbar.x = width-256;
		toolbar.width = 256;
		toolbar.height = height;
	}
	
	void SwitchViewMode()
	{
		
	}
	
	void CreateAction()
	{
		mc.SendPacket(Packet18CreateAction());
	}
	
	void FisheyeToggle()
	{
		viewport.fisheye = !viewport.fisheye;
	}
	
	void IncH()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		
		
		mc.SendPacket(Packet10EdgeHeight(edge:preview.selectededge, offset:g.edges[preview.selectededge].offset, height:g.edges[preview.selectededge].height+1));
	}
	
	void DecH()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		
		mc.SendPacket(Packet10EdgeHeight(edge:preview.selectededge, offset:g.edges[preview.selectededge].offset, height:g.edges[preview.selectededge].height-1));
	}
	
	void IncO()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		
		mc.SendPacket(Packet10EdgeHeight(edge:preview.selectededge, offset:g.edges[preview.selectededge].offset+1, height:g.edges[preview.selectededge].height));
	}
	
	void DecO()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		
		mc.SendPacket(Packet10EdgeHeight(edge:preview.selectededge, offset:g.edges[preview.selectededge].offset-1, height:g.edges[preview.selectededge].height));
	}
	
	void ToggleVis()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		
		mc.SendPacket(Packet8ToggleVis(edge:preview.selectededge,hidden:!g.edges[preview.selectededge].hidden));
	}
	
	void IncT()
	{
		if(preview.selectedsector == -1)
		{
			return;
		}
		
		mc.SendPacket(Packet9SectorHeight(sector:preview.selectedsector, low:g.sectors[preview.selectedsector].low, high:g.sectors[preview.selectedsector].high+1));
	}
	
	void DecT()
	{
		if(preview.selectedsector == -1)
		{
			return;
		}
		
		mc.SendPacket(Packet9SectorHeight(sector:preview.selectedsector, low:g.sectors[preview.selectedsector].low, high:g.sectors[preview.selectedsector].high-1));
	}
	
	void IncF()
	{
		if(preview.selectedsector == -1)
		{
			return;
		}
		
		mc.SendPacket(Packet9SectorHeight(sector:preview.selectedsector, low:g.sectors[preview.selectedsector].low+1, high:g.sectors[preview.selectedsector].high));
	}
	
	void DecF()
	{
		if(preview.selectedsector == -1)
		{
			return;
		}
		
		mc.SendPacket(Packet9SectorHeight(sector:preview.selectedsector, low:g.sectors[preview.selectedsector].low-1, high:g.sectors[preview.selectedsector].high));
	}
	
	
	void AddVertex()
	{
		mc.SendPacket(Packet2AddVert());
		//g.verts ~= float2([0.0f,0.0f]);
	}
	
	void CreateSector()
	{
		preview.selectedsector = g.sectors.length;
		mc.SendPacket(Packet5AddSector());
		//g.sectors ~= Sector(edges:[],high:2f,low:-2f,floortex:0,ceilingtex:0);
	}
	
	void AddToSector()
	{
		if(preview.selectedsector == -1)
		{
			return;
		}
		if(preview.selectededge == -1)
		{
			return;
		}
		mc.SendPacket(Packet6SetEdgeSector(sector:preview.selectedsector,edge:preview.selectededge));
		//g.sectors[preview.selectedsector].edges ~= preview.selectededge;
	}
	
	void CreateModel()
	{
		preview.selectedmodel = g.models.length;
		mc.SendPacket(Packet15CreateModel());
		//g.sectors ~= Sector(edges:[],high:2f,low:-2f,floortex:0,ceilingtex:0);
	}
	
	void AddToModel()
	{
		if(preview.selectedmodel == -1)
		{
			return;
		}
		if(preview.selectedsector == -1)
		{
			return;
		}
		mc.SendPacket(Packet16AddToModel(sector:preview.selectedsector,model:preview.selectedmodel));
	}
	
	void LoadMap()
	{
		g.LoadMap(mapname.text);
	}
	
	void LoadModel()
	{
		g.LoadModel(mapname.text);
	}
	
	void SaveMap()
	{
		File* mapfile = new File(mapname.text,"wb");
		
		SaveSector[] savesec;
		SaveModel[] savemodels;
		Edge[] saveedge;
		
		foreach(sector; g.sectors)
		{
			
			ulong edgestart = saveedge.length;
			ulong edgecount = 0;
			foreach(edgeindex; sector.edges)
			{
				Edge edge = g.edges[edgeindex];
				
				saveedge ~= edge;
				edgecount++;
			}
			
			savesec ~= SaveSector(deleted:sector.deleted, edgestart:edgestart, edgecount:edgecount, high:sector.high, low:sector.low, floortex:sector.floortex, ceilingtex:sector.ceilingtex);
		}
		
		foreach(model; g.models)
		{
			ulong secstart = savesec.length;
			ulong seccount = 0;
			foreach(sectorindex; model.sectors)
			{
				SaveSector sector = savesec[sectorindex];
				
				savesec ~= sector;
				seccount++;
			}
			
			savemodels ~= SaveModel(sectorstart:secstart,sectorcount:seccount);
		}
		
		mapfile.rawWrite([g.verts.length]);
		mapfile.rawWrite([saveedge.length]);
		mapfile.rawWrite([savesec.length]);
		mapfile.rawWrite([g.textures.length]);
		mapfile.rawWrite([g.models.length]);
		mapfile.rawWrite(g.verts);
		mapfile.rawWrite(saveedge);
		mapfile.rawWrite(savesec);
		mapfile.rawWrite(g.textures);
		mapfile.rawWrite(savemodels);
		mapfile.close();
	}
	
	
	
	void Delete()
	{
		if(preview.selectedsector != -1)
		{
			g.sectors[preview.selectedsector].deleted = true;
		}
		
		if(preview.selectededge != -1)
		{
			g.edges[preview.selectededge].deleted = true;
		}
	}
	
	void Link()
	{
		if(preview.selectedsector == -1)
		{
			return;
		}
		
		if(preview.selectededge == -1)
		{
			return;
		}
		mc.SendPacket(Packet7SetEdgePortal(sector:preview.selectedsector,edge:preview.selectededge));
		//g.edges[preview.selectededge].portal = preview.selectedsector;
	}
	
	void SetTexture()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		if(texname.text.length > 64)
		{
			return;
		}
		char[64] texture = 0;
		texture[0..texname.text.length] = texname.text[];
		mc.SendPacket(Packet11EdgeTexture(edge:preview.selectededge,texture:texture));
	}
	
	void AddEntity()
	{
		mc.SendPacket(Packet13AddEntity());
	}
	
	void SetEntityModel()
	{
		if(preview.selectedentity == -1)
		{
			return;
		}
		mc.SendPacket(Packet14SetEntityModel(entity:preview.selectedentity));
	}
	
	ushort behavior = 0;
	
	void IncreaseEntityBehavior()
	{
		if(preview.selectedentity == -1)
		{
			return;
		}
		mc.SendPacket(Packet17SetEntityBehavior(entity:preview.selectedentity,behavior:++behavior));
	}
	
	void DecreaseEntityBehavior()
	{
		if(preview.selectedentity == -1)
		{
			return;
		}
		if(behavior == 0)
		{
			return;
		}
		mc.SendPacket(Packet17SetEntityBehavior(entity:preview.selectedentity,behavior:--behavior));
	}
}
