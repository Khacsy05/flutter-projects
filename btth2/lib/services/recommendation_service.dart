import 'dart:math';
import 'package:btth1/models/cloud_document.dart';
import 'package:btth1/models/user_preference.dart';

class RecommendationResult {
  final CloudDoc document;
  final double score; // 0.0 -> 1.0
  final int matchPercentage; // 0 -> 100%
  final List<String> matchingReasons;
  final List<String> matchedTags;

  RecommendationResult({
    required this.document,
    required this.score,
    required this.matchPercentage,
    required this.matchingReasons,
    required this.matchedTags,
  });
}

class RecommendationService {
  /// Thuật toán Recommendation tính toán độ tương đồng giữa tài liệu và hồ sơ sở thích
  static List<RecommendationResult> computeRecommendations({
    required List<CloudDoc> allDocuments,
    required UserPreference preference,
    String? currentUserId,
    int limit = 10,
  }) {
    final List<RecommendationResult> results = [];

    final userTags = preference.favoriteTags.map((e) => e.toLowerCase().trim()).toSet();
    final userCourses = preference.preferredCourses.map((e) => e.toLowerCase().trim()).toSet();

    for (final doc in allDocuments) {
      // Bỏ qua tài liệu do chính user sở hữu nếu muốn gợi ý tài liệu từ cộng đồng/người khác,
      // hoặc vẫn cho phép gợi ý nếu kho tài liệu ít người.
      // Ưu tiên cao hơn cho tài liệu chưa đọc hoặc của người khác.

      final docTags = doc.tags.map((e) => e.toLowerCase().trim()).toSet();
      final docCourse = doc.courseName.toLowerCase().trim();

      // 1. Tag Similarity (Jaccard Index)
      final intersectionTags = docTags.intersection(userTags);
      final unionTags = docTags.union(userTags);
      double tagScore = unionTags.isEmpty ? 0.0 : (intersectionTags.length / unionTags.length);

      // Nếu không trùng tags trực tiếp, kiểm tra tiêu đề và ghi chú xem có chứa từ khóa sở thích không
      if (tagScore == 0.0) {
        final contentText = '${doc.title} ${doc.note}'.toLowerCase();
        int keywordMatches = 0;
        for (final tag in userTags) {
          if (contentText.contains(tag)) {
            keywordMatches++;
          }
        }
        if (keywordMatches > 0) {
          tagScore = min(0.4, keywordMatches * 0.15);
        }
      }

      // 2. Course Affinity Match
      double courseScore = userCourses.contains(docCourse) ? 1.0 : 0.0;

      // 3. Historical Interaction Weight
      double interactionScore = 0.0;
      if (preference.tagInteractions.isNotEmpty) {
        int interactionHits = 0;
        for (final tag in docTags) {
          interactionHits += preference.tagInteractions[tag] ?? 0;
        }
        interactionScore = min(1.0, interactionHits / 5.0);
      }

      // 4. Recency Decay Score (Tài liệu mới hơn được ưu tiên nhẹ)
      final daysOld = DateTime.now().difference(doc.updatedAt).inDays;
      final double recencyScore = 1.0 / (1.0 + log(1.0 + max(0, daysOld)));

      // 5. Tổng hợp trọng số (Weights: Tag 45%, Course 30%, History 15%, Recency 10%)
      double finalScore = (0.45 * tagScore) +
          (0.30 * courseScore) +
          (0.15 * interactionScore) +
          (0.10 * recencyScore);

      // Đưa về dải 0.0 -> 1.0
      finalScore = finalScore.clamp(0.0, 1.0);

      // Phân tích lý do đề xuất
      final List<String> reasons = [];
      if (intersectionTags.isNotEmpty) {
        reasons.add('Trùng khớp ${intersectionTags.length} thẻ sở thích (#${intersectionTags.take(3).join(', #')})');
      }
      if (courseScore > 0) {
        reasons.add('Môn học trong danh sách quan tâm: ${doc.courseName}');
      }
      if (interactionScore > 0.3) {
        reasons.add('Dựa trên thói quen đọc tài liệu gần đây');
      }
      if (doc.isPhysical && doc.locationName != null) {
        reasons.add('Tài liệu có sẵn tại ${doc.locationName}');
      }
      if (reasons.isEmpty) {
        reasons.add('Gợi ý phổ biến phù hợp với ngành học');
      }

      final matchPercent = (finalScore * 100).round();

      // Chỉ thêm nếu có độ tương đồng tối thiểu (>10%)
      if (finalScore >= 0.10) {
        results.add(RecommendationResult(
          document: doc,
          score: finalScore,
          matchPercentage: matchPercent,
          matchingReasons: reasons,
          matchedTags: intersectionTags.toList(),
        ));
      }
    }

    // Sắp xếp giảm dần theo điểm số gợi ý
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.take(limit).toList();
  }
}
