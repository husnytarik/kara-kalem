shader_type spatial;
// Bina cephesi: tuğla, pencere, vitrin, korniş. Çatı düz katran. Dünya koordinatından üretilir.
uniform vec4 renk : source_color = vec4(0.55, 0.3, 0.25, 1.0);
uniform float taban = 0.0;
uniform float yukseklik = 12.0;
uniform float kat = 3.6;

varying vec3 wp;
varying vec3 wn;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 c = renk.rgb;
	float rough = 0.92;
	float metal = 0.0;
	if (wn.y > 0.5) {
		c = vec3(0.16, 0.16, 0.17);
	} else if (wn.y > -0.5) {
		bool xduvar = abs(wn.x) > 0.5;
		float u = xduvar ? wp.z : wp.x;
		float v = wp.y - taban;
		// kaba kaplama: tuğla dizileri
		float sat = floor(v / 0.22);
		float ofs = mod(sat, 2.0) * 0.5;
		float tx = u / 0.65 + ofs;
		vec2 tuglaId = vec2(floor(tx), sat);
		vec2 f = vec2(fract(tx), fract(v / 0.22));
		float harc = step(f.x, 0.07) + step(f.y, 0.1);
		float ton = hash(tuglaId + (xduvar ? 17.0 : 0.0));
		float aa = clamp(1.0 - fwidth(v / 0.22) * 2.0, 0.0, 1.0);
		vec3 tugla = mix(c, vec3(0.55, 0.26, 0.2), 0.45) * (0.8 + 0.4 * ton);
		// harç: açık gri; tuğla başına belirgin ton farkı + yüzey lekesi
		float leke = hash(floor(vec2(u, v) * 9.0) + tuglaId);
		tugla *= 0.9 + 0.2 * leke;
		tugla = mix(tugla, tugla * 0.45 + vec3(0.1), clamp(harc, 0.0, 1.0) * 0.9 * aa);
		c = mix(c, tugla, aa);
		float katno = floor(v / kat);
		float kf = fract(v / kat);
		float ust = yukseklik - v;
		// korniş / parapet
		if (ust < 1.1) {
			c = renk.rgb * (ust > 0.55 ? 1.12 : 0.8);
		} else if (katno < 0.5) {
			// zemin kat: vitrin
			float cu = fract(u / 4.2);
			float vit = step(0.1, cu) * step(cu, 0.9) * step(0.14, kf) * step(kf, 0.72);
			float cerceve = step(0.07, cu) * step(cu, 0.93) * step(0.1, kf) * step(kf, 0.76);
			c = mix(c, vec3(0.1, 0.07, 0.05), cerceve);
			vec3 cam = mix(vec3(0.16, 0.22, 0.28), vec3(0.55, 0.45, 0.25), hash(vec2(floor(u / 4.2), 3.0)) * 0.6);
			c = mix(c, cam, vit);
			// tabela şeridi
			c = mix(c, c * 0.6, step(0.78, kf) * step(kf, 0.9));
			rough = mix(0.92, 0.2, vit);
		} else {
			float cu = fract(u / 3.1);
			float pen = step(0.28, cu) * step(cu, 0.72) * step(0.28, kf) * step(kf, 0.84);
			float cerc = step(0.22, cu) * step(cu, 0.78) * step(0.22, kf) * step(kf, 0.9);
			float yak = step(0.86, hash(vec2(floor(u / 3.1), katno + (xduvar ? 5.0 : 0.0))));
			vec3 cam = mix(vec3(0.12, 0.17, 0.22), vec3(0.95, 0.75, 0.4), yak * 0.55);
			c = mix(c, c * 1.35, cerc * (1.0 - pen));
			c = mix(c, cam, pen);
			rough = mix(0.92, 0.25, pen);
			// pencere alt taşı
			c = mix(c, c * 0.7, step(0.22, kf) * step(kf, 0.28) * step(0.22, cu) * step(cu, 0.78));
		}
	}
	ALBEDO = c;
	ROUGHNESS = rough;
	METALLIC = metal;
}
