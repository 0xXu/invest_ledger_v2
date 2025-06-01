import 'package:http/http.dart' as http;

class StockInfoService {
  static final Map<String, String> _stockNameCache = {
    // A股常见股票代码和名称映射
    '000001': '平安银行',
    '000002': '万科A',
    '000858': '五粮液',
    '002735': '王子新材',
    '002536': '飞龙股份',
    '600000': '浦发银行',
    '600036': '招商银行',
    '600519': '贵州茅台',
    '600887': '伊利股份',
  };

  /// 获取股票名称
  /// 优先从缓存获取，如果没有则尝试从API获取
  static Future<String> getStockName(String stockCode) async {
    // 首先检查缓存
    if (_stockNameCache.containsKey(stockCode)) {
      return _stockNameCache[stockCode]!;
    }

    // 尝试从API获取（这里可以集成真实的股票API）
    try {
      // 这里可以调用真实的股票信息API
      // 例如：新浪财经、腾讯财经等免费API
      final stockName = await _fetchStockNameFromAPI(stockCode);
      if (stockName != null && stockName.isNotEmpty) {
        return stockName;
      }
    } catch (e) {
      // API调用失败，继续使用默认逻辑
    }

    // 如果都没有找到，返回股票代码本身
    return stockCode;
  }

  /// 从API获取股票名称（示例实现）
  static Future<String?> _fetchStockNameFromAPI(String stockCode) async {
    try {
      // 这里可以实现真实的API调用
      // 例如调用新浪财经API或其他免费股票信息API

      // 示例：使用新浪财经API（需要根据实际情况调整）
      final url = 'https://hq.sinajs.cn/list=$stockCode';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Referer': 'https://finance.sina.com.cn',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final content = response.body;
        // 解析新浪财经返回的数据
        final regex = RegExp(r'var hq_str_\w+="([^"]+)"');
        final match = regex.firstMatch(content);

        if (match != null) {
          final data = match.group(1)?.split(',');
          if (data != null && data.isNotEmpty) {
            return data[0]; // 股票名称通常在第一个位置
          }
        }
      }
    } catch (e) {
      // 网络错误或解析错误，返回null
      return null;
    }

    return null;
  }

  /// 验证股票代码格式
  static bool isValidStockCode(String stockCode) {
    // A股股票代码格式：6位数字
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(stockCode);
  }

  /// 根据股票代码判断交易所
  static String getExchange(String stockCode) {
    if (!isValidStockCode(stockCode)) {
      return 'Unknown';
    }

    final code = stockCode.substring(0, 3);
    switch (code) {
      case '000':
      case '001':
      case '002':
      case '003':
        return '深交所';
      case '600':
      case '601':
      case '603':
      case '605':
        return '上交所';
      case '688':
        return '科创板';
      case '300':
        return '创业板';
      default:
        return 'Unknown';
    }
  }

  /// 添加股票名称到缓存
  static void addToCache(String stockCode, String stockName) {
    // 注意：这里只是内存缓存，应用重启后会丢失
    // 如果需要持久化，可以使用SharedPreferences或数据库
    _stockNameCache[stockCode] = stockName;
  }
}
