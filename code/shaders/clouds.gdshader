shader_type fog;

#include "fastnoiselite.gdshaderinc"

void fog() {
	
	fnl_state noise = fnlCreateState(302941);
	float dense_height = 128.0;
	float ho = (WORLD_POSITION.y - dense_height) / 64.0;
	float height_factor = clamp(1.0 - ho * ho, 0.0, 1.0);
	DENSITY = fnlGetNoise3D(noise, WORLD_POSITION.x, WORLD_POSITION.y, WORLD_POSITION.z) * height_factor;
	ALBEDO = vec3(1, 1, 1);
	// Called once for every froxel that is touched by an axis-aligned bounding box
	// of the associated FogVolume. This means that froxels that just barely touch
	// a given FogVolume will still be used.
}
