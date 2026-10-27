# Optional Emscripten helpers. This browser experiment was generated with AI (Cursor).
# vcpkg still archives MODULE libraries; scripts/build-wasm.sh does the final link.
# Native generators never call the body below.

function(primext_add_game_module target)
	if(CMAKE_SYSTEM_NAME STREQUAL "Emscripten")
		set_target_properties(${target} PROPERTIES
			OUTPUT_NAME "${ARGN}"
			PREFIX ""
			SUFFIX ".wasm"
		)
		target_link_options(${target} PRIVATE
			"SHELL:-s SIDE_MODULE=2"
			"SHELL:-s EXPORT_ALL=1"
			"SHELL:-s ALLOW_MEMORY_GROWTH=1"
			"SHELL:-s IMPORTED_MEMORY=1"
			"SHELL:-s ERROR_ON_UNDEFINED_SYMBOLS=0"
		)
	endif()
endfunction()
