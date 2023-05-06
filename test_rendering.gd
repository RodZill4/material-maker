extends Panel

@onready var texture_rect = $VBoxContainer/TextureRect

var computeSrc : String = "#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba16f) uniform image2D OUTPUT_TEXTURE;

layout(set = 1, binding = 0, std430) restrict buffer Parameters {
	float p_o9044_columns;
	float p_o9044_rows;
	float p_o9044_width_x;
	float p_o9044_width_y;
	float p_o9044_stitch;
};

float dot2(vec2 x) {
	return dot(x, x);
}

float rand(vec2 x) {
	return fract(cos(mod(dot(x, vec2(13.9898, 8.141)), 3.14)) * 43758.5453);
}

vec2 rand2(vec2 x) {
	return fract(cos(mod(vec2(dot(x, vec2(13.9898, 8.141)),
							  dot(x, vec2(3.4562, 17.398))), vec2(3.14))) * 43758.5453);
}

vec3 rand3(vec2 x) {
	return fract(cos(mod(vec3(dot(x, vec2(13.9898, 8.141)),
							  dot(x, vec2(3.4562, 17.398)),
							  dot(x, vec2(13.254, 5.867))), vec3(3.14))) * 43758.5453);
}

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = c.g < c.b ? vec4(c.bg, K.wz) : vec4(c.gb, K.xy);
	vec4 q = c.r < p.x ? vec4(p.xyw, c.r) : vec4(c.r, p.yzx);

	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float param_rnd(float minimum, float maximum, float seed) {
	return minimum+(maximum-minimum)*rand(vec2(seed));
}
vec3 weave(vec2 uv, vec2 count, float stitch, float width_x, float width_y) {
	uv *= stitch;
	uv *= count;
	float c1 = (sin( 3.1415926 / stitch * (uv.x + floor(uv.y) - (stitch - 1.0))) * 0.25 + 0.75 ) *step(abs(fract(uv.y)-0.5), width_x*0.5);
	float c2 = (sin(3.1415926 / stitch * (1.0+uv.y+floor(uv.x) ))* 0.25 + 0.75 )*step(abs(fract(uv.x)-0.5), width_y*0.5);
	return vec3(max(c1, c2), 1.0-step(c1, c2), 1.0-step(c2, c1));
}

void main() {
	float _seed_variation_ = 0.0;
	vec2 UV = (gl_GlobalInvocationID.xy+0.5)/imageSize(OUTPUT_TEXTURE);
	vec3 o9044_0 = weave((UV), vec2(p_o9044_columns, p_o9044_rows), p_o9044_stitch, p_o9044_width_x*1.0, p_o9044_width_y*1.0);float o9044_0_2_f = o9044_0.x;
	vec4 outColor = vec4(vec3(o9044_0_2_f), 1.0);
	imageStore(OUTPUT_TEXTURE, ivec2(gl_GlobalInvocationID.xy), outColor);
}"

var framebuffer: RID
var pipeline: RID
var shader: RID
var img_texture: RID

var clearColors := PackedColorArray([Color.TRANSPARENT])
@onready var rd := RenderingServer.create_local_rendering_device()

const IMAGE_SIZE = 512

func _ready():
	update()

func update_compute():
	var src : RDShaderSource = RDShaderSource.new()
	src.source_compute = computeSrc
	var spirv : RDShaderSPIRV = rd.shader_compile_spirv_from_source(src)
	print(spirv.compile_error_compute)
	shader = rd.shader_create_from_spirv(spirv)
	
	var fmt := RDTextureFormat.new()
	fmt.width = IMAGE_SIZE
	fmt.height = IMAGE_SIZE
	fmt.format = RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var view = RDTextureView.new()
	
	var output_image := Image.create(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAH)
	var output_tex = rd.texture_create(fmt, view, [ output_image.get_data() ])
	var output_tex_uniform := RDUniform.new()
	output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_tex_uniform.binding = 0
	output_tex_uniform.add_id(output_tex)
	var uniform_set_0 = rd.uniform_set_create([output_tex_uniform], shader, 0)
	
	var parameters_values : PackedFloat32Array = PackedFloat32Array()
	parameters_values.append(%Columns.value)
	parameters_values.append(%Rows.value)
	parameters_values.append(%WidthX.value)
	parameters_values.append(%WidthY.value)
	parameters_values.append(%Stitch.value)
	var parameters_bytes : PackedByteArray = parameters_values.to_byte_array()
	var parameters_buffer = rd.storage_buffer_create(parameters_bytes.size(), parameters_bytes)
	var parameters_uniform := RDUniform.new()
	parameters_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	parameters_uniform.binding = 0
	parameters_uniform.add_id(parameters_buffer)
	var uniform_set_1 = rd.uniform_set_create([parameters_uniform], shader, 1)
	
	# Create a compute pipeline
	pipeline = rd.compute_pipeline_create(shader)
	var compute_list := rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set_0, 0)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set_1, 1)
	rd.compute_list_dispatch(compute_list, IMAGE_SIZE, IMAGE_SIZE, 1)
	rd.compute_list_end()
	#rd.submit()
	#rd.sync()
	var byte_data : PackedByteArray = rd.texture_get_data(output_tex, 0)
	var image : Image = Image.create_from_data(IMAGE_SIZE, IMAGE_SIZE, false, Image.FORMAT_RGBAH, byte_data)
	texture_rect.texture = ImageTexture.create_from_image(image)
	
	print("hello")

func update(_x : float = 0.0):
	update_compute()

func _exit_tree():
	rd.free_rid(pipeline)
	rd.free_rid(framebuffer)
	rd.free_rid(shader)
	rd.free_rid(img_texture)
