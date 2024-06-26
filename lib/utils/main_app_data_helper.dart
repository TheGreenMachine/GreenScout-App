import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dart_ipify/dart_ipify.dart';
import 'package:flutter/material.dart';
import 'package:green_scout/main.dart';
import 'package:green_scout/pages/leaderboard.dart';
import 'package:green_scout/utils/achievement_manager.dart';
import 'package:green_scout/utils/app_state.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

/// A helper class that simplifies accessing important data for the application.
/// 
/// It acts like a wrapper around the app state and provides a interface to the
/// stored data within App's shared preferences.
/// 
/// Additionally, it contains logic related to maintaing match cache and achievement
/// unlocking.
class MainAppData {
  static const _scouterKey = "Scouter";
  static const _displayNameKey = "Display Name";
  static const _loginStatusKey = "Logged In";
  static const _userRoleKey = "User Role";
  static const _adminStatusKey = "Admin";
  static const _teamVerifiedKey = "Verified";
  static const _userCertificateKey = "User Certificate";
  static const _userUUIDKey = "User UUID";
  static const _allTimeMatchCacheKey = "Match JSONS";
  static const _tempMatchCacheKey = "TEMP Match JSONS";
  static const _userLifeScore = "User Life Score";
  static const _userHighScore = "User High Score";

  static void autoSetAdminStatus() {
    isAdmin = userRole == "admin" || userRole == "super";
    isTeamVerified = isAdmin || userRole == "1816";
  }

  static String get scouterName {
    return App.getString(_scouterKey) ?? "";
  }

  static set scouterName(String value) {
    App.setString(_scouterKey, value);
  }

  static String get displayName {
    return App.getString(_displayNameKey) ?? scouterName;
  }

  static set displayName(String value) {
    App.setString(_displayNameKey, value);
  }

  static bool get loggedIn {
    return App.getBool(_loginStatusKey) ?? false;
  }

  static set loggedIn(bool value) {
    App.setBool(_loginStatusKey, value);
  }

  static bool get isAdmin {
    return App.getBool(_adminStatusKey) ?? false;
  }

  static set isAdmin(bool value) {
    App.setBool(_adminStatusKey, value);
  }

  static bool get isTeamVerified {
    return App.getBool(_teamVerifiedKey) ?? false;
  }

  static set isTeamVerified(bool value) {
    App.setBool(_teamVerifiedKey, value);
  }

  static String get userRole {
    return App.getString(_userRoleKey) ?? "None";
  }

  static set userRole(String value) {
    App.setString(_userRoleKey, value);
  }

  static String get userCertificate {
    return App.getString(_userCertificateKey) ?? "";
  }

  static set userCertificate(String value) {
    App.setString(_userCertificateKey, value);
  }

  static String get userUUID {
    return App.getString(_userUUIDKey) ?? "";
  }

  static set userUUID(String value) {
    App.setString(_userUUIDKey, value);
  }

  static List<String> get immediateMatchCache {
    return App.getStringList(_tempMatchCacheKey) ?? [];
  }

  static List<String> get allTimeMatchCache {
    return App.getStringList(_allTimeMatchCacheKey) ?? [];
  }

  static int get lifeScore {
    return App.getInt(_userLifeScore) ?? 0;
  }

  static set lifeScore(int value) {
    App.setInt(_userLifeScore, value);
  }

  static int get highScore {
    return App.getInt(_userHighScore) ?? 0;
  }

  static set highScore(int value) {
    App.setInt(_userHighScore, value);
  }

  static void addToMatchCache(String matchJSON) {
    App.setStringList(
      _tempMatchCacheKey,
      [
        ...immediateMatchCache,
        matchJSON,
      ],
    );

    // So... what we're doing is concatenating the old list
    // of match cache and then combining it with the new data
    // we just got.
    //
    // The reason we're using a set (which is '<String>{}') is because
    // a set as a structure has the neat property of only allowing one
    // instance of an item at a time. So, essentially they are a list
    // which only contains unique elements.
    App.setStringList(
      _allTimeMatchCacheKey,
      <String>{...allTimeMatchCache, ...immediateMatchCache}.toList(),
    );
  }

  static void confirmMatchMangled(String jsonStr, bool success) {
    final allTime = allTimeMatchCache.toSet();

    try {
      final json = jsonDecode(jsonStr);
      json["Mangled"] = !success;

      allTime.remove(jsonStr);
      allTime.add(jsonEncode(json));
    } catch (e) {
      // Do nothing...
      log("Captured exception while confirming matches: $e");
    }

    App.setStringList(_allTimeMatchCacheKey, allTime.toList());
  }

  static void resetImmediateMatchCache() {
    log("Resetting immediate match cache");
    App.setStringList(_tempMatchCacheKey, []);
  }

  static void resetAllTimeMatchCache() {
    log("Resetting all time match cache");
    App.setStringList(_allTimeMatchCacheKey, []);
  }

  static void resetMatchCache() {
    log("Resetting all match cache (all time and immediate)");
    App.setStringList(_tempMatchCacheKey, []);
    App.setStringList(_allTimeMatchCacheKey, []);
  }

  static Future<bool> updateDisplayName(String newDisplayName) async {
    return App.httpRequest("/setDisplayName", "", headers: {
      "Username": MainAppData.scouterName,
      "displayName": newDisplayName,
    });
  }

  static Future<bool> updateLeaderboardColor(LeaderboardColor newColor) async {
    return App.httpRequest("/setColor", "", headers: {
      "Username": MainAppData.scouterName,
      "uuid": MainAppData.userUUID,
      "color": newColor.name,
    });
  }

  static Future<bool> updateUserPfp(XFile file) async {
    return App.httpRequest("/setUserPfp", await file.readAsBytes(),
        headers: {"Username": MainAppData.scouterName, "Filename": file.name});
  }

  static Future<void> setUserInfo() async {
    await App.httpRequest("/userInfo", "", onGet: (response) {
      var responseJson = jsonDecode(response.body);
      MainAppData.scouterName = responseJson["Username"];
      MainAppData.displayName = responseJson["DisplayName"];
      MainAppData.lifeScore = responseJson["LifeScore"];
      MainAppData.highScore = responseJson["HighScore"];
      Settings.selectedLeaderboardColor.ref.value =
          LeaderboardColor.values.elementAtOrNull(responseJson["Color"]) ??
              LeaderboardColor.none;

      if (!AchievementManager.isCheating()) {
        AchievementManager.syncAchievements(
            responseJson["Badges"], responseJson["Accolades"]);
      }
    }, headers: {
      "username": MainAppData.scouterName,
      "uuid": MainAppData.userUUID
    });

    await App.httpRequest("getPfp", "", onGet: (response) {
      if (response.statusCode == 200) {
        App.setPfp(Image.memory(response.bodyBytes));
      } else {
        App.setPfp(const Icon(Icons.account_circle));
      }
    }, headers: {"username": MainAppData.scouterName});
  }

  static Future<void> checkIpForeign(BuildContext context) async {
    var ip = await Ipify.ipv4();
    var response = await http.get(Uri.parse("https://ipinfo.io/$ip/json"));
    if (jsonDecode(response.body)["country"] != "US" && context.mounted) {
      triggerForeign(context);
    }
  }

  /// Achievement methods. These could be made more generic but it'd be a million parameters

  static void triggerForeign(BuildContext context) {
    if (!AchievementManager.isCheating() && MainAppData.loggedIn) {
      App.showAchievementUnlocked(
          context, "Achievement Unlocked: Foreign Fracas",
          subtitle:
              "Opened the app while outside of the United States - Unlocked Rudy Gobert highlights in Extras");
      AchievementManager.rudyHighlightsUnlocked.value = true;
      App.setBool("Foreign Fracas", true);
      App.httpRequest("/provideAdditions",
          '{"UUID": "${MainAppData.userUUID}", "Achievements": ["Foreign Fracas"]}');
    }
  }

  static void triggerDebug(BuildContext context) {
    if (!AchievementManager.isCheating() && MainAppData.loggedIn) {
      App.showAchievementUnlocked(context, "Achievement Unlocked: Debugger",
          subtitle: "Opened the debug menu");
      App.setBool("Debugger", true);
      App.httpRequest("/provideAdditions",
          '{"UUID": "${MainAppData.userUUID}", "Achievements": ["Debugger"]}');
    }
  }

  static void triggerDetective(BuildContext context) {
    if (!AchievementManager.isCheating() && MainAppData.loggedIn) {
      App.showAchievementUnlocked(context, "Achievement Unlocked: Detective",
          subtitle: "Changed the match layout");
      App.setBool("Detective", true);
      App.httpRequest("/provideAdditions",
          '{"UUID": "${MainAppData.userUUID}", "Achievements": ["Detective"]}');
    }
  }

  static void triggerStrategizer(BuildContext context) {
    if (!AchievementManager.isCheating() && MainAppData.loggedIn) {
      App.showAchievementUnlocked(
          context, "Achievement Unlocked: Strategizer =- ",
          subtitle:
              "Opened the spreadsheet link - Unlocked Naz Reid highlights (Re-open Extras!)");
      App.setBool("Strategizer", true);
      AchievementManager.nazHighlightsUnlocked.value = true;
      App.httpRequest("/provideAdditions",
          '{"UUID": "${MainAppData.userUUID}", "Achievements": ["Strategizer"]}');
    }
  }

  static void notifyAchievement(Achievement achievement) {
    App.showAchievementUnlocked(globalNavigatorKey.currentContext!,
        "Achievement Unlocked: ${achievement.name}",
        subtitle: achievement.description +
            (achievement.unlocks != null
                ? " - Unlocked ${achievement.unlocks}"
                : ""));
  }

  static Future<void> notifyAchievementList(
      List<Achievement> achievements) async {
    for (var achievement in achievements) {
      notifyAchievement(achievement);
    }
  }

  static Future<String> getSpreadsheetLink() async {
    String link = "";
    await App.httpRequest("/spreadsheet", "", onGet: (response) {
      link = response.body;
    });
    return link;
  }
}
