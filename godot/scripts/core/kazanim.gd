extends RefCounted
# Kazanımlar: oyun "bitmez", her büyük dönüm noktası bir kazanımdır. Oyun yalnızca ölümle (ve mirasçı seçilmezse) sona erer.
# Durum: oyun.kaz = {id: alındığı oyun dakikası}

const LISTE := {
	"durust": {"ad": "Dürüst iş", "ac": "Temiz kasa, temiz dosya, sıfır haraç: saygın bir iş adamı oldun."},
	"baskan": {"ad": "Belediye Başkanı", "ac": "Seçimi kazandın; belediye merdivenlerinde alkışlandın."},
	"hakim": {"ad": "Şehrin Efendisi", "ac": "Mahallelerin neredeyse hepsi senin."},
	"tapu": {"ad": "Tapusuz kaldın", "ac": "Taksitler ödenmedi; tefecinin adamları meyhaneyi aldı."},
	"dava": {"ad": "Mahkemelik", "ac": "Dosyan 100'e çıktı ve dava açıldı."},
	"federal": {"ad": "Kâğıtla düşen", "ac": "Federal ajanlar vergi kaçakçılığından seni yakaladı."},
	"hapis": {"ad": "Demir parmaklıklar", "ac": "İlk kez hapse girdin."},
	"evlilik": {"ad": "Yuva", "ac": "Evlendin."},
	"cocuk": {"ad": "Baba/Anne oldun", "ac": "İlk çocuğun doğdu."},
	"malikane": {"ad": "Malikâne sahibi", "ac": "Kendi malikânene kavuştun."},
	"nesil": {"ad": "Miras", "ac": "Ailenin başı bir sonraki nesle geçti."},
	"nesil3": {"ad": "Üç kuşak", "ac": "Üçüncü nesil ailenin başına geçti."},
	"baba": {"ad": "Baba", "ac": "Korkulan, zengin ve sayılan biri oldun."},
	"is_adami": {"ad": "Saygın iş adamı", "ac": "Sevilen, kazanan, temiz bir isim oldun."},
	"rezil": {"ad": "Rezil haraççı", "ac": "Kimse seni ciddiye almıyor. Ama hâlâ ayaktasın."},
	"kumar_zengin": {"ad": "Şanslı el", "ac": "Kumarda tek seferde $200 kazandın."},
	"dibe": {"ad": "Dibe vurdun", "ac": "Cebinde hiç para kalmadı ve tefeciye borçlusun."},
}

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

func var_mi(id: String) -> bool:
	return oyun.kaz.has(id)

func ver(id: String) -> void:
	if oyun.kaz.has(id) or not LISTE.has(id):
		return
	oyun.kaz[id] = oyun.t
	oyun.kayit("★ KAZANIM: %s — %s" % [LISTE[id]["ad"], LISTE[id]["ac"]], "good")
	oyun.degisti.emit()

func sayi() -> int:
	return oyun.kaz.size()

# Günlük: hayat tipi ve dibe vurma.
func gun() -> void:
	var tip: String = oyun.un_k.tip()["ad"]
	match tip:
		"Baba":
			ver("baba")
		"Saygın iş adamı":
			ver("is_adami")
		"Rezil haraççı":
			ver("rezil")
	if oyun.temiz + oyun.kirli < 20.0 and float(oyun.kotu["tef"]) > 0.0:
		ver("dibe")
