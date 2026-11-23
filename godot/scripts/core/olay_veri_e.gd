extends RefCounted
# Olay verisi E: Dünya (aile modlu), Zincirler (yalniz zincir_cek ile), Nadir.

const OLAY := {
	# ---------- DÜNYA ----------
	"w01": {"b": "Zayıf aile yardım istiyor", "m": "{F} zor durumda; eski bir borç yüzünden senden himaye istiyor.", "ev": [2, 4], "w": 7, "cd": 25, "f": "zayif", "tag": "dünya", "s": [
		["Himayeye al", "", 0.8, "y.kulis+4;saygi+3;kirli+250", "{F} artık sana bağlı.", "adam-1", "Himaye bir tuzak çıktı."],
		["Reddet", "", 1.0, "", "{F} başka kapıya gitti.", "", ""],
		["Sömür", "", 0.6, "kirli+500;y.korku+3;saygi-2", "{F}'dan ağır haraç aldın.", "ger+3", "{F} sana düşman oldu."],
	]},
	"w02": {"b": "Güçlü aile baskısı", "m": "{F} bölgende gücünü gösteriyor; adamları köşede dolaşıyor.", "ev": [2, 4], "w": 7, "cd": 25, "f": "guclu", "tag": "dünya", "s": [
		["Geri adım at", "", 1.0, "saygi-4;ger-2", "Bir süre sessiz kaldın.", "", ""],
		["Göz dağı ver", "adam>=3", 0.4, "y.korku+4;saygi+3", "{F} geri çekildi.", "ger+5;yara+20", "Çatışma çıktı."],
		["Müzakere et", "karizma>=6", 0.55, "ger-4;y.kulis+3", "Bir sınır çizildi.", "saygi-3", "Müzakere sonuç vermedi."],
	]},
	"w03": {"b": "Denk aile teklifi", "m": "{F} seninle eşit şartlarda bir ittifak istiyor.", "ev": [2, 4], "w": 7, "cd": 25, "f": "esit", "tag": "dünya", "s": [
		["İttifak kur", "", 0.7, "y.kulis+5;ger-4;kirli+250", "İki aile birlikte güçlendi.", "ger+3", "İttifak kısa sürdü."],
		["Reddet", "", 1.0, "ger+1", "Mesafeyi korudun.", "", ""],
		["Hileli ittifak", "zeka>=7", 0.45, "kirli+600;y.golge+3", "{F}'ı oyuna getirdin.", "ger+6", "{F} hileyi fark etti."],
	]},
	"w04": {"b": "Teslim olan aile", "m": "{F}, korkudan sana boyun eğmek istiyor.", "ev": [2, 4], "w": 5, "cd": 40, "f": "teslim", "tag": "dünya", "s": [
		["Kabul et", "", 1.0, "inf+10;y.korku+3;kirli+250", "{F} artık senin gölgende.", "", ""],
		["Affet", "", 1.0, "saygi+4;sevgi+2;ger-3", "Cömertliğin konuşuldu.", "", ""],
		["Yok et", "adam>=4", 0.6, "inf+20;y.korku+6;ger+3", "{F} sahneden silindi.", "yara+25;arama+8", "Çatışma kanlı geçti."],
	]},
	"w05": {"b": "Gerginlik tırmanıyor", "m": "{F} ile aranızda tehlikeli bir gerginlik var; sokakta ilk kıvılcım çıktı.", "ev": [2, 4], "w": 7, "cd": 20, "f": "gerg", "tag": "kriz", "s": [
		["Saldır", "adam>=3", 0.5, "inf+10;y.korku+5;ger+2", "İlk darbeyi sen vurdun.", "yara+25;adam-1;ger+4", "Saldırı püskürtüldü."],
		["Barış öner", "karizma>=6", 0.55, "ger-6;saygi+3", "Taraflar sakinleşti.", "saygi-2;ger+1", "Barış teklifi zayıflık sayıldı."],
		["Savunmaya geç", "", 1.0, "stres+2;ger-1", "Adamlarını topladın.", "", ""],
	]},
	"w06": {"b": "Kırılgan kuşak", "m": "{F}'ın genç varisi büyük bir hata yaptı; düzen sarsıldı.", "ev": [2, 4], "w": 4, "cd": 40, "f": "rakip", "tag": "dünya", "s": [
		["Fırsattan yararlan", "", 0.6, "inf+12;kirli+300", "Bölgelerini ele geçirdin.", "ger+4", "{F} sana karşı birleşti."],
		["Gençle konuş", "karizma>=6", 0.6, "saygi+4;y.kulis+4", "Genç sana saygı duydu.", "", ""],
		["Seyirci kal", "", 1.0, "", "Beklemek en iyisiydi.", "", ""],
	]},
	"w07": {"b": "Rakibin iç savaşı", "m": "{F}'ın içinde bir iktidar savaşı çıkmış.", "ev": [2, 4], "w": 4, "cd": 40, "f": "rakip", "tag": "dünya", "s": [
		["Bir tarafı destekle", "adam>=3", 0.55, "y.kulis+6;inf+10", "Destek verdiğin taraf kazandı.", "ger+4", "Kaybeden tarafı seçtin."],
		["Tüm tarafları ez", "adam>=4", 0.4, "inf+20;y.korku+5", "Hepsini devirdin.", "yara+25;adam-2", "Planın çöktü."],
		["Bekle", "", 1.0, "", "Tozun dinmesini bekledin.", "", ""],
	]},
	"w08": {"b": "Rakip ele geçirme girişimi", "m": "{F}, mahallendeki bir işyerine el koymaya çalışıyor.", "ev": [1, 4], "w": 6, "cd": 20, "f": "rakip", "tag": "kriz", "s": [
		["Karşı çık", "adam>=2", 0.55, "y.korku+3;saygi+3", "İşyeri senin kaldı.", "yara+15;adam-1;ger+3", "Kavgayı kaybettin."],
		["Polise bildir", "", 0.4, "ger+1;arama+3", "Polis geldi; rakip çekildi.", "saygi-4", "Polis seni küçümsedi."],
		["Pazarlık et", "karizma>=5", 0.6, "kirli+200", "Yarı yarıya anlaştınız.", "saygi-2", "Pazarlık olmadı."],
	]},
	"w09": {"b": "Güçlü ailenin ziyareti", "m": "{F}'ın başı seni özel bir görüşmeye çağırdı.", "ev": [3, 4], "w": 5, "cd": 40, "f": "guclu", "tag": "dünya", "s": [
		["Git", "", 0.7, "y.kulis+4;saygi+2", "Saygılı bir tanışma oldu.", "saygi-3;stres+3", "Seni küçük gördüler."],
		["Davete sebep göster", "", 1.0, "", "Randevu ertelendi.", "", ""],
		["Askerlerle git", "adam>=4", 0.5, "saygi+4;y.korku+3", "Gücünü sergiledin.", "ger+4", "Gerginlik doğdu."],
	]},
	"w10": {"b": "Zayıf ailenin hıyaneti", "m": "{F}, güçsüz olsa da arkandan iş çeviriyor.", "ev": [2, 4], "w": 4, "cd": 30, "f": "zayif", "tag": "dünya", "s": [
		["Cezalandır", "adam>=2", 0.7, "y.korku+4;inf+8", "Ders aldılar.", "yara+10;ger+3", "Kavga çıktı."],
		["Affet", "", 1.0, "saygi+2;sevgi+1", "Cömertliğin takdir edildi.", "", ""],
		["Görmezden gel", "", 1.0, "saygi-1", "İş büyümedi.", "", ""],
	]},
	# ---------- ZİNCİR (yalniz zincir_cek ile gelir) ----------
	"z01": {"b": "Gölgede bir isim", "m": "Geçmişten gelen bir isim, senin hakkında bir şey fısıldıyor.", "ev": [0, 4], "w": 1, "cd": 9999, "k": "yil>=9999", "tag": "zincir", "s": [
		["Dinle", "", 0.6, "y.kulis+3", "Faydalı bir bilgi edindin.", "stres+2", "Söylentiydi."],
		["Önemseme", "", 1.0, "", "Geçti gitti.", "", ""],
	]},
	"z02": {"b": "Tefecinin öfkesi", "m": "Bir önceki olayın ardından tefeci yeniden çıkageldi; bu kez yanında adamlar var.", "ev": [0, 4], "w": 1, "cd": 9999, "k": "yil>=9999", "tag": "zincir", "s": [
		["Borcu öde", "kirli>=100", 1.0, "kirli-100;tef-100;stres-2", "Borç kapandı.", "", ""],
		["Direnmeyi dene", "adam>=1", 0.45, "y.korku+3;saygi+3", "Adamlar kaçtı.", "yara+25;rezil+3", "Dayak yedin."],
		["Şehirden kaç", "", 0.5, "stres-3", "Birkaç gün saklandın.", "yara+10;rezil+3", "Yakalandın."],
	]},
	"z03": {"b": "Kaptanın intikamı", "m": "Daha önce karşına dikilen biri intikam için ortaya çıktı.", "ev": [0, 4], "w": 1, "cd": 9999, "k": "yil>=9999", "tag": "zincir", "s": [
		["Yüzleş", "adam>=2", 0.55, "y.korku+5;saygi+3", "Sorun bir kez ve herkesin gözü önünde çözüldü.", "yara+25;adam-1", "Adamların ağır yaralandı."],
		["Para ver", "kirli>=200", 0.9, "kirli-200;ger-2", "Sessizlik satın aldın.", "", ""],
		["Kaçın", "", 0.5, "stres-1", "İzini kaybettirdin.", "saygi-3;stres+3", "Seni buldular."],
	]},
	"z04": {"b": "Eski borç geri dönüyor", "m": "Yıllar önce yardım ettiğin biri, minnetini göstermek için kapına geldi.", "ev": [0, 4], "w": 1, "cd": 9999, "k": "yil>=9999", "tag": "zincir", "s": [
		["Kabul et", "", 1.0, "saygi+3;sevgi+3;kirli+250", "Eski dostluk işe yaradı.", "", ""],
		["Reddet", "", 1.0, "", "Gururunu korudun.", "", ""],
	]},
	"z05": {"b": "Ölümcül sır", "m": "Biri, geçmişteki bir sırrını elinde tuttuğunu söylüyor.", "ev": [0, 4], "w": 1, "cd": 9999, "k": "yil>=9999", "tag": "zincir", "s": [
		["Parayla sustur", "kirli>=300", 0.8, "kirli-300", "Sır gömüldü.", "kirli-300;stres+4", "Sır yine de yayıldı."],
		["Tehdit et", "adam>=2", 0.5, "y.korku+4", "Sustu.", "arama+10", "Polise gitti."],
		["Görmezden gel", "", 0.5, "", "Blöf çıktı.", "saygi-5;arama+8", "Sır yayıldı."],
	]},
	"z06": {"b": "Büyük intikam", "m": "Sana düşman olan biri uzun süre sabrettikten sonra harekete geçti.", "ev": [0, 4], "w": 1, "cd": 9999, "k": "yil>=9999", "tag": "zincir", "s": [
		["Savaş", "adam>=3", 0.5, "y.korku+6;saygi+4", "Düşman yıkıldı.", "yara+30;adam-2", "Ağır kayıplar verdin."],
		["Müzakere", "karizma>=6", 0.5, "ger-5;saygi+2", "Hesap kapandı.", "saygi-3", "Müzakere tutmadı."],
	]},
	# ---------- NADİR ----------
	"x01": {"b": "Gizemli yabancı", "m": "Pahalı giyimli bir yabancı, sana bir zarf bırakıp kayboldu.", "ev": [1, 4], "w": 1, "cd": 200, "tag": "nadir", "s": [
		["Zarfı aç", "", 0.6, "kirli+800", "Zarfta para vardı.", "stres+5", "Zarfta tehdit vardı."],
		["Yak", "", 1.0, "", "Kaçtı gitti.", "", ""],
	]},
	"x02": {"b": "Şans oyunu", "m": "Eski bir dost seni gizli bir kumar masasına çağırıyor.", "ev": [0, 4], "w": 1, "cd": 150, "tag": "nadir", "s": [
		["Oyna", "kirli>=100", 0.4, "kirli+600", "Şansın yaver gitti.", "kirli-100", "Kaybettin."],
		["Seyret", "", 1.0, "", "Masadan kalktın.", "", ""],
	]},
	"x03": {"b": "Eski mektup", "m": "Postacı, yıllar önce yazılmış bir mektup getirdi.", "ev": [0, 4], "w": 1, "cd": 300, "tag": "nadir", "s": [
		["Oku", "", 1.0, "stres-3;sevgi+1", "Eski günler aklına düştü.", "", ""],
		["Yak", "", 1.0, "", "Geçmiş geçmişte kalsın.", "", ""],
	]},
	"x04": {"b": "Gezgin sanatçı", "m": "Sokakta bir gezgin sanatçı portreni çizmeyi öneriyor.", "ev": [1, 4], "w": 1, "cd": 200, "tag": "nadir", "s": [
		["Çizdir", "temiz>=30", 1.0, "temiz-30;saygi+1;stres-2", "Portre duvarında asılı.", "", ""],
		["Reddet", "", 1.0, "", "Yoluna devam ettin.", "", ""],
	]},
	"x05": {"b": "Yağmurlu gece", "m": "Yağmurlu bir gecede kapını biri çaldı; ıslak ve yorgun biri.", "ev": [0, 4], "w": 1, "cd": 250, "tag": "nadir", "s": [
		["İçeri al", "", 0.7, "sevgi+3;saygi+1", "Eski bir yolcuydu; kısa bir dost edindin.", "temiz-30", "Eşyanı çaldı."],
		["Kapıyı açma", "", 1.0, "", "Gece sessiz geçti.", "", ""],
	]},
}
