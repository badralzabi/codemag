import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LudoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new Ludo Game
  Future<String> createGame(String player1Id, String player2Id) async {
    final docRef = _db.collection('ludo_games').doc();
    await docRef.set({
      'player1Id': player1Id, // Red
      'player2Id': player2Id, // Blue
      'currentTurn': player1Id,
      'diceValue': 0,
      'gameState': 'playing', // waiting, playing, finished
      'winner': null,
      'lastUpdated': FieldValue.serverTimestamp(),
      'tokens': {
        // -1 means in base. 0-51 is the main path. 52-56 is the home stretch. 57 is home.
        'red_0': -1, 'red_1': -1, 'red_2': -1, 'red_3': -1,
        'blue_0': -1, 'blue_1': -1, 'blue_2': -1, 'blue_3': -1,
      }
    });
    return docRef.id;
  }

  // Stream a specific game
  Stream<DocumentSnapshot> streamGame(String gameId) {
    return _db.collection('ludo_games').doc(gameId).snapshots();
  }

  // Update Dice Roll
  Future<void> updateDiceRoll(String gameId, int diceValue) async {
    await _db.collection('ludo_games').doc(gameId).update({
      'diceValue': diceValue,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Update Token Position
  Future<void> updateTokens(String gameId, Map<String, dynamic> newTokens, String nextTurnId) async {
    await _db.collection('ludo_games').doc(gameId).update({
      'tokens': newTokens,
      'currentTurn': nextTurnId,
      'diceValue': 0, // Reset dice after move
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}
