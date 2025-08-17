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
	
	
	
	long extruding_edge_vert = -1;
	long raisingedge = -1;
	
	
	void DrawSector(SDL_Renderer* renderer, ulong sectorindex)
	{
		Sector sector = g.sectors[sectorindex];
		foreach(edgeindex; sector.edges)
		{
			Edge edge = g.edges[edgeindex];
			float2 edgestart = g.verts[edge.start];
			float2 edgeend = g.verts[edge.end];
			float3 start = float3([edgestart[0],edgestart[1],-edge.offset]);
			float3 end = float3([edgeend[0],edgeend[1],-edge.offset]);
			ProjectLine(renderer,start,end);
			start[2] += edge.height;
			end[2] += edge.height;
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
	
	override void MousePressed(int cx, int cy, MouseButton button, bool covered)
	{	
		if(covered)
		{
			return;
		}
	
		if(button == MouseButton.Left)
		{
			if(skew > -PI22_5-PI45 && skew < -PI22_5)
			{
				foreach(i, edge; g.edges)
				{
					if(edge.deleted)
					{
						continue;
					}
					float2 start2 = g.verts[edge.start];
					float2 end2 = g.verts[edge.end];
					float2 start = Project(float3([start2[0],start2[1],edge.height-edge.offset]));
					float2 end = Project(float3([end2[0],end2[1],edge.height-edge.offset]));
					
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
						raisingedge = i;
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
			if(raisingedge != -1)
			{
				Edge edge = g.edges[raisingedge];
				float2 start = g.verts[edge.start];
				float2 end = g.verts[edge.end];
				
				float ydot = float3([(start[0]+end[0])*0.5f,(start[1]+end[1])*0.5f,-edge.offset])*up;
				float z = ((cy - height/2 - ydot)/up[2])*scale;
				mc.SendPacket(Packet10EdgeHeight(edge:raisingedge, offset:edge.offset, height:z));
				return;
			}
		}
		else
		{
			extruding_edge_vert = -1;
			raisingedge = -1;
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
	this()
	{
		viewport = new ViewportPanel(this);
		preview = new MapPreview(this);
	}
	
	override void Layout()
	{
		viewport.x = 1;
		viewport.y = 1;
		preview.x = viewport.width+2;
		preview.y = 1;
		preview.width = width-preview.x-1;
		preview.height = height-2;
	}
}