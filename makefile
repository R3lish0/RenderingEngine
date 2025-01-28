# Compiler and flags
CXX = g++
CXXFLAGS = -I./include -std=c++17 -O3 -I/usr/include/lua.hpp
LDFLAGS = -L/usr/local/lib -llua

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

.PHONY: mac
mac: CXX = g++-14
mac: CXXFLAGS = -I./include -std=c++17 -o1 -I/opt/homebrew/Cellar/lua/5.4.7/include/lua
mac: LDFLAGS = -L/opt/homebrew/Cellar/lua/5.4.7/lib -llua
mac: $(TARGET)

# Rule for compiling the object file for bench
bench.o: $(SRC) ./include/rtweekend.h
	$(CXX) $(CXXFLAGS) -c $(SRC) -o ./make/bench.o

# Clean rule
.PHONY: clean
clean:
	rm -f ./make/*
	rm image.ppm
