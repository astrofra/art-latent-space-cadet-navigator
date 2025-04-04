$input vWorldPos, vNormal, vTangent, vBinormal, vTexCoord0, vTexCoord1, vLinearShadowCoord0, vLinearShadowCoord1, vLinearShadowCoord2, vLinearShadowCoord3, vSpotShadowCoord, vProjPos, vPrevProjPos

// HARFANG(R) Copyright (C) 2022 Emmanuel Julien, NWNC HARFANG. Released under GPL/LGPL/Commercial Licence, see licence.txt for details.
#include <forward_pipeline.sh>

#define SAMPLE_WIDTH 20

uniform vec4 uBaseOpacityColor;
uniform vec4 uSelfColor;
uniform vec4 uCustom;	//	uCustom.x,y = UV scale
						//	uCustom.z,w = UV offset
uniform vec4 uFade;		//	uFade.x = master opacity
uniform vec4 uFramerate;		//	uFramerate.x = framerate

SAMPLER2D(uBaseOpacityMap, 0);
SAMPLER2D(uSelfMap, 4);

// Function to compute the texture coordinates based on the frame index
vec2 getFrameUV(vec2 baseTexCoord, float time) {
    float frame_duration = 1.0 / uFramerate.x; // Duration of each frame
    float frame_index = mod(floor(time / frame_duration), 128.0); // Current frame index (0-127)

    // Determine grid position
    vec2 grid_coord = vec2(mod(frame_index, 8.0), floor(frame_index / 8.0)); // 8 images per row, 16 rows
    vec2 tex_coord = (grid_coord + baseTexCoord) * vec2(1.0 / 8.0, 1.0 / 16.0); // Scale to grid UVs

    return tex_coord;
}

float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

void main() {
    vec4 frameColor = vec4(1.0, 0.0, 1.0, 1.0);
    vec4 color_opacity;

// Fetch alpha blending level from the color/opacity texture
#if USE_BASE_COLOR_OPACITY_MAP
    color_opacity = texture2D(uBaseOpacityMap, vTexCoord0);
#else
    color_opacity = vec4(1.0, 0.0, 1.0, 1.0);
#endif

// Fetch the color RGB content from the self illum texture
#if USE_SELF_MAP
    // Use uClock to control the frame sequence
    float time = uClock.x;

    // Get the texture coordinates for the current frame
    vec2 vTexCoord0_xform = vTexCoord0 * uCustom.xy + uCustom.zw;
    vec2 frameUV = getFrameUV(vTexCoord0_xform, time);

    // Sample the packed texture
    frameColor = texture2D(uSelfMap, frameUV);
#else
    frameColor = uSelfColor;
#endif

    vec4 final_color = mix(color_opacity, frameColor, clamp(map(color_opacity.w, 0.25, 1.0, 0.0, 1.0), 0.0, 1.0));

    // Output the color
    gl_FragColor = vec4(final_color.xyz, color_opacity.w * uFade.x);
}
