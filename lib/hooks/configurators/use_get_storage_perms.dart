import 'package:device_info_plus/device_info_plus.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:spotube/hooks/utils/use_async_effect.dart';
import 'package:spotube/provider/local_tracks/local_tracks_provider.dart';
import 'package:spotube/utils/platform.dart';

void useGetStoragePermissions(WidgetRef ref) {
  final context = useContext();

  useAsyncEffect(
    () async {
      if (kIsAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt < 33) {
          final hasNoStoragePerm = !await Permission.storage.isGranted &&
              !await Permission.storage.isLimited;
          if (hasNoStoragePerm) {
            await Permission.storage.request();
            if (context.mounted) ref.invalidate(localTracksProvider);
          }
        } else {
          final hasNoAudioPerm = !await Permission.audio.isGranted &&
              !await Permission.audio.isLimited;
          if (hasNoAudioPerm) {
            await Permission.audio.request();
            if (context.mounted) ref.invalidate(localTracksProvider);
          }

          if (!await Permission.notification.isGranted) {
            await Permission.notification.request();
          }
        }

        // On Android 11+ direct filesystem access to user-picked folders
        // (e.g. /storage/emulated/0/Music) requires MANAGE_EXTERNAL_STORAGE
        // unless the app routes through MediaStore/SAF. Music players are
        // eligible for this permission and it lets Spotube enumerate the
        // user's library regardless of where they keep it.
        if (sdkInt >= 30 &&
            !await Permission.manageExternalStorage.isGranted) {
          await Permission.manageExternalStorage.request();
          if (context.mounted) ref.invalidate(localTracksProvider);
        }
      }

      if (kIsIOS) {
        final hasStoragePerm = await Permission.storage.isGranted ||
            await Permission.storage.isLimited;

        if (!hasStoragePerm) {
          await Permission.storage.request();
          if (context.mounted) ref.invalidate(localTracksProvider);
        }
      }
    },
    null,
    [],
  );
}