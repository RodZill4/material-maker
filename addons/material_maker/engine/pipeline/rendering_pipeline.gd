extends MMPipeline
class_name MMRenderingPipeline


var index_count : int = 0
var clearColors : PackedColorArray = PackedColorArray([Color.TRANSPARENT])


func create_framebuffer(rd : RenderingDevice, texture_rid : RID) -> RID:
	var framebuffer : RID = rd.framebuffer_create([texture_rid])
	
	return framebuffer

func compile_shader(rd : RenderingDevice, vertex_source : String, fragment_source : String, rids : RIDs, replaces : Dictionary = {}) -> RID:
	var shader = do_compile_shader(rd, { vertex=vertex_source, fragment=fragment_source }, replaces)
	rids.add(shader)
	return shader

func bind_buffer_uniforms(rd : RenderingDevice, draw_list : int, shader : RID, buffers : Array[PackedByteArray], set : int, rids : RIDs):
	var uniform_set : RID = rd.uniform_set_create(create_buffers_uniform_list(rd, buffers, rids), shader, set)
	rids.add(uniform_set)
	rd.draw_list_bind_uniform_set(draw_list, uniform_set, set)

func draw_list_extra_setup(rd : RenderingDevice, draw_list : int, shader : RID, rids : RIDs):
	pass
	
func render(vertex_shader : String, fragment_shader : String, size : Vector2i, texture_type : int, target_texture : MMTexture, replaces : Dictionary = {}):
	var rd : RenderingDevice = await mm_renderer.request_rendering_device(self)
	var rids : RIDs = RIDs.new()
	
	var shader = compile_shader(rd, vertex_shader, fragment_shader, rids)
	
	var target_texture_id : RID = create_output_texture(rd, size, texture_type, true)
	var framebuffer : RID = create_framebuffer(rd, target_texture_id)
	rids.add(framebuffer)

	var blend : RDPipelineColorBlendState = RDPipelineColorBlendState.new()
	blend.attachments.push_back(RDPipelineColorBlendStateAttachment.new())
	var pipeline : RID = rd.render_pipeline_create(
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
	
	draw_list_extra_setup(rd, draw_list, shader, rids)
	
	rd.draw_list_draw(draw_list, index_count == 0, 1, index_count)
	rd.draw_list_end()
	rd.submit()
	rd.sync()
	
	var texture_type_struct : Dictionary = TEXTURE_TYPE[texture_type]
	target_texture.set_texture_rid(target_texture_id, size, texture_type_struct.data_format, rd)
	
	rids.free_rids(rd)
	
	mm_renderer.release_rendering_device(self)
