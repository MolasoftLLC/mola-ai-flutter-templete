import 'package:shared_preferences/shared_preferences.dart';

class AdCounterService {
  static const String _counterKey = 'ad_search_counter';
  
  static Future<bool> shouldShowAd() async {
    final prefs = await SharedPreferences.getInstance();
    
    int currentCounter = prefs.getInt(_counterKey) ?? 0;
    
    currentCounter++;
    
    await prefs.setInt(_counterKey, currentCounter);
    
    bool shouldShow = currentCounter % 3 == 0;
    
    print('AdCounterService: counter=$currentCounter, shouldShowAd=$shouldShow');
    
    return shouldShow;
  }
  
  static Future<int> getCurrentCounter() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_counterKey) ?? 0;
  }
  
  static Future<void> resetCounter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_counterKey);
    print('AdCounterService: counter reset');
  }
}
