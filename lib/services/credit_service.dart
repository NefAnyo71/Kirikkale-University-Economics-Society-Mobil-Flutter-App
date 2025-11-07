import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreditService {
  static const int CREDIT_PER_DOWNLOAD = 1;
  static const int CREDIT_PER_SHARE = 5;
  static const int FREE_DOWNLOAD_LIMIT = 3;
  static const int CREDIT_PER_AD = 1; // 5 reklam = 1 kredi
  static const int CREDIT_PER_LIKE = 1; // 10 beğeni = 1 kredi
  static const int CREDIT_LOSS_PER_DISLIKE = 1; // 10 beğenmeme = -1 kredi

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı kredi bilgilerini getir
  static Future<Map<String, dynamic>> getUserCredits(String userEmail) async {
    try {
      final doc = await _firestore.collection('user_credits').doc(userEmail).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'totalCredits': data['totalCredits'] ?? FREE_DOWNLOAD_LIMIT,
          'usedCredits': data['usedCredits'] ?? 0,
          'availableCredits': (data['totalCredits'] ?? FREE_DOWNLOAD_LIMIT) - (data['usedCredits'] ?? 0),
          'totalShares': data['totalShares'] ?? 0,
          'totalDownloads': data['totalDownloads'] ?? 0,
          'adsWatched': data['adsWatched'] ?? 0,
          'likesReceived': data['likesReceived'] ?? 0,
          'dislikesReceived': data['dislikesReceived'] ?? 0,
        };
      } else {
        // İlk kez kullanıcı - başlangıç kredisi ver
        await _firestore.collection('user_credits').doc(userEmail).set({
          'totalCredits': FREE_DOWNLOAD_LIMIT,
          'usedCredits': 0,
          'totalShares': 0,
          'totalDownloads': 0,
          'adsWatched': 0,
          'likesReceived': 0,
          'dislikesReceived': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        return {
          'totalCredits': FREE_DOWNLOAD_LIMIT,
          'usedCredits': 0,
          'availableCredits': FREE_DOWNLOAD_LIMIT,
          'totalShares': 0,
          'totalDownloads': 0,
          'adsWatched': 0,
          'likesReceived': 0,
          'dislikesReceived': 0,
        };
      }
    } catch (e) {
      print('Kredi bilgisi alınırken hata: $e');
      return {
        'totalCredits': 0,
        'usedCredits': 0,
        'availableCredits': 0,
        'totalShares': 0,
        'totalDownloads': 0,
        'adsWatched': 0,
        'likesReceived': 0,
        'dislikesReceived': 0,
      };
    }
  }

  // Reklam izleme kredisi ekle
  static Future<bool> addCreditsForAd(String userEmail) async {
    try {
      final docRef = _firestore.collection('user_credits').doc(userEmail);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final currentAdsWatched = data['adsWatched'] ?? 0;
          final newAdsWatched = currentAdsWatched + 1;
          
          // Her 5 reklam için 1 kredi
          if (newAdsWatched % 5 == 0) {
            transaction.update(docRef, {
              'totalCredits': FieldValue.increment(CREDIT_PER_AD),
              'adsWatched': newAdsWatched,
              'lastAdWatchedAt': FieldValue.serverTimestamp(),
            });
          } else {
            transaction.update(docRef, {
              'adsWatched': newAdsWatched,
              'lastAdWatchedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      });
      
      return true;
    } catch (e) {
      print('Reklam kredisi eklenirken hata: $e');
      return false;
    }
  }

  // Beğeni kredisi ekle
  static Future<bool> addCreditsForLike(String userEmail) async {
    try {
      final docRef = _firestore.collection('user_credits').doc(userEmail);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final currentLikes = data['likesReceived'] ?? 0;
          final newLikes = currentLikes + 1;
          
          // Her 10 beğeni için 1 kredi
          if (newLikes % 10 == 0) {
            transaction.update(docRef, {
              'totalCredits': FieldValue.increment(CREDIT_PER_LIKE),
              'likesReceived': newLikes,
            });
          } else {
            transaction.update(docRef, {
              'likesReceived': newLikes,
            });
          }
        }
      });
      
      return true;
    } catch (e) {
      print('Beğeni kredisi eklenirken hata: $e');
      return false;
    }
  }

  // Beğenmeme kredisi çıkar
  static Future<bool> removeCreditsForDislike(String userEmail) async {
    try {
      final docRef = _firestore.collection('user_credits').doc(userEmail);
      
      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final currentDislikes = data['dislikesReceived'] ?? 0;
          final newDislikes = currentDislikes + 1;
          
          // Her 10 beğenmeme için -1 kredi
          if (newDislikes % 10 == 0) {
            final currentTotal = data['totalCredits'] ?? 0;
            if (currentTotal > 0) {
              transaction.update(docRef, {
                'totalCredits': FieldValue.increment(-CREDIT_LOSS_PER_DISLIKE),
                'dislikesReceived': newDislikes,
              });
            } else {
              transaction.update(docRef, {
                'dislikesReceived': newDislikes,
              });
            }
          } else {
            transaction.update(docRef, {
              'dislikesReceived': newDislikes,
            });
          }
        }
      });
      
      return true;
    } catch (e) {
      print('Beğenmeme kredisi çıkarılırken hata: $e');
      return false;
    }
  }

  // Not paylaşım kredisi ekle
  static Future<bool> addCreditsForShare(String userEmail) async {
    try {
      await _firestore.collection('user_credits').doc(userEmail).update({
        'totalCredits': FieldValue.increment(CREDIT_PER_SHARE),
        'totalShares': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      print('Paylaşım kredisi eklenirken hata: $e');
      return false;
    }
  }

  // İndirme için kredi kullan
  static Future<bool> useCreditsForDownload(String userEmail) async {
    try {
      final docRef = _firestore.collection('user_credits').doc(userEmail);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final totalCredits = data['totalCredits'] ?? 0;
          final usedCredits = data['usedCredits'] ?? 0;
          final availableCredits = totalCredits - usedCredits;
          
          if (availableCredits >= CREDIT_PER_DOWNLOAD) {
            transaction.update(docRef, {
              'usedCredits': FieldValue.increment(CREDIT_PER_DOWNLOAD),
              'totalDownloads': FieldValue.increment(1),
            });
            return true;
          }
        }
        return false;
      });
    } catch (e) {
      print('Kredi kullanılırken hata: $e');
      return false;
    }
  }

  // Kullanıcının indirme yapıp yapamayacağını kontrol et
  static Future<bool> canUserDownload(String userEmail) async {
    try {
      final credits = await getUserCredits(userEmail);
      return credits['availableCredits'] >= CREDIT_PER_DOWNLOAD;
    } catch (e) {
      print('İndirme kontrolü yapılırken hata: $e');
      return false;
    }
  }

  // Reklam izleme sayısını getir
  static Future<int> getAdsWatchedCount(String userEmail) async {
    try {
      final doc = await _firestore.collection('user_credits').doc(userEmail).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['adsWatched'] ?? 0;
      }
      return 0;
    } catch (e) {
      print('Reklam sayısı alınırken hata: $e');
      return 0;
    }
  }

  // Tüm kullanıcıların kredi bilgilerini getir
  static Future<List<Map<String, dynamic>>> getAllUserCredits() async {
    try {
      final snapshot = await _firestore.collection('user_credits').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userEmail': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Tüm kullanıcı kredileri alınırken hata: $e');
      return [];
    }
  }

  // Kullanıcı kredilerini manuel senkronize et
  static Future<bool> syncUserCreditsManually(String userEmail) async {
    try {
      // Kullanıcının mevcut kredi bilgilerini yeniden hesapla
      final credits = await getUserCredits(userEmail);
      return true;
    } catch (e) {
      print('Kredi senkronizasyonu yapılırken hata: $e');
      return false;
    }
  }
}