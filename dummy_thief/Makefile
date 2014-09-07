OBJECTS = SocketWrapper.o main.o
OUTPUT=main

BUILD_PATH = ./Build/
BINARY_PARH = .
SOURCE_PATH = ./

LUA_PATH = ./lua-5_23/

CXXFLAGS=-Wall -std=c++11 -O -isystem/usr/local/include 
LDFLAGS=-Wall -L/usr/local/lib -L./ -llua523_static /usr/local/Cellar/boost/1.55.0_2/lib/libboost_system.a \

_OBJECTS=$(addprefix $(BUILD_PATH),$(OBJECTS))

LINK_OBJECTS = $(_OBJECTS)
compile: ready objects link final

run:
	@./$(OUTPUT)

clean:
	@rm -rf $(_OBJECTS)
	@echo Clean completed.

$(BUILD_PATH)%.o: $(SOURCE_PATH)%.cpp
	@echo Compiling $< ...
	@$(CXX) -c $<		$(CXXFLAGS) -o		$@

ready:

final:
	@echo Build finished.

objects: $(_OBJECTS)

link:
	@echo Linking...
	@$(CXX) -o $(BINARY_PARH)/$(OUTPUT) $(LINK_OBJECTS) $(LDFLAGS)