extends RefCounted
# Olay verisi A: Sokak çocuğu (Evre 0) ve Haraççı (Evre 1). Biçim için olaylar.gd başına bak.

const OLAY := {
	"s04": {"b": "Aç çocuk", "m": "Köşede yırtık montlu bir çocuk sana bakıyor. Üç gündür bir şey yememiş gibi.", "ev": [0, 1], "w": 6, "cd": 14, "tag": "vicdan", "s": [
		["Ekmek ver", "temiz>=5", 1.0, "temiz-5;sevgi+3;y.kanun+1", "Çocuk ekmeği kapıp gülümsedi. Mahalle bunu duydu.", "", ""],
		["Görmezden gel", "", 1.0, "stres+2", "Yüzüne bakmadan geçtin. İçinde bir şey sızladı.", "", ""],
		["Onu gözcü yap", "", 0.6, "kirli+15;y.golge+2", "Çocuk sokakları avucunun içi gibi biliyor; sana bilgi getiriyor.", "sevgi-2;stres+2", "Çocuk korktu ve kaçtı. Birkaç kişi seni gördü."],
	]},
	"s05": {"b": "Kavga çağrısı", "m": "Kahvehanede bir külhanbeyi masana yaklaştı: «Sen buralarda sözü geçen biri olmaya çalışıyorsun. Dışarı çıkalım.»", "ev": [0, 1], "w": 7, "cd": 10, "bec": "guc", "tag": "kavga", "s": [
		["Kabul et", "", "0.5,guc,0.04", "saygi+4;y.korku+4;kirli+30", "Adamı yere serdin. Kahvehane alkışladı.", "yara+25;saygi-2", "Yumruğu yedin; kahvehane gülüyor."],
		["Reddet", "", 1.0, "saygi-1", "Omuz silkip çıktın. Kimse bir şey demedi ama gördüler.", "", ""],
		["Hakem ol", "karizma>=6", 0.7, "sevgi+3;saygi+2", "İkisini de oturtup barıştırdın. Mahalle seni sevdi.", "saygi-1", "Seni dinleyen çıkmadı; kavga yine çıktı."],
	]},
	"s07": {"b": "Meyhane dedikodusu", "m": "Meyhanede yan masadakiler alçak sesle konuşuyor. Bir sevkiyat, bir yer, bir saat.", "ev": [0, 1], "w": 8, "cd": 10, "tag": "bilgi", "s": [
		["Kulak ver", "", 0.65, "y.golge+3;kirli+40", "Duyduğun bilgiyi doğru kişiye sattın.", "arama+3", "Fark ettiler. Ters ters baktılar."],
		["Kâğıt oyununa katıl", "temiz>=20", 0.45, "kirli+60", "Eli sen topladın.", "temiz-20;stres+3", "Elini kaybettin. Cebin hafifledi."],
		["Uzak dur", "", 1.0, "", "Masandan kalkmadın.", "", ""],
	]},
	"s08": {"b": "İlk iş teklifi", "m": "Üç ayrı kapı aynı gün çalındı: Bir kasap çırak arıyor. Bir tanıdık kaçak mal taşıtmak istiyor. Bir de sokaktaki adamlar esnaftan para toplamayı öneriyor.", "ev": [0, 0], "w": 12, "cd": 40, "tek": true, "tag": "yol", "s": [
		["Kasaba çırak ol", "", 1.0, "temiz+40;y.kanun+3;sevgi+2", "Kasap seni sevdi. Ellerin kokuyor ama cebin dolu.", "", ""],
		["Kaçak mal taşı", "", 0.65, "kirli+80;y.golge+3", "Karanlıkta sorunsuz geçtin; para peşin.", "arama+5;kirli+20", "Bir devriye gördü; mal yarıya indi."],
		["Esnaftan koruma iste", "", 0.55, "kirli+70;y.korku+3;saygi+1", "İlk haracını aldın.", "sevgi-2;arama+4", "Esnaf polise gitmekle tehdit etti."],
	]},
	"s09": {"b": "Mahalle şenliği", "m": "Meydanda orkestra çalıyor, sokaklar kalabalık. Herkes eğleniyor; sen de oradasın.", "ev": [0, 3], "w": 5, "cd": 14, "tag": "topluluk", "s": [
		["Cömertçe ısmarla", "temiz>=30", 1.0, "temiz-30;sevgi+5;saygi+2", "Masalara içki yolladın. Şenlik senin adını anıyor.", "", ""],
		["Sadece izle", "", 1.0, "", "Bir köşede müziğin tadını çıkardın.", "", ""],
		["Kalabalıkta cep tara", "", 0.6, "kirli+55;y.golge+2", "Birkaç cüzdan el değiştirdi. Kimse anlamadı.", "arama+6;sevgi-3", "Biri elini tuttu; bağırışlar yükseldi."],
	]},
	"s10": {"b": "Gece yarısı kapı", "m": "Gece yarısı kapı hafifçe tıkırdadı. Dışarıda kanlı kolu olan bir adam: «Birkaç gün saklanmam lazım. Soru sorma.»", "ev": [0, 1], "w": 3, "cd": 60, "tek": true, "tag": "gizem", "s": [
		["Sakla", "", 1.0, "stres+3;sonra:z02:25", "Adamı eve aldın. Gözü kapıda, elinde bıçak uyuyor.", "", ""],
		["İhbar et", "", 1.0, "arama-5;y.kanun+2;saygi-1", "Polise haber verdin. Adamın yüzü aklında kalacak.", "", ""],
		["Geri çevir", "", 1.0, "", "Kapıyı kapattın. Gecenin ilerleyen saatinde dışarıda ayak sesleri oldu.", "", ""],
	]},
	"s11": {"b": "Kaçak içki partisi", "m": "Bir tanıdık, arka odada küçük bir kaçak içki partisi düzenleyecek ve senden kapıya bakmanı istiyor.", "ev": [0, 1], "w": 5, "cd": 12, "yol": "golge", "tag": "iş", "s": [
		["Kapıda dur", "", 0.7, "kirli+45;y.golge+2", "Gece sorunsuz geçti; kapı parası cebinde.", "arama+6", "Baskın oldu, zor kaçtın."],
		["Kendi partini düzenle", "temiz>=40", 0.55, "kirli+110;saygi+2", "Tuttu: salon doldu.", "temiz-40;arama+6", "Kimse gelmedi; masraf boşa."],
		["Reddet", "", 1.0, "", "Başını salladın.", "", ""],
	]},
	"s12": {"b": "Kayıp köpek", "m": "Komşuların çocuğu ağlayarak yanına geldi: köpeği kaybolmuş. Mahalle onu aramaya başlamış bile.", "ev": [0, 2], "w": 4, "cd": 25, "tag": "topluluk", "s": [
		["Ara", "", 0.75, "sevgi+4;saygi+1", "Köpeği bir bodrumda buldun. Çocuk seni sarılarak teşekkür etti.", "stres+2", "Bütün gün aradın, bulamadın."],
		["Ödül ilan et", "temiz>=15", 1.0, "temiz-15;sevgi+3", "Kısa sürede köpek geri geldi.", "", ""],
		["Aldırma", "", 1.0, "", "Başka işlerin var.", "", ""],
	]},
	"s13": {"b": "Eski hesap", "m": "Eski bir tanıdık sokakta seni durdurdu: «Sana yıllar önce bir iyilik yapmıştım, hatırlıyor musun?»", "ev": [0, 2], "w": 4, "cd": 30, "tag": "ilişki", "s": [
		["Hatırla ve öde", "temiz>=30", 1.0, "temiz-30;saygi+3;sevgi+2", "Borcunu ödedin; adam seni sevgiyle andı.", "", ""],
		["Kandır", "karizma>=5", 0.6, "", "Lafı çevirdin; adam yenik sustu.", "saygi-3", "Adam sinirlendi: «Seni unutmayacağım.»"],
		["Sertleş", "", 1.0, "y.korku+3;sevgi-2", "Gözünü dikip baktın; adam geri çekildi.", "", ""],
	]},
	"s14": {"b": "Pazar kavgası", "m": "Pazarda iki tezgâhtar birbirine girdi. Biri seni gördü: «Sen karar ver!»", "ev": [0, 1], "w": 5, "cd": 10, "tag": "topluluk", "s": [
		["Adil davran", "karizma>=5", 0.7, "sevgi+3;saygi+2", "Taraflar seni dinledi; pazar barıştı.", "saygi-2", "İkisi de sana kızdı."],
		["Güçlünün yanında dur", "", 1.0, "kirli+30;sevgi-2", "Güçlü tezgâhtar sana bahşiş verdi.", "", ""],
		["Aldırma", "", 1.0, "", "Çekip gittin.", "", ""],
	]},
	"h08": {"b": "Küçük soygun teklifi", "m": "Bir tanıdık, ucuz bir dükkâna gece baskını önerdi: «Üç kişiyiz, kasa dolu. Sen de katıl.»", "ev": [1, 2], "w": 6, "cd": 12, "yol": "golge", "tag": "suç", "k": "y_golge>=3", "s": [
		["Katıl", "", "0.5,zeka,0.03", "kirli+260;y.golge+3", "Her şey plana uydu: kasa boşaldı, sokak sakin.", "arama+10;stres+4", "Ters gitti, zor kaçtın. Polis aradı."],
		["Planı düzelt", "zeka>=6", 0.75, "kirli+180;y.golge+2", "Daha güvenli bir yol seçtin; payın küçük ama temiz.", "arama+4", "Plan ortada bozuldu; kimse bir şey kazanmadı."],
		["Reddet", "", 1.0, "", "Fırsat gitti.", "", ""],
	]},
	"h09": {"b": "Taverna kumarı", "m": "Taverna arka odasında yüksek bahisli bir poker oyunu var. Masaya oturmanı istiyorlar.", "ev": [1, 2], "w": 5, "cd": 10, "tag": "kumar", "s": [
		["Küçük bahis ($50)", "para>=50", 0.5, "kirli+50", "Elin güzeldi.", "kirli-50", "Kaybettin."],
		["Büyük bahis ($200)", "para>=200", 0.45, "kirli+200;saygi+1", "Adamın en iyi eli düştü; masa seni konuşuyor.", "kirli-200;stres+4", "Yüksek bahis sana yaramadı."],
		["Hile yap", "zeka>=7", 0.6, "kirli+150", "Kimse fark etmedi.", "kirli-100;y.korku-2;arama+3", "Yakalandın; masa sana kızdı."],
		["Kalk", "", 1.0, "", "Masadan kalktın.", "", ""],
	]},
	"h10": {"b": "Tanıdık gelir", "m": "Bir komşu seni evine yemeğe çağırdı. Masada tanışmak istediğin biri var.", "ev": [1, 3], "w": 5, "cd": 40, "k": "!evli", "tag": "aile", "s": [
		["Tanış", "yas>=18", 1.0, "es_aday+1", "Sohbet ilerledi; evlenebileceğin adaylar belirdi (Ailem panelinden).", "", ""],
		["Kibarca uzak dur", "", 1.0, "stres-1", "Nazikçe reddettin.", "", ""],
	]},
	"h11": {"b": "Hastalık", "m": "Birkaç gündür öksürüyorsun. Mahallede bir şifacı var; bir de doktor.", "ev": [1, 4], "w": 4, "cd": 40, "tag": "sağlık", "s": [
		["Doktora git", "temiz>=40", 1.0, "temiz-40;stres-3", "Doktor ilaç yazdı. İyileşiyorsun.", "", ""],
		["Şifacıya git", "", 0.6, "stres-2;sevgi+1", "Bitkisel çay iyi geldi.", "yara+10", "Düzelmedin."],
		["Aldırma", "", 0.5, "", "Atlatıldı.", "yara+20;stres+3", "Hastalık ağırlaştı."],
	]},
	"h12": {"b": "Sahte para", "m": "Bir gölgenin içinden sahte banknot destesi uzatıldı: «Piyasaya sürersen iki katını verir.»", "ev": [1, 2], "w": 4, "cd": 30, "yol": "golge", "k": "y_golge>=4", "tag": "suç", "s": [
		["Piyasaya sür", "", 0.5, "kirli+200;y.golge+3;arama+6", "Esnaf ayırt edemedi; paralar döndü.", "arama+14;sevgi-3", "Banknotlar fark edildi; mahallede söz yayıldı."],
		["Polise bildir", "", 1.0, "arama-5;y.kanun+3;dok.polis+5", "Polis seni dürüst bir vatandaş gördü.", "", ""],
		["Reddet", "", 1.0, "", "Elini sürmedin.", "", ""],
	]},
	"h13": {"b": "Rakip çıraklar", "m": "Meyhane çevresindeki genç çıraklar seni örnek alıyor ve sana bağlanmak istiyor.", "ev": [1, 2], "w": 5, "cd": 20, "k": "adam<5", "tag": "adam", "s": [
		["Birini al", "para>=150", 1.0, "kirli-150;adam+1", "Gencin gözleri parladı. Ekibe katıldı.", "", ""],
		["Öğüt ver", "", 1.0, "sevgi+2;saygi+2", "Tecrübeni paylaştın.", "", ""],
		["Başından savma", "", 1.0, "saygi-1", "Çıraklar küstü.", "", ""],
	]},
	"h14": {"b": "Birikim ve harcama", "m": "Bir tüccar, elinde biriken parayı yatırıma çevirmeni öneriyor: «Dükkân tutarsan her ay kira gelir.»", "ev": [1, 2], "w": 4, "cd": 25, "k": "para>=400", "tag": "iş", "s": [
		["Yatır", "temiz>=300", 0.7, "temiz-300;saygi+2;y.kanun+2;sevgi+1", "Dükkân doldu; kasa çalışıyor.", "temiz-100", "Dükkân kötü yerdeymiş; kira alamadın."],
		["Cebinde tut", "", 1.0, "", "Güvenli olan cebin.", "", ""],
	]},
}
