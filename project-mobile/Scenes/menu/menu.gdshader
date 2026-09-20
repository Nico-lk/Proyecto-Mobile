shader_type canvas_item;

// Parámetros configurables desde el Inspector
uniform vec4 hologram_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);
uniform float lines_frequency : hint_range(0.1, 100.0) = 40.0;
uniform float lines_speed : hint_range(0.0, 10.0) = 1.0;
uniform float scan_glitch_speed : hint_range(0.0, 20.0) = 2.0;
uniform float alpha_glitch_speed : hint_range(0.0, 20.0) = 5.0;

// Función para generar ruido pseudo-aleatorio
float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    // Obtener el color y alfa original del texto/textura
    vec4 current_color = texture(TEXTURE, UV);
    
    // Si el pixel original es transparente, no pintamos nada
    if (current_color.a == 0.0) {
        discard;
    }
    
    // 1. Efecto de líneas de escaneo en movimiento
    float scan_line = sin((UV.y + TIME * lines_speed) * lines_frequency);
    scan_line = (scan_line + 1.0) / 2.0; // Normalizar entre 0 y 1
    scan_line = mix(0.4, 1.0, scan_line); // Evitar que sea totalmente invisible
    
    // 2. Ruido / Parpadeo sutil en el Alfa (Transparencia)
    float alpha_flicker = random(vec2(floor(TIME * alpha_glitch_speed), 0.0));
    alpha_flicker = mix(0.7, .0, alpha_flicker);
    
    // 3. Glitch de desplazamiento horizontal aleatorio
    vec2 glitch_uv = UV;
    if (random(vec2(floor(TIME * scan_glitch_speed), 0.0)) > 0.85) {
        glitch_uv.x += (random(vec2(floor(UV.y * 10.0), TIME)) - 0.5) * 0.03;
    }
    
    // Volver a muestrear con la deformación del glitch
    vec4 glitch_color = texture(TEXTURE, glitch_uv);
    
    // Combinar todo el efecto
    COLOR.rgb = hologram_color.rgb;
    COLOR.a = glitch_color.a * hologram_color.a * scan_line * alpha_flicker;
}