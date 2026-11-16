@tool
extends Node3D
# Harita sahnesine koyabileceğin "savaş alanı" işareti. Oyuncu bir çatışmaya girdiğinde konumuna en yakın
# (150 m içindeki) işaret seçilir; savaş onun seviyesinde yapılır. Sahne boşsa programla üretilen
# geçici (gri kutu) seviye kullanılır. Seviye sahnesi için scenes/battle/OKU.md'ye bak.

@export_enum("sokak", "ic", "liman") var tur := "sokak"
@export var sahne: PackedScene

func _ready() -> void:
	add_to_group("savas_alani")
