import 'dart:math';

/// Enterprise-Grade Market Model
class MarketRate {
  final String id;
  final String productName;
  final String category;
  final String state;
  final String district;
  final String market;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final DateTime priceDate;
  final String unit;
  final String variety;
  final String grade;
  final int arrivals;
  final double qualityScore;

  MarketRate({
    required this.id,
    required this.productName,
    required this.category,
    required this.state,
    required this.district,
    required this.market,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.priceDate,
    required this.unit,
    required this.variety,
    required this.grade,
    required this.arrivals,
    this.qualityScore = 8.0,
  });

  factory MarketRate.fromJson(Map<String, dynamic> json) {
    return MarketRate(
      id: json['id'] ?? '',
      productName: json['commodity'] ?? json['productName'] ?? '',
      category: json['category'] ?? 'Others',
      state: json['state'] ?? '',
      district: json['district'] ?? '',
      market: json['market'] ?? '',
      minPrice: (json['min_price'] ?? json['minPrice'] ?? 0).toDouble(),
      maxPrice: (json['max_price'] ?? json['maxPrice'] ?? 0).toDouble(),
      modalPrice: (json['modal_price'] ?? json['modalPrice'] ?? 0).toDouble(),
      priceDate:
          DateTime.tryParse(json['price_date'] ?? json['priceDate'] ?? '') ??
              DateTime.now(),
      unit: json['unit'] ?? 'Kg',
      variety: json['variety'] ?? 'Common',
      grade: json['grade'] ?? 'FAQ',
      arrivals: (json['arrivals'] ?? 0).toInt(),
      qualityScore: (json['qualityScore'] ?? 8.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'category': category,
      'state': state,
      'district': district,
      'market': market,
      'min_price': minPrice,
      'max_price': maxPrice,
      'modal_price': modalPrice,
      'price_date': priceDate.toIso8601String(),
      'unit': unit,
      'variety': variety,
      'grade': grade,
      'arrivals': arrivals,
      'qualityScore': qualityScore,
    };
  }
}

class APMCApiService {
  // --- NATIONWIDE MASTER GEOGRAPHY ---
  static const Map<String, List<String>> indiaGeography = {
    'Andaman and Nicobar Islands': [
      'Nicobar',
      'North and Middle Andaman',
      'South Andaman'
    ],
    'Andhra Pradesh': [
      'Anantapur',
      'Chittoor',
      'East Godavari',
      'Guntur',
      'Kadapa',
      'Krishna',
      'Kurnool',
      'Nellore',
      'Prakasam',
      'Srikakulam',
      'Visakhapatnam',
      'Vizianagaram',
      'West Godavari'
    ],
    'Arunachal Pradesh': [
      'Anjaw',
      'Changlang',
      'Dibang Valley',
      'East Kameng',
      'East Siang',
      'Kamle',
      'Kra Daadi',
      'Kurung Kumey',
      'Lepa Rada',
      'Lohit',
      'Longding',
      'Lower Dibang Valley',
      'Lower Siang',
      'Lower Subansiri',
      'Namsai',
      'Pakke Kessang',
      'Papum Pare',
      'Shi Yomi',
      'Siang',
      'Tawang',
      'Tirap',
      'Upper Siang',
      'Upper Subansiri',
      'West Kameng',
      'West Siang'
    ],
    'Assam': [
      'Baksa',
      'Barpeta',
      'Biswanath',
      'Bongaigaon',
      'Cachar',
      'Charaideo',
      'Chirang',
      'Darrang',
      'Dhemaji',
      'Dhubri',
      'Dibrugarh',
      'Dima Hasao',
      'Goalpara',
      'Golaghat',
      'Hailakandi',
      'Hojai',
      'Jorhat',
      'Kamrup',
      'Kamrup Metropolitan',
      'Karbi Anglong',
      'Karimganj',
      'Kokrajhar',
      'Lakhimpur',
      'Majuli',
      'Morigaon',
      'Nagaon',
      'Nalbari',
      'Sivasagar',
      'Sonitpur',
      'South Salmara-Mankachar',
      'Tinsukia',
      'Udalguri',
      'West Karbi Anglong',
      'Bajali',
      'Tamulpur'
    ],
    'Bihar': [
      'Araria',
      'Arwal',
      'Aurangabad',
      'Banka',
      'Begusarai',
      'Bhagalpur',
      'Bhojpur',
      'Buxar',
      'Darbhanga',
      'East Champaran',
      'Gaya',
      'Gopalganj',
      'Jamui',
      'Jehanabad',
      'Kaimur',
      'Katihar',
      'Khagaria',
      'Kishanganj',
      'Lakhisarai',
      'Madhepura',
      'Madhubani',
      'Munger',
      'Muzaffarpur',
      'Nalanda',
      'Nawada',
      'Patna',
      'Purnia',
      'Rohtas',
      'Saharsa',
      'Samastipur',
      'Saran',
      'Sheikhpura',
      'Sheohar',
      'Sitamarhi',
      'Siwan',
      'Supaul',
      'Vaishali',
      'West Champaran'
    ],
    'Chhattisgarh': [
      'Balod',
      'Baloda Bazar',
      'Balrampur',
      'Bastar',
      'Bemetara',
      'Bijapur',
      'Bilaspur',
      'Dantewada',
      'Dhamtari',
      'Durg',
      'Gariaband',
      'Janjgir-Champa',
      'Jashpur',
      'Kabirdham',
      'Kanker',
      'Kondagaon',
      'Korba',
      'Koriya',
      'Mahasamund',
      'Mungeli',
      'Narayanpur',
      'Raigarh',
      'Raipur',
      'Rajnandgaon',
      'Sakti',
      'Sarangarh-Bilaigarh',
      'Sukma',
      'Surajpur',
      'Surguja'
    ],
    'Delhi': [
      'Central Delhi',
      'East Delhi',
      'New Delhi',
      'North Delhi',
      'North East Delhi',
      'North West Delhi',
      'Shahdara',
      'South Delhi',
      'South East Delhi',
      'South West Delhi',
      'West Delhi'
    ],
    'Goa': ['North Goa', 'South Goa'],
    'Gujarat': [
      'Ahmedabad',
      'Amreli',
      'Anand',
      'Aravalli',
      'Banaskantha',
      'Bharuch',
      'Bhavnagar',
      'Botad',
      'Chhota Udepur',
      'Dahod',
      'Dang',
      'Devbhumi Dwarka',
      'Gandhinagar',
      'Gir Somnath',
      'Jamnagar',
      'Junagadh',
      'Kheda',
      'Kutch',
      'Mahisagar',
      'Mehsana',
      'Morbi',
      'Narmada',
      'Navsari',
      'Panchmahal',
      'Patan',
      'Porbandar',
      'Rajkot',
      'Sabarkantha',
      'Surat',
      'Surendranagar',
      'Tapi',
      'Vadodara',
      'Valsad'
    ],
    'Haryana': [
      'Ambala',
      'Bhiwani',
      'Charkhi Dadri',
      'Faridabad',
      'Fatehabad',
      'Gurgaon',
      'Hisar',
      'Jhajjar',
      'Jind',
      'Kaithal',
      'Karnal',
      'Kurukshetra',
      'Mahendragarh',
      'Nuh',
      'Palwal',
      'Panchkula',
      'Panipat',
      'Rewari',
      'Rohtak',
      'Sirsa',
      'Sonipat',
      'Yamunanagar'
    ],
    'Himachal Pradesh': [
      'Bilaspur',
      'Chamba',
      'Hamirpur',
      'Kangra',
      'Kinnaur',
      'Kullu',
      'Lahaul and Spiti',
      'Mandi',
      'Shimla',
      'Sirmaur',
      'Solan',
      'Una'
    ],
    'Jammu and Kashmir': [
      'Anantnag',
      'Bandipora',
      'Baramulla',
      'Budgam',
      'Doda',
      'Ganderbal',
      'Jammu',
      'Kathua',
      'Kishtwar',
      'Kulgam',
      'Kupwara',
      'Poonch',
      'Pulwama',
      'Rajouri',
      'Ramban',
      'Reasi',
      'Samba',
      'Shopian',
      'Srinagar',
      'Udhampur'
    ],
    'Jharkhand': [
      'Bokaro',
      'Chatra',
      'Deoghar',
      'Dhanbad',
      'Dumka',
      'East Singhbhum',
      'Garhwa',
      'Giridih',
      'Godda',
      'Gumla',
      'Hazaribagh',
      'Jamtara',
      'Khunti',
      'Koderma',
      'Latehar',
      'Lohardaga',
      'Palamu',
      'Ramgarh',
      'Ranchi',
      'Sahibganj',
      'Seraikela-Kharsawan',
      'Simdega',
      'West Singhbhum'
    ],
    'Karnataka': [
      'Bagalkot',
      'Bangalore Rural',
      'Bangalore Urban',
      'Belgaum',
      'Bellary',
      'Bidar',
      'Chamarajanagar',
      'Chikkaballapur',
      'Chikmagalur',
      'Chitradurga',
      'Dakshina Kannada',
      'Davanagere',
      'Dharwad',
      'Gadag',
      'Gulbarga',
      'Hassan',
      'Haveri',
      'Kodagu',
      'Kolar',
      'Koppal',
      'Mandya',
      'Mysore',
      'Raichur',
      'Ramanagara',
      'Shimoga',
      'Tumkur',
      'Udupi',
      'Uttara Kannada',
      'Vijayapura',
      'Vijayanagara',
      'Yadgir'
    ],
    'Kerala': [
      'Alappuzha',
      'Ernakulam',
      'Idukki',
      'Kannur',
      'Kasaragod',
      'Kollam',
      'Kottayam',
      'Kozhikode',
      'Malappuram',
      'Palakkad',
      'Pathanamthitta',
      'Thiruvananthapuram',
      'Thrissur',
      'Wayanad'
    ],
    'Madhya Pradesh': [
      'Agar Malwa',
      'Alirajpur',
      'Anuppur',
      'Ashoknagar',
      'Balaghat',
      'Barwani',
      'Betul',
      'Bhind',
      'Bhopal',
      'Burhanpur',
      'Chhatarpur',
      'Chhindwara',
      'Damoh',
      'Datia',
      'Dewas',
      'Dhar',
      'Dindori',
      'Guna',
      'Gwalior',
      'Harda',
      'Hoshangabad',
      'Indore',
      'Jabalpur',
      'Jhabua',
      'Katni',
      'Khandwa',
      'Khargone',
      'Mandla',
      'Mandsaur',
      'Morena',
      'Narsinghpur',
      'Neemuch',
      'Panna',
      'Raisen',
      'Rajgarh',
      'Ratlam',
      'Rewa',
      'Sagar',
      'Satna',
      'Sehore',
      'Seoni',
      'Shahdol',
      'Shajapur',
      'Sheopur',
      'Shivpuri',
      'Sidhi',
      'Singrauli',
      'Tikamgarh',
      'Ujjain',
      'Umaria',
      'Vidisha',
      'Niwari'
    ],
    'Maharashtra': [
      'Ahmednagar',
      'Akola',
      'Amravati',
      'Aurangabad',
      'Beed',
      'Bhandara',
      'Buldhana',
      'Chandrapur',
      'Dhule',
      'Gadchiroli',
      'Gondia',
      'Hingoli',
      'Jalgaon',
      'Jalna',
      'Kolhapur',
      'Latur',
      'Mumbai City',
      'Mumbai Suburban',
      'Nagpur',
      'Nanded',
      'Nandurbar',
      'Nashik',
      'Osmanabad',
      'Palghar',
      'Parbhani',
      'Pune',
      'Raigad',
      'Ratnagiri',
      'Sangli',
      'Satara',
      'Sindhudurg',
      'Solapur',
      'Thane',
      'Wardha',
      'Washim',
      'Yavatmal'
    ],
    'Manipur': [
      'Bishnupur',
      'Chandel',
      'Churachandpur',
      'Imphal East',
      'Imphal West',
      'Jiribam',
      'Kakching',
      'Kamjong',
      'Kangpokpi',
      'Noney',
      'Pherzawl',
      'Senapati',
      'Tamenglong',
      'Tengnoupal',
      'Thoubal',
      'Ukhrul'
    ],
    'Meghalaya': [
      'East Garo Hills',
      'East Jaintia Hills',
      'East Khasi Hills',
      'North Garo Hills',
      'Ri Bhoi',
      'South Garo Hills',
      'South West Garo Hills',
      'South West Khasi Hills',
      'West Garo Hills',
      'West Jaintia Hills',
      'West Khasi Hills'
    ],
    'Mizoram': [
      'Aizawl',
      'Champhai',
      'Hnahthial',
      'Khawzawl',
      'Kolasib',
      'Lawngtlai',
      'Lunglei',
      'Mamit',
      'Saiha',
      'Saitual',
      'Serchhip'
    ],
    'Nagaland': [
      'Chumoukedima',
      'Dimapur',
      'Kiphire',
      'Kohima',
      'Longleng',
      'Mokokchung',
      'Mon',
      'Niuland',
      'Noklak',
      'Peren',
      'Phek',
      'Shamator',
      'Tseminyu',
      'Tuensang',
      'Wokha',
      'Zunheboto'
    ],
    'Odisha': [
      'Angul',
      'Balangir',
      'Balasore',
      'Bargarh',
      'Bhadrak',
      'Boudh',
      'Cuttack',
      'Deogarh',
      'Dhenkanal',
      'Gajapati',
      'Ganjam',
      'Jagatsinghpur',
      'Jajpur',
      'Jharsuguda',
      'Kalahandi',
      'Kandhamal',
      'Kendrapara',
      'Kendujhar',
      'Khordha',
      'Koraput',
      'Malkangiri',
      'Mayurbhanj',
      'Nabarangpur',
      'Nayagarh',
      'Nuapada',
      'Puri',
      'Rayagada',
      'Sambalpur',
      'Sonepur',
      'Sundargarh'
    ],
    'Punjab': [
      'Amritsar',
      'Barnala',
      'Bathinda',
      'Faridkot',
      'Fatehgarh Sahib',
      'Fazilka',
      'Ferozepur',
      'Gurdaspur',
      'Hoshiarpur',
      'Jalandhar',
      'Kapurthala',
      'Ludhiana',
      'Mansa',
      'Moga',
      'Muktsar',
      'Pathankot',
      'Patiala',
      'Rupnagar',
      'Sahibzada Ajit Singh Nagar',
      'Sangrur',
      'Shahid Bhagat Singh Nagar',
      'Sri Muktsar Sahib',
      'Tarn Taran',
      'Malerkotla'
    ],
    'Rajasthan': [
      'Ajmer',
      'Alwar',
      'Banswara',
      'Baran',
      'Barmer',
      'Bharatpur',
      'Bhilwara',
      'Bikaner',
      'Bundi',
      'Chittorgarh',
      'Churu',
      'Dausa',
      'Dholpur',
      'Dungarpur',
      'Hanumangarh',
      'Jaipur',
      'Jaisalmer',
      'Jalore',
      'Jhalawar',
      'Jhunjhunu',
      'Jodhpur',
      'Karauli',
      'Kota',
      'Nagaur',
      'Pali',
      'Pratapgarh',
      'Rajsamand',
      'Sawai Madhopur',
      'Sikar',
      'Sirohi',
      'Sri Ganganagar',
      'Tonk',
      'Udaipur'
    ],
    'Tamil Nadu': [
      'Ariyalur',
      'Chennai',
      'Coimbatore',
      'Cuddalore',
      'Dharmapuri',
      'Dindigul',
      'Erode',
      'Kanchipuram',
      'Kanyakumari',
      'Karur',
      'Krishnagiri',
      'Madurai',
      'Nagapattinam',
      'Namakkal',
      'Nilgiris',
      'Perambalur',
      'Pudukkottai',
      'Ramanathapuram',
      'Salem',
      'Sivaganga',
      'Thanjavur',
      'Theni',
      'Thoothukudi',
      'Tiruchirappalli',
      'Tirunelveli',
      'Tiruppur',
      'Tiruvallur',
      'Tiruvarur',
      'Vellore',
      'Viluppuram',
      'Virudhunagar'
    ],
    'Telangana': [
      'Adilabad',
      'Hyderabad',
      'Jagtial',
      'Jangaon',
      'Kamareddy',
      'Karimnagar',
      'Khammam',
      'Mahabubabad',
      'Mahabubnagar',
      'Mancherial',
      'Medak',
      'Nalgonda',
      'Nizamabad',
      'Peddapalli',
      'Rangareddy',
      'Sangareddy',
      'Siddipet',
      'Suryapet',
      'Vikarabad',
      'Warangal'
    ],
    'Uttar Pradesh': [
      'Agra',
      'Aligarh',
      'Allahabad',
      'Ambedkar Nagar',
      'Amethi',
      'Amroha',
      'Auraiya',
      'Azamgarh',
      'Baghpat',
      'Bahraich',
      'Ballia',
      'Balrampur',
      'Banda',
      'Barabanki',
      'Bareilly',
      'Basti',
      'Bhadohi',
      'Bijnor',
      'Budaun',
      'Bulandshahr',
      'Chandauli',
      'Chitrakoot',
      'Deoria',
      'Etah',
      'Etawah',
      'Faizabad',
      'Farrukhabad',
      'Fatehpur',
      'Firozabad',
      'Gautam Buddha Nagar',
      'Ghaziabad',
      'Ghazipur',
      'Gonda',
      'Gorakhpur',
      'Hamirpur',
      'Hapur',
      'Hardoi',
      'Hathras',
      'Jalaun',
      'Jaunpur',
      'Jhansi',
      'Kannauj',
      'Kanpur Dehat',
      'Kanpur Nagar',
      'Kasganj',
      'Kaushambi',
      'Kheri',
      'Kushinagar',
      'Lalitpur',
      'Lucknow',
      'Maharajganj',
      'Mahoba',
      'Mainpuri',
      'Mathura',
      'Mau',
      'Meerut',
      'Mirzapur',
      'Moradabad',
      'Muzaffarnagar',
      'Pilibhit',
      'Pratapgarh',
      'Raebareli',
      'Rampur',
      'Saharanpur',
      'Sambhal',
      'Sant Kabir Nagar',
      'Shahjahanpur',
      'Shamli',
      'Shravasti',
      'Siddharthnagar',
      'Sitapur',
      'Sonbhadra',
      'Sultanpur',
      'Unnao',
      'Varanasi',
      'Ayodhya'
    ],
    'Uttarakhand': [
      'Almora',
      'Bageshwar',
      'Chamoli',
      'Champawat',
      'Dehradun',
      'Haridwar',
      'Nainital',
      'Pauri Garhwal',
      'Pithoragarh',
      'Rudraprayag',
      'Tehri Garhwal',
      'Udham Singh Nagar',
      'Uttarkashi'
    ],
    'West Bengal': [
      'Alipurduar',
      'Bankura',
      'Birbhum',
      'Cooch Behar',
      'Dakshin Dinajpur',
      'Darjeeling',
      'Hooghly',
      'Howrah',
      'Jalpaiguri',
      'Jhargram',
      'Kalimpong',
      'Kolkata',
      'Malda',
      'Murshidabad',
      'Nadia',
      'North 24 Parganas',
      'Paschim Bardhaman',
      'Paschim Medinipur',
      'Purba Bardhaman',
      'Purba Medinipur',
      'Purulia',
      'South 24 Parganas',
      'Uttar Dinajpur'
    ],
  };

  static const List<Map<String, dynamic>> commodities = [
    {
      'name': 'Wheat (Kanak)',
      'cat': 'Grains',
      'base': 2150.0,
      'unit': 'Quintal'
    },
    {
      'name': 'Rice (Basmati)',
      'cat': 'Grains',
      'base': 4200.0,
      'unit': 'Quintal'
    },
    {'name': 'Tomato (Desi)', 'cat': 'Vegetables', 'base': 38.0, 'unit': 'Kg'},
    {'name': 'Onion (Red)', 'cat': 'Vegetables', 'base': 32.0, 'unit': 'Kg'},
    {'name': 'Potato (Jyoti)', 'cat': 'Vegetables', 'base': 24.0, 'unit': 'Kg'},
    {
      'name': 'Cotton (Long)',
      'cat': 'Cash Crops',
      'base': 7400.0,
      'unit': 'Quintal'
    },
    {'name': 'Soybean', 'cat': 'Oil Seeds', 'base': 4850.0, 'unit': 'Quintal'},
    {
      'name': 'Mango (Alphonso)',
      'cat': 'Fruits',
      'base': 2200.0,
      'unit': 'Box'
    },
    {'name': 'Apple (Royal)', 'cat': 'Fruits', 'base': 160.0, 'unit': 'Kg'},
    {'name': 'Turmeric', 'cat': 'Spices', 'base': 165.0, 'unit': 'Kg'},
    {'name': 'Cumin (Bold)', 'cat': 'Spices', 'base': 580.0, 'unit': 'Kg'},
    {'name': 'Chickpeas', 'cat': 'Pulses', 'base': 8500.0, 'unit': 'Quintal'},
    {'name': 'Moong Dal', 'cat': 'Pulses', 'base': 7800.0, 'unit': 'Quintal'},
  ];

  /// High-Performance Stateless Big Data Engine - OPTIMIZED FOR INSTANT LOAD
  Future<List<MarketRate>> fetchMarketRates({
    String? state,
    String? district,
    String? query,
    String? category,
  }) async {
    // Zero latency for "Instant" feel
    // results will be synthesized on the fly
    List<MarketRate> synthesized = [];

    // Scoping strategy:
    List<String> statesToScan = (state == null || state == 'All States')
        ? indiaGeography.keys.toList()
        : [state];

    for (var s in statesToScan) {
      List<String> districtsToScan =
          (district == null || district == 'All Districts')
              ? indiaGeography[s] ?? []
              : [district];

      // Control density for performance in Global view
      if (state == null || state == 'All States') {
        districtsToScan = districtsToScan.take(1).toList();
      }

      for (var d in districtsToScan) {
        for (var comm in commodities) {
          // Filters
          if (category != null &&
              category != 'All Categories' &&
              comm['cat'] != category) continue;
          if (query != null && query.isNotEmpty) {
            final q = query.toLowerCase();
            if (!(comm['name'] as String).toLowerCase().contains(q) &&
                !d.toLowerCase().contains(q)) continue;
          }

          final seed = s.hashCode ^ d.hashCode ^ comm['name'].hashCode;
          final rand = Random(seed);

          final base = comm['base'] as double;
          final modal = base * (0.7 + (rand.nextDouble() * 0.6));

          synthesized.add(MarketRate(
            id: 'syn_$seed',
            productName: comm['name'] as String,
            category: comm['cat'] as String,
            state: s,
            district: d,
            market: geoRandName(d, rand),
            minPrice: modal * 0.9,
            maxPrice: modal * 1.1,
            modalPrice: modal,
            priceDate:
                DateTime.now().subtract(Duration(hours: rand.nextInt(24))),
            unit: comm['unit'] as String,
            variety: ['Desi', 'Hybrid', 'Selection'][rand.nextInt(3)],
            grade: ['FAQ', 'A-Grade'][rand.nextInt(2)],
            arrivals: 100 + rand.nextInt(5000),
            qualityScore: 7.0 + (rand.nextDouble() * 3.0),
          ));

          if (synthesized.length > 5000) break;
        }
        if (synthesized.length > 5000) break;
      }
      if (synthesized.length > 5000) break;
    }

    return synthesized;
  }

  static String geoRandName(String district, Random rand) {
    final suffixes = [
      'APMC Hub',
      'Grain Market',
      'Wholesale Yard',
      'Main Mandi',
      'Agri Center'
    ];
    return '$district ${suffixes[rand.nextInt(suffixes.length)]}';
  }

  static Map<String, dynamic> getDynamicDynamics(MarketRate rate) {
    final rand = Random(rate.id.hashCode);
    return {
      'demand': rate.modalPrice > rate.minPrice * 1.15 ? 'Very High' : 'Stable',
      'stock': rate.arrivals < 1500 ? 'Limited' : 'Abundant',
      'quality': rate.qualityScore.toStringAsFixed(1),
      'peakPeriod': '${1 + rand.nextInt(7)} Days',
      'trendMessage': rate.modalPrice > rate.minPrice * 1.15
          ? 'Exceptional demand in ${rate.market}. Strong holding position advised.'
          : 'Healthy stock inflow ensuring consistent regional pricing.',
    };
  }

  static List<Map<String, dynamic>> getTopMandis(MarketRate rate) {
    final rand = Random(rate.productName.hashCode);
    final nearby = indiaGeography[rate.state] ?? ['Regional Hub'];
    return List.generate(3, (i) {
      final district = nearby[rand.nextInt(nearby.length)];
      return {
        'name': '$district APMC',
        'state': rate.state.substring(0, 2).toUpperCase(),
        'price': rate.modalPrice * (1.03 + (rand.nextDouble() * 0.07)),
      };
    });
  }

  Future<List<Map<String, dynamic>>> fetchCommodityHistory(String name,
      {int days = 30}) async {
    final rand = Random(name.hashCode);
    return List.generate(days, (i) {
      final base = 2500.0 + rand.nextInt(1000);
      return {
        'date': DateTime.now().subtract(Duration(days: days - i)),
        'modalPrice': base + (rand.nextDouble() * 250),
      };
    });
  }

  static List<Map<String, dynamic>> getNearbyMandis(MarketRate rate) {
    final rand = Random(rate.id.hashCode ^ 999);
    final nearby = (indiaGeography[rate.state] ?? [])
        .where((d) => d != rate.district)
        .toList();

    // Fallback if no other districts in state
    if (nearby.isEmpty) nearby.add('Regional Hub');

    return List.generate(2, (i) {
      final district = nearby[rand.nextInt(nearby.length)];
      final dist = 5.0 + rand.nextDouble() * 45.0;
      final priceShift = (rand.nextDouble() - 0.4) * (rate.modalPrice * 0.05);

      return {
        'name': '$district APMC Center',
        'price': rate.modalPrice + priceShift,
        'distance': dist.toStringAsFixed(1),
        'arrivals': rand.nextInt(5000) > 3000 ? 'High' : 'Moderate',
        'trusted': '${90 + rand.nextInt(10)}%',
      };
    });
  }

  static List<String> getAvailableStates() {
    final list = indiaGeography.keys.toList();
    list.sort();
    return ['All States', ...list];
  }

  static List<String> getDistrictsForState(String state) {
    if (state == 'All States' || !indiaGeography.containsKey(state))
      return ['All Districts'];
    final list = List<String>.from(indiaGeography[state]!);
    list.sort();
    return ['All Districts', ...list];
  }

  static List<String> getAvailableCategories() {
    final list = commodities.map((e) => e['cat'] as String).toSet().toList();
    list.sort();
    return ['All Categories', ...list];
  }
}
