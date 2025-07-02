import dgui;
import bindbc.sdl;
import std.math;
import std.stdio;
import game;
import math;
import rendering;

class MapPreview : Panel
{
	long selected = -1;
	long selectededge = -1;
	long selectedsector = -1;
	bool selectedview = false;
	long grid = 8;

	this(Panel p)
	{
		super(p);
		width = 320;
		height = 240;
		entities ~= Entity(texture:0,pos:float3([0.0f,0.0f,0.0f]));
	}
	
	override void Draw(SDL_Renderer* renderer)
	{
		SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
		DGUI_FillRect(renderer, 0, 0, width, height);
		
		
		
		
		foreach(i, sector; sectors)
		{
			if(sector.deleted)
			{
				continue;
			}
			foreach(j, wall1; sector.edges)
			{
				Edge edge1 = edges[wall1];
				if(edge1.deleted)
				{
					continue;
				}
				float2 start1 = verts[edge1.start];
				float2 end1 = verts[edge1.end];
				float2 point1 = (start1+end1)*0.5f;
				float2 norm = EdgeNormalVis(edge1)*0.25f;
				if(i == selectedsector)
				{
					SDL_SetRenderDrawColor(renderer, 255, 0, 255, 255);
				}
				else
				{
					SDL_SetRenderDrawColor(renderer, 127, 127, 255, 255);
				}
				DGUI_DrawLine(renderer,cast(int)(point1[0]+width/2),cast(int)(point1[1]+height/2),cast(int)(point1[0]+norm[0]+width/2),cast(int)(point1[1]+norm[1]+height/2));
				
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
					Edge edge2 = edges[sector.edges[wall2]];
					if(edge2.deleted)
					{
						continue;
					}
					float2 start2 = verts[edge2.start];
					float2 end2 = verts[edge2.end];
					float2 point2 = (start2+end2)*0.5f;
					DGUI_DrawLine(renderer,cast(int)(point1[0]+width/2),cast(int)(point1[1]+height/2),cast(int)(point2[0]+width/2),cast(int)(point2[1]+height/2));
					//DGUI_DrawLine(renderer,cast(int)(end1[0]+width/2),cast(int)(end1[1]+height/2),cast(int)(end2[0]+width/2),cast(int)(end2[1]+height/2));
				}
			}
		}
		
		foreach(i, edge; edges)
		{
			if(edge.deleted)
			{
				continue;
			}
			float2 start = verts[edge.start];
			float2 end = verts[edge.end];
			
			if(i == selectededge)
			{
				SDL_SetRenderDrawColor(renderer, 64, 127, 255, 255);
			}
			else if(edge.hidden)
			{
				SDL_SetRenderDrawColor(renderer, 64, 64, 64, 255);
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, 255, 127, 64, 255);
			}
			
			DGUI_DrawLine(renderer,cast(int)(start[0]+width/2),cast(int)(start[1]+height/2),cast(int)(end[0]+width/2),cast(int)(end[1]+height/2));
		}
		
		foreach(i, vert; verts)
		{
			if(i == selected)
			{
				SDL_SetRenderDrawColor(renderer, 96, 255, 255, 255);
			}
			else
			{
				SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
			}
			DGUI_DrawPoint(renderer,cast(int)(vert[0]+width/2+1),cast(int)(vert[1]+height/2));
			DGUI_DrawPoint(renderer,cast(int)(vert[0]+width/2  ),cast(int)(vert[1]+height/2+1));
			DGUI_DrawPoint(renderer,cast(int)(vert[0]+width/2  ),cast(int)(vert[1]+height/2-1));
			DGUI_DrawPoint(renderer,cast(int)(vert[0]+width/2-1),cast(int)(vert[1]+height/2));
		}
		
		SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
		
		DGUI_DrawLine(renderer,cast(int)(campos[0]+width/2),cast(int)(campos[1]+height/2),cast(int)(campos[0]+(camdir[0]*2-camdir[1])*12+width/2),cast(int)(campos[1]+(camdir[1]*2+camdir[0])*12+height/2));
		DGUI_DrawLine(renderer,cast(int)(campos[0]+width/2),cast(int)(campos[1]+height/2),cast(int)(campos[0]+(camdir[0]*2+camdir[1])*12+width/2),cast(int)(campos[1]+(camdir[1]*2-camdir[0])*12+height/2));

	}
	
	override void MouseMove(int cx, int cy, int rx, int ry, uint button)
	{
		if(selected != -1)
		{
			if(button == 1)
			{
				verts[selected][0] = round((cx - width/2)/grid)*grid;
				verts[selected][1] = round((cy - height/2)/grid)*grid;
			}
		}
		else if(selectedview)
		{
			if(button == 1)
			{
				campos[0] = cx-width/2;
				campos[1] = cy-height/2;
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
			selectedview = false;
			{
				float dist = (abs(campos[0]-(cx-width/2)) + abs(campos[1]-(cy-height/2)));
				if(dist < 8)
				{
					selectedview = true;
					return;
				}
			}
			
			foreach(i, vert; verts)
			{
				float dist = (abs(vert[0]-(cx-width/2)) + abs(vert[1]-(cy-height/2)));
				if(dist < 8)
				{
					selected = i;
					return;
				}
			}
			
			foreach(i, edge; edges)
			{
				if(edge.deleted)
				{
					continue;
				}
				float2 start = verts[edge.start];
				float2 end = verts[edge.end];
				float lx = cx-width/2-start[0];
				float ly = cy-height/2-start[1];
				float endx = end[0]-start[0];
				float endy = end[1]-start[1];
				float endlen = sqrt(endx*endx+endy*endy);
				float normx = endx/endlen;
				float normy = endy/endlen;
				float forward = normx*lx + normy*ly;
				float side = abs(normx*ly - normy*lx);
				if(forward > 0 && forward < endlen && side < 5)
				{
					selectededge = i;
					return;
				}
			}
			
			float2 presspos = float2([cx-width/2,cy-height/2]);
			
			foreach(i, sector; sectors)
			{
				bool failure = false;
			
				foreach(edgeindex; sector.edges)
				{
					Edge edge = edges[edgeindex];
					float2 start = verts[edge.start];
					float2 n = EdgeNormal(edge);
					float dot = n*presspos - n*start;
					if(dot < 0)
					{
						failure = true;
					}
				}
				if(failure)
				{
					continue;
				}
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
		}
		else if(button == 2)
		{
			if(selected == -1)
			{
				return;
			}
			verts[selected][0] = round((cx - width/2)/grid)*grid;
			verts[selected][1] = round((cy - height/2)/grid)*grid;
		}
		else if(button == 3)
		{
			if(selected == -1)
			{
				return;
			}
			foreach(i, vert; verts)
			{
				float dist = (abs(vert[0]-(cx-width/2)) + abs(vert[1]-(cy-height/2)));
				if(dist < 8)
				{
					edges ~= Edge(start:selected, end:i, height:4.0f, offset:2.0f, texture:1, deleted:false);
					break;
				}
			}
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
		new Button(toolbar, "Save Map", &SaveMap);
		new Button(toolbar, "Load Map", &LoadMap);
		new Button(toolbar, "Delete", &Delete);
		new Button(toolbar, "Link", &Link);
	}
	
	void IncH()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		
		edges[preview.selectededge].height++;
	}
	
	void DecH()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		
		edges[preview.selectededge].height--;
	}
	
	void IncO()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		
		edges[preview.selectededge].offset++;
	}
	
	void DecO()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		
		edges[preview.selectededge].offset--;
	}
	
	void ToggleVis()
	{
		if(preview.selectededge == -1)
		{
			return;
		}
		
		edges[preview.selectededge].hidden = !edges[preview.selectededge].hidden;
	}
	
	void IncT()
	{
		if(preview.selectedsector == -1)
		{
			return;
		}
		
		sectors[preview.selectedsector].high++;
	}
	
	void DecT()
	{
		if(preview.selectedsector == -1)
		{
			return;
		}
		
		sectors[preview.selectedsector].high--;
	}
	
	void IncF()
	{
		if(preview.selectedsector == -1)
		{
			return;
		}
		
		sectors[preview.selectedsector].low++;
	}
	
	void DecF()
	{
		if(preview.selectedsector == -1)
		{
			return;
		}
		
		sectors[preview.selectedsector].low--;
	}
	
	
	void AddVertex()
	{
		verts ~= float2([0.0f,0.0f]);
	}
	
	void CreateSector()
	{
		preview.selectedsector = sectors.length;
		sectors ~= Sector(edges:[],high:2f,low:-2f,floortex:0,ceilingtex:0);
	}
	
	void AddToSector()
	{
		if(sectors.length == 0)
		{
			return;
		}
		if(preview.selectededge == -1)
		{
			return;
		}
		
		sectors[preview.selectedsector].edges ~= preview.selectededge;
	}
	
	struct SaveSector
	{
		ulong edgestart;
		ulong edgecount;
		float high;
		float low;
		ulong floortex;
		ulong ceilingtex;
	}
	
	void SaveMap()
	{
		File* mapfile = new File("map.mp","wb");
		
		SaveSector[] savesec;
		Edge[] saveedge;
		
		foreach(sector; sectors)
		{
			if(sector.deleted)
			{
				continue;
			}
			
			ulong edgestart = saveedge.length;
			ulong edgecount = 0;
			foreach(edgeindex; sector.edges)
			{
				Edge edge = edges[edgeindex];
				if(edge.deleted)
				{
					continue;
				}
				
				saveedge ~= edge;
				edgecount++;
			}
			
			
			savesec ~= SaveSector(edgestart:edgestart,edgecount:edgecount,high:sector.high,low:sector.low,floortex:sector.floortex,ceilingtex:sector.ceilingtex);
		}
		
		mapfile.rawWrite([verts.length]);
		mapfile.rawWrite([saveedge.length]);
		mapfile.rawWrite([savesec.length]);
		mapfile.rawWrite([textures.length]);
		mapfile.rawWrite(verts);
		mapfile.rawWrite(saveedge);
		mapfile.rawWrite(savesec);
		mapfile.rawWrite(textures);
		mapfile.close();
	}
	
	void LoadMap()
	{
		File* mapfile = new File("map.mp","rb");
		ulong[4] lengths = mapfile.rawRead(new ulong[4]);
		
		
		verts = mapfile.rawRead(new float2[lengths[0]]);
		edges = mapfile.rawRead(new Edge[lengths[1]]);
		SaveSector[] savesectors = mapfile.rawRead(new SaveSector[lengths[2]]);
		textures = mapfile.rawRead(new Texture[lengths[3]]);
		
		
		sectors = [];
		foreach(savesector; savesectors)
		{
			ulong[] edgeindices;
			foreach(i;savesector.edgestart..savesector.edgestart+savesector.edgecount)
			{
				edges[i].deleted = false;
				edgeindices ~= i;
			}
			
			sectors ~= Sector(
				edges:edgeindices,
				high:savesector.high,
				low:savesector.low,
				ceilingtex:savesector.ceilingtex,
				floortex:savesector.floortex);
		}
		mapfile.close();
	}
	
	void Delete()
	{
		if(preview.selectedsector != -1)
		{
			sectors[preview.selectedsector].deleted = true;
		}
		
		if(preview.selectededge != -1)
		{
			edges[preview.selectededge].deleted = true;
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
		
		edges[preview.selectededge].portal = preview.selectedsector;
	}
}
