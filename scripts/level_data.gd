@tool
extends Resource
class_name LevelData

# Gets populated upon time trial level clear
@export var level_times = {}
# hard-coded developer best times for time trail levels. 
const dev_times: Array[int] = [8424, 9083, 5316, 5050, 21215, 16649, 14483, 14216, 15899, 10199, 28750, 11699, 4799, 16682, 32533]
const goal_times: Array[int] = [12000, 11500, 7000, 6500, 27000, 21000, 18000, 20000, 20000, 13000, 35000, 14500, 7500, 20000, 40000]
@export var high_score = 0
@export var arcade_time = null
