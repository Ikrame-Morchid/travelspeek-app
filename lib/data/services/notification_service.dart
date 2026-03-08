import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static const String _notificationKey = 'notifications_enabled';

  Future<void> initialize() async {
    // Initialiser les fuseaux horaires
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Casablanca'));

    // Configuration Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Callback pour iOS < 10
      },
    );

    // Configuration générale
    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _onNotificationTapped(response);
      },
    );

    // Demander les permissions
    await _requestPermissions();
  }

  // ========================
  // 🔔 DEMANDER LES PERMISSIONS
  // ========================
  Future<void> _requestPermissions() async {
    // Android 13+
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // iOS
    final iosImplementation = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationKey, enabled);

    if (enabled) {
      // Activer - Programmer les notifications quotidiennes
      await _scheduleDailyNotifications();
    } else {
      // Désactiver - Annuler toutes les notifications
      await cancelAllNotifications();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationKey) ?? true;
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'travelspeek_channel',
      'TravelSpeek Notifications',
      channelDescription: 'Notifications pour les monuments et traductions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }


  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'travelspeek_channel',
      'TravelSpeek Notifications',
      channelDescription: 'Notifications pour les monuments et traductions',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> _scheduleDailyNotifications() async {
    // Notification du matin (9h00)
    await _scheduleDailyNotificationAt(
      id: 1,
      hour: 9,
      minute: 0,
      title: ' Découvrez un nouveau monument !',
      body: 'Explorez l\'histoire du Maroc aujourd\'hui',
    );

    // Notification de l'après-midi (15h00)
    await _scheduleDailyNotificationAt(
      id: 2,
      hour: 15,
      minute: 0,
      title: 'Pratiquez vos traductions !',
      body: 'Essayez de traduire quelque chose de nouveau',
    );

    // Notification du soir (20h00)
    await _scheduleDailyNotificationAt(
      id: 3,
      hour: 20,
      minute: 0,
      title: 'Vos monuments favoris',
      body: 'Avez-vous ajouté un favori aujourd\'hui ?',
    );
  }

  Future<void> _scheduleDailyNotificationAt({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Si l'heure est déjà passée aujourd'hui, programmer pour demain
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'travelspeek_daily',
      'Daily Reminders',
      channelDescription: 'Rappels quotidiens TravelSpeek',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ========================
  // ANNULER UNE NOTIFICATION
  // ========================
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // ========================
  // ANNULER TOUTES LES NOTIFICATIONS
  // ========================
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // ========================
  // QUAND L'UTILISATEUR TAPE SUR UNE NOTIFICATION
  // ========================
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    
    if (payload != null) {
      print('Notification tapped with payload: $payload');
    }
  }

  // ========================
  // NOTIFICATIONS SPÉCIFIQUES
  // ========================
  
  /// Notification quand un monument est ajouté aux favoris
  Future<void> showFavoriteAddedNotification(String monumentName) async {
    await showNotification(
      id: 100,
      title: 'Monument ajouté aux favoris',
      body: '$monumentName a été ajouté à vos favoris',
      payload: 'favorites',
    );
  }

  /// Notification après une traduction réussie
  Future<void> showTranslationSuccessNotification() async {
    await showNotification(
      id: 101,
      title: 'Traduction réussie',
      body: 'Votre texte a été traduit avec succès',
      payload: 'translation',
    );
  }

  /// Notification de bienvenue
  Future<void> showWelcomeNotification() async {
    await showNotification(
      id: 102,
      title: 'Bienvenue sur TravelSpeek !',
      body: 'Découvrez les monuments du Maroc et traduisez en temps réel',
      payload: 'welcome',
    );
  }

  /// Notification de rappel d'exploration
  Future<void> scheduleExplorationReminder() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final reminderTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);

    await scheduleNotification(
      id: 103,
      title: 'Continuez votre exploration !',
      body: 'Découvrez de nouveaux monuments aujourd\'hui',
      scheduledDate: reminderTime,
      payload: 'monuments',
    );
  }
}