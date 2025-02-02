# Compiler and flags
CXX = g++
#CXXFLAGS = -I./include -std=c++17 -O3 -I/usr/include/lua.hpp
#LDFLAGS = -L/usr/local/lib -llua

#CXX = g++-14
CXXFLAGS = -I./include -std=c++17 -o3 -I/opt/homebrew/Cellar/lua/5.4.7/include/lua \
           -I./metal-cpp -I./metal-cpp/Metal -I./metal-cpp/Foundation -I./metal-cpp/QuartzCore \
           -framework Metal -framework Foundation -framework QuartzCore

LDFLAGS = -L/opt/homebrew/Cellar/lua/5.4.7/lib -llua \
          -framework Metal -framework Foundation -framework QuartzCore

# Default source file
SRC = ./src/main.cc

# Output file
TARGET = ./make/output

# Rule for building the target
$(TARGET): main.o
	$(CXX) ./make/main.o $(LDFLAGS) -o $(TARGET)

# Rule for compiling the object file
main.o: $(SRC) ./include/rtweekend.h
	$(CXX) $(CXXFLAGS) -c $(SRC) -o ./make/main.o

# Bench target
.PHONY: bench
bench: SRC = ./src/bench.cc
bench: $(TARGET)

.PHONY: mac_s
mac_s: CXX = g++-14
mac_s: CXXFLAGS = -I./include -std=c++17 -o3 -I/usr/local/Cellar/lua/5.4.7/include/lua
mac_s: LDFLAGS = -L/usr/local/Cellar/lua/5.4.7/lib -llua
mac_s: $(TARGET)

.PHONY: linux 
linux: CXX = g++-14
linux: CXXFLAGS = -I./include -std=c++17 -o3 -I/opt/homebrew/Cellar/lua/5.4.7/include/lua
linux: LDFLAGS = -L/opt/homebrew/Cellar/lua/5.4.7/lib -llua
linux: $(TARGET)

# Rule for compiling the object file for bench
bench.o: $(SRC) ./include/rtweekend.h
	$(CXX) $(CXXFLAGS) -c $(SRC) -o ./make/bench.o

# Clean rule
.PHONY: clean
clean:
	rm -f ./make/*
	rm image.ppm
