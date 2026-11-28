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
	# ---------- PİZZİNİ (küçük kâğıt notlar: telefon dinlemesinden kaçmanın eski yolu) ----------
	"p01": {"b": "Katlanmış kâğıt", "m": "Barda biri avucuna minik, sıkı katlanmış bir kâğıt bıraktı ve kayboldu. İçinde rakamlar ve kısa satırlar var: pizzini. Sicilya'da yaşlı donların emirlerini telefon yerine bu kâğıt parçalarıyla ilettiği söylenir; okunur, yakılır.", "ev": [0, 2], "w": 5, "cd": 60, "tag": "gizem", "s": [
		["Şifreyi çöz", "zeka>=6", 0.7, "y.golge+3;saygi+2;sonra:z10:20", "Rakamlar harflere döndü: bir mesajı çözdün. Gönderen seni tanıyor.", "stres+2", "Anlamsız bir rakam yığını; gece kaldın."],
		["Okuyup yak", "", 1.0, "y.golge+2", "Kâğıt kül oldu; kimse bilmeyecek.", "", ""],
		["Polise götür", "", 1.0, "dok.polis+3;saygi-2;sevgi-2", "Karakolda teşekkür ettiler. Mahallede ise 'ispiyoncu' denmeye başlandı.", "", ""],
	]},
	"p02": {"b": "Pizzini kuryesi", "m": "Telefon hatlarının dinlendiği söyleniyor. Ekibin birbirine emirleri kâğıt notlarla yollamasını önerdi biri: küçük kâğıt, güvenilir bir kurye, okuyan yakar.", "ev": [2, 4], "w": 5, "cd": 40, "k": "adam>=2", "tag": "polis", "s": [
		["Haberleşmeyi pizziniye kaydır", "", 0.75, "arama-6;sad+2;y.golge+3", "Hat sessiz, notlar elden ele gidiyor. Polis boşuna dinliyor.", "arama+8;adam-1", "Kuryen yakalandı; cebinde not bulundu."],
		["Telefonla devam et", "", 1.0, "arama+3", "Hat dinleniyor olabilir. İhtiyatlı olmak gerek.", "", ""],
		["Çocuk kurye tut", "kirli>=60", 0.85, "kirli-60;y.golge+2;arama-3", "Mahalle çocuğu notları taşıyor; kimse çocuktan şüphelenmiyor.", "kirli-60;arama+4", "Çocuk korkup notları attı."],
	]},
	"p03": {"b": "Üstünde bulunan not", "m": "Polis, adamlarından birini üstünü arayarak durdurdu ve cebinden katlanmış bir kâğıt çıkardı. Üzerindeki rakamların ne anlama geldiğini soruyorlar.", "ev": [2, 4], "w": 5, "cd": 40, "k": "arama>=25;adam>=2", "tag": "polis", "s": [
		["Şifresi çözülemez, diye diren", "zeka>=7", 0.6, "arama-4;saygi+2", "Rakamları çözemediler; kâğıt delil sayılmadı.", "arama+10;stres+2", "Şifreyi çözdüler; ifadeler uyuşmadı."],
		["Avukat tut", "temiz>=300", 1.0, "temiz-300;arama-5", "Avukat kâğıdın delil olmadığını kanıtladı.", "", ""],
		["Rüşvetle kapat", "kirli>=400", 1.0, "kirli-400;dok.polis+3", "Kâğıt bir ocakta yandı. Dosya kapandı.", "", ""],
	]},
	"p04": {"b": "Tek satırlık not", "m": "{F}'dan bir adam elime kâğıt tutuşturup uzaklaştı: «Salı, rıhtım, yalnız gel.» Başka açıklama yok.", "ev": [2, 4], "w": 5, "cd": 40, "f": "rakip", "tag": "dünya", "s": [
		["Yalnız git", "", 0.55, "ger-5;inf+6;y.kulis+3", "Görüşme iyi geçti; ikiniz de sınırı biliyorsunuz artık.", "yara+25;ger+4", "Tuzakmış; pusuya düştün."],
		["Adamlarınla git", "adam>=2", 0.8, "ger-3;saygi+2", "Gelişin ciddiye alındı; konuşma temkinli ama olumlu bitti.", "adam-1;ger+3", "Anlaşma çıkmadı; bir adamın yaralı."],
		["Yok say", "", 1.0, "ger+2", "Mesaj ulaştı: çağrıya gelmedin.", "", ""],
	]},
	# ---------- DEDENİN MİRASI ----------
	"m01": {"b": "Dedenin evi", "m": "Mahalleli, dedenin eski evinin önünden geçerken yavaşlıyor, fısıldaşıyor. Bir yaşlı kapıda durup sana uzun uzun baktı: «Sen onun torunusun.»", "ev": [0, 4], "w": 6, "cd": 9999, "k": "tanin>=5", "tag": "miras", "s": [
		["Yaşlıyla konuş", "", 0.7, "mir.tanin+6;saygi+1", "Dedenin sandığın gibi bir kasabın değil, şehrin yarısına söz geçiren biri olduğunu öğrendin.", "stres+2", "Yaşlı ağzını açmadı, ama bakışları her şeyi söyledi."],
		["Görmezden gel", "", 1.0, "mir.tanin+2", "Evine girdin. Ama ev artık eskisi gibi sessiz değil.", "", ""],
	]},
	"m02": {"b": "Gece gelen zarf", "m": "Kapının altından bir zarf atılmış: «Dedenin adamlarından biri hâlâ sizi hatırlıyor. Rıhtımda biri sizi soruyor.» Altında imza yok.", "ev": [1, 4], "w": 6, "cd": 9999, "k": "tanin>=12", "tag": "miras", "s": [
		["Rıhtıma git", "", 0.6, "mir.tanin+6;y.kulis+3;saygi+2", "Eski Muhafızlardan biri seni bekliyordu; dedenin işlerinin nasıl dağıldığını anlattı.", "yara+15;stres+3", "Rıhtımda seni tartan gözler vardı; ürkütücüydü."],
		["Polise göster", "", 0.5, "mir.tanin+1;dok.polis+2", "Zarf bir dosyaya girdi; kimse seni aramadı.", "arama+5", "Kimse ciddiye almadı."],
		["Yak", "", 1.0, "", "Zarf küle döndü; sır senin kaldı.", "", ""],
	]},
	"m03": {"b": "Dedenin eski adamı", "m": "Yaşlı bir adam yolunu kesti: «Ben Tonio. Dedeni ölene kadar korudum. Bugün gençler ayrıldı, herkes kendi payını aldı. Ama sen... sende onun gözleri var.»", "ev": [1, 4], "w": 6, "cd": 9999, "k": "tanin>=25", "tag": "miras", "s": [
		["Onu yanına al", "", 0.8, "adam+1;mir.tanin+5;sad+3", "Amca Tonio sana sadık bir silah arkadaşı oldu.", "mir.tanin+1", "Kabul etmedi; «henüz zamanı değil.»"],
		["Dedenin anılarını sor", "", 1.0, "mir.tanin+3;y.kulis+3", "Kimin kime ne kadar borçlu olduğunu öğrendin.", "", ""],
		["Geç git", "", 1.0, "mir.tanin-1", "Tonio başını eğdi, sessizce uzaklaştı.", "", ""],
	]},
	"m04": {"b": "Kırıntıların dedikodusu", "m": "Kasabadan aldığın duyum net: «Rıhtımdakiler senden çekiniyor; Ferro ise 'torunu yakında gelir' diye silah biliyor.»", "ev": [1, 4], "w": 6, "cd": 9999, "k": "tanin>=40", "tag": "miras", "s": [
		["Dedikodunun peşine düş", "", 0.65, "mir.tanin+6;y.kulis+4", "Kimin kimden korktuğunu, kimin kime sadık olduğunu öğrendin.", "stres+3;ger+2", "Seni gören oldu; ortalık karıştı."],
		["Ekibi topla", "adam>=2", 1.0, "sad+4;mir.tanin+3", "Adamların sana güveni arttı; birlik ruhu doğdu.", "", ""],
		["Aldırma", "", 1.0, "mir.tanin+1", "Söylentiler söylenti olarak kaldı.", "", ""],
	]},
	"m05": {"b": "Artık kimse değilsin", "m": "Bir akşam üzeri, hiçbir şey söylemeden birkaç eski usta kapına geliyor: şapkaları elde, gözler yerde. «Dedene gösterdiğimiz saygıyı sana da göstermek istiyoruz.» Şehir seni artık tanıyor.", "ev": [1, 4], "w": 6, "cd": 9999, "k": "tanin>=60", "tag": "miras", "s": [
		["Sözlerini kabul et", "", 1.0, "saygi+4;y.korku+2;mir.tanin+4", "Mirasın yükü artık gerçek: herkes senin kararını bekliyor.", "", ""],
		["Mesafeni koru", "", 1.0, "mir.tanin+2;sad+2", "Hâlâ dikkatli; ama ses çıkarmayan herkes seni izliyor.", "", ""],
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
	"z10": {"b": "Notun sahibi", "m": "Çözdüğün pizzininin sahibi seni buldu: yaşlı, sessiz biri. «Sen okumayı bilen birisin. Böylelerine ihtiyacımız var.» Ellerini cebinde tutuyor.", "ev": [0, 4], "w": 1, "cd": 9999, "k": "yil>=9999", "tag": "zincir", "s": [
		["Ortak ol", "", 1.0, "adam+1;y.golge+4;kirli+300;saygi+2", "Küçük kâğıtlarla çalışan sessiz bir ağın parçası oldun.", "", ""],
		["Not yazan elden pay iste", "zeka>=6", 0.55, "kirli+600;y.korku+2", "Susmanın bedelini ödedi.", "arama+8;stres+3", "Adamı ürküttün; polise gitti."],
		["Reddet", "", 1.0, "saygi+1", "Başını salladı ve kalabalığa karıştı.", "", ""],
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
