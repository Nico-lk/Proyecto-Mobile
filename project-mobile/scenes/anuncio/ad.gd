extends CanvasLayer

signal ad_finished(completed: bool)

@onready var video: VideoStreamPlayer = $Control/VideoStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	video.finished.connect(_on_video_finished)
	video.play()

func _on_video_finished() -> void:
	ad_finished.emit(true)
	queue_free()

func _on_skip_pressed() -> void:
	ad_finished.emit()
	queue_free()
