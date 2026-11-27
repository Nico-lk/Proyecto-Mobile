extends CanvasLayer

signal ad_finished(completed: bool)

const SKIP_DELAY := 5.0

@onready var video: VideoStreamPlayer = $Control/VideoStreamPlayer
@onready var skip_button: BaseButton = $Control/Skip
@onready var skip_label: Label = $Control/Label

var _time_left := SKIP_DELAY
var _can_skip := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	video.finished.connect(_on_video_finished)
	skip_button.pressed.connect(_on_skip_pressed)

	skip_button.hide()
	skip_label.show()
	_update_label()

	video.play()

func _process(delta: float) -> void:
	if _can_skip:
		return

	_time_left -= delta
	if _time_left <= 0.0:
		_enable_skip()
	else:
		_update_label()

func _update_label() -> void:
	skip_label.text = "Puedes omitir el anuncio en %d" % ceili(_time_left)

func _enable_skip() -> void:
	_can_skip = true
	skip_label.hide()
	skip_button.show()

func _on_video_finished() -> void:
	ad_finished.emit(true)
	queue_free()
	
func _on_skip_pressed() -> void:
	ad_finished.emit(true)
	queue_free()
