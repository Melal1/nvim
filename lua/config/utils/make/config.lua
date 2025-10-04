local Config = {}

Config.DefaultConfig = {
	BuildDir = "./build",
	SourceExtensions = { ".cpp", ".c", ".cc", ".cxx" },
	--TODO: Headers
	RootMarkers = { ".git", "src", "include", "build", "Makefile" },
	MaxSearchLevels = 5,

	MakefileVars = {
		CXX = "g++",
		DEBUGFLAGS = "-std=c++17 -g -O0",
		RELEASEFLAGS = "-std=c++17 -O3 -DNDEBUG",
		CXXFLAGS = "$(DEBUGFLAGS)",
		BUILD_DIR = "./build",
	},
}

return Config
