extends RefCounted
# Olay verisi B: Kaptan (Evre 2) ve Underboss (Evre 3).

const OLAY := {
	"k02": {"b": "Mahalle toplantısı", "m": "{B} halkı bir toplantı çağırdı: yol bozuk, fener yanmıyor, çöp toplanmıyor. Gözler sende.", "ev": [2, 3], "w": 7, "cd": 14, "k": "bolge>=1", "tag": "topluluk", "s": [
		["Dinle ve çöz", "temiz>=100", 1.0, "temiz-100;sevgi+6;saygi+2;inf+3", "Fener yandı, yol yamandı. Mahalle seni baş tacı etti.", "", ""],
		["Kendi kararını ver", "", 1.0, "y.korku+3;sevgi-2;saygi+1", "Toplantıyı kesip kararı sen verdin; kimse itiraz edemedi.", "", ""],
		["Papazla birlikte karar ver", "karizma>=5", 0.7, "sevgi+4;saygi+3", "Cemaat seni dinledi.", "saygi-1", "Papaz ve esnaf birbirine girdi."],
	]},
	"k03": {"b": "Adamlar kıskanç", "m": "Ekipten biri, kendisi yerine başkasının terfi ettirildiğini düşünüyor. Gözler birbirine dönmüş.", "ev": [2, 3], "w": 6, "cd": 14, "k": "adam>=4", "tag": "sadakat", "s": [
		["Terfi ver", "temiz>=80", 1.0, "temiz-80;sad+8", "Terfi sadakati güçlendirdi.", "", ""],
		["Payı böl", "kirli>=60", 1.0, "kirli-60;sad+4", "Herkes biraz memnun.", "", ""],
		["Cezalandır", "", 0.6, "y.korku+4;sad-4", "Ceza ders oldu.", "sad-10", "Ceza ters tepti; adamlar mırıldanıyor."],
	]},
	"k04": {"b": "Rakip aile devriyesi", "m": "{F}'ın adamları mahallenin sınırında devriye geziyor ve seni gözlüyor.", "ev": [2, 3], "w": 8, "cd": 12, "f": "rakip", "k": "bolge>=1", "tag": "kriz", "s": [
		["Uyar", "", 0.6, "ger-2;saygi+2", "Devriye geri çekildi.", "ger+3", "Karşı taraf alay etti; gerginlik arttı."],
		["Çatış", "adam>=2", 0.5, "ger+4;y.korku+6;saygi+3", "Adamların onları sokaktan kovdu.", "ger+6;yara+15;adam-1", "Çatışmada adam kaybettin."],
		["Müzakere", "karizma>=5", 0.55, "ger-4;y.kulis+4", "Anlaştınız.", "saygi-2", "Müzakere sonuçsuz."],
	]},
	"k05": {"b": "Esnaf birliği", "m": "Esnaflar bir birlik kurmak istiyor ve başkanlığı sana öneriyor. Bu bir saygı işareti; ama sorumluluk da getirir.", "ev": [2, 3], "w": 5, "cd": 30, "k": "isl>=2;sevgi>=15", "tag": "topluluk", "s": [
		["Başkan ol", "", 1.0, "sevgi+5;saygi+4;temiz-50;y.kanun+3", "Birliğin başına geçtin; esnaf arkanda.", "", ""],
		["Birliği dağıt", "", 1.0, "y.korku+4;sevgi-4", "Birlik kurulamadı; esnaf küstü.", "", ""],
		["Bir pay al", "", 0.6, "kirli+120;sevgi-2", "Birlikten komisyon aldın.", "saygi-3", "Esnaf bunu fark edip homurdandı."],
	]},
	"k06": {"b": "Kaçak sevkiyat", "m": "Rıhtımdan yeni bir kaçak sevkiyat geliyor. Taşımak isteyen çok, yeri sen belirliyorsun.", "ev": [2, 3], "w": 7, "cd": 12, "yol": "golge", "k": "y_golge>=5", "tag": "iş", "s": [
		["Kendin taşı", "adam>=1", 0.6, "kirli+280;y.golge+3", "Mal mahalleye sorunsuz girdi.", "arama+9;adam-1", "Devriyeye yakalandı; bir adamın gözaltında."],
		["Rakibe sat", "", 1.0, "kirli+150;y.kulis+2", "Sevkiyatın yerini sattın.", "", ""],
		["Polise bildir", "", 0.7, "arama-8;dok.polis+6;y.kanun+3", "Polis seni takdir etti.", "sevgi-2", "Rakip bunu öğrendi."],
	]},
	"k07": {"b": "Kasap kızı", "m": "Mahalleli kasabın kızı, tanışmak ister. Ailesi seni olumlu görüyor.", "ev": [2, 3], "w": 4, "cd": 40, "k": "!evli;yas>=20", "tag": "aile", "s": [
		["Tanış", "", 1.0, "es_aday+1;sevgi+2", "Tanışma iyi geçti. Ailem panelinde adaylar belirdi.", "", ""],
		["Başka zaman", "", 1.0, "", "Erteledin.", "", ""],
	]},
	"k08": {"b": "Yangın", "m": "{B}'da gecenin bir yarısı yangın çıktı; alevler dükkânların üstünden atlıyor.", "ev": [2, 4], "w": 4, "cd": 30, "k": "isl>=1", "tag": "kriz", "s": [
		["Adamlarla söndür", "adam>=1", 0.75, "sevgi+6;saygi+3;temiz-40", "Yangını erken yakaladınız; kimse ölmedi.", "temiz-150;yara+10", "Yangın büyüdü; kayıp ağır."],
		["Sorumluyu araştır", "zeka>=6", 0.55, "y.golge+3;sonra:z03:20", "Bir iz buldun; kıvılcım bir rakipten gelmiş olabilir.", "stres+3", "İz bulamadın."],
		["Sigortadan al", "", 0.5, "temiz+200", "Sigorta ödedi.", "stres+3", "Sigorta reddetti."],
	]},
	"k09": {"b": "Papaz ziyareti", "m": "Mahalle papazı kapına geldi: «Evladım, kilisenin çatısı çöküyor. Cemaat sana ümit bağlıyor.»", "ev": [2, 4], "w": 4, "cd": 30, "k": "bolge>=1", "tag": "inanç", "s": [
		["Bağış yap", "temiz>=100", 1.0, "temiz-100;saygi+4;sevgi+3", "Çatı tamir edilecek; cemaat dualar ediyor.", "", ""],
		["Reddet", "", 1.0, "saygi-1", "Papaz mahzun ayrıldı.", "", ""],
		["İtirafa gir", "", 0.6, "stres-8;dok.siyasi+2", "Yüreğini hafifletti; papaz bir sır tutacak.", "stres-3", "Papaz seni dinledi."],
	]},
	"k10": {"b": "Esnaf kızı kaçtı", "m": "Bir esnafın genç kızı evden kaçmış. Aile çaresiz.", "ev": [2, 3], "w": 3, "cd": 40, "k": "sevgi>=10", "tag": "topluluk", "s": [
		["Ara ve bul", "adam>=1", 0.7, "sevgi+5;saygi+3", "Kızı bulup ailesine teslim ettin.", "stres+2", "Bulamadın; aile kırgın."],
		["Umursama", "", 1.0, "", "Başka işlerin var.", "", ""],
		["Kaçıranı bul", "", 0.5, "y.korku+4;saygi+2", "Adamı buldun; kıza dokunamayacak.", "yara+15", "Adam seni yaraladı."],
	]},
	"k11": {"b": "Yeni göçmenler", "m": "Limana yeni bir göçmen gemisi yanaştı. Yüzlerce aç insan çalışacak yer arıyor.", "ev": [2, 3], "w": 5, "cd": 25, "k": "bolge>=1", "tag": "topluluk", "s": [
		["Yardım et", "temiz>=80", 1.0, "temiz-80;sevgi+5;saygi+2;adam+1", "İçlerinden biri sana bağlanıp ekibine katıldı.", "", ""],
		["Ucuz işçi çalıştır", "", 1.0, "kirli+120;sevgi-3", "Ucuz iş gücü; vicdan ağır.", "", ""],
		["Tanıdık aileye yönlendir", "", 1.0, "y.kulis+3;sevgi+2", "Bağlantı kurdun.", "", ""],
	]},
	"k12": {"b": "Tezgâh hırsızları", "m": "Pazarda bir grup çocuk meyve çalarken yakalandı. Esnaf çocukları sana getirdi.", "ev": [2, 3], "w": 6, "cd": 12, "tag": "topluluk", "s": [
		["Dövüp teslim et", "", 1.0, "y.korku+3;sevgi-2;dok.polis+3", "Çocuklar bir daha gelmez.", "", ""],
		["Affet", "", 1.0, "sevgi+4;saygi+1", "Çocuklar şaşkın; esnaf bile gülümsedi.", "", ""],
		["Adam yap", "", 0.6, "adam+1;sad+3", "İçlerinden biri sadık bir adam oldu.", "stres+2", "Çocuklar bir daha görünmedi."],
	]},
	"k13": {"b": "Bakkaldan bir iyilik", "m": "Mahalle bakkalı sana veresiye defterini gösterdi: borçlular çok, kimse ödemiyor. «Sen halledersin.»", "ev": [2, 3], "w": 5, "cd": 20, "k": "bolge>=1", "tag": "iş", "s": [
		["Borçluları topla", "adam>=1", 0.65, "kirli+160;y.korku+3;sevgi-2", "Borçlular ödedi.", "arama+5;sevgi-3", "Biri polise gitti."],
		["Yarısını sen öde", "temiz>=80", 1.0, "temiz-80;sevgi+5;saygi+2", "Bakkal sana minnettar.", "", ""],
		["Karışma", "", 1.0, "", "Bakkal bir daha sormadı.", "", ""],
	]},
	"k14": {"b": "Ev sahibi tehditte", "m": "Bir ev sahibi, kiracılarını sokağa atmak istiyor. Mahalleli sana geldi.", "ev": [2, 3], "w": 5, "cd": 18, "k": "bolge>=1", "tag": "topluluk", "s": [
		["Ev sahibiyle konuş", "karizma>=5", 0.65, "sevgi+5;y.kulis+2", "Ev sahibi geri adım attı.", "saygi-2", "Ev sahibi bildiğini okudu."],
		["Adamları gönder", "adam>=2", 0.7, "y.korku+4;sevgi+3;saygi+2", "Ev sahibi kiracıları bıraktı.", "arama+7", "Polis karıştı."],
		["Kiraları sen öde", "temiz>=200", 1.0, "temiz-200;sevgi+7;saygi+3", "Mahalle seni unutmayacak.", "", ""],
	]},
	"u03": {"b": "Karakol şefi randevu", "m": "Bir polis şefi seni akşam yemeğine çağırdı: «Birbirimizi tanımamız her ikimiz için de iyi olur.»", "ev": [3, 4], "w": 5, "cd": 25, "k": "arama>=30", "tag": "nüfuz", "s": [
		["Maaşa bağla", "kirli>=150", 1.0, "kirli-150;dok.polis+15;arama-10", "Şef artık ay başı zarfını bekliyor.", "", ""],
		["Reddet", "", 1.0, "arama+5;saygi+1", "Şef gülümseyerek tabağını itti.", "", ""],
		["Kozunu cebine koy", "zeka>=7", 0.5, "dok.polis+25", "Şefin gizli bir hatasını öğrendin; artık sen yönetiyorsun.", "arama+10;dok.polis-5", "Şef anladı; ilişkiniz bozuldu."],
	]},
	"u04": {"b": "Yeni mahalle fırsatı", "m": "{B} komşu mahalle, elinde tutan zayıflamış. Fırsat beklemez.", "ev": [3, 4], "w": 6, "cd": 20, "f": "zayif", "tag": "genişleme", "s": [
		["Haraçla", "adam>=3", 0.55, "inf+25;y.korku+5;ger+4", "Mahalle boyun eğdi.", "ger+6;adam-1", "Direniş vardı; bir adam gözaltına alındı."],
		["Satın al", "temiz>=800", 1.0, "temiz-800;inf+30;sevgi+3", "Sahibi seni memnuniyetle bıraktı.", "", ""],
		["Ortak yönetim öner", "karizma>=6", 0.6, "inf+15;ger-3;y.kulis+4", "Kardeşçe bir anlaşma yaptınız.", "saygi-2", "Teklif reddedildi."],
	]},
	"u05": {"b": "Kâhya isyanı", "m": "Ekibindeki bir kıdemli, sana bir gün yemekte açıkça söyledi: «Daha çok hak ediyorum.»", "ev": [3, 4], "w": 5, "cd": 16, "k": "adam>=6;sad<50", "tag": "sadakat", "s": [
		["Para ver", "kirli>=200", 1.0, "kirli-200;sad+10", "Kıdemli yatıştı.", "", ""],
		["Sert çık", "", 0.55, "y.korku+4;sad+3", "Gözlerini indirdi.", "sad-15;adam-1", "Kıdemli arkasını dönüp ayrıldı."],
		["Yeni biri bul", "para>=150", 1.0, "kirli-150;adam+1", "Yeni biri çalışıyor; kıdemli bunu gördü.", "", ""],
	]},
	"u06": {"b": "Mahkemelik arkadaş", "m": "Adamlarından biri bir dava yüzünden tutuklandı. Ailesi kapında.", "ev": [3, 4], "w": 5, "cd": 18, "k": "adam>=3", "tag": "yargı", "s": [
		["Avukat tut", "temiz>=300", 1.0, "temiz-300;sad+8;dok.yargic+5", "Adam serbest kaldı; sana minnettar.", "", ""],
		["Yargıçla konuş", "d_yargic>=15", 0.7, "sad+6;dok.yargic-5", "Yargıç bir kapı araladı.", "sad-3", "Yargıç ret etti."],
		["Kendi başına bırak", "", 1.0, "sad-8", "Adamlar bunu not etti.", "", ""],
	]},
	"u07": {"b": "Gazete manşeti", "m": "Bir gazete senin hakkında uzun bir haber hazırlıyor.", "ev": [3, 4], "w": 6, "cd": 20, "k": "saygi>=20", "tag": "medya", "s": [
		["Gazeteciyle işbirliği", "", 0.7, "saygi+5;sevgi+3", "Haber seni hayırsever gösteriyor.", "saygi-3;arama+4", "Haber seni çirkin anlatıyor."],
		["Yalanla", "", 0.5, "y.korku+3", "Gazeteciyi susturdun.", "arama+6;saygi-2", "Haber çıktı, yalanlaman gülünç kaldı."],
		["Manşeti sat", "", 1.0, "kirli+180;saygi-2", "Manşeti bir rakibe sattın.", "", ""],
	]},
	"u08": {"b": "Dernek kuruluşu", "m": "Mahalle büyükleri, bir yardım derneği kurmayı öneriyor.", "ev": [3, 4], "w": 5, "cd": 30, "k": "sevgi>=30", "tag": "topluluk", "s": [
		["Dernek kur", "temiz>=300", 1.0, "temiz-300;sevgi+8;saygi+4;nam+1", "Dernek binası açıldı; isim anılmaya başladı.", "", ""],
		["Rakibin derneğine katıl", "", 1.0, "y.kulis+4;saygi+1", "Aralarına katıldın; bir koltuk kaptın.", "", ""],
		["Reddet", "", 1.0, "", "İlgilenmedin.", "", ""],
	]},
	"u09": {"b": "Vergi müfettişi", "m": "Maliyeden bir müfettiş, defterlerine bakmak istiyor. Gözleri kasa dolabında.", "ev": [3, 4], "w": 6, "cd": 20, "k": "servet_un>=30", "tag": "federal", "s": [
		["Defterleri aç", "temiz>=200", 0.75, "temiz-200;arama-5;y.kanun+4", "Defterler temizdi; müfettiş ayrıldı.", "fed+10;temiz-300", "Eksik bulundu; ceza yedin."],
		["Rüşvet ver", "kirli>=400", 0.7, "kirli-400;dok.siyasi+6;fed+5", "Müfettiş zarfı alıp gitti.", "fed+20;arama+8", "Müfettiş zarfı alıp yine de rapor yazdı."],
		["Müfettişi uzaklaştır", "", 0.4, "fed+4", "Müfettiş bir daha uğramadı.", "fed+25;arama+10", "Müfettiş savcıya gitti."],
	]},
	"u10": {"b": "Şehre yeni aile", "m": "Doğu Avrupa'dan bir çete şehre geldi ve {B} yakınlarında yer arıyor.", "ev": [3, 4], "w": 3, "cd": 60, "tek": true, "f": "rakip", "tag": "dünya", "s": [
		["Karşıla ve konuş", "karizma>=5", 0.6, "y.kulis+4;ger-2", "Çeteyle iyi geçindiniz.", "ger+4", "Bir şeyler ters gitti."],
		["Uzak dur", "", 1.0, "", "Sokaklar yeni yüzler gördü.", "", ""],
		["Ortaklık kur", "", 0.5, "kirli+150", "Ortak bir iş açtınız.", "stres+3;arama+5", "Ortak çalışmada anlaşmazlık çıktı."],
	]},
	"u11": {"b": "Okul binası", "m": "Mahalle okulunun binası çökmek üzere. Müdür yardım diliyor.", "ev": [3, 4], "w": 4, "cd": 40, "k": "servet_un>=25", "tag": "topluluk", "s": [
		["Okulu tamir ettir", "temiz>=400", 1.0, "temiz-400;sevgi+8;saygi+4", "Okul yeniden doğdu; çocuklar adını sayıyor.", "", ""],
		["Okulu yıktırıp arsayı al", "", 0.5, "kirli+500;sevgi-8", "Arsa senin; mahalle öfkeli.", "sevgi-10;arama+6", "Mahalle direndi; olay büyüdü."],
		["Karışma", "", 1.0, "", "Müdür boynunu büktü.", "", ""],
	]},
	"u12": {"b": "Meyhane kavgası büyüdü", "m": "Meyhanede biri bıçaklandı; kavga dışarı taşıyor.", "ev": [3, 4], "k": "meyhane", "w": 6, "cd": 12, "tag": "kriz", "s": [
		["Araya gir", "", 0.65, "saygi+4;sevgi+2", "Kavgayı bitirdin.", "yara+15;saygi-1", "Aralarında kaldın; yara aldın."],
		["Kenarda bekle", "", 1.0, "", "Kimsenin yüzüne bakmadın.", "", ""],
		["Kışkırt", "", 0.5, "y.korku+3;ger+3", "Rakibin adamları zayıfladı.", "arama+6;sevgi-3", "Olay senin üstüne kaldı."],
	]},
}
