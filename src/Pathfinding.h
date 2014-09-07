#ifndef H_URD_PATHFINDING
#define H_URD_PATHFINDING

#include <vector>

#include "Map.h"

namespace Pathfinding {

	class Pathfindingcache;

	void pf_init(MapClass *map);
	void pf_dispose();

	bool find(CellClass *src, CellClass *dest, Pathfindingcache *cache);

	class Pathfindingcache {
		public:
			std::size_t idx = 0;
			std::vector<CellClass *> cache;

			void reset() { idx = 0; cache.clear(); }

			void init(const std::vector<CellClass *> &src) {
				cache = src;
			}

			void initFromRev(const std::vector<CellClass *> &src) {
				reset();
				for (auto r = src.crbegin(); r != src.crend(); ++r)
					cache.push_back(*r);
			}

			void inc() { if(idx < cache.size()) idx++; }

			CellClass *next() {
				this->inc();
				return this->getCur();
			}

			CellClass *getCur() { return cache[idx]; }
			CellClass *getNex() {
				if (idx < cache.size()-1) { return cache[idx+1]; }
				return cache[idx];
			}

			CellClass *getNexNex() {
				if (idx < cache.size()-2) { return cache[idx+2]; }
				return cache[idx];
			}

			bool ended() { return idx >= cache.size()-1; }

			bool inside(CellClass *src) {
				for (std::size_t i = idx; i < cache.size(); i++)
					if (src == cache[i]) return true;
				return false;
			}

			void jump_to(CellClass *src) {
				for (std::size_t i = idx; i < cache.size(); i++)
					if (src == cache[i]) {
						idx = i+1;
						return;
					}
			}
	};

}

#endif