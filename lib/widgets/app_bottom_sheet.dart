import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Widget child,
    List<Widget>? actions,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final sheetTheme = Theme.of(ctx);
        final dark = sheetTheme.brightness == Brightness.dark;
        final bg = dark ? AppTheme.darkSurface : Colors.white;
        final primary = AppTheme.textPrimary(ctx);
        final secondary = AppTheme.textSecondary(ctx);

        return Theme(
          data: sheetTheme,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: dark ? Colors.grey.shade700 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: primary),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle, style: TextStyle(color: secondary, height: 1.4)),
                      ],
                      const SizedBox(height: 16),
                      DefaultTextStyle(
                        style: TextStyle(color: primary, fontSize: 15, height: 1.4),
                        child: child,
                      ),
                      if (actions != null) ...[
                        const SizedBox(height: 20),
                        ...actions.map((action) {
                          if (action is FilledButton) {
                            return FilledButton(
                              onPressed: action.onPressed,
                              style: FilledButton.styleFrom(
                                backgroundColor: dark ? AppTheme.accent : AppTheme.navy,
                                foregroundColor: Colors.white,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: action.child ?? const SizedBox.shrink(),
                            );
                          }
                          if (action is OutlinedButton) {
                            return OutlinedButton(
                              onPressed: action.onPressed,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primary,
                                side: BorderSide(color: dark ? Colors.grey.shade700 : Colors.grey.shade300),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: action.child ?? const SizedBox.shrink(),
                            );
                          }
                          return action;
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
