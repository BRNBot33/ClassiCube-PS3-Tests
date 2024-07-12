SOURCE_DIR  = src
BUILD_DIR   = build
C_SOURCES   = $(wildcard $(SOURCE_DIR)/*.c)
C_OBJECTS   = $(patsubst $(SOURCE_DIR)/%.c, $(BUILD_DIR)/%.o, $(C_SOURCES))

OBJECTS = $(C_OBJECTS)
ENAME   = ClassiCube
CFLAGS  = -g -pipe -fno-math-errno -Werror -Wno-error=missing-braces -Wno-error=strict-aliasing -Wno-error=maybe-uninitialized
LDFLAGS = -g -rdynamic

ifndef RM
	# No prefined RM variable, try to guess OS default
	ifeq ($(OS),Windows_NT)
		RM = del
	else
		RM = rm -f
	endif
endif

# Enables dependency tracking (https://make.mad-scientist.net/papers/advanced-auto-dependency-generation/)
# This ensures that changing a .h file automatically results in the .c files using it being auto recompiled when next running make
# On older systems the required GCC options may not be supported - in which case just change TRACK_DEPENDENCIES to 0
TRACK_DEPENDENCIES=1

ifndef $(PLAT)
	ifeq ($(OS),Windows_NT)
		PLAT = mingw
	else
		PLAT = $(shell uname -s | tr '[:upper:]' '[:lower:]')
	endif
endif

ifeq ($(PLAT),web)
	CC      = emcc
	OEXT    = .html
	CFLAGS  = -g
	LDFLAGS = -g -s WASM=1 -s NO_EXIT_RUNTIME=1 -s ALLOW_MEMORY_GROWTH=1 -s TOTAL_STACK=1Mb --js-library $(SOURCE_DIR)/interop_web.js
	BUILD_DIR = build-web
endif

ifeq ($(PLAT),mingw)
	CC      =  gcc
	OEXT    =  .exe
	CFLAGS  += -DUNICODE
	LDFLAGS =  -g
	LIBS    =  -mwindows -lwinmm -limagehlp
	BUILD_DIR = build-win
endif

ifeq ($(PLAT),linux)
	CFLAGS  += -DCC_BUILD_ICON
	LIBS    =  -lX11 -lXi -lpthread -lGL -ldl
	BUILD_DIR = build-linux
endif

ifeq ($(PLAT),sunos)
	CFLAGS  += -DCC_BUILD_ICON
	LIBS    =  -lsocket -lX11 -lXi -lGL
	BUILD_DIR = build-solaris
endif

ifeq ($(PLAT),darwin)
	OBJECTS += $(BUILD_DIR)/Window_cocoa.o
	CFLAGS  += -DCC_BUILD_ICON
	LIBS    =
	LDFLAGS =  -rdynamic -framework Cocoa -framework OpenGL -framework IOKit -lobjc
	BUILD_DIR = build-macos
endif

ifeq ($(PLAT),freebsd)
	CFLAGS  += -I /usr/local/include -DCC_BUILD_ICON
	LDFLAGS =  -L /usr/local/lib -rdynamic
	LIBS    =  -lexecinfo -lGL -lX11 -lXi -lpthread
	BUILD_DIR = build-freebsd
endif

ifeq ($(PLAT),openbsd)
	CFLAGS  += -I /usr/X11R6/include -I /usr/local/include -DCC_BUILD_ICON
	LDFLAGS =  -L /usr/X11R6/lib -L /usr/local/lib -rdynamic
	LIBS    =  -lexecinfo -lGL -lX11 -lXi -lpthread
	BUILD_DIR = build-openbsd
endif

ifeq ($(PLAT),netbsd)
	CFLAGS  += -I /usr/X11R7/include -I /usr/pkg/include -DCC_BUILD_ICON
	LDFLAGS =  -L /usr/X11R7/lib -L /usr/pkg/lib -rdynamic
	LIBS    =  -lexecinfo -lGL -lX11 -lXi -lpthread
	BUILD_DIR = build-netbsd
endif

ifeq ($(PLAT),dragonfly)
	CFLAGS  += -I /usr/local/include -DCC_BUILD_ICON
	LDFLAGS =  -L /usr/local/lib -rdynamic
	LIBS    =  -lexecinfo -lGL -lX11 -lXi -lpthread
	BUILD_DIR = build-flybsd
endif

ifeq ($(PLAT),haiku)
	OBJECTS += $(BUILD_DIR)/Platform_BeOS.o $(BUILD_DIR)/Window_BeOS.o
	CFLAGS  = -g -pipe -fno-math-errno
	LDFLAGS = -g
	LIBS    = -lGL -lnetwork -lstdc++ -lbe -lgame -ltracker
	BUILD_DIR = build-haiku
endif

ifeq ($(PLAT),beos)
	OBJECTS += $(BUILD_DIR)/Platform_BeOS.o $(BUILD_DIR)/Window_BeOS.o
	CFLAGS  = -g -pipe
	LDFLAGS = -g
	LIBS    = -lGL -lnetwork -lstdc++ -lbe -lgame -ltracker
	BUILD_DIR = build-beos
	TRACK_DEPENDENCIES=0
endif

ifeq ($(PLAT),serenityos)
	LIBS    = -lgl -lSDL2
	BUILD_DIR = build-serenity
endif

ifeq ($(PLAT),irix)
	CC      = gcc
	LIBS    = -lGL -lX11 -lXi -lpthread -ldl
	BUILD_DIR = build-irix
endif


ifdef SDL2
	CFLAGS += -DCC_WIN_BACKEND=CC_WIN_BACKEND_SDL2
	LIBS += -lSDL2
endif
ifdef SDL3
	CFLAGS += -DCC_WIN_BACKEND=CC_WIN_BACKEND_SDL3
	LIBS += -lSDL3
endif

ifdef TERMINAL
	CFLAGS += -DCC_WIN_BACKEND=CC_WIN_BACKEND_TERMINAL -DCC_GFX_BACKEND=CC_GFX_BACKEND_SOFTGPU
	LIBS := $(subst mwindows,mconsole,$(LIBS))
endif

default: $(PLAT)

web:
	$(MAKE) $(ENAME) PLAT=web
linux:
	$(MAKE) $(ENAME) PLAT=linux
mingw:
	$(MAKE) $(ENAME) PLAT=mingw
sunos:
	$(MAKE) $(ENAME) PLAT=sunos
darwin:
	$(MAKE) $(ENAME) PLAT=darwin
freebsd:
	$(MAKE) $(ENAME) PLAT=freebsd
openbsd:
	$(MAKE) $(ENAME) PLAT=openbsd
netbsd:
	$(MAKE) $(ENAME) PLAT=netbsd
dragonfly:
	$(MAKE) $(ENAME) PLAT=dragonfly
haiku:
	$(MAKE) $(ENAME) PLAT=haiku
beos:
	$(MAKE) $(ENAME) PLAT=beos
serenityos:
	$(MAKE) $(ENAME) PLAT=serenityos
irix:
	$(MAKE) $(ENAME) PLAT=irix

# Default overrides
sdl2:
	$(MAKE) $(ENAME) SDL2=1
sdl3:
	$(MAKE) $(ENAME) SDL3=1
terminal:
	$(MAKE) $(ENAME) TERMINAL=1

# Some builds require more complex handling, so are moved to
#  separate makefiles to avoid having one giant messy makefile
dreamcast:
	$(MAKE) -f misc/dreamcast/Makefile
saturn:
	$(MAKE) -f misc/saturn/Makefile
psp:
	$(MAKE) -f misc/psp/Makefile
vita:
	$(MAKE) -f misc/vita/Makefile
ps1:
	cmake --preset default misc/ps1
	cmake --build misc/ps1/build
ps2:
	$(MAKE) -f misc/ps2/Makefile
ps3:
	$(MAKE) -f misc/ps3/Makefile
xbox:
	$(MAKE) -f misc/xbox/Makefile
xbox360:
	$(MAKE) -f misc/xbox360/Makefile
n64:
	$(MAKE) -f misc/n64/Makefile
ds:
	$(MAKE) -f misc/ds/Makefile
3ds:
	$(MAKE) -f misc/3ds/Makefile
gamecube:
	$(MAKE) -f misc/gc/Makefile
wii:
	$(MAKE) -f misc/wii/Makefile
wiiu:
	$(MAKE) -f misc/wiiu/Makefile
switch:
	$(MAKE) -f misc/switch/Makefile
os/2:
	$(MAKE) -f misc/os2/Makefile
macclassic_68k:
	$(MAKE) -f misc/macclassic/Makefile_68k
macclassic_ppc:
	$(MAKE) -f misc/macclassic/Makefile_ppc
	
clean:
	$(RM) $(OBJECTS)


$(ENAME): $(BUILD_DIR) $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@$(OEXT) $(OBJECTS) $(EXTRA_LIBS) $(LIBS)
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)


# === Compiling with dependency tracking ===
# NOTE: Tracking dependencies might not work on older systems - disable this if so
ifeq ($(TRACK_DEPENDENCIES), 1)
DEPFLAGS = -MT $@ -MMD -MP -MF $(BUILD_DIR)/$*.d
DEPFILES := $(patsubst $(SOURCE_DIR)/%.c, $(BUILD_DIR)/%.d, $(C_SOURCES))
$(DEPFILES):

$(C_OBJECTS): $(BUILD_DIR)/%.o : $(SOURCE_DIR)/%.c $(BUILD_DIR)/%.d
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) $(DEPFLAGS) -c $< -o $@

include $(wildcard $(DEPFILES))
# === Compiling WITHOUT dependency tracking ===
else
$(C_OBJECTS): $(BUILD_DIR)/%.o : $(SOURCE_DIR)/%.c
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -c $< -o $@
endif
	
# === Platform specific file compiling ===
$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.m
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -c $< -o $@
	
$(BUILD_DIR)/%.o: $(SOURCE_DIR)/%.cpp
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -c $< -o $@

# EXTRA_CFLAGS and EXTRA_LIBS are not defined in the makefile intentionally -
# define them on the command line as a simple way of adding CFLAGS/LIBS
