extends MMRenderingPipeline
class_name MMMeshRenderingPipeline

var mesh : Mesh

func draw_list_extra_setup(rd : RenderingDevice, draw_list : int, shader : RID, rids : RIDs):
	var buffers : Array[PackedByteArray] = []
	buffers.append(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].to_byte_array())
	var bounding_box : AABB = mesh.get_aabb()
	var bounding_box_array : PackedByteArray = PackedByteArray()
	bounding_box_array.resize(24)
	bounding_box_array.encode_float(0, bounding_box.position.x)
	bounding_box_array.encode_float(4, bounding_box.position.y)
	bounding_box_array.encode_float(8, bounding_box.position.z)
	bounding_box_array.encode_float(12, bounding_box.size.x)
	bounding_box_array.encode_float(16, bounding_box.size.y)
	bounding_box_array.encode_float(20, bounding_box.size.z)
	buffers.append(bounding_box_array)
	buffers.append(mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL].to_byte_array())
	buffers.append(mesh.surface_get_arrays(0)[Mesh.ARRAY_TANGENT].to_byte_array())
	buffers.append(mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV].to_byte_array())
	bind_buffer_uniforms(rd, draw_list, shader, buffers, 0, rids)
		
	var indexes = mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	if indexes == null:
		index_count = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()
	else:
		index_count = 0
		var index_buffer : RID = rd.index_buffer_create(indexes.size(), RenderingDevice.INDEX_BUFFER_FORMAT_UINT32, indexes.to_byte_array())
		var index_array : RID = rd.index_array_create(index_buffer, 0, indexes.size())
		rd.draw_list_bind_index_array(draw_list, index_array)
