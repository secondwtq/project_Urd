#include <cstdlib>
#include <cstring>
#include <vector>
using namespace std;

#include "Map.h"
#include "Pathfinding.h"

namespace Pathfinding {

	namespace {
		int xx = 0, yy = 0;
		int xx_, yy_;
		int ll, ww;
		int llmww;

		bool *InsideOpen;
		bool *InsideClose;
		CellStruct *Fathers;
		float *G;
		float *H;
		float *F;

		int numOpen;

		int *bi_t;
		CellStruct *IDCells;
		int *CellIDs;

		CellStruct minF = CellStruct(0, 0);
		CellStruct destCell;

		MapClass *curmap = nullptr;
	}

	void pf_init(MapClass *map) {
		std::cout << "BAPol: Pathfinding::pf_init: initing pathfinding cache...\n";

		unsigned int _x = map->width, _y = map->height;
		// printf("%d %d\n", _x, _y);

		curmap = map;

		xx = _x, yy = _y, xx_ = _x-1, yy_ = _y-1;
		ll = _x+1, ww = _y+1;
		llmww = ll * ww;
		InsideOpen = new bool[llmww];
		InsideClose = new bool[llmww];
		// Cells = (CellClass**)new double[llmww];
		Fathers = new CellStruct[llmww];
		G = new float[llmww];
		H = new float[llmww];
		F = new float[llmww];

		bi_t = new int[llmww];
		IDCells = new CellStruct[llmww];
		CellIDs = new int[llmww];

		// printf("xx: %d\n", xx);
		for (int i = 0; i < xx; i++)
			for (int j = 0; j <= yy; j++) {
				auto cell = curmap->getcell(i, j);
				// Cells[i*xx+j] = cell;

				if (cell) {
					IDCells[cell->RTTIID] = CellStruct(i, j);
					// printf("%d %d %d %x\n", i, xx, j, cell);
					// printf("%d\n", cell->RTTIID);
					CellIDs[i+j*xx] = cell->RTTIID;
				}
			}
	}

	void pf_dispose() {
		std::cout << "BAPol: Pathfinding::pf_dispose: disposing pathfinding cache...\n";

		delete InsideOpen;
		delete InsideClose;
		delete Fathers;
		delete bi_t;
		delete IDCells;
		delete CellIDs;
		delete G;
		delete H;
		delete F;

		InsideOpen = InsideClose = nullptr;
		Fathers = IDCells = nullptr;
		bi_t = CellIDs = nullptr;
		G = H = F = nullptr;

		minF = CellStruct(0, 0);
		curmap = nullptr;

		xx = yy = xx_ = yy_ = ll = ww = llmww = 0;

	}

	void printTree() {
		for (int i = 1; i <= numOpen; i++)
			printf("%d_%f ", bi_t[i], F[bi_t[i]]);
		printf("\n");
	}

	void Find_rec() {
		int px = minF.x, py = minF.y;
		InsideClose[CellIDs[px+py*xx]] = true;
		if (minF == destCell) return;

		static const std::size_t N_CELLS = 8;
		CellStruct _cells[N_CELLS];
		bool canAdd[N_CELLS];
		memset(canAdd, 0, sizeof(canAdd));
		// _cells[0].x = px-1, _cells[0].y = py-1;
		_cells[0].x = px, _cells[0].y = py-1;
		// _cells[2].x = px+1, _cells[2].y = py-1;
		_cells[1].x = px+1, _cells[1].y = py;
		// _cells[4].x = px+1, _cells[4].y = py+1;
		_cells[2].x = px, _cells[2].y = py+1;
		// _cells[6].x = px-1, _cells[6].y = py+1;
		_cells[3].x = px-1, _cells[3].y = py;

		for (unsigned int i = 0; i < N_CELLS; i++) {
			int x = _cells[i].x, y = _cells[i].y;
			if (x >= 0 && x <= xx_ && y >= 0 && y <= yy_)
				if (curmap->getcell(x, y)->ispassable()) canAdd[i] = true;
		}
		// if (!canAdd[1]) { canAdd[0] = canAdd[2] = false; }
		// if (!canAdd[3]) { canAdd[2] = canAdd[4] = false; }
		// if (!canAdd[5]) { canAdd[4] = canAdd[6] = false; }
		// if (!canAdd[7]) { canAdd[0] = canAdd[6] = false; }

		CellStruct cells[N_CELLS];
		unsigned char num = 0;
		for (unsigned int i = 0; i < N_CELLS; i++) {
			if (canAdd[i]) cells[num++] = _cells[i];
		}

		for (size_t i = 0; i < num; i++) {
			int x = cells[i].x, y = cells[i].y;
			int offset = x+y*xx;
			int id = CellIDs[offset];
			if (!InsideClose[id]) {
				bool better = false;
				int _G = G[px+py*xx] + 1;

				if (!InsideOpen[id]) {
					InsideOpen[id] = true;
					better = true;

					G[offset] = _G;
					int th = abs(x-destCell.x) + abs(y-destCell.y);
					H[id] = th;
					F[id] = _G+th;
					numOpen++;
					bi_t[numOpen] = id;

					for (int m = numOpen; m > 1; ) {
						if (F[bi_t[m]] <= F[bi_t[m/2]]) {
							int _t = bi_t[m/2];
							bi_t[m/2] = bi_t[m];
							bi_t[m] = _t;
							m /= 2;
						} else break;
					}
				}
				else if (_G < G[offset]) better = true;
				else better = false;
				if (better) {
					Fathers[offset] = minF;
					F[id] = _G+H[id];

					int heapl = 0;
					for (int i = 1; i <= numOpen; i++)
						if (bi_t[i] == id) { heapl = i; break; }
					for (int m = heapl; m > 1; ) {
						if (F[bi_t[m]] <= F[bi_t[m/2]]) {
							int _t = bi_t[m/2];
							bi_t[m/2] = bi_t[m];
							bi_t[m] = _t;
							m /= 2;
						} else break;
					}
				}
			}
		}

		minF = IDCells[bi_t[1]];
		if (InsideOpen[bi_t[1]]) {
			InsideOpen[bi_t[1]] = false;
			bi_t[1] = bi_t[numOpen];
			numOpen--;
			for (int v = 1;;) {
				int u = v;
				if ((2*u+1) <= numOpen) {
					if (F[bi_t[u]] >= F[bi_t[2*u]]) v = 2 * u;
					if (F[bi_t[v]] >= F[bi_t[2*u+1]]) v = 2*u+1;
				} else if (2 * u <= numOpen) if (F[bi_t[u]] >= F[bi_t[2*u]]) v = 2*u;
				if (u != v) {
					int t = bi_t[u];
					bi_t[u] = bi_t[v];
					bi_t[v] = t;
				} else break;
			}
		}
		Find_rec();
	}

	bool find(CellClass *src, CellClass *dest, Pathfindingcache *cache) {
		if (src->ispassable() && dest->ispassable()) {
			memset(InsideOpen, 0, sizeof(bool) * llmww);
			memset(InsideClose, 0, sizeof(bool) * llmww);
			memset(F, 0, sizeof(int) * llmww);

			numOpen = 0;
			CellStruct ss = CellStruct(src->LocCell.x, src->LocCell.y);
			minF = ss;
			destCell = CellStruct(dest->LocCell.x, dest->LocCell.y);

			F[CellIDs[ss.x+ss.y*xx]] = abs(ss.x-destCell.x) + abs(ss.y-destCell.y);
			G[ss.x+ss.y*xx] = 0;
			Fathers[ss.x+ss.y*xx] = CellStruct(-1, -1);

			Find_rec();

			vector<CellClass *> _cache;
			CellStruct v = Fathers[destCell.x+destCell.y*xx];
			_cache.push_back(dest);
			while (v.x != -1) {
				CellClass *cell = curmap->getcell(v.x, v.y);
				_cache.push_back(cell);
				cell->setonpath(true);
				destCell.x = v.x, destCell.y = v.y;
				v = Fathers[destCell.x+destCell.y*xx];
			}
			cache->initFromRev(_cache);
			return true;
		}
		return false;
	}

	void Find_rec_8() {
		int px = minF.x, py = minF.y;
		InsideClose[CellIDs[px+py*xx]] = true;
		if (minF == destCell) return;

		static const std::size_t N_CELLS = 8;
		CellStruct _cells[N_CELLS];
		bool canAdd[N_CELLS];
		memset(canAdd, 0, sizeof(canAdd));
		_cells[0].x = px-1, _cells[0].y = py-1;
		_cells[1].x = px, _cells[1].y = py-1;
		_cells[2].x = px+1, _cells[2].y = py-1;
		_cells[3].x = px+1, _cells[3].y = py;
		_cells[4].x = px+1, _cells[4].y = py+1;
		_cells[5].x = px, _cells[5].y = py+1;
		_cells[6].x = px-1, _cells[6].y = py+1;
		_cells[7].x = px-1, _cells[7].y = py;

		for (unsigned int i = 0; i < N_CELLS; i++) {
			int x = _cells[i].x, y = _cells[i].y;
			if (x >= 0 && x <= xx_ && y >= 0 && y <= yy_)
				if (curmap->getcell(x, y)->ispassable()) canAdd[i] = true;
		}
		if (!canAdd[1]) { canAdd[0] = canAdd[2] = false; }
		if (!canAdd[3]) { canAdd[2] = canAdd[4] = false; }
		if (!canAdd[5]) { canAdd[4] = canAdd[6] = false; }
		if (!canAdd[7]) { canAdd[0] = canAdd[6] = false; }

		CellStruct cells[N_CELLS];
		unsigned char num = 0;
		for (unsigned int i = 0; i < N_CELLS; i++) {
			if (canAdd[i]) cells[num++] = _cells[i];
		}

		for (size_t i = 0; i < num; i++) {
			int x = cells[i].x, y = cells[i].y;
			int offset = x+y*xx;
			int id = CellIDs[offset];
			if (!InsideClose[id]) {
				bool better = false;
				float _G;
				if (cells[i] == _cells[0] || cells[i] == _cells[2] || cells[i] == _cells[4] || cells[i] == _cells[6])
					_G = G[px+py*xx] + 1.414 * curmap->getcell(px, py)->infl_factor;
				else _G = G[px+py*xx] + 1 * curmap->getcell(px, py)->infl_factor;

				if (!InsideOpen[id]) {
					InsideOpen[id] = true;
					better = true;

					G[offset] = _G;
					int th = abs(x-destCell.x) + abs(y-destCell.y);
					H[id] = th;
					F[id] = _G+th;
					numOpen++;
					bi_t[numOpen] = id;

					for (int m = numOpen; m > 1; ) {
						if (F[bi_t[m]] <= F[bi_t[m/2]]) {
							int _t = bi_t[m/2];
							bi_t[m/2] = bi_t[m];
							bi_t[m] = _t;
							m /= 2;
						} else break;
					}
				}
				else if (_G < G[offset]) better = true;
				else better = false;
				if (better) {
					Fathers[offset] = minF;
					F[id] = _G+H[id];

					int heapl = 0;
					for (int i = 1; i <= numOpen; i++)
						if (bi_t[i] == id) { heapl = i; break; }
					for (int m = heapl; m > 1; ) {
						if (F[bi_t[m]] <= F[bi_t[m/2]]) {
							int _t = bi_t[m/2];
							bi_t[m/2] = bi_t[m];
							bi_t[m] = _t;
							m /= 2;
						} else break;
					}
				}
			}
		}

		minF = IDCells[bi_t[1]];
		if (InsideOpen[bi_t[1]]) {
			InsideOpen[bi_t[1]] = false;
			bi_t[1] = bi_t[numOpen];
			numOpen--;
			for (int v = 1;;) {
				int u = v;
				if ((2*u+1) <= numOpen) {
					if (F[bi_t[u]] >= F[bi_t[2*u]]) v = 2 * u;
					if (F[bi_t[v]] >= F[bi_t[2*u+1]]) v = 2*u+1;
				} else if (2 * u <= numOpen) if (F[bi_t[u]] >= F[bi_t[2*u]]) v = 2*u;
				if (u != v) {
					int t = bi_t[u];
					bi_t[u] = bi_t[v];
					bi_t[v] = t;
				} else break;
			}
		}
		Find_rec_8();
	}

	bool find_8(CellClass *src, CellClass *dest, Pathfindingcache *cache) {
		if (src->ispassable() && dest->ispassable()) {
			memset(InsideOpen, 0, sizeof(bool) * llmww);
			memset(InsideClose, 0, sizeof(bool) * llmww);
			memset(F, 0, sizeof(int) * llmww);

			numOpen = 0;
			CellStruct ss = CellStruct(src->LocCell.x, src->LocCell.y);
			minF = ss;
			destCell = CellStruct(dest->LocCell.x, dest->LocCell.y);

			F[CellIDs[ss.x+ss.y*xx]] = abs(ss.x-destCell.x) + abs(ss.y-destCell.y);
			G[ss.x+ss.y*xx] = 0;
			Fathers[ss.x+ss.y*xx] = CellStruct(-1, -1);

			Find_rec_8();

			vector<CellClass *> _cache;
			CellStruct v = Fathers[destCell.x+destCell.y*xx];
			_cache.push_back(dest);

			{
				CellClass *c = nullptr;
				if (dest->LocCell.x == v.x+1 && dest->LocCell.y == v.y+1) {
					if ((c = curmap->getcell(v.x+1, v.y)) && c->ispassable())
						_cache.push_back(c);
					else if (((c = curmap->getcell(v.x, v.y+1)) && c->ispassable())) _cache.push_back(c);
				} else if (dest->LocCell.x == v.x-1 && dest->LocCell.y == v.y-1) {
					if ((c = curmap->getcell(v.x, v.y-1)) && c->ispassable())
						_cache.push_back(c);
					else if (((c = curmap->getcell(v.x-1, v.y)) && c->ispassable())) _cache.push_back(c);
				} else if (dest->LocCell.x == v.x-1 && dest->LocCell.y == v.y+1) {
					if ((c = curmap->getcell(v.x-1, v.y)) && c->ispassable())
						_cache.push_back(curmap->getcell(v.x-1, v.y));
					else if (((c = curmap->getcell(v.x, v.y+1)) && c->ispassable())) _cache.push_back(c);
				} else if (dest->LocCell.x == v.x+1 && dest->LocCell.y == v.y-1) {
					if ((c = curmap->getcell(v.x, v.y-1)) && c->ispassable())
						_cache.push_back(curmap->getcell(v.x, v.y-1));
					else if (((c = curmap->getcell(v.x+1, v.y)) && c->ispassable())) _cache.push_back(c);
				}
			}

			while (v.x != -1) {
				CellClass *cell = curmap->getcell(v.x, v.y);
				_cache.push_back(cell);
				cell->setonpath(true);
				destCell.x = v.x, destCell.y = v.y;
				v = Fathers[destCell.x+destCell.y*xx];

				{
					CellClass *c = nullptr;
					if (cell->LocCell.x == v.x+1 && cell->LocCell.y == v.y+1) {
						if ((c = curmap->getcell(v.x+1, v.y)) && c->ispassable())
							{ c->setonpath(true); _cache.push_back(c); }
						else if (((c = curmap->getcell(v.x, v.y+1)) && c->ispassable())) { c->setonpath(true); _cache.push_back(c); }
					} else if (cell->LocCell.x == v.x-1 && cell->LocCell.y == v.y-1) {
						if ((c = curmap->getcell(v.x, v.y-1)) && c->ispassable())
							{ c->setonpath(true); _cache.push_back(c); }
						else if (((c = curmap->getcell(v.x-1, v.y)) && c->ispassable())) { c->setonpath(true); _cache.push_back(c); }
					} else if (cell->LocCell.x == v.x-1 && cell->LocCell.y == v.y+1) {
						if ((c = curmap->getcell(v.x-1, v.y)) && c->ispassable())
							{ c->setonpath(true); _cache.push_back(c); }
						else if (((c = curmap->getcell(v.x, v.y+1)) && c->ispassable())) { c->setonpath(true); _cache.push_back(c); }
					} else if (cell->LocCell.x == v.x+1 && cell->LocCell.y == v.y-1) {
						if ((c = curmap->getcell(v.x, v.y-1)) && c->ispassable())
							{ c->setonpath(true); _cache.push_back(c); }
						else if (((c = curmap->getcell(v.x+1, v.y)) && c->ispassable())) { c->setonpath(true); _cache.push_back(c); }
					}
				}
			}
			cache->initFromRev(_cache);
			return true;
		}
		return false;
	}
}
