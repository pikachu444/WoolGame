# Physical knit texture candidate

This is an independent, versioned material candidate. Existing KnitNormal/KnitAO and runtime material settings are not modified.

Run `Tools/Blender/blender-4.5.13-windows-x64/blender.exe --background --python ArtSource/bake_knit_physical.py`.

The source creates three helically twisted yarn plys along rounded stocking-stitch paths. The returns pass behind the next row's raised legs. Four columns and four rows plus surrounding neighbor stitches are projected to a low plane with actual Cycles selected-to-active NORMAL and AO baking. A backing surface closes the valleys. All shapes are independently generated, with no source-game pixels involved.

- Outputs: Textures/PhysicalKnitNormal.png and PhysicalKnitAO.png, 1024×1024, four-by-four stitches.
- Normal map: tangent OpenGL, import as NormalMap, repeat, trilinear mipmaps. Start with strength .45–.65.
- AO is raw 0–1. Do not apply the previous analytic map's (.72,.28) range expansion. Start with lerp(.5,1,rawAO).
- PhysicalKnitBakedPreview.png is a real Blender render of the baked plane under oblique lighting, not game execution evidence.
- PhysicalKnitSource.blend stores the editable high-resolution source and baked low plane. High source is hidden from render so the default preview renders the maps. High source geometry is not shipped as runtime mesh.
- Remaining judgment: this is a chunky knitted material candidate. It requires actual Unity near/far comparison before adoption; normal strength and mip behavior can change its perception substantially.
