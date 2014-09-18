#include "Map.h"

void MapClass::initmap(unsigned int width, unsigned int height) {
	this->width = width, this->height = height;
	this->Cells.clear();

	for (unsigned int y = 0; y < this->height; y++)
		for (unsigned int x = 0; x < this->width; x++)
			Cells.push_back(new CellClass(x, y));
}

CellClass *MapClass::getcell(unsigned int x, unsigned int y) {
	// printf("getting cell %d %d\n", x, y);
	if (x > this->width-1 || y > this->height-1) return nullptr;
	return this->Cells[(y*width)+x];
}

void MapClass::update_explored(const CellStruct& cent, unsigned int sight) {
	for (unsigned int y = 0; y < this->height; y++)
		for (unsigned int x = 0; x < this->width; x++) {
			CellClass *cell = this->getcell(x, y);

			//	!!! a hack, LocCell of CellClass, same below.
			unsigned int dis = _distance(cent, cell->LocCell);
			if (dis <= sight) cell->setexplored();
		}
}

void MapClass::update_onsight(const CellStruct& cent, unsigned int sight) {
	for (unsigned int y = 0; y < this->height; y++)
		for (unsigned int x = 0; x < this->width; x++) {
			CellClass *cell = this->getcell(x, y);
			unsigned int dis = _distance(cent, cell->LocCell);
			if (dis <= sight) cell->setonsight();
		}
}

void MapClass::clear_on_sight() {
	for (unsigned int y = 0; y < this->height; y++)
		for (unsigned int x = 0; x < this->width; x++)
			this->getcell(x, y)->setonsight(false);
}

void MapClass::clear_on_path() {
	for (unsigned int y = 0; y < this->height; y++)
		for (unsigned int x = 0; x < this->width; x++)
			this->getcell(x, y)->setonpath(false);
}
