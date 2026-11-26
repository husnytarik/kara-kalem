extends RefCounted
# Harbor Herald: günlük ve haftalık (pazartesi) gazete + meydan etkinlikleri + tarihî olaylar + emlak fiyatları.
# Durum oyun.gaz içindedir (kayıtla birlikte saklanır). Haberler havuza düşer, sayılar sabah basılır;
# iş ilanları yalnızca gazete okunduğunda güncellenir.

const MeydanS := preload("res://scripts/core/meydan.gd")

var oyun: Node
var rng := RandomNumberGenerator.new()

const GUN_AD := ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]
const AY_AD := ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
# tür -> etiket
const TUR := {
	"mafya": "YERALTI", "polis": "ASAYİŞ", "catisma": "SİLAHLI ÇATIŞMA", "ekonomi": "EKONOMİ", "emlak": "EMLAK",
	"saglik": "SAĞLIK", "meydan": "MEYDAN", "tarih": "DÜNYADAN", "mahalle": "MAHALLE", "magazin": "MAGAZİN",
}
const ETK_AD := {
	"idam": "Halka açık idam", "isyan": "Devlet karşıtı gösteri", "polis": "Polis gösterisi",
	"kutlama": "Kutlama", "miting": "Miting", "toren": "Resmî tören",
}
const SERI_AD := {
	"kuru": "Kuru Dönem: yasak ve tezgâh altı", "sacco": "Sacco ve Vanzetti davası", "capone": "Şikago'nun patronu: Al Capone",
	"kriz": "Büyük Bunalım yaklaşıyor", "kast": "Castellammare Savaşı", "savas": "Şehirde aileler arası savaş",
	"salgin": "Salgın", "huzursuz": "Meydanda huzursuzluk", "idam": "Darağacı ve çete reisleri", "seçim": "Seçim sezonu",
	"leopold": "Leopold ve Loeb davası", "scopes": "Scopes 'maymun' davası", "kuru_son": "Kuru dönemin sonu",
}

# [yıl, ay, gün, başlık, metin, önem, meydan türü, etki, seri]
const TARIH := [
	[1920, 1, 17, "KURU DÖNEM BAŞLADI", "Anayasanın on sekizinci maddesi yürürlüğe girdi: içki yapmak, satmak ve taşımak artık suç. Barlar kepenk indirirken tezgâh altında bambaşka bir ticaret filizleniyor.", 3, "miting", {"huzur": -2}, "kuru"],
	[1920, 8, 26, "KADINLARA OY HAKKI", "On dokuzuncu madde onaylandı: Kadınlar ilk kez sandığa gidecek. Meydanlarda coşkulu kutlamalar var.", 2, "kutlama", {"huzur": 2}, ""],
	[1920, 9, 16, "WALL STREET'TE BOMBALI SALDIRI", "Borsanın önünde at arabasıyla patlatılan bomba onlarca can aldı. Failler henüz bulunamadı.", 3, "toren", {"huzur": -2}, ""],
	[1920, 11, 2, "HARDING SEÇİLDİ, ÇAĞRI RADYODA", "Warren Harding başkan seçildi; sonuçlar ilk kez radyodan duyuruldu. 'Normale dönüş' vaadi şehirde destek buldu.", 2, "miting", {}, "seçim"],
	[1921, 7, 14, "SACCO VE VANZETTI SUÇLU BULUNDU", "İki İtalyan göçmen anarşist, bir soygun cinayetinden mahkûm edildi. Kanıtların zayıflığı konuşuluyor.", 2, "", {}, "sacco"],
	[1921, 11, 11, "MEÇHUL ASKER ANITI AÇILDI", "Büyük Savaş'ta ölen adı bilinmeyen askere devlet töreni düzenlendi.", 2, "toren", {}, ""],
	[1922, 5, 30, "LINCOLN ANITI AÇILDI", "Washington'daki Lincoln Anıtı törenle halka açıldı.", 1, "", {}, ""],
	[1922, 7, 1, "DEMİRYOLU İŞÇİLERİ GREVDE", "Yüz binlerce demiryolu işçisi ücret kesintilerine karşı iş bıraktı; kömür ve gıda sevkiyatı aksıyor.", 2, "miting", {"fk": -0.02}, ""],
	[1922, 10, 28, "ROMA'DA FAŞİSTLER İKTİDARDA", "Mussolini'nin kara gömlekleri Roma'ya yürüdü; kral hükümeti ona devretti. Şehrin İtalyan mahallelerinde endişe var.", 2, "", {}, ""],
	[1922, 11, 26, "FİRAVUN MEZARI AÇILDI", "Mısır'da Tutankhamon'un mezarı bulundu; altın dolu odalar gazetelerin baş sayfasında.", 1, "", {}, ""],
	[1923, 3, 3, "TIME DERGİSİ ÇIKTI", "Haftalık haber dergisi Time ilk sayısını yayımladı.", 1, "", {}, ""],
	[1923, 8, 2, "BAŞKAN HARDING ÖLDÜ", "Başkan Harding seyahatte hayatını kaybetti. Yerine Calvin Coolidge geçti. Şehirde yas ilan edildi.", 3, "toren", {}, ""],
	[1923, 9, 1, "TOKYO'DA BÜYÜK DEPREM", "Japonya'da Kantō depremi yüz binlerce can aldı; liman şehrinde yardım kampanyası başladı.", 2, "", {}, ""],
	[1923, 10, 22, "PETROL RÜŞVET SKANDALI", "Senato, 'Teapot Dome' petrol sahalarının rüşvetle kiralandığını soruşturuyor. Washington'da istifalar bekleniyor.", 2, "", {}, ""],
	[1924, 1, 21, "LENİN ÖLDÜ", "Sovyetler Birliği'nin kurucusu Lenin hayatını kaybetti. Sendikalarda hareketlilik var.", 2, "", {}, ""],
	[1924, 2, 12, "'RHAPSODY IN BLUE' İLK KEZ ÇALINDI", "Gershwin'in caz esintili eseri New York'ta alkış topladı.", 1, "", {}, ""],
	[1924, 5, 10, "HOOVER FEDERAL SORUŞTURMA BÜROSUNUN BAŞINDA", "Genç J. Edgar Hoover, federal soruşturma bürosunun başına getirildi; yolsuzluk ve çete avı sözü verdi.", 2, "", {"huzur": -1}, ""],
	[1924, 5, 26, "GÖÇ YASASI İMZALANDI", "Güney ve Doğu Avrupa'dan göçü kısıtlayan yasa yürürlüğe girdi. İtalyan ve İrlandalı mahalleleri öfkeli.", 2, "miting", {"huzur": -2}, ""],
	[1924, 7, 21, "LEOPOLD VE LOEB DAVASI BAŞLADI", "İki zengin üniversite öğrencisi, 14 yaşındaki bir çocuğu öldürmekten yargılanıyor. Savunmayı ünlü avukat Darrow yapıyor.", 2, "", {}, "leopold"],
	[1924, 9, 10, "LEOPOLD VE LOEB MÜEBBET ALDI", "Darrow'un konuşmasının ardından hâkim idam yerine ömür boyu hapis verdi. Halk bölünmüş durumda.", 2, "", {}, "leopold"],
	[1924, 11, 4, "COOLIDGE YENİDEN SEÇİLDİ", "Coolidge ezici çoğunlukla yeniden başkan. 'Refah' söylemi şehirde alkış topladı.", 1, "kutlama", {}, "seçim"],
	[1925, 1, 24, "TORRIO ŞİKAGO'DA VURULDU", "Şikago'nun içki baronu Johnny Torrio silahlı saldırıdan sağ kurtuldu ve çetesini Al Capone'a bırakıp kenara çekildi.", 3, "", {}, "capone"],
	[1925, 4, 10, "'BÜYÜK GATSBY' YAYIMLANDI", "Scott Fitzgerald'ın yeni romanı, caz çağının zenginlik ve boşluk hikâyesini anlatıyor.", 1, "", {}, ""],
	[1925, 7, 10, "'MAYMUN DAVASI' BAŞLADI", "Tennessee'de bir öğretmen, evrimi öğrettiği için yargılanıyor. Dava ülkenin en çok konuşulan konusu.", 2, "", {}, "scopes"],
	[1925, 8, 8, "KLAN ÜYELERİ WASHINGTON'DA YÜRÜDÜ", "Binlerce kukuletalı Ku Klux Klan üyesi başkentte yürüdü. Şehrin göçmen mahallelerinde karşı gösteri çağrıları yapılıyor.", 2, "isyan", {"huzur": -3}, ""],
	[1926, 8, 6, "GERTRUDE EDERLE MANŞ'I YÜZDÜ", "Amerikalı yüzücü Manş Denizi'ni erkeklerin rekorundan daha kısa sürede geçti.", 1, "kutlama", {}, ""],
	[1926, 8, 23, "VALENTINO ÖLDÜ, BİNLER SOKAKTA", "Beyazperdenin yıldızı Rudolph Valentino genç yaşta öldü. Cenazesinde izdiham yaşandı.", 2, "toren", {}, ""],
	[1926, 9, 18, "MIAMI'Yİ KASIRGA VURDU", "Güney sahilini vuran kasırga yüzlerce can aldı; liman şehirlerinde yardım toplanıyor.", 2, "", {"fk": -0.01}, ""],
	[1926, 10, 11, "WEISS KİLİSE ÖNÜNDE KURŞUNLANDI", "Şikago'nun kuzey yakası çetesinin başı Hymie Weiss ölü bulundu. Capone'a karşı kurulan cephe dağıldı.", 3, "", {}, "capone"],
	[1926, 10, 31, "HOUDINI ÖLDÜ", "Efsanevi illüzyonist Harry Houdini cadılar bayramında hayatını kaybetti.", 1, "", {}, ""],
	[1927, 4, 16, "MISSISSIPPI TAŞKINI", "Mississippi nehri yataklarını aştı; yüz binlerce kişi evsiz kaldı. Şehirde bağış kampanyası başladı.", 2, "", {}, ""],
	[1927, 5, 21, "LINDBERGH ATLANTİK'İ GEÇTİ", "Genç pilot Charles Lindbergh tek başına New York'tan Paris'e uçtu. Ülke bunu konuşuyor.", 3, "kutlama", {"huzur": 3}, ""],
	[1927, 8, 23, "SACCO VE VANZETTI İDAM EDİLDİ", "Yedi yıl süren davanın ardından iki anarşist elektrikli sandalyede idam edildi. Dünyanın dört yanında protestolar sürüyor.", 3, "isyan", {"huzur": -3}, "sacco"],
	[1927, 9, 30, "BABE RUTH 60. HOME RUN'U ATTI", "Yankees'in yıldızı bir sezonda 60 home run attı. Stadyumlarda ayakta alkış var.", 1, "", {}, ""],
	[1927, 10, 6, "İLK SESLİ FİLM: CAZ ŞARKICISI", "Sinemada ilk kez oyuncular konuştu. Sessiz film orkestraları işsiz kalmaktan korkuyor.", 2, "", {}, ""],
	[1928, 7, 1, "BROOKLYN'DE ARABADAN MAKİNELİ SALDIRI", "Yerel mafya babası Frankie Yale, ilk kez makineli tüfekle arabadan tarandı. Polis çeteleri silahsızlandırmaktan söz ediyor.", 3, "", {}, ""],
	[1928, 9, 28, "PENİSİLİN KEŞFEDİLDİ", "İskoç bilimci Fleming, küf mantarından bakteri öldüren bir madde bulduğunu duyurdu.", 2, "", {}, ""],
	[1928, 11, 6, "HOOVER BAŞKAN SEÇİLDİ", "Herbert Hoover ezici bir farkla Beyaz Saray'a girdi. 'Her tencerede tavuk' vaadi halkı umutlandırdı.", 2, "miting", {}, "seçim"],
	[1928, 11, 18, "MICKEY MOUSE SİNEMADA", "Disney'in 'Steamboat Willie' çizgi filmi sesle seyirciyle buluştu.", 1, "", {}, ""],
	[1929, 2, 14, "SEVGİLİLER GÜNÜ KATLİAMI", "Şikago'da bir garajda yedi kişi polis üniformalı adamlarca duvara dizilip kurşuna dizildi. Çeteler arası savaş kamuoyunu dehşete düşürdü.", 3, "", {"huzur": -2}, "capone"],
	[1929, 5, 13, "ATLANTIC CITY'DE ÇETE ZİRVESİ", "Ülkenin dört bir yanından çete liderleri sahil kasabasında bir araya geldi. Yetkililer 'barış anlaşması' dedikodusu yayıyor.", 2, "", {}, "capone"],
	[1929, 5, 16, "İLK OSCAR TÖRENİ", "Sinema akademisi ilk ödüllerini bir akşam yemeğinde dağıttı.", 1, "", {}, ""],
	[1929, 10, 24, "KARA PERŞEMBE: BORSA ÇÖKTÜ", "Wall Street'te hisseler birkaç saatte eridi. Binlerce yatırımcı bir gecede iflas etti; bankaların önünde kuyruklar var.", 3, "isyan", {"fk": -0.22, "huzur": -4}, "kriz"],
	[1929, 11, 29, "ÇÖKÜŞ DERİNLEŞİYOR: İŞTEN ÇIKARMALAR BAŞLADI", "Borsadaki çöküşün ardından fabrikalar işçi çıkarıyor. İş ilanlarının yerini işçi alım kuyrukları aldı.", 2, "", {"fk": -0.06}, "kriz"],
	[1930, 2, 26, "NEW YORK'TA CASTELLAMMARESE SAVAŞI BAŞLADI", "Eski mafya patronu Reina'nın öldürülmesiyle İtalyan çeteleri arasında kanlı bir güç savaşı başladı.", 3, "", {}, "kast"],
	[1930, 3, 13, "PLUTO KEŞFEDİLDİ", "Gökbilimciler Güneş Sistemi'nde dokuzuncu gezegeni bulduklarını açıkladı.", 1, "", {}, ""],
	[1930, 6, 9, "GAZETECİ JAKE LINGLE VURULDU", "Şikago Tribune muhabiri Lingle, kalabalık bir geçitte öldürüldü. Basın çete ilişkilerinin açıklanmasını talep ediyor.", 3, "", {}, "capone"],
	[1930, 6, 17, "HAWLEY-SMOOT GÜMRÜK YASASI", "İthalata ağır gümrük vergisi getiren yasa, liman şehrinde ticareti vurdu.", 2, "", {"fk": -0.04}, "kriz"],
	[1930, 12, 11, "BANKA İFLASI: MEVDUAT SAHİPLERİ SOKAKTA", "New York'taki büyük bir banka batınca binlerce hesap sahibi paralarını kaybetti. Şubelerin önünde yığılma var.", 3, "isyan", {"fk": -0.08, "huzur": -3}, "kriz"],
	[1931, 3, 3, "'YILDIZLI BAYRAK' MİLLİ MARŞ OLDU", "Kongre 'The Star-Spangled Banner'ı resmen milli marş ilan etti.", 1, "", {}, ""],
	[1931, 4, 15, "MASSERIA BROOKLYN'DE ÖLDÜRÜLDÜ", "Eski mafya patronu Joe Masseria bir lokantada kurşunlandı. Castellammarese savaşının seyri değişiyor.", 3, "", {}, "kast"],
	[1931, 5, 1, "EMPIRE STATE BUILDING AÇILDI", "Dünyanın en yüksek binası yarım yılda tamamlandı. Başkan Hoover düğmeye basarak açtı.", 2, "kutlama", {"huzur": 2}, ""],
	[1931, 6, 5, "AL CAPONE HAKKINDA VERGİ KAÇAKÇILIĞI İDDİANAMESİ", "Federal savcılar, Capone'u cinayet değil gelir vergisinden yargılayacak. Hazine ajanları aylardır defterleri inceliyordu.", 3, "", {}, "capone"],
	[1931, 9, 10, "MARANZANO ÖLDÜRÜLDÜ: YENİ DÜZEN", "Castellammarese savaşı bitti. Kıdemli patronların yerini 'komisyon' denen yeni bir yapı alıyor.", 3, "", {}, "kast"],
	[1931, 10, 17, "CAPONE'A 11 YIL HAPİS", "Şikago'nun efsanevi çete lideri vergi kaçakçılığından 11 yıl hapse mahkûm edildi. Bir dönem kapanıyor mu?", 3, "", {"huzur": -1}, "capone"],
	[1932, 3, 1, "LINDBERGH'İN BEBEĞİ KAÇIRILDI", "Ünlü pilotun 20 aylık oğlu evinden kaçırıldı. Ülke bu haberi nefesini tutarak izliyor.", 3, "", {}, ""],
	[1932, 7, 28, "BONUS ARMY DAĞITILDI", "Başkentte tazminat isteyen gaziler ordu tarafından zorla dağıtıldı. Şehirde gösteri çağrıları var.", 3, "isyan", {"huzur": -3}, "kriz"],
	[1932, 7, 30, "LOS ANGELES OLİMPİYATLARI AÇILDI", "Dünya gençliği krizin gölgesinde olimpiyat meşalesini yaktı.", 1, "kutlama", {}, ""],
	[1932, 11, 8, "ROOSEVELT BAŞKAN SEÇİLDİ", "Franklin Roosevelt 'yeni düzen' vaadiyle seçimleri kazandı. Kuru dönemin sonu da gündemde.", 3, "miting", {"huzur": 1}, "seçim"],
	[1933, 1, 30, "HİTLER ALMANYA'DA BAŞBAKAN", "Nasyonal Sosyalist lider Almanya'da hükümeti kurdu. Avrupa'da gerginlik artıyor.", 2, "", {}, ""],
	[1933, 3, 6, "ROOSEVELT BANKALARI KAPATTI", "Başkan Roosevelt günler süren 'banka tatili' ilan etti. Meydanlarda halk bilgilendiriliyor.", 3, "miting", {"fk": 0.02}, "kriz"],
	[1933, 4, 7, "BİRA YENİDEN YASAL!", "Yüzde 3,2'lik bira satışına izin veren yasa bugün yürürlüğe girdi. Sokaklar bayram yeri!", 3, "kutlama", {"huzur": 3}, "kuru_son"],
	[1933, 12, 5, "KURU DÖNEM SONA ERDİ", "Yirmi birinci anayasa değişikliği onaylandı: Yasak kaldırıldı. Barlar yeniden açılıyor; yeraltı ticaretinin altın çağı kapanıyor mu?", 3, "kutlama", {"huzur": 3}, "kuru_son"],
	[1934, 5, 23, "BONNIE VE CLYDE ÖLDÜRÜLDÜ", "Banka soyguncusu çift Louisiana'da pusuya düşürüldü.", 2, "", {}, ""],
	[1934, 7, 22, "DILLINGER VURULDU", "'Kamu düşmanı numara bir' John Dillinger Şikago'da bir sinema çıkışında federal ajanlarca vuruldu.", 3, "", {}, ""],
	[1934, 8, 11, "ALCATRAZ HAPİSHANE OLARAK AÇILDI", "San Francisco koyundaki ada, en tehlikeli mahkûmlar için federal hapishane oldu.", 2, "", {}, ""],
	[1935, 8, 14, "SOSYAL GÜVENLİK YASASI", "Yaşlılara emeklilik ve işsizlere yardım getiren yasa imzalandı.", 2, "", {}, ""],
	[1935, 10, 23, "DUTCH SCHULTZ VURULDU", "New York'un içki ve numara baronu Dutch Schultz bir lokantada vuruldu.", 3, "", {}, ""],
	[1936, 8, 1, "BERLİN OLİMPİYATLARI BAŞLADI", "Dünya, siyasi gerginlik altında Berlin'de buluştu.", 1, "", {}, ""],
	[1937, 5, 6, "HİNDENBURG ZEPLİNİ YANDI", "Alevler içinde yere çakılan hava gemisi ülkeyi şoke etti.", 2, "", {}, ""],
	[1938, 10, 30, "RADYO OYUNU PANİK YARATTI", "Orson Welles'in 'Dünyalar Savaşı' radyo uyarlaması gerçek bir istila sanılıp bazı şehirlerde paniğe yol açtı.", 2, "", {}, ""],
	[1939, 9, 1, "AVRUPA'DA SAVAŞ BAŞLADI", "Almanya Polonya'ya saldırdı; İngiltere ve Fransa savaş ilan etti. Liman şehri gerginlikle bekliyor.", 3, "miting", {"fk": 0.03}, ""],
]
# Yıllık resmî günler [ay, gün, ad, tür]
const BAYRAM := [
	[1, 1, "Yılbaşı şenliği", "kutlama"], [2, 22, "Başkan Washington'ın doğum günü anması", "toren"], [5, 30, "Anma Günü (Memorial Day) töreni", "toren"],
	[7, 4, "Bağımsızlık Günü kutlaması", "kutlama"], [11, 11, "Ateşkes Günü anma töreni", "toren"], [11, 25, "Şükran Günü şenliği", "kutlama"], [12, 24, "Noel ağacı ve yılbaşı pazarı", "kutlama"],
]

# Dolgu haberleri (sakin günler)
const DOLGU := [
	["magazin", "LİMAN SAHASINDA BOKS GECESİ", "Cumartesi akşamı liman sendikası salonunda 'Demir' Dolan ile Kuzeyli Pete karşı karşıya geliyor. Biletler 50 sente."],
	["magazin", "YENİ SİNEMA SALONU AÇILIYOR", "Downtown'da 600 kişilik yeni bir sinema salonu, piyanist ve orkestra eşliğinde sessiz filmler gösterecek."],
	["ekonomi", "BALIKÇILARIN SEZONU VERİMLİ GEÇİYOR", "Liman balıkçıları ağları dolu döndüğünü, fiyatların ise düştüğünü bildirdi."],
	["mahalle", "BELEDİYE YOL ÇALIŞMASI BAŞLATTI", "Flats'te taş döşeme çalışmaları sürüyor; araçların bazı sokaklardan geçişi kısıtlandı."],
	["magazin", "ÇAY SALONLARI MODA", "Genç kadınlar arasında şapka ve kısa etek akımı sürüyor; vaizler tepkili."],
	["ekonomi", "KÖMÜR FİYATLARI İSTİKRARLI", "Kış öncesi kömür tüccarları fiyatların değişmeyeceğini söyledi."],
	["magazin", "ŞEHİR OPERASINDA YENİ SEZON", "Operanın sezon açılışı, belediye başkanı ve şehrin ileri gelenlerini bir araya getirecek."],
	["mahalle", "ÇOCUKLAR İÇİN OKUL YEMEĞİ", "Hayırsever bir dernek, mahalle okullarında öğle yemeği dağıtmaya başladı."],
	["polis", "TRAFİKTE YENİ KURALLAR", "Polis, kavşaklarda sağdan gidiş kuralına uymayan sürücülere ceza yazılacağını duyurdu."],
	["magazin", "BEYZBOL KUPASI HEYECANI", "Liman Takımı (Dockers) ve Tepe Şahinleri hafta sonu şehrin kupasını oynayacak."],
	["ekonomi", "YENİ OTOMOBİL SALONU", "Kasabın çocuğu yeni bir otomobil bayisi açtı; taksitle satış kampanyası başlattı."],
	["saglik", "SAĞLIK DAİRESİNDEN UYARI", "Belediye doktorları halkı pis sulardan ve çiğ yiyeceklerden kaçınmaya çağırdı."],
]
const REKLAM := [
	"Dr. Hartley'in Şifalı Tonik'i — her derde deva! (Alkol oranı %22; yalnızca tıbbi amaçla satılır.)",
	"Pearson Mağazası: kışlık paltolar ve fötr şapkalar bu hafta %20 indirimli.",
	"Radyonuzu bugün kurun: 12 dolara kristal alıcı, kurulum bedava!",
	"Kodak Brownie — her anı ölümsüzleştirin. 2 dolardan başlayan fiyatlarla.",
	"Singer dikiş makineleri: aylık 2 dolar taksitle.",
	"Madam Rose'un Dans Salonu: Charleston dersleri her akşam.",
	"Liman Nakliyat: vapur seferleri ve yük taşıma, güvenli ve hızlı.",
	"Kalem Berberhanesi: tıraş 15 sent, saç kesimi 35 sent.",
]
const IDAM_AD := ["Eddie 'Kertenkele' Pruitt", "Tommy Boyle", "Carmine 'Kör' Lupo", "Jack Delaney", "Silas Wren", "Nicky 'Dişçi' Falcone", "Walter Stokes", "Big Mike Hanrahan", "Ray 'Fare' Costello"]
const IDAM_SUC := ["üç kişiyi öldürmekten", "bir polis memurunu vurmaktan", "bir banka soygununda gardiyan öldürmekten", "kaçak içki kavgasında iki kişiyi öldürmekten", "bir kundakla beş kişinin ölümüne yol açmaktan", "bir kuyumcu soygununda iki kişiyi öldürmekten"]
const ISYAN_NEDEN := ["kuru dönem polis baskınlarını", "kira ve vergi zamlarını", "işsizliği ve açlığı", "rüşvetçi belediye yönetimini", "liman ücretlerinin kesilmesini", "mahalle okullarının kapatılmasını"]
const KUTLAMA_AD := ["Bahar şenliği", "Liman Bayramı", "Belediye başkanının park açılışı", "Mahalle bando günü", "Hasat şenliği", "Hayır balosu ve havai fişek gösterisi"]
const MITING_AD := [["Liman Sendikası mitingi", "sendika"], ["Belediye seçim mitingi", "secim"], ["Kuru dönem yanlısı kadınlar derneği toplantısı", "temp"], ["Gaziler derneği mitingi", "gazi"], ["Vaiz Moriarty'nin açık hava ayini", "vaiz"]]
const POLIS_AD := [["Kaçak içki fıçıları meydanda imha ediliyor", "imha"], ["Polis orkestrası ve geçit töreni", "gecit"], ["Aranan suçluların afişleri ve yeni telsizli devriye araçları tanıtıldı", "tanitim"]]

func _init(o: Node) -> void:
	oyun = o
	rng.randomize()

func yeni() -> Dictionary:
	return {"haber": [], "sayilar": [], "ilan": [], "ilan_gun": -1, "fk": {}, "bfk": {}, "fk_g": 1.0, "etk": {}, "gec": [],
		"son_etk": -99, "yapilan": [], "seri": {}, "emlak": {"gun": -1, "satir": []}, "no": 0}

func baslat() -> void:
	var G: Dictionary = oyun.gaz
	if G.is_empty():
		oyun.gaz = yeni()
	var g: int = oyun.tarih()["gun"]
	ilan_yenile()
	if oyun.gaz["sayilar"].is_empty():
		_tarih_olaylari(g)
		_sayi_bas(g)
		for s in oyun.gaz["sayilar"]:
			s["okundu"] = true   # ilk sayı zaten elinde

# ---------- tarih/format ----------
func tarih_yazi(gun: int) -> String:
	var d: Dictionary = oyun.tarih(gun * oyun.DAY)
	return "%s · %d %s %d" % [GUN_AD[gun % 7], oyun.takvim_gun(gun * oyun.DAY), AY_AD[int(d["ay_yil"]) - 1], 1919 + int(d["yil"])]

func _gercek_ay_gun(gercek_gun: int) -> int:
	return clampi((gercek_gun - 1) / 3 + 1, 1, 10)

func bolge_ad(id: String) -> String:
	return oyun.harita.bolgeler[id]["ad"] if oyun.harita.bolgeler.has(id) else id

# ---------- haber havuzu ----------
func haber(tur: String, bas: String, metin: String, onem: int = 1, bolge: String = "", seri: String = "") -> void:
	var G: Dictionary = oyun.gaz
	if G.is_empty():
		return
	var g: int = oyun.tarih()["gun"]
	for h in G["haber"]:
		if h["gun"] == g and h["bas"] == bas and h["metin"] == metin:
			return
	G["haber"].append({"t": oyun.t, "gun": g, "tur": tur, "bas": bas, "metin": metin, "onem": onem, "bolge": bolge, "seri": seri, "yay": false})
	if G["haber"].size() > 220:
		G["haber"].pop_front()
	if seri != "":
		var S: Dictionary = G["seri"]
		if not S.has(seri):
			S[seri] = {"satir": [], "son": g}
		S[seri]["son"] = g
		S[seri]["satir"].append({"gun": g, "bas": bas})
		if S[seri]["satir"].size() > 12:
			S[seri]["satir"].pop_front()

# Kayıt defterinden gazeteye süzme: yalnızca kamuya açık (tarafsız) olaylar yazılır.
const KURAL := [
	["^SAVAŞ: (.+) ile (.+) arasında savaş çıktı", "mafya", "MAFYA SAVAŞI PATLAK VERDİ", "%s ile %s arasındaki gerginlik silahlı savaşa dönüştü. Mahallelerde panik var.", 3, "savas"],
	["^Savaş: (.+)$", "mafya", "AİLELER ARASINDA KANLI ÇATIŞMA", "Sokak savaşında %s", 2, "savas"],
	["^Barış: (.+)$", "mafya", "MAFYA AİLELERİ BARIŞ MASASINDA", "%s", 2, "savas"],
	["^Polis (.+)'a baskın yaptı", "polis", "POLİS BASKINI", "Polis, ihbar üzerine %s'a baskın düzenledi; defterlere ve nakit paraya el kondu.", 2, ""],
	["^ŞEHİRDE (.+) SALGINI", "saglik", "ŞEHİRDE SALGIN ALARMI", "Belediye sağlık dairesi, %s salgını nedeniyle halkı kalabalıktan uzak durmaya çağırdı. Revirler dolu.", 3, "salgin"],
	["^(.+) salgını sönmeye", "saglik", "SALGIN GERİLİYOR", "%s salgını yavaş yavaş sönüyor; şehir toparlanıyor.", 2, "salgin"],
	["^(.+) kapandı: dükkân", "emlak", "İŞYERİ KAPANDI", "%s kepenk indirdi; dükkân kiralık/satılık ilanına çıktı.", 1, ""],
	["^(.+) yeni bir kiracıya verildi", "emlak", "BOŞ DÜKKÂN KİRALANDI", "%s yeni kiracısına kavuştu; kiralık ilanı kaldırıldı.", 1, ""],
	["^(.+) ve (.+) adamları çatıştı: (.+) üstün", "catisma", "SOKAKTA SİLAHLI ÇATIŞMA", "%s ile %s çeteleri arasında silahlı çatışma çıktı; %s üstün geldi. Yaralılar var.", 2, ""],
	["^(.+): (.+) darbe girişiminde", "mafya", "AİLE İÇİNDE İHANET", "%s ailesinde bir darbe girişimi bastırıldı; %s'ın cezalandırıldığı konuşuluyor.", 2, ""],
	["^(.+): (.+) afaroz edildi", "mafya", "AİLEDEN ATILDI", "%s: %s aileden aforoz edildi.", 1, ""],
	["^(.+): (.+) mahalleyi (.+) aldı", "mahalle", "MAHALLENİN KONTROLÜ EL DEĞİŞTİRDİ", "%s'da güç dengesi değişti: %s sokakların kontrolünü ele geçirdi (önceki hâkim: %s).", 2, ""],
	["^(.+) sahipsiz kaldı: (.+) nüfuzunu", "mahalle", "MAHALLEDE BOŞLUK", "%s sahipsiz kaldı: %s geri çekildi. Mahallede kimin sözü geçeceği belirsiz.", 1, ""],
	["^(.+)'da hırsızlık dalgası", "mahalle", "HIRSIZLIK DALGASI", "%s'da hırsızlık vakaları arttı; esnaf polisten devriye istiyor.", 1, ""],
	["^(.+)'da mahalle şenliği", "mahalle", "MAHALLE ŞENLİĞİ", "%s'da düzenlenen şenlikte halk doyasıya eğlendi.", 1, ""],
	["^(.+), (.+) adamlarından birini yakaladı", "polis", "POLİS ÇETE ÜYESİ YAKALADI", "%s, %s çetesinden birini yakaladığını duyurdu.", 1, ""],
	["^(.+): (.+) yeni (.+) oldu", "mafya", "AİLEDE YENİ LİDER", "%s ailesinde yönetim değişti: %s yeni %s oldu.", 2, ""],
]
var _re: Array = []

func kayittan(metin: String, _tur: String) -> void:
	if oyun.gaz.is_empty():
		return
	var ml := " " + metin + " "
	if ml.contains(" Sen ") or ml.contains(" Sen,") or ml.contains(" Senin ") or ml.contains(" Sen'"):
		return   # oyuncunun kendi işleri gazeteye yansımaz
	if _re.is_empty():
		for k in KURAL:
			var re := RegEx.new()
			re.compile(k[0])
			_re.append(re)
	for i in KURAL.size():
		var m: RegExMatch = _re[i].search(metin)
		if m == null:
			continue
		var k: Array = KURAL[i]
		var args: Array = []
		for gi in range(1, m.get_group_count() + 1):
			args.append(m.get_string(gi))
		var govde: String = k[3] % args if args.size() > 0 else k[3]
		haber(k[1], k[2], govde, k[4], "", k[5])
		return

# Oyuncunun girdiği silahlı çatışmanın gazete versiyonu (kimlik belirsiz).
func catisma_haber(sonuc: Dictionary) -> void:
	if oyun.gaz.is_empty():
		return
	var bid: String = oyun.oyuncu_bolge
	var yer: String = bolge_ad(bid) if bid != "" else "şehirde"
	var olu: int = int(sonuc.get("dusman_olu", 0)) + int(sonuc.get("adam_olu", 0))
	var govde := "Tanıklara göre kimliği belirsiz bir grup, silahlı adamlarla sokak ortasında çatıştı."
	if olu > 0:
		govde += " %d kişi hayatını kaybetti." % olu
	else:
		govde += " Ölen olmadı, ancak yaralılar var."
	haber("catisma", "%s'DA SİLAHLI ÇATIŞMA" % yer.to_upper(), govde, 3 if olu >= 3 else 2, bid)

# Rakip ailenin üyesi öldü (özellikle lider): haber ve gerekirse meydan.
func uye_haberi(u: Dictionary, neden: String) -> void:
	if oyun.gaz.is_empty() or not (u["fak"] in oyun.NPC):
		return
	var rt: String = u["rutbe"]
	var aile: String = oyun.FAK[u["fak"]]["ad"]
	if rt == "don":
		haber("mafya", "%s LİDERİ %s ÖLDÜ" % [aile.to_upper(), u["ad"].to_upper()], "%s ailesinin başı %s %s. Ailenin sırada kimin olduğu belirsiz; mahallelerde silahlar sessiz değil." % [aile, u["ad"], neden], 3, "", "idam")
	elif rt == "ikinci":
		haber("mafya", "%s'İN İKİNCİ ADAMI ÖLDÜ" % aile.to_upper(), "%s ailesinin ikinci adamı %s %s." % [aile, u["ad"], neden], 2)

# ---------- günlük akış ----------
func gun() -> void:
	if oyun.gaz.is_empty():
		oyun.gaz = yeni()
	var g: int = oyun.tarih()["gun"]
	_etk_bitir()
	_tarih_olaylari(g)
	if g % 7 == 0:
		_haftalik_fiyat(g)
	_etk_planla(g)
	_sayi_bas(g)

func ay() -> void:
	pass

func _etki_uygula(e: Dictionary) -> void:
	var G: Dictionary = oyun.gaz
	if e.has("fk"):
		G["fk_g"] = clampf(float(G["fk_g"]) * (1.0 + float(e["fk"])), 0.45, 1.8)
	if e.has("huzur"):
		for id in oyun.bolge:
			oyun.bolge[id]["huzur"] = clampf(float(oyun.bolge[id]["huzur"]) + float(e["huzur"]), 0.0, 100.0)

func _tarih_olaylari(g: int) -> void:
	var G: Dictionary = oyun.gaz
	var d: Dictionary = oyun.tarih()
	var yil: int = 1919 + int(d["yil"])
	for e in TARIH:
		if e[0] != yil or e[1] != d["ay_yil"] or _gercek_ay_gun(int(e[2])) != int(d["ay_gun"]):
			continue
		var key := "%d-%d-%d" % [e[0], e[1], e[2]]
		if G["yapilan"].has(key):
			continue
		G["yapilan"].append(key)
		haber("tarih", e[3], e[4], int(e[5]), "", e[8])
		_etki_uygula(e[7])
		if e[6] != "":
			_etk_kur(e[6], g, {"bas": e[3], "metin": e[4], "tarih": true})
	# yıllık resmî günler
	for b in BAYRAM:
		if b[0] == d["ay_yil"] and _gercek_ay_gun(int(b[1])) == int(d["ay_gun"]):
			var key2 := "b%d-%d-%d" % [yil, b[0], b[1]]
			if not G["yapilan"].has(key2):
				G["yapilan"].append(key2)
				haber("meydan", "MEYDANDA %s" % String(b[2]).to_upper(), "Belediye, %s için meydanda program düzenliyor." % b[2], 1, "eastside")
				if G["etk"].is_empty():
					_etk_kur(b[3], g, {"bas": String(b[2]), "metin": "", "bayram": true})
	if G["yapilan"].size() > 400:
		G["yapilan"] = G["yapilan"].slice(-200)

# ---------- meydan etkinlikleri ----------
func etk() -> Dictionary:
	return oyun.gaz.get("etk", {})

# Saat içinde mi? durum: "" | "hazirlik" (iki saat önce kurulum) | "aktif"
func etk_durum() -> String:
	var e: Dictionary = etk()
	if e.is_empty():
		return ""
	if oyun.t >= int(e["bit_t"]):
		return ""
	if oyun.t >= int(e["bas_t"]):
		return "aktif"
	if oyun.t >= int(e["bas_t"]) - 120:
		return "hazirlik"
	return ""

func kalabalik_var() -> bool:
	var e: Dictionary = etk()
	return not e.is_empty() and oyun.t >= int(e["bas_t"]) - 30 and oyun.t < int(e["bit_t"])

func _uye_sec() -> Dictionary:
	var adaylar: Array = []
	for u in oyun.uyeler:
		if u["durum"] == "aktif" and u["fak"] in oyun.NPC and u["rutbe"] != "don":
			adaylar.append(u)
	if adaylar.is_empty() or rng.randf() > 0.45:
		return {}
	return adaylar[rng.randi() % adaylar.size()]

func _etk_kur(tur: String, g: int, ek: Dictionary) -> void:
	var G: Dictionary = oyun.gaz
	if not G["etk"].is_empty():
		return
	var e := {"tur": tur, "bas_t": g * oyun.DAY + 14 * 60, "bit_t": g * oyun.DAY + 18 * 60, "ad": ETK_AD.get(tur, "Etkinlik"), "bolge": "eastside", "bildirildi": false}
	if ek.get("tarih", false) or ek.get("bayram", false):
		e["bas"] = ek["bas"]
		e["metin"] = ek["metin"]
		e["neden"] = "son gelişmeleri"
	else:
		e["bas_t"] += (1 + rng.randi() % 2) * oyun.DAY
		e["bit_t"] += (e["bas_t"] - (g * oyun.DAY + 14 * 60))
		_etk_icerik(e)
	# başlangıç gününe göre etkinlik tarihi
	e["gun"] = int(e["bas_t"]) / oyun.DAY
	G["etk"] = e
	G["son_etk"] = g
	if not ek.get("tarih", false) and not ek.get("bayram", false):
		var gn: String = GUN_AD[int(e["gun"]) % 7]
		haber("meydan", "MEYDAN PROGRAMI: %s" % String(e["ad"]).to_upper(), "%s günü saat 14'te meydanda %s. %s" % [gn, String(e["ad"]).to_lower(), e["duyuru"]], 2, "eastside", "huzursuz" if tur in ["isyan"] else "")

func _etk_planla(g: int) -> void:
	var G: Dictionary = oyun.gaz
	if not G["etk"].is_empty() or g - int(G["son_etk"]) < 3:
		return
	if rng.randf() > 0.22:
		return
	var w := {"idam": 1.0, "isyan": 0.6 + (1.0 if float(oyun.bolge["eastside"]["huzur"]) < 45.0 else 0.0), "polis": 0.9 + oyun.arama / 100.0, "kutlama": 1.1, "miting": 1.0, "toren": 0.3}
	var top := 0.0
	for k in w:
		top += w[k]
	var r: float = rng.randf() * top
	var sec := "kutlama"
	for k in w:
		r -= w[k]
		if r <= 0.0:
			sec = k
			break
	_etk_kur(sec, g, {})

func _etk_icerik(e: Dictionary) -> void:
	match e["tur"]:
		"idam":
			var u: Dictionary = _uye_sec()
			if not u.is_empty():
				e["uid"] = u["uid"]
				e["kisi"] = oyun.uye_ad(u)
				e["aile"] = oyun.FAK[u["fak"]]["ad"]
				e["suc"] = IDAM_SUC[rng.randi() % IDAM_SUC.size()]
				e["duyuru"] = "%s ailesinden %s, %s yargılandı ve idama mahkûm edildi; infaz halka açık yapılacak." % [e["aile"], e["kisi"], e["suc"]]
			else:
				e["kisi"] = IDAM_AD[rng.randi() % IDAM_AD.size()]
				e["suc"] = IDAM_SUC[rng.randi() % IDAM_SUC.size()]
				e["duyuru"] = "%s, %s idama mahkûm edildi; infaz halka açık yapılacak." % [e["kisi"], e["suc"]]
		"isyan":
			e["neden"] = ISYAN_NEDEN[rng.randi() % ISYAN_NEDEN.size()]
			e["duyuru"] = "Sendikalar ve mahalle dernekleri %s protesto etmek için meydanda toplanacak. Polis alarmda." % e["neden"]
		"polis":
			var p: Array = POLIS_AD[rng.randi() % POLIS_AD.size()]
			e["ad"] = p[0] if p[1] == "imha" else ("Polis geçit töreni" if p[1] == "gecit" else "Polis tanıtım günü")
			e["alt"] = p[1]
			e["duyuru"] = "Komiserlik: %s." % p[0]
		"kutlama":
			e["ad"] = KUTLAMA_AD[rng.randi() % KUTLAMA_AD.size()]
			e["duyuru"] = "Bando, tezgâhlar ve havai fişek var; herkes davetli."
		"miting":
			var m: Array = MITING_AD[rng.randi() % MITING_AD.size()]
			e["ad"] = m[0]
			e["alt"] = m[1]
			e["duyuru"] = "Konuşmacılar halka seslenecek; kalabalık bekleniyor."
		"toren":
			e["ad"] = "Belediye anma töreni"
			e["duyuru"] = "Belediye başkanı ve komiser katılacak; tüm halk davetli."

func _etk_bitir() -> void:
	var G: Dictionary = oyun.gaz
	var e: Dictionary = G["etk"]
	if e.is_empty() or oyun.t < int(e["bit_t"]):
		return
	var g: int = oyun.tarih()["gun"]
	var b: Dictionary = oyun.bolge["eastside"]
	var bas := ""
	var metin := ""
	var onem := 2
	var tur := "meydan"
	var seri := ""
	var sonuc := ""
	match e["tur"]:
		"idam":
			seri = "idam"
			var aktif := false
			if e.has("uid"):
				var u: Dictionary = oyun.uye(int(e["uid"]))
				aktif = not u.is_empty() and u["durum"] == "aktif"
				if aktif:
					oyun.uye_oldu(int(e["uid"]), "meydanda asıldı", true)
				if aktif:
					bas = "%s ÜYESİ %s MEYDANDA ASILDI" % [String(e["aile"]).to_upper(), String(e["kisi"]).to_upper()]
					metin = "%s ailesinden %s, %s mahkûm edildiği idam cezasıyla bugün meydanda asıldı. Kalabalık sessizce dağıldı; ailenin intikam arayışına girdiği konuşuluyor." % [e["aile"], e["kisi"], e["suc"]]
					onem = 3
				else:
					bas = "İDAM İPTAL EDİLDİ"
					metin = "Meydanda infaz edilecek %s, infazdan önce ölü bulunduğu için idam töreni yapılmadı." % e["kisi"]
					onem = 2
			else:
				bas = "%s MEYDANDA ASILDI" % String(e["kisi"]).to_upper()
				metin = "%s, %s idama mahkûm edilmişti. Cezası bugün halkın önünde infaz edildi; çete çevreleri tepkisiz kaldı." % [e["kisi"], e["suc"]]
			b["huzur"] = maxf(0.0, float(b["huzur"]) - 2.0)
			b["kor"] = minf(100.0, float(b["kor"]) + 3.0)
			sonuc = "Meydanda %s asıldı." % e["kisi"]
		"isyan":
			seri = "huzursuz"
			var r: float = rng.randf()
			if r < 0.5:
				var gz: int = 8 + rng.randi() % 25
				bas = "MEYDANDAKİ GÖSTERİ POLİSÇE DAĞITILDI"
				metin = "%s protesto eden kalabalık, polis copları ve atlı birliklerle dağıtıldı. %d kişi gözaltına alındı." % [e["neden"], gz]
				b["huzur"] = maxf(0.0, float(b["huzur"]) - 3.0)
				b["sev"] = maxf(0.0, float(b["sev"]) - 2.0)
			elif r < 0.8:
				bas = "BELEDİYE GERİ ADIM ATTI"
				metin = "Meydanda %s protesto eden binlerce kişi toplandı; belediye başkanı görüşme sözü verip talepleri inceleyeceğini duyurdu." % e["neden"]
				b["huzur"] = minf(100.0, float(b["huzur"]) + 1.0)
			else:
				var ol: int = 1 + rng.randi() % 4
				bas = "MEYDANDA KANLI ÇATIŞMA"
				metin = "Meydandaki gösteri polisle çatışmaya döndü. %d kişi hayatını kaybetti, onlarca yaralı var. Sokaklarda gerginlik sürüyor." % ol
				tur = "catisma"
				onem = 3
				b["huzur"] = maxf(0.0, float(b["huzur"]) - 7.0)
				b["kor"] = minf(100.0, float(b["kor"]) + 4.0)
				for id in oyun.bolge:
					oyun.bolge[id]["huzur"] = maxf(0.0, float(oyun.bolge[id]["huzur"]) - 1.0)
			e["sonuc_bas"] = bas
			sonuc = bas
		"polis":
			bas = "POLİS MEYDANDA GÖSTERİ YAPTI"
			match e.get("alt", ""):
				"imha":
					bas = "KAÇAK İÇKİ FIÇILARI MEYDANDA İMHA EDİLDİ"
					metin = "Polis, yakaladığı yüzlerce fıçı kaçak içkiyi halkın önünde baltayla kırıp kanalizasyona döktü. Kalabalıktan 'yazık!' sesleri yükseldi."
				"gecit":
					metin = "Polis orkestrası geçit töreniyle meydanda yürüdü; komiser, 'suça geçit yok' mesajı verdi."
				_:
					metin = "Polis meydanda yeni telsizli devriye araçlarını ve aranan suçluların afişlerini tanıttı; komiser çetelere gözdağı verdi."
			onem = 1
			b["huzur"] = minf(100.0, float(b["huzur"]) + 1.0)
			sonuc = "Polis gösterisi yapıldı."
		"kutlama":
			bas = "%s COŞKUYLA KUTLANDI" % String(e["ad"]).to_upper()
			var kat: int = 400 + rng.randi() % 1600
			metin = "Meydanda düzenlenen kutlamaya yaklaşık %d kişi katıldı. Bando çaldı, tezgâhlar dolup taştı." % kat
			if e.get("tarih", false) or e.get("bayram", false):
				bas = "MEYDANDA " + String(e["bas"]).to_upper()
				metin = "Meydandaki kutlamaya yaklaşık %d kişi katıldı. Bando çaldı, çocuklar bayrak salladı." % kat
			onem = 1
			b["huzur"] = minf(100.0, float(b["huzur"]) + 3.0)
			b["sev"] = minf(100.0, float(b["sev"]) + 2.0)
			sonuc = "Kutlama yapıldı."
		"miting":
			var alt: String = e.get("alt", "")
			bas = "MEYDANDA %s" % String(e["ad"]).to_upper()
			match alt:
				"secim":
					metin = "Belediye adayları meydanda halka seslendi. Tammany yanlıları meydanı doldurdu."
					oyun.add_inf(b, "tammany", 1.5)
				"sendika":
					metin = "Liman Sendikası ücret zammı ve güvenli çalışma koşulları istedi; patronlar toplantıyı yakından izledi."
					b["sev"] = minf(100.0, float(b["sev"]) + 1.0)
				"temp":
					metin = "Kuru dönem yanlısı kadınlar kaçak içki satan barları kınadı; polise sert tedbir çağrısı yaptılar."
				"gazi":
					metin = "Savaş gazileri maaş ve iş talebiyle toplandı; belediye başkanı yardım sözü verdi."
				"vaiz":
					metin = "Vaiz Moriarty ahlâki çöküşten söz etti; kalabalık coşkuyla dua etti."
				_:
					metin = String(e["metin"]) if e.has("metin") and e["metin"] != "" else "Kalabalık meydanda toplandı."
					bas = "MEYDANDA " + String(e.get("bas", "MİTİNG")).to_upper()
			onem = 1
			sonuc = "Miting yapıldı."
		"toren":
			bas = "MEYDANDA ANMA TÖRENİ"
			metin = "Belediye başkanı, komiser ve yüzlerce vatandaş meydandaki anma törenine katıldı; çelenkler bırakıldı."
			onem = 1
			sonuc = "Tören yapıldı."
	if bas != "":
		haber(tur, bas, metin, onem, "eastside", seri)
	G["gec"].append({"gun": g - 1, "tur": e["tur"], "ad": e["ad"], "sonuc": sonuc})
	if G["gec"].size() > 8:
		G["gec"].pop_front()
	G["etk"] = {}

# ---------- emlak fiyatları ----------
func fiyat_k(i: int, bid: String) -> float:
	var G: Dictionary = oyun.gaz
	if G.is_empty():
		return 1.0
	return float(G["fk"].get(str(i), 1.0)) * float(G["bfk"].get(bid, 1.0)) * float(G["fk_g"])

func _haftalik_fiyat(g: int) -> void:
	var G: Dictionary = oyun.gaz
	var satir: Array = []
	G["fk_g"] = lerpf(float(G["fk_g"]), 1.0, 0.05) * (1.0 + rng.randf_range(-0.012, 0.012))
	for bid in oyun.bolge:
		var b: Dictionary = oyun.bolge[bid]
		var eski: float = float(G["bfk"].get(bid, 1.0))
		var yeni_f: float = clampf(eski * (1.0 + rng.randf_range(-0.03, 0.03) + (float(b["huzur"]) - 55.0) / 1800.0), 0.7, 1.45)
		G["bfk"][bid] = yeni_f
		var oran: float = (yeni_f - eski) / eski
		if absf(oran) >= 0.03:
			satir.append({"bas": "%s bölgesinde emlak fiyatları %%%d %s." % [bolge_ad(bid), int(round(absf(oran) * 100.0)), "yükseldi" if oran > 0 else "düştü"], "oran": oran})
	var adaylar: Array = []
	for i in oyun.isy:
		var r: Dictionary = oyun.isy[i]
		if r["sahip"] or r["tur"] in ["resmi", "depo", "luks"]:
			continue
		adaylar.append(i)
	adaylar.shuffle()
	var sayac := 0
	for i in adaylar:
		if sayac >= 6:
			break
		var r2: Dictionary = oyun.isy[i]
		var bid2: String = oyun.harita.yerler[i]["bolge"]
		var onceki: int = oyun.ilan_fiyat(i)
		var f: float = float(G["fk"].get(str(i), 1.0)) * rng.randf_range(0.82, 1.24)
		G["fk"][str(i)] = clampf(f, 0.55, 1.9)
		var sonra: int = oyun.ilan_fiyat(i)
		if onceki <= 0:
			continue
		var d: float = float(sonra - onceki) / float(onceki)
		if absf(d) < 0.04:
			continue
		sayac += 1
		var tur_ad := "ev" if r2["tur"] == "konut" else "işyeri"
		var durum := " (kiralık/satılık ilanı)" if r2.get("bos", false) else ""
		satir.append({"bas": "%s (%s) — %s satış fiyatı $%d → $%d (%%%+d)%s" % [oyun.harita.yerler[i]["ad"], bolge_ad(bid2), tur_ad, onceki, sonra, int(round(d * 100.0)), durum], "oran": d, "bina": i})
	G["emlak"] = {"gun": g, "satir": satir}
	if satir.size() > 0:
		var ilk: Dictionary = satir[0]
		haber("emlak", "HAFTALIK EMLAK ÖZETİ", "Bu hafta %d ilan/işyerinde fiyat değişti. %s" % [satir.size(), ilk["bas"]], 1)

# ---------- iş ilanları ----------
func ilan_yenile() -> void:
	var G: Dictionary = oyun.gaz
	if G.is_empty():
		return
	G["ilan"] = oyun.meslek.ilan_uret()
	G["ilan_gun"] = oyun.tarih()["gun"]

# ---------- sayı basımı ----------
func _en_iyi(liste: Array, n: int) -> Array:
	var kopya: Array = liste.duplicate()
	kopya.sort_custom(func(a, b): return a["onem"] > b["onem"] or (a["onem"] == b["onem"] and a["t"] > b["t"]))
	return kopya.slice(0, n)

func _sayi_bas(g: int) -> void:
	var G: Dictionary = oyun.gaz
	G["no"] = int(G["no"]) + 1
	var haftalik: bool = g % 7 == 0
	var yeni_h: Array = []
	for h in G["haber"]:
		if not h["yay"] and h["gun"] >= g - 3:
			yeni_h.append(h)
	var secim: Array = _en_iyi(yeni_h, 6 if haftalik else 5)
	# sakin günlerde dolgu
	var i2 := 0
	while secim.size() < 3 and i2 < 4:
		i2 += 1
		var d: Array = DOLGU[rng.randi() % DOLGU.size()]
		var var_mi := false
		for s in secim:
			if s["bas"] == d[1]:
				var_mi = true
		if not var_mi:
			secim.append({"tur": d[0], "bas": d[1], "metin": d[2], "onem": 0, "t": 0, "gun": g, "bolge": "", "seri": "", "yay": true})
	for h in secim:
		h["yay"] = true
	var man: Dictionary = secim[0] if not secim.is_empty() else {}
	var digerleri: Array = secim.slice(1)
	var sayi := {"no": G["no"], "gun": g, "tip": "haftalik" if haftalik else "gunluk", "tarih": tarih_yazi(g), "manset": _kopya(man), "haber": digerleri.map(_kopya),
		"hava": hava_yazi(), "reklam": REKLAM[rng.randi() % REKLAM.size()], "okundu": false}
	sayi["meydan"] = _meydan_satirlari()
	if haftalik:
		sayi["hafta"] = _hafta_ozeti(g)
		sayi["emlak"] = (G["emlak"] as Dictionary).duplicate(true)
	G["sayilar"] = [sayi]   # yalnızca bugünün gazetesi tutulur
	oyun.kayit("%s sabah gazetesi kapının önüne bırakıldı: «%s»" % ["Haftalık" if haftalik else "Günlük", man.get("bas", "Harbor Herald")], "info")

func _kopya(h: Dictionary) -> Dictionary:
	return {"tur": h.get("tur", "mahalle"), "bas": h.get("bas", ""), "metin": h.get("metin", ""), "onem": h.get("onem", 1)}

func hava_yazi() -> String:
	var h: Dictionary = oyun.hava()
	var t: String = {"acik": "Açık ve güneşli", "bulutlu": "Bulutlu", "yagmur": "Yağmurlu", "kar": "Karlı"}.get(h["tur"], "Değişken")
	return "%s · %s" % [t, oyun.mevsim()]

func _meydan_satirlari() -> Array:
	var r: Array = []
	var e: Dictionary = etk()
	if not e.is_empty():
		var gn: int = int(e["gun"])
		r.append("%s: %s — %s günü saat 14:00. %s" % [ETK_AD.get(e["tur"], "Etkinlik"), e["ad"], GUN_AD[gn % 7], e.get("duyuru", "")])
	for k in oyun.gaz["gec"].slice(-3):
		r.append("Geçen: %s — %s" % [k["ad"], k["sonuc"]])
	return r

func _hafta_ozeti(g: int) -> Dictionary:
	var G: Dictionary = oyun.gaz
	var sayim := {}
	var son: Array = []
	for h in G["haber"]:
		if h["gun"] >= g - 7 and h["onem"] > 0:
			son.append(h)
			sayim[h["tur"]] = int(sayim.get(h["tur"], 0)) + 1
	var satir: Array = []
	for k in ["catisma", "mafya", "polis", "saglik", "meydan", "emlak", "tarih", "mahalle"]:
		if sayim.has(k):
			satir.append("%s: %d haber" % [TUR[k], sayim[k]])
	var arc: Array = []
	for sid in G["seri"]:
		var S: Dictionary = G["seri"][sid]
		if g - int(S["son"]) <= 28 and S["satir"].size() >= 2:
			arc.append({"ad": SERI_AD.get(sid, sid), "satir": (S["satir"] as Array).slice(-4).map(func(x): return {"gun": x["gun"], "bas": x["bas"]})})
	# ekonomi çizgisi
	var ek: Array = []
	var fg: float = float(G["fk_g"])
	ek.append("Genel emlak endeksi: %%%d (taban 100)." % int(round(fg * 100.0)))
	var pahali := ""
	var ucuz := ""
	var pk := 0.0
	var uk := 99.0
	for bid in oyun.bolge:
		var v: float = float(G["bfk"].get(bid, 1.0))
		if v > pk:
			pk = v
			pahali = bid
		if v < uk:
			uk = v
			ucuz = bid
	if pahali != "":
		ek.append("En pahalılaşan mahalle: %s (%%%d). En ucuzlayan: %s (%%%d)." % [bolge_ad(pahali), int(round(pk * 100.0)), bolge_ad(ucuz), int(round(uk * 100.0))])
	return {"bilanco": satir, "olaylar": _en_iyi(son, 7).map(_kopya), "seri": arc, "ekonomi": ek}

# ---------- okuma ----------
func okunmamis() -> int:
	var n := 0
	for s in oyun.gaz.get("sayilar", []):
		if not s["okundu"]:
			n += 1
	return n

func oku() -> void:
	var G: Dictionary = oyun.gaz
	if G.is_empty():
		return
	for s in G["sayilar"]:
		s["okundu"] = true
	if int(G["ilan_gun"]) != int(oyun.tarih()["gun"]):
		ilan_yenile()   # ilanlar yalnızca gazete okunduğunda güncellenir
