import 'package:flutter/material.dart';

import '../../../common/localization/localization_extensions.dart';
import '../../common/widgets/primary_app_bar.dart';

class HowToUse extends StatelessWidget {
  const HowToUse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PrimaryAppBar(
        title: context.l10n.termsOfUse,
        titleFontSize: 18,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: const Color(0xFF1D3567),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: [
            Text(
              context.l10n.termsTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 28),
            _TermsParagraph(context.l10n.termsAiUsage),
            _TermsParagraph(context.l10n.termsAiDisclaimer),
            _TermsParagraph(context.l10n.termsAccount),
            _TermsParagraph(context.l10n.termsContentPolicy),
            _TermsParagraph(context.l10n.termsServiceAvailability),
            _TermsParagraph(context.l10n.termsClosing),
          ],
        ),
      ),
    );
  }
}

class _TermsParagraph extends StatelessWidget {
  const _TermsParagraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          height: 1.65,
        ),
      ),
    );
  }
}
