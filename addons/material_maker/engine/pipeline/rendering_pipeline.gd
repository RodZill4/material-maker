extends MMPipeline
class_name MMRenderingPipeline

var vertSrc = "#version 450

layout(binding = 0, std430) buffer restrict readonly Positions {
	vec3 positions[];
};
layout(binding = 1, std430) buffer restrict readonly Normals {
	vec3 normals[];
};
layout(binding = 2, std430) buffer restrict readonly UVs {
	vec2 uvs[];
};

void main() {
	gl_Position = vec4(uvs[gl_VertexIndex]*2.0-vec2(1.0), 0.0, 1.0);
	//gl_Color = vec4(positions[gl_VertexIndex], 1.0);
}"

var fragSrc = "#version 450
layout(location = 0) out vec4 outColor;
void main() {
	outColor = vec4(1.0, 0.0, 0.0, 1.0);
}"

var framebuffer : RID
var pipeline : RID
var img_texture : RID

var clearColors : PackedColorArray = PackedColorArray([Color.TRANSPARENT])

func create_target_texture(rd : RenderingDevice, size : Vector2i, texture_type : int, rids : RIDs) -> RID:
	var tf = RDTextureFormat.new()
	var texture_type_struct : Dictionary = TEXTURE_TYPE[texture_type]
	tf.format = texture_type_struct.data_format
	tf.height = size.x
	tf.width = size.y
	tf.usage_bits =  RenderingDevice.TEXTURE_USAGE_COLOR_ATTACHMENT_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	tf.texture_type = RenderingDevice.TEXTURE_TYPE_2D
	
	var data = PackedByteArray()
	data.resize(tf.height*tf.width*texture_type_struct.channels*texture_type_struct.bytes_per_channel)
	
	var texture_rid : RID = rd.texture_create(tf, RDTextureView.new(), [data])
	rids.add(texture_rid)
	
	return texture_rid

func create_framebuffer(rd : RenderingDevice, texture_rid : RID, rids : RIDs) -> RID:
	var framebuffer : RID = rd.framebuffer_create([texture_rid])
	rids.add(texture_rid)
	
	return framebuffer

func compile_shader(rd : RenderingDevice, vertex_source : String, fragment_source : String, rids : RIDs) -> RID:
	var rv : bool = true
	var src : RDShaderSource = RDShaderSource.new()
	src.source_vertex = vertex_source
	src.source_fragment = fragment_source
	var spirv : RDShaderSPIRV = rd.shader_compile_spirv_from_source(src)
	var shader = RID()
	if spirv.compile_error_vertex != "":
		var ln : int = 0
		for l in vertex_source.split("\n"):
			ln += 1
			print("%4d: %s" % [ ln, l ])
		print("VERTEX SHADER ERROR: "+spirv.compile_error_vertex)
		rv = false
	if spirv.compile_error_fragment != "":
		var ln : int = 0
		for l in fragment_source.split("\n"):
			ln += 1
			print("%4d: %s" % [ ln, l ])
		print("FRAGMENT SHADER ERROR: "+spirv.compile_error_fragment)
		rv = false
	if rv:
		shader = rd.shader_create_from_spirv(spirv)
	rids.add(shader)
	return shader

func render(mesh : Mesh, size : Vector2i, texture_type : int, target_texture : ImageTexture):
	var rd : RenderingDevice = await mm_renderer.request_rendering_device(self)
	var rids : RIDs = RIDs.new()
	
	var shader = compile_shader(rd, vertSrc, fragSrc, rids)
	var target_texture_id : RID = create_target_texture(rd, size, texture_type, rids)
	var framebuffer : RID = create_framebuffer(rd, target_texture_id, rids)
	
	var blend : RDPipelineColorBlendState = RDPipelineColorBlendState.new()
	blend.attachments.push_back(RDPipelineColorBlendStateAttachment.new())
	pipeline = rd.render_pipeline_create(
		shader,
		rd.framebuffer_get_format(framebuffer),
		-1,
		RenderingDevice.RENDER_PRIMITIVE_TRIANGLES,
		RDPipelineRasterizationState.new(),
		RDPipelineMultisampleState.new(),
		RDPipelineDepthStencilState.new(),
		blend
	)
	
	var draw_list : int = rd.draw_list_begin(framebuffer,
		RenderingDevice.INITIAL_ACTION_CLEAR, RenderingDevice.FINAL_ACTION_READ,
		RenderingDevice.INITIAL_ACTION_CLEAR, RenderingDevice.FINAL_ACTION_READ,
		clearColors)
	rd.draw_list_bind_render_pipeline(draw_list, pipeline)
	var buffers : Array[PackedByteArray] = []
	buffers.append(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].to_byte_array())
	buffers.append(mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL].to_byte_array())
	buffers.append(mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV].to_byte_array())
	var uniform_set : RID = rd.uniform_set_create(create_buffers_uniform_list(rd, buffers, rids), shader, 0)
	rids.add(uniform_set)
	rd.draw_list_bind_uniform_set(draw_list, uniform_set, 0)
	print(mesh.surface_get_arrays(0)[0].size())
	rd.draw_list_draw(draw_list, false, 1, mesh.surface_get_arrays(0)[0].size())
	rd.draw_list_end()
	rd.submit()
	rd.sync()
	
	var texture_type_struct : Dictionary = TEXTURE_TYPE[texture_type]
	var data = rd.texture_get_data(target_texture_id, 0)
	var generated_image = Image.create_from_data(size.x, size.y, false, texture_type_struct.image_format, data)
	target_texture.set_image(generated_image)
	
	rids.free_rids(rd)
	
	mm_renderer.release_rendering_device(self)
