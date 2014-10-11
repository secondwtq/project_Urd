#ifndef H_URD_MAP
#define H_URD_MAP

#include <iostream>
#include <vector>
#include <algorithm>
#include <cstdlib>

template <typename T>
class VectorT { };

template <typename T>
class Vector2DT : public VectorT<T> {
	public:
		T x, y;
		Vector2DT() : x(), y() { }
		Vector2DT(T _x, T _y) : x(_x), y(_y) { }

		bool operator==(const Vector2DT<T> &o) { return ((this->x == o.x) && (this->y == o.y)); }
		Vector2DT<T> &operator=(const Vector2DT<T> &o) { this->x = o.x, this->y = o.y; return *this; }
		Vector2DT<T> &operator+=(const Vector2DT<T> &o) { x+=o.x, y+=o.y; return *this; }
		Vector2DT<T> operator+(const Vector2DT<T> &o) { Vector2DT<T> ret = *this; ret += o; return ret; }
};

using CellStruct = Vector2DT<int>;

inline unsigned int _distance(const CellStruct& p1, const CellStruct& p2) {
	return std::max(abs(p1.x-p2.x), abs(p1.y-p2.y));
}

static unsigned int _cell_Max_ID = 0;

class CellClass {
	public:
		unsigned int RTTIID = 0;

		CellStruct LocCell = CellStruct(0, 0);

		CellClass(unsigned int locx, unsigned int locy) : LocCell(locx, locy) {
			this->RTTIID = ++_cell_Max_ID;
		}

		bool unpassable = false, explored = false, on_sight = false, on_path = false;

		bool ispassable() { return !(this->unpassable); }

		void setunpassable(bool p = true) { this->unpassable = p; }

		bool isexplored() { return this->explored; }

		void setexplored(bool p = true) { this->explored = p; }

		bool isonsight() { return this->on_sight; }

		void setonsight(bool p = true) { this->on_sight = p; }

		bool isonpath() { return this->on_path; }

		void setonpath(bool p = true) { this->on_path = p; }

		CellStruct getpos() { return this->LocCell; }
};

class MapClass {
	public:

		unsigned int width = 0, height = 0;
		std::vector <CellClass *> Cells;

		void initmap(unsigned int width, unsigned int height);

		// bool iscellexplored(unsigned int x, unsigned int y);

		// bool setcellexplored(unsigned int x, unsigned int y, bool p = true);

		CellClass *getcell(int x, int y);

		// CellClass *getneighborcell(CellClass *cell, unsigned int dir);

		void update_explored(const CellStruct& cent, unsigned int sight);

		void update_onsight(const CellStruct& cent, unsigned int sight);

		void clear_on_sight();

		void clear_on_path();

		~MapClass() {
			std::cout << "BAPol: MapClass::~MapClass: disposing map...\n";
			for (unsigned int y = 0; y < this->height; y++)
				for (unsigned int x = 0; x < this->width; x++)
					delete this->getcell(x, y);
		}

		// void iscellpassable(unsigned int x, unsigned int y);
};

#endif
