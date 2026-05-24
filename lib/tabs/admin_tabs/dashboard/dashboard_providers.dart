import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/firebase_service.dart';

final usersCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getCount('users');
  return count;
});

final purchasesCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getCount('purchases');
  return count;
});

final notificationsCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getCount('notifications');
  return count;
});

final commnetsCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getCount('comments');
  return count;
});

final articlesCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getArticlesCount();
  return count;
});

final eventsCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getEventsCount();
  return count;
});

final pendingArticlesCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getPendingArticlesCount();
  return count;
});

final subscriberCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getSubscribedUsersCount();
  return count;
});

final authorsCountProvider = FutureProvider<int>((ref)async{
  final int count = await FirebaseService().getAuthorsCount();
  return count;
});