@tool
extends Resource

@export_storage var next_positive_id:int = 1
@export_storage var next_negative_id:int = -1
@export_storage var available_ids:PackedInt64Array = []

func new_id() -> int:
		if not available_ids.is_empty():
				var last_index = available_ids.size() - 1
				var id = available_ids[last_index]
				available_ids.remove_at(last_index)
				return id

		if next_positive_id != 9223372036854775807:
				var id = next_positive_id
				next_positive_id += 1
				return id

		elif next_negative_id != -9223372036854775808:
				var id = next_negative_id
				next_negative_id -= 1
				return id

		return 0

func remove_id(id:int) -> bool:
		if id == 0:
				return false

		# 检查ID是否在有效范围内
		if (id > 0 && id >= next_positive_id) || (id < 0 && id <= next_negative_id):
				return false

		# 避免重复添加
		if not _contains_id(id):
				available_ids.append(id)

		return true

func _contains_id(id: int) -> bool:
		for existing_id in available_ids:
				if existing_id == id:
						return true
		return false

## 检测并重构可用ID列表
## callable: 检测函数，接受一个id参数，返回true表示该ID正在被使用，false表示未被使用
func rebuild_available_ids(callable:Callable) -> void:
		var new_available_ids: PackedInt64Array = []
		var new_max_positive = 0
		var new_min_negative = 0

		# 检查所有已分配的ID范围
		for i in range(1, next_positive_id - 1):
				if not callable.call(i):
						new_available_ids.append(i)
				else:
						# 更新实际的最大正数ID
						if i > new_max_positive:
								new_max_positive = i

		for i in range(-1, next_negative_id + 1, -1):
				if not callable.call(i):
						new_available_ids.append(i)
				else:
						# 更新实际的最小负数ID
						if i < new_min_negative:
								new_min_negative = i

		# 更新管理器状态
		available_ids = new_available_ids
		next_positive_id = new_max_positive + 1 if new_max_positive > 0 else 1
		next_negative_id = new_min_negative - 1 if new_min_negative < 0 else -1

## 重置管理器
func reset() -> void:
		next_positive_id = 1
		next_negative_id = -1
		available_ids.clear()
