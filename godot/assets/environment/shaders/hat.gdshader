shader_type spatial;
// Bina vurgu çizgisi: binanın biraz büyütülmüş kutusunun yalnızca arka yüzleri çizilir; bina önde kaldığından kenarda ince bir hat görünür.
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;
uniform vec4 renk : source_color = vec4(1.0, 0.8, 0.3, 1.0);

void fragment() {
	ALBEDO = renk.rgb;
}
