#version 330 core
uniform vec3 iResolution;
uniform float iTime;
uniform vec2 uCenter;
out vec4 fragColor;

void main() {
  vec2 fragCoord = gl_FragCoord.xy;

  float maxRadius = 1280.0;
  float duration = 2.0;
  float expandDuration = 1.0;
  float contractDuration = 1.0;

  float totalTime = clamp(iTime, 0.0, duration);

  float radius;
  if (totalTime <= expandDuration) {
    float t = totalTime / expandDuration;
    radius = t * maxRadius;
  } else {
    float t = (totalTime - expandDuration) / contractDuration;
    radius = (1.0 - t) * maxRadius;
  }

  float ringThickness = 5.0;
  float edgeSoftness = 8.0;

  vec2 dir = fragCoord - uCenter;
  float angle = atan(dir.y, dir.x);
  float len = length(dir);

  float waveFreq = 6.0;
  float waveAmp = 1.5;
  float waveSpeed = 6.0;
  float innerWave = sin(angle * waveFreq + totalTime * waveSpeed) * waveAmp;

  float innerRadius = radius - ringThickness + innerWave;
  float outerRadius = radius;

  float innerEdge = smoothstep(innerRadius - edgeSoftness, innerRadius, len);
  float outerEdge = 1.0 - smoothstep(outerRadius, outerRadius + edgeSoftness, len);
  float ring = innerEdge * outerEdge;

  vec3 baseColor1 = vec3(1.0, 0.4, 0.8);  // pink
  vec3 baseColor2 = vec3(0.3, 0.6, 1.0);  // blue
  vec3 baseColor3 = vec3(0.8, 0.3, 1.0);  // purple

  float colorWave = sin(angle * 6.0 + totalTime * 4.0) * 0.5 + 0.5;
  vec3 ringColor = mix(baseColor1, mix(baseColor2, baseColor3, colorWave), 
      sin(len * 0.01 + totalTime * 3.0) * 0.5 + 0.5);


  vec3 finalColor = ringColor;
  float finalAlpha = ring;

  float fadeOut = 1.0;
  if (totalTime >= duration * 0.85) {
    fadeOut = smoothstep(duration, duration * 0.85, totalTime);
  }

  fragColor = vec4(finalColor * fadeOut, finalAlpha * fadeOut);
}

