This is a collection of useful Nimrod modules. The theme is Game Development.
Examples of usage can usually be found at the end of the module's source or in
the `examples/` directory

```
If any of these is missing license (they probably all are) then you can treat 
them as public domain, no attribution required. Licenses listed below are for
the corresponding (wrapped) software. The wrapper itself does not fall under
this license.
``` 

## Modules
* fowltek/vector_math - implements types for vectors of two, three and four
* fowltek/entitty - implements a dynamic component/entity system
* fowltek/pointer_arithm - implements pointer arithmetic for use with c libraries
* fowltek/maybe_t - implements a `Maybe[T]` 
* fowltek/idgen - a simple sequential ID generator
* Spatial organizationing: fowltek/bbtree, fowltek/qtree

## Wrappers

### Graphics
* SDL2  http://libsdl.org - moved to its own package (ZLib)
* Assimp (Open Asset Import Library) - moved to its own package (BSD, more info: http://assimp.sourceforge.net/main_license.html)
* Devil - image loading and editing software (LGPL)
* Clutter - nice gtk-ish gui library
* Horde3D - an open source 3D rendering engine (Eclipse Public License v1.0 (EPL))
* FTGL (FreeTypeGL http://sf.net/projects/ftgl) - for the fonts and such (LGPLv2)

### Physics
* ODE (Open Dynamics Engine) - a performant 3D physics library used in many commercial games
* Bullet - another high performance 3D physics library. This wrapper may not be complete, it is based off Bullet's C-API which is limited.

### Other
* FANN (Fast Artificial Neural Net http://leenissen.dk/)
