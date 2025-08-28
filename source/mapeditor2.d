import dguiw;
import rendering;
import bindbc.sdl;
import math;
import std.math;
import std.stdio;
import game;
import client;
import packet;

const float PI22_5 = 70.6858347058f;
const float PI45 = 141.371669412f;
const float PI90 = 282.743338823f;

class MapPreview : Panel
{
	enum EditorMode
	{
		Extruding,
		Raising
	}
	
	
	this(Panel p)
	{
		super(p);
	}
	
	float skew = 0.0f;
	float rot = 0.0f;
	float grid = 8.0f;
	float3 right = ~float3([1.0f,0.0f,0.0f]);
	float3 up = ~float3([0.0f,1.0f,0.0f]);
	float3 pos = float3([0.0f,0.0f,0.0f]);
	float scale = 1.0f;

	float2 Project(float3 p)
	{
		p = (p-pos)*scale;
		return float2([p*right+width/2,p*up+height/2]);
	}
	
	float2 ProjectOffset(float3 p)
	{
		return float2([p*right,p*up]);
	}
	
	void ProjectLine(SDL_Renderer* renderer, float3 start3, float3 end3)
	{
		float2 start = Project(start3);
		float2 end = Project(end3);
		
		DGUI_DrawLine(renderer,cast(int)(start[0]),cast(int)(start[1]),cast(int)(end[0]),cast(int)(end[1]));
	}
	
	
	enum EdgeSide
	{
		None,
		Top,
		Left,
		Bottom,
		Right
	}
	
	long extruding_edge_vert = -1;
	long raising_edge = -1;
	long lowering_edge = -1;
	long on_edge = -1;
	EdgeSide on_edge_side = EdgeSide.None;
	EditorMode mode = EditorMode.Extruding;
	
	void DrawSector(SDL_Renderer* renderer, ulong sectorindex)
	{
		ubyte ro,go,bo,ao;
		SDL_GetRenderDrawColor(renderer, &ro, &go, &bo, &ao);
		
		Sector sector = g.sectors[sectorindex];
		foreach(edgeindex; sector.edges)
		{
			Edge edge = g.edges[edgeindex];
			if(edge.deleted)
			{
				continue;
			}
			
			
			
			if(!InFront(edge))
			{
				continue;
			}
			
			float2 edgestart = g.verts[edge.start];
			float2 edgeend = g.verts[edge.end];
			float3 start = float3([edgestart[0],edgestart[1],-edge.offset]);
			float3 end = float3([edgeend[0],edgeend[1],-edge.offset]);
			float3 mid = (start+end)*0.5f;
			float3 norm = mid - float3([edgestart[1]-edgeend[1],edgeend[0]-edgestart[0],0.0f])*0.125f;


			SDL_SetRenderDrawColor(renderer, 128, 128, 255, 64);
			ProjectLine(renderer,mid,norm);
			
			if(edgeindex == on_edge)
			{
				if(mode == EditorMode.Raising)
				{
					SDL_SetRenderDrawColor(renderer, ro, go, bo, ao);
				}
				else
				{
					SDL_SetRenderDrawColor(renderer, 64, 128, 255, 255);
				}
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, ro, go, bo, ao);
			}
			
			if(edgeindex == on_edge && mode == EditorMode.Raising && on_edge_side == EdgeSide.Left)
			{
				SDL_SetRenderDrawColor(renderer, 64, 255, 128, 255);
				ProjectLine(renderer,start,float3([start[0],start[1],start[2]+edge.height]));
				SDL_SetRenderDrawColor(renderer, ro, go, bo, ao);
			}
			else
			{
				ProjectLine(renderer,start,float3([start[0],start[1],start[2]+edge.height]));
			}
			
			
			if(edgeindex == on_edge && mode == EditorMode.Raising && on_edge_side == EdgeSide.Right)
			{
				SDL_SetRenderDrawColor(renderer, 64, 255, 128, 255);
				ProjectLine(renderer,end,float3([end[0],end[1],end[2]+edge.height]));
				SDL_SetRenderDrawColor(renderer, ro, go, bo, ao);
			}
			else
			{
				ProjectLine(renderer,end,float3([end[0],end[1],end[2]+edge.height]));
			}
			
			
			
			
			
			if(edgeindex == on_edge && mode == EditorMode.Raising && on_edge_side == EdgeSide.Bottom)
			{
				SDL_SetRenderDrawColor(renderer, 64, 255, 128, 255);
				ProjectLine(renderer,start,end);
				SDL_SetRenderDrawColor(renderer, ro, go, bo, ao);
			}
			else
			{
				ProjectLine(renderer,start,end);
			}
			
			
			start[2] += edge.height;
			end[2] += edge.height;
			if(edgeindex == on_edge && mode == EditorMode.Raising && on_edge_side == EdgeSide.Top)
			{
				SDL_SetRenderDrawColor(renderer, 64, 255, 128, 255);
			}
			ProjectLine(renderer,start,end);
			
			
		}
	}
	
	override void DrawContent(SDL_Renderer* renderer)
	{
		
		SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
		DGUI_FillRect(renderer, 0, 0, width, height);
	
		SDL_SetRenderDrawColor(renderer, 0, 64, 0, 64);
		
		foreach(i; -16..16)
		{
			float3 start = float3([i*grid+cast(int)(pos[0]/grid)*grid,-grid*16+cast(int)(pos[1]/grid)*grid,0]);
			float3 end = float3([i*grid+cast(int)(pos[0]/grid)*grid,grid*16+cast(int)(pos[1]/grid)*grid,0]);
			ProjectLine(renderer,start,end);
		}
		foreach(i; -16..16)
		{
			float3 start = float3([-grid*16+cast(int)(pos[0]/grid)*grid,i*grid+cast(int)(pos[1]/grid)*grid,0]);
			float3 end = float3([grid*16+cast(int)(pos[0]/grid)*grid,i*grid+cast(int)(pos[1]/grid)*grid,0]);
			ProjectLine(renderer,start,end);
		}
		
		
		if(viewent >= g.entities.length)
		{
			return;
		}
		
		ulong cursector = g.entities[viewent].cursector;
		
		foreach(sectorindex, sector; g.sectors)
		{
			if(sectorindex == cursector)
			{
				SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, 128, 128, 128, 64);
			}
			DrawSector(renderer, sectorindex);
		}
	}
	
	bool InFront(Edge edge)
	{
		if(up[2] == 0.0f)
		{
			return true;
		}
		float2 start = g.verts[edge.start];
		float2 end = g.verts[edge.end];
		float2 dir = end-start;
		return float2([right[0],right[1]])*dir <= 0;
	}
	
	bool OnEdge(Edge edge, int cx, int cy, float mul)
	{
		float2 start2 = g.verts[edge.start];
		float2 end2 = g.verts[edge.end];
		float2 start = Project(float3([start2[0],start2[1],edge.height*mul-edge.offset]));
		float2 end = Project(float3([end2[0],end2[1],edge.height*mul-edge.offset]));
		
		float lx = cx-start[0];
		float ly = cy-start[1];
		float endx = end[0]-start[0];
		float endy = end[1]-start[1];
		float endlen = sqrt(endx*endx+endy*endy);
		float normx = endx/endlen;
		float normy = endy/endlen;
		float forward = normx*lx + normy*ly;
		float side = abs(normx*ly - normy*lx);
		return forward > 0 && forward < endlen && side < 4;
	}
	
	bool OnEdgeSide(Edge edge, int cx, int cy, float mul)
	{
		float2 start2 = g.verts[edge.start];
		float2 end2 = g.verts[edge.end];
		float2 diff = end2-start2;
		start2 = start2+diff*mul;
		float2 startlow = Project(float3([start2[0],start2[1],-edge.offset]));
		float2 starttop = Project(float3([start2[0],start2[1],edge.height-edge.offset]));
		
		float lx = cx-startlow[0];
		float ly = cy-startlow[1];
		float endx = starttop[0]-startlow[0];
		float endy = starttop[1]-startlow[1];
		float endlen = sqrt(endx*endx+endy*endy);
		float normx = endx/endlen;
		float normy = endy/endlen;
		float forward = normx*lx + normy*ly;
		float side = abs(normx*ly - normy*lx);
		return forward > 0 && forward < endlen && side < 4;
	}
	
	override void MousePressed(int cx, int cy, MouseButton button, bool covered)
	{	
		if(covered)
		{
			return;
		}
	
		if(button == MouseButton.Left)
		{
			if(mode == EditorMode.Raising)
			{
				foreach(i, edge; g.edges)
				{
					if(edge.deleted)
					{
						continue;
					}
					
					if(!InFront(edge))
					{
						continue;
					}
					
					if(OnEdge(edge, cx, cy, 1.0f))
					{
						raising_edge = i;
						on_edge_side = EdgeSide.Top;
						return;
					}
					
					if(OnEdge(edge, cx, cy, 0.0f))
					{
						lowering_edge = i;
						on_edge_side = EdgeSide.Bottom;
						return;
					}
				}
			}
			else
			{
				foreach(i, edge; g.edges)
				{
					if(edge.deleted)
					{
						continue;
					}
					
					if(!InFront(edge))
					{
						continue;
					}
					
					if(OnEdge(edge, cx, cy, 0.0f) || OnEdge(edge, cx, cy, 1.0f))
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
	}
	
	void SubdivideEdge(ulong edge, int cx, int cy)
	{
		float2 screenpos = float2([cx - width/2,cy - height/2]);
		float2 r = float2([right[0],right[1]])*scale;
		float2 u = float2([up[0],up[1]])*scale;
		float2 hpos = (r*screenpos[0])*(1.0/(r*r)) + (u*(screenpos[1]+up[2]*pos[2]*scale))*(1.0/(u*u));
		hpos[0] += pos[0];
		hpos[1] += pos[1];
		
		mc.SendPacket(Packet2AddVert(pos:float2([round(hpos[0]/grid)*grid,round(hpos[1]/grid)*grid])));
		
		mc.SendPacket(Packet27SetEdge(edgeindex:edge,start:g.edges[edge].start,end:g.verts.length));
		Edge newedge = g.edges[edge];
		newedge.start = g.verts.length;
		mc.SendPacket(Packet4AddEdge(edge:newedge));
		
		
		foreach(i, sector; g.sectors)
		{
			foreach(edgeindex; sector.edges)
			{
				if(edgeindex == edge)
				{
					mc.SendPacket(Packet6SetEdgeSector(sector:i,edge:g.edges.length));
					break;
				}
			}
		}
		extruding_edge_vert = g.verts.length;
	}
	
	void ExtrudeEdge(ulong edge, int cx, int cy)
	{
		Edge newedge = g.edges[edge];
		float2 screenpos = float2([cx - width/2,cy - height/2]);
		float2 r = float2([right[0],right[1]])*scale;
		float2 u = float2([up[0],up[1]])*scale;
		float2 hpos = (r*screenpos[0])*(1.0/(r*r)) + (u*(screenpos[1]+up[2]*pos[2]*scale))*(1.0/(u*u));
		hpos[0] += pos[0];
		hpos[1] += pos[1];
		
		mc.SendPacket(Packet2AddVert(pos:float2([round(hpos[0]/grid)*grid,round(hpos[1]/grid)*grid])));
		
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
		
		
		mc.SendPacket(Packet7SetEdgePortal(edge:edge,sector:g.sectors.length));
		mc.SendPacket(Packet8ToggleVis(edge:edge,hidden:true));
		extruding_edge_vert = g.verts.length;
	}
	
	override void MouseMoved(int cx, int cy, int rx, int ry, bool covered)
	{
		on_edge = -1;
		if(covered)
		{
			return;
		}
		if(DGUI_IsButtonPressed(MouseButton.Left))
		{
			if(extruding_edge_vert != -1)
			{
				float2 screenpos = float2([cx - width/2,cy - height/2]);
				float2 r = float2([right[0],right[1]])*scale;
				float2 u = float2([up[0],up[1]])*scale;
				float2 hpos = (r*screenpos[0])*(1.0/(r*r)) + (u*(screenpos[1]+up[2]*pos[2]*scale))*(1.0/(u*u));
				hpos[0] += pos[0];
				hpos[1] += pos[1];
				
				mc.SendPacket(Packet3SetVert(vertid:extruding_edge_vert,pos:float2([round(hpos[0]/grid)*grid,round(hpos[1]/grid)*grid])));
				return;
			}
			if(raising_edge != -1)
			{
				Edge edge = g.edges[raising_edge];
				float2 start = g.verts[edge.start];
				float2 end = g.verts[edge.end];
				
				float ydot = float3([(start[0]+end[0])*0.5f,(start[1]+end[1])*0.5f,-edge.offset])*up*scale;
				float z = (cy - height/2 - ydot)/up[2]/scale;
				mc.SendPacket(Packet10EdgeHeight(edge:raising_edge, offset:edge.offset, height:round(z/grid)*grid));
				return;
			}
			if(lowering_edge != -1)
			{
				Edge edge = g.edges[lowering_edge];
				float2 start = g.verts[edge.start];
				float2 end = g.verts[edge.end];
				
				float ydot = float3([(start[0]+end[0])*0.5f,(start[1]+end[1])*0.5f,0.0f])*up*scale;
				float z = (cy - height/2 - ydot)/up[2]/scale;
				z = -round(z/grid)*grid;
				mc.SendPacket(Packet10EdgeHeight(edge:lowering_edge, offset:z, height:edge.height-edge.offset+z));
				return;
			}
		}
		else
		{
			extruding_edge_vert = -1;
			raising_edge = -1;
			lowering_edge = -1;
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
				skew = skew < -PI90 ? -PI90 : (skew > 0 ? 0 : skew);
			}
			
		}
		
		
		right = float3([cos(rot/90.0f),-sin(rot/90.0f),0.0f]);
		up = float3([sin(rot/90.0f)*cos(skew/90.0f),cos(rot/90.0f)*cos(skew/90.0f),sin(skew/90.0f)]);
		
		if(skew > -PI22_5-PI45 && skew < -PI22_5)
		{
			mode = EditorMode.Raising;
			foreach(i, edge; g.edges)
			{
				if(!InFront(edge))
				{
					continue;
				}
				if(OnEdge(edge,cx,cy,1.0f))
				{
					on_edge_side = EdgeSide.Top;
					on_edge = i;
					break;
				}
				if(OnEdge(edge,cx,cy,0.0f))
				{
					on_edge_side = EdgeSide.Bottom;
					on_edge = i;
					break;
				}
				if(OnEdgeSide(edge,cx,cy,0.0f))
				{
					on_edge_side = EdgeSide.Left;
					on_edge = i;
					break;
				}
				if(OnEdgeSide(edge,cx,cy,1.0f))
				{
					on_edge_side = EdgeSide.Right;
					on_edge = i;
					break;
				}
			}
		}
		else
		{
			mode = EditorMode.Extruding;
			foreach(i, edge; g.edges)
			{
				if(!InFront(edge))
				{
					continue;
				}
				if(OnEdge(edge,cx,cy,0.0f) || OnEdge(edge,cx,cy,1.0f))
				{
					on_edge = i;
					break;
				}
			}
		}
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

class MapEditor : RootPanel
{
	ViewportPanel viewport;
	MapPreview preview;
	Panel toolbar;
	this()
	{
		viewport = new ViewportPanel(this);
		preview = new MapPreview(this);
		toolbar = new Panel(this);
		new Button(toolbar, "Fisheye Toggle", &FisheyeToggle);
	}
	
	override void Layout()
	{
		viewport.x = 1;
		viewport.y = 1;
		preview.x = viewport.width+2;
		preview.y = 1;
		preview.width = width-preview.x-3;
		preview.height = height-2;
		toolbar.x = 1;
		toolbar.y = viewport.height+2;
		toolbar.width = viewport.width;
		toolbar.height = height-viewport.height-3;
		toolbar.LayoutVertically();
	}
	
	void FisheyeToggle()
	{
		viewport.fisheye = !viewport.fisheye;
	}
}