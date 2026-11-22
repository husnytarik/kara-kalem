extends RefCounted
# İsimli şehir sakinleri: her biri hep aynı bölgede, hep aynı saat aralıklarında, aynı yerlerde görünür.
# Oyun mekaniğine etkisi YOK (şimdilik): sadece yaşayan bir şehir hissi. İleride dedikodu/bilgi/görev bunlara bağlanabilir.
# rutin: [başlangıç saati, bitiş saati, bina adı]. "*" = bölgede dolaşır. Aralık dışında kişi evinde (haritada görünmez).
# Bina adı, o bölgedeki ilk eşleşen binadır (II/III varyasyonları dahil, ad başı eşleşir).

const LISTE := [
	# ---------- SOUTHSIDE ----------
	{"ad": "Rosa Esposito", "is": "Bakkal", "bolge": "southside", "not": "Sokağın gazetesi: kimin ne aldığını bilir.",
		"rutin": [[6.5, 12.0, "Corner Grocer"], [12.0, 13.0, "Social Hall"], [13.0, 19.0, "Corner Grocer"]]},
	{"ad": "Gus Kalogeropoulos", "is": "Berber", "bolge": "southside", "not": "Koltuğunda herkes konuşur.",
		"rutin": [[8.0, 18.5, "Barber Shop"], [19.0, 22.0, "Pool Hall"]]},
	{"ad": "Peder Brennan", "is": "Papaz", "bolge": "southside", "not": "Mahallenin günah çıkarma odası.",
		"rutin": [[7.0, 9.0, "Social Hall"], [9.0, 17.0, "*"], [17.0, 20.0, "Social Hall"]]},
	{"ad": "Moe Kaplan", "is": "Boksör", "bolge": "southside", "not": "Sağ kulağı hep çınlar.",
		"rutin": [[9.0, 14.0, "Boxing Gym"], [14.0, 17.0, "Butcher Row"], [18.0, 23.0, "Murphy's Tavern"]]},
	{"ad": "Annie Doyle", "is": "Çamaşırcı", "bolge": "southside", "not": "Üç çocuğuyla yalnız.",
		"rutin": [[7.0, 17.0, "Laundry Tenement"], [17.0, 18.5, "Corner Grocer"]]},
	{"ad": "Tommy Cavallo", "is": "Çırak", "bolge": "southside", "not": "Pawn Shop'ta çalışıyor, her şeyi merak eder.",
		"rutin": [[9.0, 18.0, "Pawn Shop"], [18.0, 20.0, "Soda Fountain"]]},
	# ---------- EASTSIDE ----------
	{"ad": "Haim Rosenbaum", "is": "Fırıncı", "bolge": "eastside", "not": "Gün doğmadan ekmek pişirir.",
		"rutin": [[4.5, 13.0, "Bakeshop"], [13.0, 14.0, "Deli"], [14.0, 17.0, "Bakeshop"]]},
	{"ad": "Sarah Levin", "is": "Terzi", "bolge": "eastside", "not": "Garment Sweatshop'ta vardiyada.",
		"rutin": [[7.0, 12.0, "Garment Sweatshop"], [12.0, 12.75, "Open Market"], [12.75, 18.0, "Garment Sweatshop"]]},
	{"ad": "Abe Feldman", "is": "Matbaacı", "bolge": "eastside", "not": "Broşür basar; hangi tarafa yazdığı belli olmaz.",
		"rutin": [[8.0, 17.5, "Print Shop"], [18.0, 21.0, "Yiddish Theater"]]},
	{"ad": "Rabbi Mendel", "is": "Hahambaşı", "bolge": "eastside", "not": "Cuma akşamları sokaklar sessizleşir.",
		"rutin": [[6.0, 9.0, "Synagogue"], [9.0, 16.0, "Public School 12"], [16.0, 20.0, "Synagogue"]]},
	{"ad": "Dora Katz", "is": "Öğretmen", "bolge": "eastside", "not": "Çocuklar için yirmi dil bilir, hepsi azarlama.",
		"rutin": [[7.5, 15.5, "Public School 12"], [16.0, 18.0, "Open Market"]]},
	{"ad": "Joe Gold", "is": "Seyyar satıcı", "bolge": "eastside", "not": "Pushcart Alley'nin sesi.",
		"rutin": [[6.0, 11.0, "Pushcart Alley"], [11.0, 18.0, "*"]]},
	# ---------- HILLTOP ----------
	{"ad": "Mrs. Eleanor Whitfield", "is": "Hayırsever", "bolge": "hilltop", "not": "Her salı bir yardım balosu verir.",
		"rutin": [[10.0, 13.0, "Florist"], [13.0, 16.0, "Country Club"], [16.0, 19.0, "Art Gallery"]]},
	{"ad": "Dr. Alistair Pryce", "is": "Diş hekimi", "bolge": "hilltop", "not": "Hastaları kadar dedikodu da dinler.",
		"rutin": [[9.0, 17.0, "Dentist"], [18.0, 22.0, "Country Club"]]},
	{"ad": "Mr. Cornelius Vane", "is": "Kuyumcu", "bolge": "hilltop", "not": "Dükkânından hiç ayrılmaz, kapıda silahlı bir bekçi var.",
		"rutin": [[9.5, 17.5, "Jeweler"], [18.0, 20.0, "Hotel Belmont"]]},
	{"ad": "Franklin Hale", "is": "Avukat", "bolge": "hilltop", "not": "Hem Marchetti'nin hem Belediye'nin işini görür.",
		"rutin": [[8.5, 18.0, "Attorney"], [12.0, 13.0, "Hotel Belmont"]]},
	{"ad": "Miss Clara Bell", "is": "Kütüphaneci", "bolge": "hilltop", "not": "Sessizlik kuralını sertçe uygular.",
		"rutin": [[9.0, 17.0, "Private Library"], [17.0, 19.0, "Florist"]]},
	{"ad": "Henry Moss", "is": "Şoför", "bolge": "hilltop", "not": "Her akşam patronunu bir yerden alır.",
		"rutin": [[7.0, 20.0, "Chauffeur Garage"], [20.0, 23.0, "Mansion"]]},
	# ---------- DOWNTOWN ----------
	{"ad": "Edie Marlowe", "is": "Gazete editörü", "bolge": "downtown", "not": "Daily Courier'ın sert kalemi.",
		"rutin": [[8.0, 19.0, "Daily Courier"], [12.0, 13.0, "Drugstore"], [19.0, 22.0, "Orpheum Cinema"]]},
	{"ad": "Walter Brogan", "is": "Komiser", "bolge": "downtown", "not": "Otuz yıllık polis; yasayı iyi bilir, iyi eğer.",
		"rutin": [[7.0, 19.0, "Precinct House"], [19.0, 21.0, "Drugstore"]]},
	{"ad": "Lily Chen", "is": "Telefon santralcisi", "bolge": "downtown", "not": "Şehirdeki her konuşmanın bir kısmını duyar.",
		"rutin": [[8.0, 17.0, "Telephone Exchange"], [17.5, 19.0, "Department Store"]]},
	{"ad": "Mr. Abernathy", "is": "Bankacı", "bolge": "downtown", "not": "Kasadaki parayı değil, sizin güveninizi sayar.",
		"rutin": [[8.5, 17.0, "First National Bank"], [12.0, 13.0, "Chamber of Commerce"]]},
	{"ad": "Stella Ruiz", "is": "Tezgâhtar", "bolge": "downtown", "not": "Department Store'da şapka bölümü.",
		"rutin": [[9.0, 18.0, "Department Store"], [18.0, 20.0, "Orpheum Cinema"]]},
	{"ad": "Hank Murray", "is": "Posta memuru", "bolge": "downtown", "not": "Hangi mektubun kimden geldiğini bilir.",
		"rutin": [[7.5, 16.5, "Post Office"], [16.5, 19.0, "*"]]},
	# ---------- FLATS ----------
	{"ad": "Stanley Kowalczyk", "is": "Demirci", "bolge": "flats", "not": "Boğa gibi güçlü, kuzu gibi sessiz.",
		"rutin": [[6.0, 17.0, "Blacksmith"], [17.0, 18.5, "Turkish Bath"]]},
	{"ad": "Big Tony Russo", "is": "Dökümcü", "bolge": "flats", "not": "Foundry'nin ateşi hiç sönmez.",
		"rutin": [[5.5, 14.0, "Foundry"], [14.0, 15.0, "Produce Stand"], [15.0, 18.0, "Foundry"]]},
	{"ad": "Olga Petrov", "is": "Manav", "bolge": "flats", "not": "Sabah en taze malı o getirir.",
		"rutin": [[5.0, 13.0, "Produce Stand"], [13.0, 18.0, "Cold Storage"]]},
	{"ad": "Jimmy Brick", "is": "İnşaat işçisi", "bolge": "flats", "not": "Brick Yard'da çalışır; borçludur.",
		"rutin": [[6.0, 17.0, "Brick Yard"], [17.0, 18.5, "Tool & Die"]]},
	{"ad": "Gertie Schmidt", "is": "Hurdacı", "bolge": "flats", "not": "Çöpte hazine bulur; kimsenin işine karışmaz.",
		"rutin": [[7.0, 17.0, "Junk Yard"], [17.0, 18.0, "*"]]},
	{"ad": "Boris Volkov", "is": "Demiryolu işçisi", "bolge": "flats", "not": "Rail Depot'ta vardiya, bir de akşam hamamı.",
		"rutin": [[5.0, 14.0, "Rail Depot"], [14.0, 16.0, "Turkish Bath"]]},
	# ---------- DOCKS ----------
	{"ad": "Koca Jack Kowalski", "is": "Sendika başkanı", "bolge": "docks", "not": "Grev fonunu kasada, bira elinde taşır.",
		"rutin": [[6.0, 17.0, "Stevedore Union"], [17.0, 23.0, "Sailors Bar"]]},
	{"ad": "Capt. Silas Reed", "is": "Gemi kaptanı", "bolge": "docks", "not": "Yasaktan önce rom, sonra yük taşıdı.",
		"rutin": [[7.0, 15.0, "Shipyard"], [15.0, 17.0, "Harbor Master"], [18.0, 23.0, "Sailors Bar"]]},
	{"ad": "Mary Flynn", "is": "Balıkçı kadını", "bolge": "docks", "not": "Gün doğmadan balığı indirir.",
		"rutin": [[4.5, 12.0, "Fish Market"], [12.0, 17.0, "Cannery"]]},
	{"ad": "Pete Doolan", "is": "Gümrük memuru", "bolge": "docks", "not": "Gözünü yumması için ayrı bir tarifesi var.",
		"rutin": [[8.0, 17.0, "Customs House"], [17.5, 21.0, "Sailors Bar"]]},
	{"ad": "Old Ned", "is": "Halat ustası", "bolge": "docks", "not": "Elleri yıllardan beri kendi düğümü gibi.",
		"rutin": [[6.0, 16.0, "Rope Works"], [16.0, 17.5, "Coal Yard"]]},
	{"ad": "Luigi Bianchi", "is": "Gemi levazımcısı", "bolge": "docks", "not": "Ship Chandler'da her şeyin fiyatı pazarlığa açıktır.",
		"rutin": [[7.5, 18.0, "Ship Chandler"], [18.0, 20.0, "Dock Hiring Hall"]]},
]

# Bu saatte (0-24) kişi nerede? Dönen: {"yer": bina adı, "bas": bu aralığın başlangıç saati} ya da boş (evde).
static func aralik(s: Dictionary, saat: float) -> Dictionary:
	for r in s["rutin"]:
		if saat >= r[0] and saat < r[1]:
			return {"yer": r[2], "bas": r[0], "son": r[1]}
	return {}
