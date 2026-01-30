# GrouMap Store App - AI Copilot Instructions

## Project Overview
**GrouMap Store** is a Flutter-based loyalty/points management system for store owners and staff. It connects to Firebase (project: `groumap-ea452`) and uses Riverpod for state management with a multi-platform target (Web, Android, iOS).

### Key Architecture Layers
- **Authentication**: Firebase Auth via `auth_provider.dart` (owner/staff role-based access)
- **Data**: Firestore collections with subcollections (e.g., `stores/{storeId}/transactions/`)
- **State**: Flutter Riverpod (`StreamProvider.family` for real-time data, `StateNotifierProvider` for mutations)
- **UI**: Material 3 with orange theme (seed color: `#FF6B35`)

---

## State Management Patterns (Riverpod)

### StreamProvider for Real-Time Data
**When to use**: Watching Firestore documents or collections that change frequently.

```dart
// Pattern: StreamProvider.family<DataType, ParamType>
final storeDataProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, storeId) {
  return FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .snapshots()
      .map((snapshot) => snapshot.exists ? snapshot.data() : null)
      .handleError((error) {
        debugPrint('Error: $error');
        return null;
      });
});
```

**Key patterns**:
- Always include `.handleError()` to prevent stream crashes
- Use `.family<ReturnType, ParameterType>` to pass parameters (storeId, userId, etc.)
- Sort data in `.map()` after fetching: `..sort((a, b) => bTime.compareTo(aTime))`
- Add `doc['id'] = doc.id` to data maps for document reference

### FutureProvider for One-Time Queries
**When to use**: Single async operations, calculations, or expensive queries that don't need real-time updates.

```dart
final referralKpiProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, storeId) async {
  // Fetch data once, not reactive
});
```

### StateNotifierProvider for Complex Mutations
**When to use**: Multi-step operations (e.g., point awards, payment processing) or state requiring `AsyncValue` for loading/error handling.

```dart
class QRVerificationNotifier extends StateNotifier<QRVerificationState> {
  QRVerificationNotifier() : super(const QRVerificationState());
  
  // Methods update state: state = state.copyWith(...)
}

final qrVerificationProvider = StateNotifierProvider<QRVerificationNotifier, QRVerificationState>((ref) {
  return QRVerificationNotifier();
});
```

---

## Firebase Patterns

### Data Structure
- **Users**: `users/{userId}` → role fields: `isOwner`, `currentStoreId`, `createdStores`
- **Stores**: `stores/{storeId}` → core data
- **Transactions**: `point_transactions/{storeId}/{subcollection}` → hierarchical by store
- **Collections with subcollections**: `posts/{storeId}/posts/`, `coupons/{storeId}/coupons/`

### Firestore Query Patterns
- **Filter by date range**: Use `startOfDay`, `endOfDay` for same-day stats
- **Pagination**: Not commonly used; use `.limit(100)` for large collections
- **Sorting**: Always do client-side (Firestore index limitations)
  ```dart
  ..sort((a, b) {
    final aTime = a['createdAt']?.toDate() ?? DateTime(1970);
    final bTime = b['createdAt']?.toDate() ?? DateTime(1970);
    return bTime.compareTo(aTime); // newest first
  });
  ```

### Authentication Context
- Access current user: `final user = ref.watch(currentUserProvider);`
- Check owner status: `final isOwner = ref.watch(userIsOwnerProvider);`
- Get current store: `final storeId = ref.watch(userStoreIdProvider);`

---

## Development Workflow

### Build & Run
```bash
# Development (hot reload)
flutter run -d web-server --web-renderer html --web-port 8080

# Web build
flutter build web

# Android/iOS (standard Flutter)
flutter pub get && flutter run -d android
```

### Code Generation
Required for models with `@freezed` annotation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
Models using Freezed: `notification_model.dart`, `point_request_model.dart`, `qr_token_model.dart`, `qr_verification_model.dart`, `ranking_model.dart`

### Testing
- Existing test: `test/widget_test.dart`
- Run: `flutter test`

---

## Project-Specific Conventions

### Error Handling
- **Provider errors**: Always `.handleError()` in streams to return safe fallback values
- **UI**: Use `AsyncValue.when()` to handle loading/error/data states
  ```dart
  data.when(
    data: (value) => displayData(value),
    loading: () => const CircularProgressIndicator(),
    error: (err, stack) => ErrorWidget(),
  );
  ```

### Naming Conventions
- Provider names: `{entityName}{ActionOrType}Provider` (e.g., `storeDataProvider`, `userNotificationsProvider`)
- View files: `*_view.dart` (e.g., `help_support_view.dart`)
- Models: `*_model.dart`
- Services: `*_service.dart`

### UI Theme
- Primary color: `0xFFFF6B35` (orange)
- Use `ColorScheme.fromSeed(seedColor: Color(0xFFFF6B35))`
- All buttons/cards use Material 3 rounded corners (BorderRadius: 12)

### Logging
- Use `debugPrint()` for all debug statements (not `print()`)
- Always log before operations: `debugPrint('RankingService: Getting ranking data...')`

---

## Common Tasks

### Adding a New Feature (Provider + View)
1. Create `lib/providers/{feature}_provider.dart` with StreamProvider/FutureProvider
2. Define Service class in same file with Firestore queries
3. Add model if needed: `lib/models/{feature}_model.dart`
4. Create view: `lib/views/{category}/{feature}_view.dart`
5. Use `ConsumerWidget` to access providers: `ref.watch(myProvider)`

### Updating a Firestore Collection
1. Fetch current data in StateNotifier
2. Update Firestore with `.update()` or `.set()`
3. Return result/error in state
4. UI watches state via `AsyncValue.when()`

### Debugging Data Flow
- Check provider dependencies: `ref.watch()` vs `ref.listen()`
- Verify Firestore rules in `firestore.rules` for access control
- Monitor real-time updates in `todayStoreStatsProvider` pattern (watch daily subcollections)

---

## Critical Files Reference
- **App bootstrap**: [lib/main.dart](lib/main.dart) - Firebase init, theme config
- **Auth flow**: [lib/views/auth/](lib/views/auth/) - login, signup, email verification
- **Provider hub**: [lib/providers/](lib/providers/) - all state management
- **Firestore rules**: [firestore.rules](firestore.rules) - access control logic
- **Key store logic**: [lib/providers/store_provider.dart](lib/providers/store_provider.dart) (1396 lines - complex stats aggregation)

---

## External Dependencies
- **flutter_riverpod**: ^2.5.1 (state management)
- **Firebase suite**: Core, Auth, Firestore, Storage, Functions, Messaging
- **flutter_map**: ^7.0.0 (map display)
- **mobile_scanner**: 6.0.2 (QR code scanning)
- **fl_chart**: ^0.68.0 (analytics charts)
- **freezed_annotation**: ^2.4.4 (model generation)

---

## Notes for AI Agents
- **Real-time sensitivity**: Store stats update throughout the day; use `StreamProvider` for live dashboards
- **Multi-store context**: Many providers take `storeId` parameter; verify context when reading/writing
- **Firestore structure**: Subcollections are hierarchical (stores → transactions/coupons/posts); navigate carefully
- **Owner vs Staff**: Role affects what data users can access/modify (check `firestore.rules`)
