// liquid cursor trail: when the cursor jumps, a tapered drop stretches from the old
// position to the new one and drains into the cursor, in the cursor's own color.

const float DURATION = 0.30; // seconds for the trail to fully drain
const float MERGE = 0.012;   // how softly the trail melts into the cursor (normalized units)
const float MIN_JUMP_CELLS = 3.5; // same-line moves shorter than this many cells get no trail

// pixels -> resolution-independent units (y spans -1..1); isPos = 0 for sizes
vec2 norm(vec2 v, float isPos) {
    return (v * 2.0 - iResolution.xy * isPos) / iResolution.y;
}

float sdBox(vec2 p, vec2 center, vec2 halfSize) {
    vec2 d = abs(p - center) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// segment from a (radius ra) to b (radius rb), radius interpolated along it
float sdTaper(vec2 p, vec2 a, vec2 b, float ra, float rb) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / max(dot(ba, ba), 1e-6), 0.0, 1.0);
    return length(pa - ba * h) - mix(ra, rb, h);
}

// smooth minimum: blends two shapes like liquid instead of a hard union
float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float easeOutCubic(float x) {
    return 1.0 - pow(1.0 - x, 3.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    fragColor = texture(iChannel0, fragCoord / iResolution.xy);

    float t = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    if (t >= 1.0 || iCurrentCursor.z <= 0.0) return; // idle: nothing to draw

    vec2 p = norm(fragCoord, 1.0);
    vec4 cur = vec4(norm(iCurrentCursor.xy, 1.0), norm(iCurrentCursor.zw, 0.0));
    vec4 prev = vec4(norm(iPreviousCursor.xy, 1.0), norm(iPreviousCursor.zw, 0.0));

    // cursor xy is the top-left corner with y pointing up
    vec2 curHalf = cur.zw * 0.5;
    vec2 curC = cur.xy + vec2(curHalf.x, -curHalf.y);
    vec2 prevC = prev.xy + vec2(prev.z, -prev.w) * 0.5;

    // typing / backspace / h,l move a cell or two on the same line: no trail for those,
    // only real jumps get the liquid effect
    // measured in cells, not cursor widths: the insert-mode bar cursor is only a few px wide.
    // a cell is roughly half as wide as it is tall
    float cellW = max(cur.z, cur.w * 0.5);
    vec2 delta = abs(curC - prevC);
    if (delta.y < cur.w * 0.5 && delta.x < cellW * MIN_JUMP_CELLS) return;

    // the tail drains from the old spot into the cursor, fast at first then settling
    vec2 tail = mix(prevC, curC, easeOutCubic(t));

    // body is a bit thicker than the cursor so it reads as liquid, not a line;
    // max() keeps it from going hair-thin with the bar cursor in insert mode
    float rHead = max(curHalf.x, curHalf.y * 0.6);
    float rTail = rHead * 0.45 * (1.0 - t);

    float dCursor = sdBox(p, curC, curHalf);
    float dTrail = sdTaper(p, curC, tail, rHead, rTail);
    // a round droplet at the end of the tail, shrinking as it drains
    float dDrop = length(p - tail) - rHead * 0.8 * (1.0 - t);
    float d = smin(smin(dTrail, dDrop, MERGE), dCursor, MERGE);

    // leave the cursor cell itself alone so the character under a block cursor stays visible
    if (dCursor <= 0.0) return;

    float px = 2.0 / iResolution.y;
    float alpha = 1.0 - smoothstep(-px, px, d);
    alpha *= 1.0 - t * t; // fade out right at the end so it doesn't pop away

    fragColor = vec4(mix(fragColor.rgb, iCurrentCursorColor.rgb, alpha * iCurrentCursorColor.a), fragColor.a);
}
