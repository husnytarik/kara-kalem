extends RefCounted
# İsimli şehir sakinleri: her biri hep aynı bölgede, hep aynı saat aralıklarında, aynı yerlerde görünür.
# Oyun mekaniğine etkisi YOK (şimdilik): sadece yaşayan bir şehir hissi. İleride dedikodu/bilgi/görev bunlara bağlanabilir.
# rutin: [başlangıç saati, bitiş saati, bina adı]. "*" = bölgede dolaşır. Aralık dışında kişi evinde (haritada görünmez).
# Bina adı, o bölgedeki ilk eşleşen binadır (II/III varyasyonları dahil, ad başı eşleşir).

const LISTE := [
	# ---------- SOUTHSIDE ----------
	{"ad": "Rosa Esposito", "is": "Bakkal", "bolge": "southside",
		"rutin": [[6.5, 12.0, "Corner Grocer"], [12.0, 13.0, "Social Hall"], [13.0, 19.0, "Corner Grocer"]]},
	{"ad": "Gus Kalogeropoulos", "is": "Berber", "bolge": "southside",
		"rutin": [[8.0, 18.5, "Barber Shop"], [19.0, 22.0, "Pool Hall"]]},
	{"ad": "Peder Brennan", "is": "Papaz", "bolge": "southside",
		"rutin": [[7.0, 9.0, "Social Hall"], [9.0, 17.0, "*"], [17.0, 20.0, "Social Hall"]]},
	{"ad": "Moe Kaplan", "is": "Boksör", "bolge": "southside",
		"rutin": [[9.0, 14.0, "Boxing Gym"], [14.0, 17.0, "Butcher Row"], [18.0, 23.0, "Murphy's Tavern"]]},
	{"ad": "Annie Doyle", "is": "Çamaşırcı", "bolge": "southside",
		"rutin": [[7.0, 17.0, "Laundry Tenement"], [17.0, 18.5, "Corner Grocer"]]},
	{"ad": "Tommy Cavallo", "is": "Çırak", "bolge": "southside",
		"rutin": [[9.0, 18.0, "Pawn Shop"], [18.0, 20.0, "Soda Fountain"]]},
	# ---------- EASTSIDE ----------
	{"ad": "Haim Rosenbaum", "is": "Fırıncı", "bolge": "eastside",
		"rutin": [[4.5, 13.0, "Bakeshop"], [13.0, 14.0, "Deli"], [14.0, 17.0, "Bakeshop"]]},
	{"ad": "Sarah Levin", "is": "Terzi", "bolge": "eastside",
		"rutin": [[7.0, 12.0, "Garment Sweatshop"], [12.0, 12.75, "Open Market"], [12.75, 18.0, "Garment Sweatshop"]]},
	{"ad": "Abe Feldman", "is": "Matbaacı", "bolge": "eastside",
		"rutin": [[8.0, 17.5, "Print Shop"], [18.0, 21.0, "Yiddish Theater"]]},
	{"ad": "Rabbi Mendel", "is": "Hahambaşı", "bolge": "eastside",
		"rutin": [[6.0, 9.0, "Synagogue"], [9.0, 16.0, "Public School 12"], [16.0, 20.0, "Synagogue"]]},
	{"ad": "Dora Katz", "is": "Öğretmen", "bolge": "eastside",
		"rutin": [[7.5, 15.5, "Public School 12"], [16.0, 18.0, "Open Market"]]},
	{"ad": "Joe Gold", "is": "Seyyar satıcı", "bolge": "eastside",
		"rutin": [[6.0, 11.0, "Pushcart Alley"], [11.0, 18.0, "*"]]},
	# ---------- HILLTOP ----------
	{"ad": "Mrs. Eleanor Whitfield", "is": "Hayırsever", "bolge": "hilltop",
		"rutin": [[10.0, 13.0, "Florist"], [13.0, 16.0, "Country Club"], [16.0, 19.0, "Art Gallery"]]},
	{"ad": "Dr. Alistair Pryce", "is": "Diş hekimi", "bolge": "hilltop",
		"rutin": [[9.0, 17.0, "Dentist"], [18.0, 22.0, "Country Club"]]},
	{"ad": "Mr. Cornelius Vane", "is": "Kuyumcu", "bolge": "hilltop",
		"rutin": [[9.5, 17.5, "Jeweler"], [18.0, 20.0, "Hotel Belmont"]]},
	{"ad": "Franklin Hale", "is": "Avukat", "bolge": "hilltop",
		"rutin": [[8.5, 18.0, "Attorney"], [12.0, 13.0, "Hotel Belmont"]]},
	{"ad": "Miss Clara Bell", "is": "Kütüphaneci", "bolge": "hilltop",
		"rutin": [[9.0, 17.0, "Private Library"], [17.0, 19.0, "Florist"]]},
	{"ad": "Henry Moss", "is": "Şoför", "bolge": "hilltop",
		"rutin": [[7.0, 20.0, "Chauffeur Garage"], [20.0, 23.0, "Mansion"]]},
	# ---------- DOWNTOWN ----------
	{"ad": "Edie Marlowe", "is": "Gazete editörü", "bolge": "downtown",
		"rutin": [[8.0, 19.0, "Daily Courier"], [12.0, 13.0, "Drugstore"], [19.0, 22.0, "Orpheum Cinema"]]},
	{"ad": "Walter Brogan", "is": "Komiser", "bolge": "downtown",
		"rutin": [[7.0, 19.0, "Precinct House"], [19.0, 21.0, "Drugstore"]]},
	{"ad": "Lily Chen", "is": "Telefon santralcisi", "bolge": "downtown",
		"rutin": [[8.0, 17.0, "Telephone Exchange"], [17.5, 19.0, "Department Store"]]},
	{"ad": "Mr. Abernathy", "is": "Bankacı", "bolge": "downtown",
		"rutin": [[8.5, 17.0, "First National Bank"], [12.0, 13.0, "Chamber of Commerce"]]},
	{"ad": "Stella Ruiz", "is": "Tezgâhtar", "bolge": "downtown",
		"rutin": [[9.0, 18.0, "Department Store"], [18.0, 20.0, "Orpheum Cinema"]]},
	{"ad": "Hank Murray", "is": "Posta memuru", "bolge": "downtown",
		"rutin": [[7.5, 16.5, "Post Office"], [16.5, 19.0, "*"]]},
	# ---------- FLATS ----------
	{"ad": "Stanley Kowalczyk", "is": "Demirci", "bolge": "flats",
		"rutin": [[6.0, 17.0, "Blacksmith"], [17.0, 18.5, "Turkish Bath"]]},
	{"ad": "Big Tony Russo", "is": "Dökümcü", "bolge": "flats",
		"rutin": [[5.5, 14.0, "Foundry"], [14.0, 15.0, "Produce Stand"], [15.0, 18.0, "Foundry"]]},
	{"ad": "Olga Petrov", "is": "Manav", "bolge": "flats",
		"rutin": [[5.0, 13.0, "Produce Stand"], [13.0, 18.0, "Cold Storage"]]},
	{"ad": "Jimmy Brick", "is": "İnşaat işçisi", "bolge": "flats",
		"rutin": [[6.0, 17.0, "Brick Yard"], [17.0, 18.5, "Tool & Die"]]},
	{"ad": "Gertie Schmidt", "is": "Hurdacı", "bolge": "flats",
		"rutin": [[7.0, 17.0, "Junk Yard"], [17.0, 18.0, "*"]]},
	{"ad": "Boris Volkov", "is": "Demiryolu işçisi", "bolge": "flats",
		"rutin": [[5.0, 14.0, "Rail Depot"], [14.0, 16.0, "Turkish Bath"]]},
	# ---------- DOCKS ----------
	{"ad": "Koca Jack Kowalski", "is": "Sendika başkanı", "bolge": "docks",
		"rutin": [[6.0, 17.0, "Stevedore Union"], [17.0, 23.0, "Sailors Bar"]]},
	{"ad": "Capt. Silas Reed", "is": "Gemi kaptanı", "bolge": "docks",
		"rutin": [[7.0, 15.0, "Shipyard"], [15.0, 17.0, "Harbor Master"], [18.0, 23.0, "Sailors Bar"]]},
	{"ad": "Mary Flynn", "is": "Balıkçı kadını", "bolge": "docks",
		"rutin": [[4.5, 12.0, "Fish Market"], [12.0, 17.0, "Cannery"]]},
	{"ad": "Pete Doolan", "is": "Gümrük memuru", "bolge": "docks",
		"rutin": [[8.0, 17.0, "Customs House"], [17.5, 21.0, "Sailors Bar"]]},
	{"ad": "Old Ned", "is": "Halat ustası", "bolge": "docks",
		"rutin": [[6.0, 16.0, "Rope Works"], [16.0, 17.5, "Coal Yard"]]},
	{"ad": "Luigi Bianchi", "is": "Gemi levazımcısı", "bolge": "docks",
		"rutin": [[7.5, 18.0, "Ship Chandler"], [18.0, 20.0, "Dock Hiring Hall"]]},
]

# Bu saatte (0-24) kişi nerede? Dönen: {"yer": bina adı, "bas": bu aralığın başlangıç saati} ya da boş (evde).
static func aralik(s: Dictionary, saat: float) -> Dictionary:
	for r in s["rutin"]:
		if saat >= r[0] and saat < r[1]:
			return {"yer": r[2], "bas": r[0], "son": r[1]}
	return {}
