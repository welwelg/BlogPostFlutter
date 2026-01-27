# Flutter Blog App - AI Coding Agent Instructions

## Architecture Overview

This is a **feature-driven Flutter blog application** using **Riverpod** for state management and **Supabase** for backend/auth.

### Clean Architecture Pattern
- **Features**: `lib/features/{auth,blog,comment,likes,profile}/`
- **Layers per feature**:
  - `models/` - Data classes with `fromJson()` and `toJson()` factories
  - `repository/` - Supabase database/storage operations (no UI logic)
  - `controllers/` - Riverpod StateNotifierProvider + business logic
  - `screens/` - UI widgets (ConsumerWidget/ConsumerStatefulWidget)

### Data Flow
`Supabase` ↔ `Repository` ↔ `Controller (StateNotifier)` ↔ `UI (watches Provider)`

---

## Riverpod State Management Patterns

### Three Provider Types (Used Consistently)

1. **Repository Provider** (Dependency Injection)
   ```dart
   final blogRepositoryProvider = Provider((ref) {
     return BlogRepository(Supabase.instance.client);
   });
   ```

2. **Data Provider** (GET data - Stream for realtime, Future for one-time)
   - `StreamProvider`: Realtime database listening (`getAllBlogsProvider`, `commentsStreamProvider`)
   - `FutureProvider.family`: User-specific data (`profileProvider(userId)`)
   - `commentCountProvider`: Custom stream counting rows

3. **Controller Provider** (UPDATE/DELETE actions)
   - `StateNotifierProvider<Controller, bool>` - state bool = loading flag
   - Pattern: Pass `ref` to constructor for `ref.invalidate()` triggers
   ```dart
   final blogControllerProvider = StateNotifierProvider<BlogController, bool>((ref) {
     return BlogController(ref, ref.watch(blogRepositoryProvider));
   });
   ```

### Critical Pattern: ref.invalidate()
- Manually trigger data refresh after mutations
- Example: After upload, invalidate the stream provider:
  ```dart
  _ref.invalidate(getAllBlogsProvider); // Reset stream connection
  ```

---

## Feature-Specific Conventions

### Auth (`features/auth/`)
- **Repository**: Handles Supabase Auth API + profiles table insert on signup
- **Controller**: Manages loading state only (true/false)
- **authStateProvider**: `StreamProvider<AuthState>` watches login/logout globally
- **Usage**: Main route decision in `main.dart` based on `session != null`

### Blog (`features/blog/`)
- **Models**: Include nullable `imageUrl` field
- **Repository**: Handles image upload to `blog_images` bucket + CRUD
- **Realtime**: `getAllBlogsProvider` is StreamProvider (ordered desc by created_at)
- **Image Handling**: Check `kIsWeb` before picking/uploading:
  ```dart
  if (kIsWeb) {
    final bytes = await image.readAsBytes();
    // Use uploadBinary() for web
  } else {
    // Use upload(File) for mobile
  }
  ```

### Comments (`features/comment/`)
- **Realtime**: `commentsStreamProvider.family` gets comments by blogId
- **Image Support**: Comments can have attachments (image_url field)
- **Refresh Pattern**: After add/edit/delete, invalidate `commentsStreamProvider(blogId)`

### Likes (`features/likes/`)
- **Special Provider**: `StateNotifierProvider.autoDispose.family<LikesController, AsyncValue<LikeState>, String>`
- **LikeState**: Contains `isLiked` boolean + `count` integer
- **Auto-dispose**: Automatically resets when user logs out/switches blogs

### Profile (`features/profile/`)
- **Field Mapping**: 
  - `display_name` in DB → `fullName` in app
  - `profile_image` in DB → `avatarUrl` in app
- **Image Storage**: Saved in `blog_images` bucket (shared with blogs)
- **Timestamp Usage**: Append milliseconds to filename to avoid browser cache:
  ```dart
  final fileName = 'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}';
  ```

---

## Common Implementation Tasks

### Adding a New CRUD Feature
1. Create `models/` with `fromJson()` and `toJson()`
2. Create `repository/` class with methods that call `_supabase.from('table')`
3. Create `controller/` with StateNotifierProvider + update methods
4. Create `screens/` using `ConsumerWidget` or `ConsumerStatefulWidget`
5. Use `ref.watch(dataProvider)` and `ref.read(controllerProvider.notifier).action()`

### Uploading Images
- Always check `kIsWeb` before file operations
- For web: Use `.readAsBytes()` + `uploadBinary()`
- For mobile: Use `File()` + `upload()`
- Get public URL: `storage.from(bucket).getPublicUrl(fileName)`

### Handling Loading States
- Controllers expose `bool state` as loading flag
- Watch: `final loading = ref.watch(controllerProvider);`
- Show spinner while true, disable buttons with `onPressed: loading ? null : () {}`

### Form Validation
- Use `GlobalKey<FormState>` with `TextFormField` validators
- Call `.currentState!.validate()` before submit
- Example: [auth_screen.dart](lib/features/auth/screens/auth_screen.dart#L50)

### Error Handling
- Controllers catch and `rethrow` to UI
- Show `ScaffoldMessenger.showSnackBar()` on error
- **Important**: Check `if (mounted)` before showing dialogs in async operations

---

## Critical Gotchas & Fixed Patterns

1. **Mounted Safety**: Always check `if (mounted)` before setState/showSnackBar after async:
   ```dart
   if (!mounted) return;
   ScaffoldMessenger.of(context).showSnackBar(...);
   ```

2. **StreamProvider Refresh**: Use `ref.invalidate()` to reset streams (not `.refresh()`)

3. **Image Field Names**: DB uses snake_case (`image_url`, `user_id`), models use camelCase

4. **Supabase Storage**: All images stored in `blog_images` bucket regardless of type

5. **Time-based Filenames**: Use `DateTime.now()` with milliseconds to bypass browser caching

---

## Key Files Reference

- **Entry**: [main.dart](main.dart) - Supabase init + auth gate
- **State Pattern**: [auth_controller.dart](lib/features/auth/controllers/auth_controller.dart)
- **Realtime Pattern**: [blog_controller.dart](lib/features/blog/controllers/blog_controller.dart) + `getAllBlogsProvider`
- **Image Handling**: [profile_screen.dart](lib/features/profile/screens/profile_screen.dart#L55) - kIsWeb check
- **UI Patterns**: [blog_detail_screen.dart](lib/features/blog/screens/blog_detail_screen.dart) - complex realtime UI

---

## Build & Development

- **Flutter Version**: 3.0.0+
- **Key Dependencies**: `flutter_riverpod`, `supabase_flutter`, `image_picker`
- **Analysis**: Run `flutter analyze` (uses flutter_lints/flutter.yaml)
- **No Custom Conventions File**: Follow Flutter naming (snake_case files, PascalCase classes)

---

## When Adding Features

1. Ask: Is it a new feature module? → Follow feature folder structure
2. Ask: Does it need realtime data? → Use `StreamProvider`
3. Ask: Does it mutate data? → Use `StateNotifierProvider` controller
4. Ask: Does it handle images? → Remember `kIsWeb` + filename timestamps
5. Always invalidate related providers after mutations for instant UI updates
