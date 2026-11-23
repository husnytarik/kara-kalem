extends RefCounted
# Olay verisi C: Don/Şehir (Evre 4), Baba, Saygın iş adamı ve Rezil/Dip yolları.

const OLAY := {
	# ---------- DON / ŞEHİR ----------
	"d01": {"b": "Şehir savaşı kıvılcımı", "m": "İki büyük aile arasındaki gerginlik patlamak üzere; ikisi de seni yanına çekmek istiyor.", "ev": [4, 4], "w": 8, "cd": 25, "f": "gerg", "k": "bolge>=3", "tag": "kriz", "s": [
		["{F}'ın yanında dur", "", 0.6, "ger-5;y.kulis+4;saygi+3", "Müttefikin güçlendi.", "ger+3;adam-1", "Savaşın ortasında kaldın."],
		["Arabulucu ol", "karizma>=6", 0.55, "saygi+6;sevgi+3;y.kulis+5;ger-4", "İkisini de masaya oturttun. Şehir seni konuşuyor.", "saygi-3", "İki taraf da sana kızdı."],
		["İkisine de ihanet et", "zeka>=8", 0.4, "kirli+800;y.golge+5", "Karmaşadan faydalandın.", "ger+8;yara+20", "İkisi de senin peşinde."],
	]},
	"d03": {"b": "Federal soruşturma", "m": "Federal ajanlar kapını çalıp defterlerini incelemek istediklerini söyledi.", "ev": [3, 4], "w": 8, "cd": 25, "k": "fed>=35", "tag": "federal", "s": [
		["Avukatla savun", "temiz>=500", 1.0, "temiz-500;fed-20", "Avukat dosyayı yavaşlattı.", "", ""],
		["Kâğıtları yok et", "", 0.55, "fed-15;arama+5", "Delil yok oldu.", "fed+15;arama+10", "Yok ederken yakalandın."],
		["Yargıçla anlaş", "d_yargic>=40", 1.0, "dok.yargic-40;fed-30", "Yargıç dosyayı kapattı.", "", ""],
	]},
	"d04": {"b": "Büyük bankacı", "m": "Şehrin en büyük bankasının sahibi seni özel bir yemeğe çağırdı: «Birlikte çok kazanabiliriz.»", "ev": [4, 4], "w": 5, "cd": 40, "k": "servet_un>=55", "tag": "iş", "s": [
		["Ortaklığı kabul et", "temiz>=2000", 0.7, "temiz-2000;temiz+5000;fed+5;saygi+4", "Banka kârı bölüşüyor; sermayen büyüdü.", "temiz-2000;fed+10", "Banka sana dış gösterdi; sermaye gitti."],
		["Reddet", "", 1.0, "", "Bankacı gülümsedi ve başka birine yöneldi.", "", ""],
		["Soygunu planla", "adam>=4", 0.4, "kirli+4000;y.golge+5;arama+10", "Plan tuttu; devasa bir vurgun.", "arama+25;hapis:4", "Plan ortada bozuldu."],
	]},
	"d05": {"b": "Senatör yemeği", "m": "Bir senatör seninle yemek yemek istiyor; gözünde dünyanın en eski ittifakı var.", "ev": [4, 4], "w": 5, "cd": 40, "k": "d_siyasi>=20", "tag": "nüfuz", "s": [
		["Destek sözü ver", "temiz>=1000", 1.0, "temiz-1000;dok.siyasi+15;saygi+3", "Senatör sana borçlu.", "", ""],
		["Şantajla", "zeka>=7", 0.5, "dok.siyasi+25;fed+8", "Bir sırrını öğrendin; senatör artık yönetilebilir.", "dok.siyasi-10;arama+10", "Senatör bunu fark etti."],
		["Reddet", "", 1.0, "saygi+2", "Senatör şaşırdı.", "", ""],
	]},
	"d06": {"b": "Şehir yıldönümü", "m": "Aile namının doğuşunun yıldönümü yaklaşıyor. Herkes büyük bir parti bekliyor.", "ev": [4, 4], "w": 3, "cd": 120, "k": "nam>=1", "tag": "prestij", "s": [
		["Büyük parti ver", "temiz>=1500", 1.0, "temiz-1500;nam+1;sevgi+5;saygi+5", "Şehrin yarısı davetliydi.", "", ""],
		["Sessiz geç", "", 1.0, "", "Kimse bir şey demedi.", "", ""],
	]},
	"d07": {"b": "Mafya Konseyi", "m": "Şehrin büyük aileleri bir konsey kurmak istiyor ve seni de çağırıyor.", "ev": [4, 4], "w": 5, "cd": 60, "f": "rakip", "k": "bolge>=3", "tag": "dünya", "s": [
		["Başkanlığı iste", "karizma>=7", 0.45, "saygi+8;y.kulis+6;ger-5", "Konsey başkanlığı sana verildi.", "ger+3;saygi-3", "Başkanlık başkasına gitti."],
		["Üye ol", "", 1.0, "y.kulis+4;ger-3", "Konseyde bir koltuğun var.", "", ""],
		["Katılma", "", 1.0, "ger+2;saygi+1", "Bağımsız kaldın.", "", ""],
	]},
	"d08": {"b": "Kıtalararası kaçakçılık", "m": "Liman müdürü, büyük bir sevkiyat için seni arıyor.", "ev": [4, 4], "w": 5, "cd": 30, "yol": "golge", "k": "y_golge>=10", "tag": "iş", "s": [
		["Büyük sevkiyat yap", "adam>=3", 0.55, "kirli+3500;y.golge+4;fed+4", "Mal sorunsuz geldi.", "kirli-1500;arama+12;adam-1", "Mal el konuldu."],
		["Liman memurunu satın al", "kirli>=1000", 1.0, "kirli-1000;dok.polis+10", "Memur artık senin.", "", ""],
		["Geç", "", 1.0, "", "Riske girmedin.", "", ""],
	]},
	"d09": {"b": "Bakan ziyareti", "m": "Bakan, şehre geldi ve seninle özel görüşmek istiyor.", "ev": [4, 4], "w": 3, "cd": 60, "k": "d_siyasi>=30", "tag": "nüfuz", "s": [
		["Karşıla", "", 0.7, "dok.siyasi+10;saygi+4", "Bakan seni dinledi.", "arama+6", "Bakan gazetecilerle geldi."],
		["Sessiz geç", "", 1.0, "", "Görüşme yapılmadı.", "", ""],
	]},
	"d10": {"b": "İtibar suikastı", "m": "Gazeteler senin hakkında yalan bir haber yaymaya başladı.", "ev": [4, 4], "w": 4, "cd": 30, "k": "saygi>=40", "tag": "kriz", "s": [
		["Yalanla", "", 0.6, "saygi+3", "Yalanlama etki etti.", "saygi-6", "Yalanlama yeni haberlere yol açtı."],
		["Yayıncıyı bul", "adam>=3", 0.5, "y.korku+5;ger+3", "Yayıncıyı susturdun.", "arama+8;saygi-3", "Girişim fark edildi."],
		["Sessiz kal", "", 1.0, "saygi-3", "Fırtına dinene kadar bekledin.", "", ""],
	]},
	"d11": {"b": "Hapishane isyanı", "m": "Eski hapishane arkadaşlarından biri isyan çıkarmak üzere; senden yardım istiyor.", "ev": [4, 4], "w": 3, "cd": 60, "k": "hapis>=1", "tag": "adalet", "s": [
		["Müdürle anlaş", "kirli>=300", 1.0, "kirli-300;dok.yargic+8", "Müdür gözünü kapattı.", "", ""],
		["İsyana yardım et", "", 0.4, "y.korku+6;sad+6", "İsyan başarılı oldu.", "arama+20;hapis:3", "İsyan bastırıldı ve seni yakaladılar."],
		["Aldırma", "", 1.0, "", "Önemsemedin.", "", ""],
	]},
	"d12": {"b": "Kuraklık ve kıtlık", "m": "Bu yıl hasat zayıf; şehirde ekmek pahalandı, aç insanlar var.", "ev": [3, 4], "w": 4, "cd": 60, "k": "sevgi>=25", "tag": "felaket", "s": [
		["Gıda dağıt", "temiz>=1000", 1.0, "temiz-1000;sevgi+10;saygi+5;nam+1", "Şehir seni anıyor.", "", ""],
		["Stokla ve sat", "", 0.55, "temiz+1200;sevgi-8", "Fiyatı kat kat yükselttin.", "sevgi-12;arama+8", "Halk öfkelendi."],
		["Rakibe sat", "", 1.0, "kirli+500", "Elindeki erzakı rakibe sattın.", "", ""],
	]},
	"d13": {"b": "Üniversite bursu", "m": "Şehrin üniversitesi sana bir burs fonu kurmanı öneriyor.", "ev": [4, 4], "w": 3, "cd": 90, "k": "servet_un>=60", "tag": "prestij", "s": [
		["Burs fonu kur", "temiz>=2000", 1.0, "temiz-2000;nam+1;sevgi+6;saygi+6", "Fonun adı senin adınla anılıyor.", "", ""],
		["Reddet", "", 1.0, "", "Başka yatırımlar var.", "", ""],
	]},
	"d14": {"b": "Şehir festivali", "m": "Şehir festivalinin ana sponsorluğu boş kaldı.", "ev": [4, 4], "w": 5, "cd": 30, "k": "sevgi>=30", "tag": "prestij", "s": [
		["Ana sponsor ol", "temiz>=1200", 1.0, "temiz-1200;sevgi+7;saygi+5", "Şehir bir hafta boyunca seninle yaşadı.", "", ""],
		["Rakibin sponsorluğunu engelle", "adam>=3", 0.5, "y.korku+5;ger+3", "Rakip sponsorluktan çekildi.", "arama+8;sevgi-3", "Şehir olayı not etti."],
		["Seyirci kal", "", 1.0, "", "Sokaktan izledin.", "", ""],
	]},
	# ---------- BABA ----------
	"b01": {"b": "İhanetin kokusu", "m": "Ekipte bir şeyler ters. Fısıltılar var; biri seni satıyor gibi.", "ev": [3, 4], "w": 7, "cd": 18, "tip": ["Baba"], "k": "adam>=4;sad<55", "tag": "sadakat", "s": [
		["Gizlice araştır", "zeka>=6", 0.65, "y.korku+3;sad+4", "Muhbiri buldun; sessizce sildin.", "sad-5;stres+3", "Bir şey bulamadın."],
		["Herkesi topla ve ürket", "", 1.0, "y.korku+5;sad-6;stres+2", "Sert sözlerin kimseyi rahat bırakmadı.", "", ""],
		["Gör ama yut", "", 1.0, "sad-3", "Şüphe kaldı ama tartışmadın.", "", ""],
	]},
	"b02": {"b": "Ceza kararı", "m": "İhanet eden adam sana getirildi. Tüm gözler sende.", "ev": [3, 4], "w": 6, "cd": 25, "tip": ["Baba"], "k": "adam>=3", "tag": "sertlik", "s": [
		["Sessizce cezalandır", "", 1.0, "y.korku+5;saygi-2;adam-1", "Ceza sessizce uygulandı; mesaj iletildi.", "", ""],
		["Herkese göstererek cezalandır", "", 1.0, "y.korku+9;sevgi-6;sad+4;adam-1", "Mahalle ürpererek konuştu.", "", ""],
		["Affet", "", 1.0, "saygi+3;sad+5;sevgi+2", "Adam ayaklarına kapandı; adamlar bunu gördü.", "", ""],
	]},
	"b03": {"b": "Rakip aile hediyesi", "m": "{F}'dan bir paket geldi: pahalı bir saat ve imzasız bir kart.", "ev": [3, 4], "w": 5, "cd": 25, "tip": ["Baba"], "f": "esit", "tag": "dünya", "s": [
		["Kabul et", "", 1.0, "ger-3;y.kulis+3;saygi+1", "Hediye iyi niyet sayıldı.", "", ""],
		["İade et", "", 1.0, "ger+3;y.korku+3", "Gönderdiğin mesaj açıktı.", "", ""],
		["Kartı oku", "zeka>=6", 0.6, "y.kulis+4;kirli+250", "Kartta saklı bir bilgi vardı.", "stres+2", "Kartta bir şey yoktu."],
	]},
	"b04": {"b": "Cenaze", "m": "Eski bir mahalle ihtiyarı öldü; aile senden cenazesine gelmeni istiyor.", "ev": [2, 4], "w": 4, "cd": 40, "tip": ["Baba", "Saygın iş adamı"], "tag": "ritüel", "s": [
		["Görkemli cenaze düzenle", "temiz>=300", 1.0, "temiz-300;saygi+4;sevgi+4", "Cenaze mahallenin en kalabalığı oldu.", "", ""],
		["Sade katıl", "", 1.0, "saygi+2;sevgi+2", "Dualara katıldın.", "", ""],
		["Katılma", "", 1.0, "saygi-4;sevgi-3", "Eksik kaldın; yüzler asıldı.", "", ""],
	]},
	"b05": {"b": "Bölge tapusu", "m": "Elinde tutmak istediğin bir mahalle köşesi için tapu satılığa çıkarıldı.", "ev": [3, 4], "w": 4, "cd": 30, "tip": ["Baba"], "k": "para>=3000", "tag": "iş", "s": [
		["Satın al", "temiz>=3000", 1.0, "temiz-3000;inf+20;saygi+3", "Tapu senin; mahalle artık seni tanıyor.", "", ""],
		["Sahibini korkut", "adam>=3", 0.6, "inf+15;y.korku+5", "Sahibi fiyatı düşürdü.", "arama+8;sevgi-4", "Sahibi polise gitti."],
		["Başkasına bırak", "", 1.0, "", "Başka biri aldı.", "", ""],
	]},
	"b06": {"b": "Sivil kayıp", "m": "Bir çatışmada kazara bir yoldan geçen vuruldu. Cenaze mahalleden çıkıyor.", "ev": [3, 4], "w": 4, "cd": 40, "tip": ["Baba"], "k": "y_korku>=20", "tag": "kriz", "s": [
		["Tazminat öde", "temiz>=500", 1.0, "temiz-500;sevgi+4;saygi+3", "Aile tazminatı kabul etti.", "", ""],
		["Örtbas et", "kirli>=300", 0.6, "kirli-300;arama-4", "Olay kapandı.", "arama+10;sevgi-6", "Örtbas deşifre oldu."],
		["Faili cezalandır", "", 1.0, "saygi+4;adam-1;sad-3", "Adalet yerine geldi; adamlar sustu.", "", ""],
	]},
	"b07": {"b": "Genç çete", "m": "Mahalleli gençlerden oluşan bir çete, sokak köşelerinde ortaya çıktı.", "ev": [3, 4], "w": 4, "cd": 25, "tip": ["Baba"], "k": "yas>=35", "tag": "gelecek", "s": [
		["Himayeye al", "", 0.7, "adam+2;y.korku+3;sad+3", "Gençler sana bağlandı.", "sevgi-3", "Gençler seni dinlemedi."],
		["Dağıt", "adam>=3", 0.6, "y.korku+4;saygi+2", "Çete dağıldı.", "yara+10;arama+5", "Çatışma çıktı."],
		["Yok say", "", 1.0, "", "Bu işe karışmadın.", "", ""],
	]},
	"b08": {"b": "Vasiyet", "m": "Yaşlandığını hissediyorsun. Avukat, vasiyetini yazmanı öneriyor.", "ev": [3, 4], "w": 5, "cd": 120, "k": "yas>=55", "tag": "miras", "s": [
		["Eşit böl", "", 1.0, "nam+1;stres-4;sevgi+2", "Çocuklar kavga etmeyecek.", "", ""],
		["En yetenekliye bırak", "", 1.0, "saygi+2;stres-2", "Mirasçın belli oldu.", "", ""],
		["Yazma", "", 1.0, "stres+3", "Ertelemeyi seçtin.", "", ""],
	]},
	# ---------- SAYGIN İŞ ADAMI ----------
	"i01": {"b": "Yeni ortaklık", "m": "Yükselen bir girişimci, seninle bir ortaklık önerdi.", "ev": [2, 4], "w": 7, "cd": 20, "tip": ["Saygın iş adamı"], "yol": "kanun", "tag": "iş", "s": [
		["Kabul et", "temiz>=300", 0.75, "temiz-300;temiz+700;saygi+3", "Ortaklık tuttu.", "temiz-300;saygi-1", "Ortak seni dolandırdı."],
		["Pazarlık yap", "zeka>=7", 0.7, "temiz-200;temiz+800;saygi+4", "Daha iyi bir pay kopardın.", "saygi-1", "Pazarlık sonuç vermedi."],
		["Reddet", "", 1.0, "", "Riske girmedin.", "", ""],
	]},
	"i02": {"b": "Banka kredisi", "m": "Banka sana düşük faizli bir kredi öneriyor.", "ev": [2, 4], "w": 6, "cd": 30, "tip": ["Saygın iş adamı"], "k": "temiz>=500", "tag": "finans", "s": [
		["Kredi al", "", 0.75, "temiz+1500;temiz-300", "Krediyi iyi kullandın.", "temiz-500;saygi-2", "Yatırım tutmadı; kredi sırtında."],
		["Reddet", "", 1.0, "", "Bankaya ihtiyacın yok.", "", ""],
	]},
	"i03": {"b": "Fabrika grevi", "m": "İşçiler daha yüksek ücret için grev çağrısı yaptı.", "ev": [3, 4], "w": 5, "cd": 40, "tip": ["Saygın iş adamı"], "k": "isl>=3", "tag": "iş", "s": [
		["Zam yap", "temiz>=400", 1.0, "temiz-400;sevgi+6;saygi+3", "İşçiler seni alkışladı.", "", ""],
		["Grevi kır", "adam>=3", 0.55, "y.korku+4;temiz+300;sevgi-8", "Grev kırıldı.", "sevgi-12;arama+8", "Grev kırma tepki çekti."],
		["Müzakere et", "karizma>=7", 0.65, "temiz-150;sevgi+4;saygi+3", "Orta yolda buluştunuz.", "sevgi-2", "Müzakere çıkmaza girdi."],
	]},
	"i04": {"b": "Rakip iş adamı", "m": "Şehrin diğer ucundaki bir iş adamı, müşterilerini çalmaya başladı.", "ev": [2, 4], "w": 6, "cd": 20, "tip": ["Saygın iş adamı"], "tag": "iş", "s": [
		["Fiyat savaşı", "temiz>=300", 0.6, "temiz-300;temiz+700", "Rakip çekildi.", "temiz-500", "Savaş pahalıya patladı."],
		["Ortaklık öner", "", 0.55, "temiz+400;saygi+2;y.kulis+3", "İki firma birleşti.", "saygi-1", "Teklif reddedildi."],
		["Kulis yap", "d_siyasi>=10", 0.65, "dok.siyasi+4;y.kulis+4", "Siyasi bir dost edindin.", "temiz-150", "Kulis sonuç vermedi."],
	]},
	"i05": {"b": "Vergi dairesi", "m": "Vergi dairesi bu yıl senden kapsamlı bir beyan bekliyor.", "ev": [2, 4], "w": 5, "cd": 40, "tip": ["Saygın iş adamı"], "k": "servet_un>=30", "tag": "federal", "s": [
		["Dürüst defter", "temiz>=250", 1.0, "temiz-250;fed-5;y.kanun+3", "Beyan temiz; fed rahatladı.", "", ""],
		["Muhasebe oyunu", "zeka>=8", 0.65, "temiz+300;fed+5", "Vergi azaldı.", "fed+18;temiz-400", "Muhasebe oyunu fark edildi."],
		["Rüşvet ver", "kirli>=300", 0.8, "kirli-300;dok.siyasi+4;fed+4", "Rapor sessizce kapandı.", "fed+14;arama+6", "Müfettiş rüşveti raporladı."],
	]},
	"i06": {"b": "Hayır balosu", "m": "Şehirdeki hayır balosunun ev sahipliğini yapmak ister misin?", "ev": [3, 4], "w": 5, "cd": 40, "tip": ["Saygın iş adamı"], "k": "saygi>=30", "tag": "prestij", "s": [
		["Ev sahibi ol", "temiz>=1000", 1.0, "temiz-1000;sevgi+6;saygi+6;nam+1", "Balo şehrin sosyal takviminde yer etti.", "", ""],
		["Davet kabul et", "", 1.0, "saygi+2;y.kulis+2", "Konuk olarak katıldın.", "", ""],
		["Katılma", "", 1.0, "", "Başka işlerin var.", "", ""],
	]},
	"i07": {"b": "Gazete satın alma", "m": "Yerel bir gazete iflasın eşiğinde; yeni sahip arıyor.", "ev": [3, 4], "w": 3, "cd": 90, "tip": ["Saygın iş adamı"], "k": "servet_un>=55", "tag": "medya", "s": [
		["Gazeteyi satın al", "temiz>=2000", 1.0, "temiz-2000;saygi+5;dok.siyasi+8", "Gazete artık senin sesin.", "", ""],
		["Reklam ver", "temiz>=200", 1.0, "temiz-200;saygi+2", "Gazetede adın geçti.", "", ""],
		["Geç", "", 1.0, "", "Başka işler.", "", ""],
	]},
	"i08": {"b": "Kabine görevi", "m": "Vali, seni şehir meclisinde bir göreve çağırdı.", "ev": [4, 4], "w": 3, "cd": 90, "tip": ["Saygın iş adamı"], "k": "d_siyasi>=30", "tag": "siyaset", "s": [
		["Kabul et", "", 1.0, "dok.siyasi+10;saygi+5;sevgi+3", "Meclisin bir parçası oldun.", "", ""],
		["Bağımsız kal", "", 1.0, "saygi+1", "Özgürlüğünü seçtin.", "", ""],
	]},
	"i09": {"b": "Yeni mühendis", "m": "Genç bir mühendis, yeni bir üretim makinesi için ortak arıyor.", "ev": [3, 4], "w": 4, "cd": 40, "tip": ["Saygın iş adamı"], "k": "servet_un>=40", "tag": "iş", "s": [
		["Yatırım yap", "temiz>=800", 0.65, "temiz-800;temiz+3000;saygi+4", "Makine tuttu; kâr kasanı doldurdu.", "temiz-400", "Makine tutmadı."],
		["Çalıştır", "", 1.0, "temiz+200;saygi+1", "Mühendis firmanda çalışmaya başladı.", "", ""],
		["Reddet", "", 1.0, "", "Başka yatırımlar var.", "", ""],
	]},
	"i10": {"b": "Rüşvet teklifi", "m": "Bir belediye memuru, ihaleyi senin lehine çevirmek için pay istiyor.", "ev": [3, 4], "w": 5, "cd": 30, "tip": ["Saygın iş adamı"], "k": "d_siyasi>=15", "tag": "ahlak", "s": [
		["Reddet", "", 1.0, "saygi+4;sevgi+3;y.kanun+3", "İlkelerinden ödün vermedin.", "", ""],
		["Kabul et", "kirli>=300", 0.8, "kirli-300;temiz+1200;y.golge+3;fed+4", "İhale senin oldu.", "fed+12;saygi-5", "Memur seni ele verdi."],
		["Raporla", "", 0.7, "y.kanun+5;saygi+3;dok.siyasi-5", "Memur uzaklaştırıldı; düşman kazandın.", "", "Rapor kaybolup gitti."],
	]},
	# ---------- REZİL / DİP ----------
	"r01": {"b": "Fiyasko soygun", "m": "Dibe vurmuş birkaç serseri, 'kolay iş' vaadiyle seni soyguna çağırdı.", "ev": [0, 2], "w": 8, "cd": 12, "k": "rezil>=5", "tag": "komedi", "s": [
		["Katıl", "", 0.3, "kirli+200;y.golge+3", "Her şey yolunda gitti; inanılmaz.", "rezil+6;arama+8", "Maskeyi ters taktılar; mahalle bunu uzun yıllar konuşacak."],
		["Plana itiraz et", "zeka>=6", 0.6, "saygi+2", "Çocuklar seni dinleyip vazgeçti.", "saygi-2", "Seni dinlemeyip gittiler; sonunda yakalandılar."],
		["Reddet", "", 1.0, "", "Haklı çıktın.", "", ""],
	]},
	"r02": {"b": "Tefeci kapıda", "m": "Tefeci adamı bu kez yalnız değil. Biri kapıyı kıracak gibi duruyor.", "ev": [0, 2], "w": 8, "cd": 10, "k": "tef>=100", "tag": "borç", "s": [
		["Faizi öde", "kirli>=50", 1.0, "kirli-50;stres+2", "Adamlar ayrıldı.", "", ""],
		["Kaç", "", 0.4, "stres+3", "Kapıdan gizlice çıktın.", "yara+20;rezil+4", "Yakalandın; dayak yedin."],
		["Daha çok borç al", "", 1.0, "tef+300;stres+5", "Çözüm yerine yük ekledin.", "", ""],
	]},
	"r03": {"b": "Eski dostun alayı", "m": "Eski bir arkadaşın seni sokakta durdurdu: «Vay, kimleri görüyorum. Hâlâ aynı yerde misin?»", "ev": [0, 3], "w": 5, "cd": 18, "k": "saygi<10;rezil>=5", "tag": "utanç", "s": [
		["Kavga et", "", 0.5, "saygi+2;y.korku+2", "Yumruk yedi; sen de saygı kazandın.", "yara+15;rezil+3", "Kavgayı kaybettin; rezil oldun."],
		["Gülüp geç", "karizma>=5", 0.6, "saygi+1", "Esprili bir cevap verdin.", "saygi-2", "Cevabın soğuk kaldı."],
		["Yardım iste", "", 0.4, "temiz+50;saygi-1", "Biraz yardım etti.", "saygi-3", "Arkasını dönüp gitti."],
	]},
	"r04": {"b": "Çıkış fırsatı", "m": "Tanıdık bir esnaf, sana küçük bir iş vermek istiyor. İşi yaparsan yeniden ayağa kalkabilirsin.", "ev": [0, 2], "w": 4, "cd": 30, "k": "servet_un<20", "tag": "umut", "s": [
		["Yeni bir başlangıç yap", "", 0.7, "temiz+80;y.kanun+4;sevgi+3;rezil-4", "Çalışkanlığın fark edildi.", "stres+3", "İş yürümedi."],
		["Eski yola dön", "", 0.4, "kirli+120;y.golge+2", "Eski yöntemler çalıştı.", "arama+8;rezil+3", "Eski yöntemler yine ters gitti."],
		["Reddet", "", 1.0, "", "Gururunu seçtin.", "", ""],
	]},
	"r05": {"b": "Hapis arkadaşı", "m": "Eski bir hapishane arkadaşı seni arıyor. Elinde bir iş var.", "ev": [0, 3], "w": 4, "cd": 25, "k": "hapis>=1", "tag": "suç", "s": [
		["Dinle", "", 0.6, "kirli+150;y.golge+3", "Bilgi paha biçilmezdi.", "arama+8", "Adam seni polise ele verdi."],
		["Kavga et", "", 0.5, "y.korku+3", "Adam seni bir daha aramaz.", "yara+15", "Kavgada sen yaralandın."],
		["Aldırma", "", 1.0, "", "Eski defteri kapadın.", "", ""],
	]},
	"r06": {"b": "Mahalle el uzatıyor", "m": "Mahalleliler, durumunu bilip sana yemek ve iş önerdi.", "ev": [0, 3], "w": 4, "cd": 25, "k": "sevgi>=5;saygi<15", "tag": "umut", "s": [
		["Kabul et", "", 1.0, "sevgi+4;stres-3;rezil-3", "Mahalle seni yeniden kabul etti.", "", ""],
		["Gururunu koru", "", 1.0, "saygi-1", "Reddettin; yalnızlık sürüyor.", "", ""],
	]},
	"r07": {"b": "Açlık", "m": "Birkaç gündür sıcak bir şey yemedin; mide kazınıyor.", "ev": [0, 2], "w": 6, "cd": 12, "k": "para<20", "tag": "yaşam", "s": [
		["Dilen", "", 1.0, "temiz+10;saygi-3;stres+2", "Birkaç kuruş topladın.", "", ""],
		["Aş evine git", "", 1.0, "stres-3;sevgi+1", "Sıcak bir çorba içtin.", "", ""],
		["Çal", "", 0.5, "kirli+30;y.golge+1", "Bir somun ekmek.", "arama+6;rezil+3", "Yakalandın; dayak yedin."],
	]},
	"r08": {"b": "Son şans", "m": "Tefecinin sabrı tükenmek üzere; kapıda bir not var: «Bu hafta son.»", "ev": [0, 3], "w": 5, "cd": 20, "k": "tef>=500", "tag": "borç", "s": [
		["Elindekileri sat", "", 1.0, "tef-300;temiz-50;saygi-3", "Borcun bir kısmını kapattın.", "", ""],
		["Kaçmayı dene", "", 0.35, "stres-3", "Şehirden sıvıştın; ama borç peşinde.", "yara+30;rezil+6", "Yakalandın; ağır dayak yedin."],
		["Tefeciyle yüzleş", "karizma>=6", 0.5, "tef-250", "Borcun bir kısmını affettirdin.", "yara+20", "Tefeci sinirlendi."],
	]},
	"r09": {"b": "Sokakta aşağılanma", "m": "Mahallede bir grup çocuk arkandan yürüyüp seninle alay ediyor.", "ev": [0, 2], "w": 5, "cd": 15, "k": "rezil>=10", "tag": "utanç", "s": [
		["Görmezden gel", "", 1.0, "stres+2", "Yürümeye devam ettin.", "", ""],
		["Kovala", "", 0.5, "saygi+1", "Çocuklar dağıldı.", "saygi-2;stres+3", "Çocuklar daha çok alay etti."],
		["Onlarla konuş", "karizma>=5", 0.65, "sevgi+3;saygi+1", "Çocuklar sustu; biri senden özür diledi.", "saygi-1", "Konuşman anlaşılmadı."],
	]},
}
