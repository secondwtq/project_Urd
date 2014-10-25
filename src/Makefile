OBJECTS = SocketWrapper.o main.o Map.o Pathfinding.o Utils.o
OUTPUT=main

BUILD_PATH = ./Build/
BINARY_PARH = .
SOURCE_PATH = ./

CXXFLAGS_=-Wall -std=c++11 -O2 -isystem../include -g
LDFLAGS_=-Wall -L../lib/

CXXFLAGS_DARWIN = 
CXXFLAGS_MINGW =

LDFLAGS_DARWIN = -lboost155_system_darwinclang -llua523_static_darwinclang -lboost155_program_options_darwinclang
LDFLAGS_MINGW = -llua523_static_mingw -lboost155_system_mingw -lboost155_program_options_mingw -lws2_32 -static

RUN_FLAGS =

CXXFLAGS = $(CXXFLAGS_) $(CXXFLAGS_DARWIN)
LDFLAGS = $(LDFLAGS_) $(LDFLAGS_DARWIN)

OS := $(shell uname)

_OBJECTS=$(addprefix $(BUILD_PATH),$(OBJECTS))

LINK_OBJECTS = $(_OBJECTS)


ifeq ($(OS), Darwin)
CXXFLAGS = $(CXXFLAGS_) $(CXXFLAGS_DARWIN)
LDFLAGS = $(LDFLAGS_) $(LDFLAGS_DARWIN)
else
CXXFLAGS = $(CXXFLAGS_) $(CXXFLAGS_MINGW)
LDFLAGS = $(LDFLAGS_) $(LDFLAGS_MINGW)
endif

compile: ready objects link final

run:
	@./$(OUTPUT) $(RUN_FLAGS)

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