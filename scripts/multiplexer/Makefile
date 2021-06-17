# Author: Jon Larrea

# COMPILER
CC = gcc

#FLAGS
CFLAGS = -c -Wall -ansi -g -std=c99

#LINK FLAGS
LINKFLAGS = -lpthread

TARGET = nervion_multiplexer

# PATHS
SOURCE_DIRECTORY = source/
INCLUDE_DIRECTORY = headers/
OBJECT_DIRECTORY = objects/
BUILD_DIRECTORY = build/

CFILES = $(wildcard $(SOURCE_DIRECTORY)*.c)
OBJECTS = $(patsubst $(SOURCE_DIRECTORY)%.c, $(OBJECT_DIRECTORY)%.o, $(CFILES))

all: $(LIB) $(OBJECT_DIRECTORY) $(TARGET)

$(TARGET): $(OBJECTS)
	@echo "Building $@..."
	@echo "$(CURRENT_DIR)$(LIB_PATH)$(LIB)"
	@$(CC) $(OBJECTS) $(LINKFLAGS) -o $@

$(OBJECT_DIRECTORY):
	@mkdir $(OBJECT_DIRECTORY)

$(OBJECT_DIRECTORY)%.o: $(SOURCE_DIRECTORY)%.c
	@echo "Building $@..."
	@$(CC) -I $(INCLUDE_DIRECTORY) -I $(LIB_PATH)include/ $(CFLAGS) $< -o $@

.PHONY: clean
clean:
	@echo "Removing objects files..."
	@rm -rf $(OBJECT_DIRECTORY) $(TARGET)
