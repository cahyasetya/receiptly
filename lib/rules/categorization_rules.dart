import '../models/expense_category.dart';

final Map<ExpenseCategory, List<String>> categoryKeywords = {
  ExpenseCategory.ipl: [
    'ipl', 'ipp', 'pengelolaan', 'service charge', 'maintenance',
  ],
  ExpenseCategory.listrik: [
    'listrik', 'pln', 'token listrik', 'meterai',
  ],
  ExpenseCategory.air: [
    'air', 'pdam', 'pam', 'air minum',
  ],
  ExpenseCategory.wifi: [
    'wifi', 'internet', 'indihome', 'first media', 'm3', 'telkom',
    'my republic', 'orbit', 'byu', 'starlink',
  ],
  ExpenseCategory.groceries: [
    'sabun', 'sabun cuci piring', 'sabun cuci baju', 'sabun toilet',
    'pewangi', 'sabun lantai', 'galon', 'aqua', 'gas', 'elpiji',
    'bright gas', 'upin', 'piring', 'kulkas', 'pembersih', 'lap',
    'spons', 'sikat', 'sapu', 'pel', 'kantong', 'plastik', 'detergen',
    'pelembut', 'pemutih', 'pengharum', 'penghilang',
    'deterjen', 'rinso', 'attack', 'so klin', 'molto', 'downy',
    'sunlight', 'mama lemon', 'cip', 'betadine', 'antiseptik',
  ],
  ExpenseCategory.buah: [
    'buah', 'apel', 'jeruk', 'pisang', 'anggur', 'mangga', 'semangka',
    'melon', 'nanas', 'pepaya', 'salak', 'rambutan', 'duku',
    'stroberi', 'blueberi', 'kiwi', 'alpukat', 'kelapa',
  ],
  ExpenseCategory.bahanMakanan: [
    'beras', 'telur', 'minyak', 'gula', 'terigu', 'mie instan',
    'indomie', 'sarden', 'kornet', 'kecap', 'saos', 'saus',
    'bumbu', 'bawang', 'cabai', 'tomat', 'kentang', 'wortel',
    'kol', 'bayam', 'kangkung', 'tahu', 'tempe', 'daging',
    'ayam', 'ikan', 'udang', 'cumi', 'kerupuk', 'tepung',
    'susu', 'keju', 'mentega', 'margarin', 'ragi', 'fermipan',
    'minuman', 'teh', 'kopi', 'gula pasir', 'gula merah',
    'kacang', 'tahu putih', 'tahu kuning', 'bakso', 'pangsit',
    'siomay', 'cokelat', 'biskuit', 'wafer', 'roti',
  ],
  ExpenseCategory.laundry: [
    'laundry', 'cuci', 'setrika', 'dry clean', 'dryclean', 'ckg',
  ],
  ExpenseCategory.makanan: [
    'mcdonald', 'burger', 'starbucks', 'coffee', 'cafe', 'restaurant',
    'pizza', 'kfc', 'subway', 'bakery', 'donut', 'soto', 'bakso', 'nasi',
    'mie', 'ayam', 'sate', 'gorengan', 'warteg', 'kantin', 'kopi',
    'teh', 'jus', 'minuman', 'camilan', 'snack', 'roti', 'kue',
    'gojek', 'grabfood', 'shopeefood', 'gofood',
    'makan', 'sarapan', 'makan siang', 'makan malam',
  ],
  ExpenseCategory.transportasi: [
    'bensin', 'pertalite', 'pertamax', 'solar', 'angkot', 'ojek',
    'gojek', 'gocar', 'grabcar', 'grabbike', 'taxi', 'taksi',
    'toll', 'tol', 'parkir', 'bahan bakar', 'bbm', 'spbu',
    'bus', 'transjakarta', 'krl', 'mrt', 'lrt', 'kereta',
    'pesawat', 'tiket pesawat', 'tiket',
  ],
  ExpenseCategory.rekreasi: [
    'bioskop', 'xxi', 'cgv', 'nonton', 'konser', 'liburan', 'wisata',
    'museum', 'zoo', 'taman', 'pantai', 'gunung', 'hotel', 'penginapan',
    'game', 'steam', 'playstation', 'netflix', 'spotify', 'hiburan',
  ],
  ExpenseCategory.takTerduga: [
    'darurat', 'medis', 'obat', 'apotek', 'dokter', 'klinik', 'rs',
    'perbaikan', 'service', 'bengkel', 'tambal ban',
  ],
  ExpenseCategory.tabunganApart: [
    'tabungan apart', 'tab apart', 'apartemen', 'dp apart',
  ],
  ExpenseCategory.skincare: [
    'skincare', 'make up', 'makeup', 'face wash', 'moisturizer',
    'sunscreen', 'serum', 'toner', 'lipstick', 'foundation',
    'bedak', 'maskara', 'eyeliner', 'blush on', 'wardah',
    'ponds', 'garnier', 'the originote', 'avoskin', 'skintific',
    'somethinc', 'cosrx', 'innisfree', 'nature republic',
  ],
  ExpenseCategory.pakaian: [
    'baju', 'pakaian', 'celana', 'rok', 'dress', 'gaun', 'kemeja',
    'kaos', 'jaket', 'sweater', 'hoodie', 'jeans', 'kain',
    'seragam', 'batik', 'sarung', 'jilbab', 'hijab', 'sepatu',
    'sandal', 'tas', 'dompet', 'topi', 'ikat pinggang',
    'h&m', 'zara', 'uniqlo', 'adidas', 'nike', 'puma',
  ],
};

final Map<ExpenseCategory, List<RegExp>> categoryRegex = {
  ExpenseCategory.laundry: [
    RegExp(r'CKG', caseSensitive: false),
    RegExp(r'Laundry\s+Kilat', caseSensitive: false),
    RegExp(r'Cuci\s+(Kering|Basah|Setrika|Lipat)', caseSensitive: false),
  ],
  ExpenseCategory.makanan: [
    RegExp(r'Makan\s+Siang|Makan\s+Malam|Sarapan', caseSensitive: false),
  ],
  ExpenseCategory.transportasi: [
    RegExp(r'TRX\s+\d', caseSensitive: false),
    RegExp(r'Taxi|Taksi', caseSensitive: false),
  ],
};

final Map<ExpenseCategory, List<RegExp>> categoryExclusions = {
  ExpenseCategory.makanan: [
    RegExp(r'CKG', caseSensitive: false),
  ],
};
