import dgui;
import bindbc.sdl;
import std.math;
import std.stdio;
import game;
import math;
import rendering;
import client;
import packet;



class MapPreview : Panel
{
	long selected = -1;
	long selectededge = -1;
	long selectedsector = -1;
	bool selectedview = false;
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
		width = 320;
		height = 240;
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
	
	override void Draw(SDL_Renderer* renderer)
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
		
		SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
		
		foreach(entity; g.entities)
		{
			float2 dir = float2([sin(entity.rot),-cos(entity.rot)]);
			float2 eoff = ProjectOffset(float3([dir[0],dir[1],0.0f]));
			float2 eoffp = ProjectOffset(float3([dir[1],-dir[0],0.0f]));
			float2 epos = Project(entity.pos);
			
			DGUI_DrawLine(renderer,cast(int)(epos[0]),cast(int)(epos[1]),cast(int)(epos[0]+eoff[0]*12-eoffp[0]*4),cast(int)(epos[1]+eoff[1]*12-eoffp[1]*4));
			DGUI_DrawLine(renderer,cast(int)(epos[0]),cast(int)(epos[1]),cast(int)(epos[0]+eoff[0]*12+eoffp[0]*4),cast(int)(epos[1]+eoff[1]*12+eoffp[1]*4));
		}

	}
	
	override void MouseMove(int cx, int cy, int rx, int ry, uint button)
	{
		if(selected != -1)
		{
			if(button == 1)
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
		if(button == 2)
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
	
	
	
	override void Click(int cx, int cy, int button, int action)
	{
		if(action == SDL_RELEASED)
		{
			return;
		}
		
		if(button == 1)
		{
			selected = -1;
			selectededge = -1;
			//selectedsector = -1;

			
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
			
			foreach(i, sector; g.sectors)
			{
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
						float side = abs(norm[0]*l[1] - norm[1]*l[0]);
						if(forward > 0 && forward < diffl && side < 0.2f/scale)
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
		}
		else if(button == 3)
		{
			if(selected == -1)
			{
				return;
			}
			foreach(i, vert; g.verts)
			{
				float2 pos = Project(float3([vert[0],vert[1],0.0f]));
				float dist = (abs(pos[0]-(cx)) + abs(pos[1]-(cy)));
				if(dist < 8)
				{
					mc.SendPacket(Packet4AddEdge(edge:Edge(start:selected, end:i, height:4.0f, offset:2.0f, texture:1, deleted:false)));
					break;
				}
			}
		}
		else if(button == 4) // Scroll down
		{
			scale *= 0.5f;
		}
		else if(button == 5) // Scroll up
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
		vertical = true;
	}

	override void PerformLayout()
	{
		FitWidth();
		FitHeight();
		super.PerformLayout();
	}
}

class Editor : Panel
{
	this(Panel p)
	{
		super(p);
		vertical = false;
	}
	override void PerformLayout()
	{
		FitWidth();
		FitHeight();
		super.PerformLayout();
	}
}

class MapEditor : Panel
{
	MapPreview preview;
	ViewportPanel viewport;
	Toolbar toolbar;
	Editor editor;
	Textbox texname;
	Textbox mapname;
	
	this()
	{
		padding_top = 16;
		padding_bottom = 16;
		padding_left = 16;
		padding_right = 16;
		gap = 16;
		editor = new Editor(this);
		preview = new MapPreview(editor);
		toolbar = new Toolbar(editor);
		viewport = new ViewportPanel(this);
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
		new Button(toolbar, "Load Model", &LoadModel);
		new Button(toolbar, "Fisheye Toggle", &FisheyeToggle);
		
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
		if(g.sectors.length == 0)
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
		
		mapfile.rawWrite([g.verts.length]);
		mapfile.rawWrite([saveedge.length]);
		mapfile.rawWrite([savesec.length]);
		mapfile.rawWrite([g.textures.length]);
		mapfile.rawWrite(g.verts);
		mapfile.rawWrite(saveedge);
		mapfile.rawWrite(savesec);
		mapfile.rawWrite(g.textures);
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
}
