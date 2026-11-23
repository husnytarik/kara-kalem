extends RefCounted
# Olay verisi D: Aile (A01-A14) ve Nüfuz (N01-N10).

const OLAY := {
	# ---------- AİLE ----------
	"a01": {"b": "Tanışma", "m": "Bir akrabanın düğününde dikkatini çeken biri var; göz göze geldiniz.", "ev": [1, 3], "w": 6, "cd": 40, "k": "!evli;yas>=20", "tag": "aile", "s": [
		["Konuş", "karizma>=4", 0.6, "es_aday;sevgi+2", "Sohbet uzadı; bir hikâye başlıyor.", "stres+2", "Sohbet tutmadı."],
		["Uzaktan izle", "", 1.0, "", "Fırsat geçti.", "", ""],
	]},
	"a02": {"b": "Evlilik çağrısı", "m": "Aile büyükleri artık evlenmeni bekliyor; bir görücü adayı var.", "ev": [1, 4], "w": 5, "cd": 60, "k": "!evli;yas>=22", "tag": "aile", "s": [
		["Görüşmeyi kabul et", "", 0.7, "es_aday;saygi+2", "Görüşme iyi geçti.", "stres+2", "Aday seni beğenmedi."],
		["Reddet", "", 1.0, "saygi-1", "Büyükler hayal kırıklığına uğradı.", "", ""],
	]},
	"a03": {"b": "İlk bebek", "m": "Evde yeni bir bebek var; heyecan ve endişe birlikte.", "ev": [1, 4], "w": 4, "cd": 40, "k": "evli;cocuk<2", "tag": "aile", "s": [
		["Kutla", "temiz>=100", 1.0, "temiz-100;sevgi+4;stres-3", "Mahalle sevindi.", "", ""],
		["Sakin geç", "", 1.0, "stres-1", "Mutluluğu sessizce yaşadın.", "", ""],
	]},
	"a04": {"b": "Çocuğun okulu", "m": "Çocuğun okul çağına geldi; hangi okula yazılacak?", "ev": [1, 4], "w": 5, "cd": 40, "k": "cocuk6>=1", "tag": "aile", "s": [
		["Pahalı okul", "temiz>=300", 1.0, "temiz-300;saygi+2", "Çocuk iyi bir eğitim alıyor.", "", ""],
		["Mahalle okulu", "", 1.0, "sevgi+2", "Çocuk mahallede büyüyecek.", "", ""],
		["Kendin öğret", "zeka>=6", 0.7, "stres+2", "Evde ders başladı; çocuk ilerliyor.", "stres+4", "Zamanın yetmedi."],
	]},
	"a05": {"b": "Ergen isyanı", "m": "Çocuğun, babasının yoluna karşı çıkıyor: «Senin gibi olmak istemiyorum.»", "ev": [2, 4], "w": 5, "cd": 40, "k": "cocuk12>=1", "tag": "aile", "s": [
		["Konuş", "karizma>=5", 0.6, "stres-2;sevgi+2", "Birbirinizi anladınız.", "stres+4", "Konuşma kavgaya döndü."],
		["Sertlik göster", "", 0.4, "saygi+1", "Çocuk boyun eğdi.", "stres+5;sevgi-3", "Çocuk evden ayrıldı."],
		["Özgür bırak", "", 1.0, "stres+1", "Kendi yolunu seçecek.", "", ""],
	]},
	"a06": {"b": "Eşin sızlanması", "m": "Eşin, uzun saatler ve tehlikeli işlerinden şikâyetçi.", "ev": [2, 4], "w": 5, "cd": 30, "k": "evli;stres>=30", "tag": "aile", "s": [
		["Zaman ayır", "", 1.0, "stres-5;sevgi+2", "Birlikte bir akşam geçirdiniz.", "", ""],
		["Hediye al", "temiz>=150", 1.0, "temiz-150;stres-3", "Gülümsedi.", "", ""],
		["Aldırma", "", 1.0, "stres+3", "Sorun büyüyor.", "", ""],
	]},
	"a07": {"b": "Hastalık", "m": "Ailenden biri hastalandı; doktor pahalı bir tedavi öneriyor.", "ev": [1, 4], "w": 5, "cd": 40, "k": "evli;para>=100", "tag": "aile", "s": [
		["En iyi doktoru getir", "temiz>=500", 0.9, "temiz-500;stres-3;sevgi+2", "İyileşti.", "temiz-500;stres+8", "Tedavi yetersiz kaldı."],
		["Ucuz tedavi", "", 0.55, "stres-1", "Şükür, atlattı.", "stres+10", "Durum kötüleşti."],
	]},
	"a08": {"b": "Akraba talebi", "m": "Uzak bir akraba kapına dayandı: «Ailemizin yarısı sana güveniyor, bana iş ver.»", "ev": [1, 3], "w": 5, "cd": 30, "k": "para>=100", "tag": "aile", "s": [
		["İş ver", "", 0.7, "adam+1;sevgi+2", "İşini iyi yapıyor.", "temiz-100;saygi-2", "Para çaldı."],
		["Para ver", "temiz>=100", 1.0, "temiz-100;sevgi+3", "Minnettar kaldı.", "", ""],
		["Kapı dışarı et", "", 1.0, "saygi-3;sevgi-3", "Akrabalar sana küstü.", "", ""],
	]},
	"a09": {"b": "Doğum günü", "m": "Bugün senin doğum günün; ev halkı sürpriz hazırlamış.", "ev": [1, 4], "w": 4, "cd": 90, "k": "evli", "tag": "aile", "s": [
		["Sevinçle kutla", "", 1.0, "stres-5;sevgi+2", "Güzel bir gün geçirdin.", "", ""],
		["Çalışmaya devam et", "", 1.0, "stres+2", "Eşin darıldı.", "", ""],
	]},
	"a10": {"b": "Çocuğun yaramazlığı", "m": "Çocuğun mahallede bir cam kırdı; esnaf kapına geldi.", "ev": [1, 3], "w": 4, "cd": 25, "k": "cocuk6>=1", "tag": "aile", "s": [
		["Tazmin et", "temiz>=50", 1.0, "temiz-50;saygi+1", "Esnaf sakinleşti.", "", ""],
		["Çocuğu azarla", "", 1.0, "sevgi-1", "Çocuk surat astı.", "", ""],
		["Gülüp geç", "", 1.0, "sevgi+1", "Esnaf de güldü.", "", ""],
	]},
	"a11": {"b": "Torun", "m": "Evlenen çocuğundan bir torun haberi geldi.", "ev": [2, 4], "w": 4, "cd": 60, "k": "evlicocuk>=1", "tag": "aile", "s": [
		["Büyük kutlama", "temiz>=300", 1.0, "temiz-300;sevgi+5;saygi+3", "Aile bir araya geldi.", "", ""],
		["Aile içinde kutla", "", 1.0, "stres-3", "Samimi bir akşam geçti.", "", ""],
	]},
	"a12": {"b": "Miras kavgası", "m": "Aile içinde bir miras tartışması çıktı; herkes kendi payını istiyor.", "ev": [2, 4], "w": 4, "cd": 60, "k": "nesil>=1;servet_un>=30", "tag": "aile", "s": [
		["Adil böl", "", 1.0, "saygi+3;sevgi+3", "Kimse bir şey diyemedi.", "", ""],
		["Kendin al", "", 0.5, "temiz+500", "Zorla aldın.", "sevgi-8;saygi-3", "Aile seni dışladı."],
		["Avukatla çöz", "temiz>=300", 1.0, "temiz-300;stres-3", "Avukat durumu çözdü.", "", ""],
	]},
	"a13": {"b": "Aile yemeği", "m": "Hafta sonu geniş aile yemeği; herkes geliyor.", "ev": [1, 4], "w": 5, "cd": 30, "k": "evli", "tag": "aile", "s": [
		["Büyük sofra kur", "temiz>=100", 1.0, "temiz-100;sevgi+3;stres-4", "Mutlu bir akşam.", "", ""],
		["İş telefonuna cevap ver", "", 1.0, "stres+2;sevgi-2", "Sofra yarıda kaldı.", "", ""],
	]},
	"a14": {"b": "Vefat", "m": "Aile büyüklerinden biri vefat etti; cenaze yaklaşıyor.", "ev": [2, 4], "w": 3, "cd": 90, "k": "yas>=40", "tag": "aile", "s": [
		["Görkemli cenaze", "temiz>=500", 1.0, "temiz-500;saygi+4;sevgi+4", "Cenaze şehrin konuşulan olayı oldu.", "", ""],
		["Mütevazı cenaze", "", 1.0, "stres+2;sevgi+2", "Sessiz bir veda.", "", ""],
	]},
	# ---------- NÜFUZ ----------
	"n01": {"b": "Polis müdürü", "m": "Polis müdürü bir ortaklık öneriyor: «Sen rahat çalış, ben bakmam.»", "ev": [2, 4], "w": 6, "cd": 30, "k": "arama>=25;kirli>=300", "tag": "nüfuz", "s": [
		["Aylık ver", "kirli>=300", 1.0, "kirli-300;dok.polis+12;arama-10", "Polis gözlerini kapattı.", "", ""],
		["Reddet", "", 1.0, "arama+3", "Müdür öfkelendi.", "", ""],
		["Şantajla", "zeka>=7", 0.45, "dok.polis+20;arama-12", "Müdür artık senin.", "arama+15;y.korku-3", "Müdür seni ele verdi."],
	]},
	"n02": {"b": "Yargıç yemeği", "m": "Bir yargıç özel bir yemek daveti gönderdi; bir şey istiyor.", "ev": [3, 4], "w": 5, "cd": 40, "k": "d_yargic>=0;saygi>=25", "tag": "nüfuz", "s": [
		["Git ve dinle", "karizma>=5", 0.65, "dok.yargic+10;saygi+2", "Dostluk kuruldu.", "saygi-1", "Yargıç seni beğenmedi."],
		["Hediyeyle git", "temiz>=300", 0.8, "temiz-300;dok.yargic+15", "Hediyen kabul edildi.", "temiz-300;fed+6", "Hediye rüşvet sayıldı."],
		["Gitme", "", 1.0, "", "Davete uymadın.", "", ""],
	]},
	"n03": {"b": "Gazeteci", "m": "Ünlü bir gazeteci, işlerin hakkında soru soruyor.", "ev": [2, 4], "w": 5, "cd": 30, "k": "arama>=30", "tag": "medya", "s": [
		["Röportaj ver", "karizma>=6", 0.6, "saygi+4;arama+4", "Röportaj sempatik çıktı.", "saygi-3;arama+10", "Sözlerin çarpıtıldı."],
		["Para ver", "kirli>=200", 0.8, "kirli-200;arama-6", "Haber çıkmadı.", "arama+10", "Haber yine çıktı."],
		["Tehdit et", "adam>=3", 0.5, "y.korku+4", "Gazeteci sustu.", "arama+14;saygi-4", "Gazeteci polise gitti."],
	]},
	"n04": {"b": "Din adamı", "m": "Mahalle imamı, kilise ile ilgili bir bağış için seni arıyor.", "ev": [2, 4], "w": 4, "cd": 40, "k": "saygi>=20", "tag": "mahalle", "s": [
		["Bağış yap", "temiz>=200", 1.0, "temiz-200;sevgi+5;saygi+3", "Mahalle seni takdir etti.", "", ""],
		["Dua için katıl", "", 1.0, "sevgi+2;stres-2", "Huzur buldun.", "", ""],
		["Reddet", "", 1.0, "sevgi-2", "Cemaat seni not etti.", "", ""],
	]},
	"n05": {"b": "Sendika", "m": "Liman sendikası, bir grev için senden destek istiyor.", "ev": [3, 4], "w": 4, "cd": 40, "k": "bolge>=2", "tag": "siyaset", "s": [
		["Destek ver", "temiz>=300", 1.0, "temiz-300;sevgi+6;y.kulis+3", "İşçiler seni anıyor.", "", ""],
		["Grevi kır", "adam>=3", 0.55, "kirli+400;sevgi-8", "Grev kırıldı.", "arama+10;sevgi-12", "Grev kırıcılar yakalandı."],
		["Tarafsız kal", "", 1.0, "", "Bu sana ait değil.", "", ""],
	]},
	"n06": {"b": "Seçim kampanyası", "m": "Bir aday senden seçim parası ve oy toplamanı istiyor.", "ev": [3, 4], "w": 5, "cd": 50, "k": "sevgi>=25", "tag": "siyaset", "s": [
		["Destekle", "temiz>=500", 0.7, "temiz-500;dok.siyasi+15;y.kulis+4", "Aday kazandı; sana borçlu.", "temiz-500;arama+5", "Aday kaybetti."],
		["Rakibini destekle", "temiz>=500", 0.6, "temiz-500;dok.siyasi+10", "Kazanan taraf sendin.", "temiz-500", "Kaybettin."],
		["Karışma", "", 1.0, "", "Bu işe girmedin.", "", ""],
	]},
	"n07": {"b": "Federal ajan", "m": "Bir federal ajan, sana gizlice bir bilgi satmak istiyor.", "ev": [3, 4], "w": 4, "cd": 40, "k": "fed>=15", "tag": "federal", "s": [
		["Satın al", "kirli>=500", 0.65, "kirli-500;fed-12", "Bilgi doğruydu; önlemini aldın.", "kirli-500;fed+8", "Bu bir tuzaktı."],
		["Ajanı ele ver", "", 0.5, "fed-6;y.korku+3", "Ajan şehirden kayboldu.", "fed+14", "Ajan seni ele verdi."],
		["Kapıyı kapat", "", 1.0, "", "Konuşmadın.", "", ""],
	]},
	"n08": {"b": "Vali daveti", "m": "Vali, bir hayır gecesine konuk olmanı rica ediyor.", "ev": [3, 4], "w": 4, "cd": 60, "k": "saygi>=40", "tag": "nüfuz", "s": [
		["Git", "", 0.8, "dok.siyasi+8;saygi+3", "Valiyle dostluk başladı.", "saygi-1", "Gecede sıkıldın."],
		["Hediyeyle git", "temiz>=500", 1.0, "temiz-500;dok.siyasi+14;saygi+4", "Vali bunu unutmayacak.", "", ""],
		["Gitme", "", 1.0, "", "Başka işlerin var.", "", ""],
	]},
	"n09": {"b": "Dedikodu", "m": "Mahallede senin hakkında bir dedikodu dolaşıyor.", "ev": [1, 4], "w": 5, "cd": 60, "k": "saygi>=15", "tag": "mahalle", "s": [
		["Yalanla", "karizma>=5", 0.6, "saygi+2", "Dedikodu söndü.", "saygi-2", "Yalanlama dedikoduyu büyüttü."],
		["Yok say", "", 1.0, "saygi-1", "Zamanla geçer.", "", ""],
		["Kaynağı bul", "zeka>=6", 0.55, "y.korku+3", "Kaynağı susturdun.", "stres+3", "Kimseyi bulamadın."],
	]},
	"n10": {"b": "İtibarlı yardım", "m": "Mahalleden biri, senin dostluğunla onurlanmak istediğini söylüyor.", "ev": [1, 3], "w": 4, "cd": 25, "k": "sevgi>=15", "tag": "mahalle", "s": [
		["Çocuğunun vaftiz babası ol", "", 1.0, "sevgi+5;saygi+2", "Bağın güçlendi.", "", ""],
		["Hediye gönder", "temiz>=50", 1.0, "temiz-50;sevgi+2", "Hediye beğenildi.", "", ""],
		["Kibarca reddet", "", 1.0, "", "Anlayış gördün.", "", ""],
	]},
}
