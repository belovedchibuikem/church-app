import '../api/app_failure.dart';

typedef JsonObject = Map<String, Object?>;

abstract interface class AuthRepository {
  Future<AppResult<JsonObject>> signIn(JsonObject credentials);
  Future<AppResult<JsonObject>> register(JsonObject registration);
  Future<AppResult<void>> requestPasswordReset(String email);
  Future<AppResult<void>> resetPassword(JsonObject payload);
  Future<AppResult<void>> verify(JsonObject challenge);
  Future<AppResult<void>> signOut();

  /// Leaves stored tokens on the device so fingerprint can unlock next time.
  Future<AppResult<void>> lockSession();

  Future<AppResult<JsonObject>> restoreSession();
}

abstract interface class ProfileRepository {
  Future<AppResult<JsonObject>> getProfile();
  Future<AppResult<JsonObject>> updateProfile(JsonObject changes);
  Future<AppResult<JsonObject>> getDashboard();
}

abstract interface class ChurchRepository {
  Future<AppResult<List<JsonObject>>> searchChurches(JsonObject filters);
  Future<AppResult<JsonObject>> getChurch(String id);
  Future<AppResult<void>> requestMembership(
    String churchId, {
    bool confirmTransfer = false,
    String? homeChurchId,
  });
  Future<AppResult<void>> joinHomeChurch(
    String homeChurchId, {
    bool confirmTransfer = false,
  });
  Future<AppResult<List<JsonObject>>> listMemberships();
  Future<AppResult<List<JsonObject>>> listChurchMembers(String churchId);
  Future<AppResult<List<JsonObject>>> listGroups();
  Future<AppResult<void>> joinGroup(String groupId);
  Future<AppResult<void>> leaveGroup(String groupId);
  Future<AppResult<List<JsonObject>>> listAnnouncements();
  Future<AppResult<List<JsonObject>>> listDocuments();
}

abstract interface class HomeChurchRepository {
  Future<AppResult<JsonObject>> getDashboard(String id);
  Future<AppResult<JsonObject>> submitApplication(JsonObject application);
  Future<AppResult<void>> submitReport(JsonObject report);
}

abstract interface class MissionRepository {
  Future<AppResult<List<JsonObject>>> getCrusades(JsonObject filters);
  Future<AppResult<JsonObject>> getSoul(String id);
  Future<AppResult<JsonObject>> createSoul(JsonObject soul);
  Future<AppResult<void>> assignMentor(String soulId, String mentorId);
  Future<AppResult<JsonObject>> recordFollowUp(String soulId, JsonObject body);
  Future<AppResult<JsonObject>> completeFollowUp(
    String soulId, [
    JsonObject body = const {},
  ]);
}

abstract interface class KcaRepository {
  Future<AppResult<JsonObject>> getAccess();
  Future<AppResult<JsonObject>> getDashboard();
  Future<AppResult<JsonObject>> getOrientation();
  Future<AppResult<JsonObject>> completeOrientationStage(String stage);
  Future<AppResult<JsonObject>> completeOrientation();
  Future<AppResult<JsonObject>> getPracticalService();
  Future<AppResult<List<JsonObject>>> listModules();
  Future<AppResult<JsonObject>> getModule(String moduleId);
  Future<AppResult<JsonObject>> evaluateModulePrerequisites(String moduleId);
  Future<AppResult<List<JsonObject>>> listAssignments();
  Future<AppResult<JsonObject>> getMentor();
  Future<AppResult<List<JsonObject>>> listAttendance();
  Future<AppResult<JsonObject>> submitEvidence(JsonObject evidence);
  Future<AppResult<JsonObject>> getLesson(String lessonId);
  Future<AppResult<JsonObject>> completeLesson(
    String lessonId, {
    bool acknowledged = true,
    String? idempotencyKey,
    String? unlockToken,
  });
  Future<AppResult<JsonObject>> getChapter(String chapterId);
  Future<AppResult<JsonObject>> completeChapter(
    String chapterId, {
    bool acknowledged = true,
    String? idempotencyKey,
    String? unlockToken,
  });
  Future<AppResult<JsonObject>> getAssignment(String assignmentId);
  Future<AppResult<JsonObject>> recordSoulWin(String assignmentId, JsonObject body);
  Future<AppResult<List<JsonObject>>> listMentees();
  Future<AppResult<JsonObject>> getMentee(String enrollmentId);
  Future<AppResult<JsonObject>> createNote(JsonObject body);
  Future<AppResult<void>> syncQueuedCompletions();
  Future<AppResult<JsonObject>> getCurrentApplication();
  Future<AppResult<JsonObject>> getAdmissionLetter();
  Future<AppResult<JsonObject>> downloadAdmissionLetter();
  Future<AppResult<String>> uploadAdmissionSignature({
    required List<int> bytes,
    String filename,
  });
  Future<AppResult<JsonObject>> acceptAdmissionLetter(JsonObject body);
  Future<AppResult<JsonObject>> submitApplication(
    JsonObject applicationData, {
    bool finalize = true,
  });
  Future<AppResult<JsonObject>> verifyCertificate(String code);
  Future<AppResult<List<JsonObject>>> listDirectory(JsonObject filters);
  Future<AppResult<void>> follow(String personId);
  Future<AppResult<void>> unfollow(String personId);
  Future<AppResult<List<JsonObject>>> listFollowing();
}

abstract interface class PressRepository {
  Future<AppResult<List<JsonObject>>> search(JsonObject filters);
  Future<AppResult<JsonObject>> getPublication(String id);
  Future<AppResult<JsonObject>> download(String id);
  Future<AppResult<JsonObject>> uploadAdminFile({
    required List<int> bytes,
    required String filename,
    String purpose = 'press_content',
    String classification = 'internal',
  });
  Future<AppResult<JsonObject>> createPublication(JsonObject body);
}

abstract interface class EventRepository {
  Future<AppResult<List<JsonObject>>> list(JsonObject filters);
  Future<AppResult<JsonObject>> get(String id);
  Future<AppResult<JsonObject>> register(String eventId, JsonObject attendee);
  Future<AppResult<JsonObject>> getTicket(String registrationId);
  Future<AppResult<List<JsonObject>>> listMyRegistrations({
    String when = 'all',
  });
  Future<AppResult<JsonObject>> recordFeedback(
    String registrationId,
    int rating,
  );
}

abstract interface class PrayerRepository {
  Future<AppResult<List<JsonObject>>> listOwn();
  Future<AppResult<JsonObject>> create(JsonObject request);
}

abstract interface class NeedRepository {
  Future<AppResult<List<JsonObject>>> listOwn();
  Future<AppResult<JsonObject>> create(JsonObject request);
}

abstract interface class TestimonyRepository {
  Future<AppResult<List<JsonObject>>> listOwn();
  Future<AppResult<JsonObject>> create(JsonObject request);
}

abstract interface class PaymentRepository {
  Future<AppResult<List<JsonObject>>> listIntents();
  Future<AppResult<JsonObject>> getIntent(String id);
  Future<AppResult<List<JsonObject>>> listTransactions();
  Future<AppResult<JsonObject>> initiate(JsonObject payment);
  /// Completes a local_manual giving intent. Hosted Paystack/Flutterwave/Stripe
  /// checkout is completed by the provider webhook, then polled via [getIntent].
  Future<AppResult<JsonObject>> completeGivingIntent(
    String intentId, {
    String? proofFileAssetId,
  });
  Future<AppResult<JsonObject>> uploadPaymentProof({
    required List<int> bytes,
    required String filename,
  });
  Future<AppResult<JsonObject>> initiateEventPayment(String registrationId);
  Future<AppResult<JsonObject>> getConfiguration();
  Future<AppResult<JsonObject>> getTransaction(String id);
  Future<AppResult<JsonObject>> getReceipt(String id);
}

abstract interface class MessageRepository {
  Future<AppResult<List<JsonObject>>> conversations();
  Future<AppResult<List<JsonObject>>> messages(String conversationId);
  Future<AppResult<JsonObject>> createConversation(JsonObject body);
  Future<AppResult<JsonObject>> send(String conversationId, JsonObject message);
}

abstract interface class NotificationRepository {
  Future<AppResult<List<JsonObject>>> list();
  Future<AppResult<JsonObject>> markRead(String notificationId);
  Future<AppResult<JsonObject>> resolveDestination(String notificationId);
}

abstract interface class BibleRepository {
  Future<AppResult<JsonObject>> books({String? version});
  Future<AppResult<JsonObject>> chapter(
    String book,
    int chapter, {
    String? version,
  });
  Future<AppResult<JsonObject>> search(String query, {String? version});
  Future<AppResult<List<JsonObject>>> plans();
  Future<AppResult<JsonObject>> progress();
  Future<AppResult<JsonObject>> enroll(String planCode, {int? durationDays});
  Future<AppResult<JsonObject>> completeDay(String enrollmentId, int day);
  Future<AppResult<JsonObject>> savePosition(String book, int chapter);
}

abstract interface class SecurityRepository {
  Future<AppResult<List<JsonObject>>> sessions();
  Future<AppResult<void>> revokeSession(String id);
  Future<AppResult<void>> updateConsent(String id, bool granted);
}
