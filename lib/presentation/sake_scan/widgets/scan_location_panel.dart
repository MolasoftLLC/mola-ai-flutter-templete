import 'package:flutter/material.dart';
import 'scan_record_questions.dart';

class ScanLocationPanel extends StatelessWidget {
  const ScanLocationPanel({
    super.key,
    required this.message,
    required this.answers,
    required this.onChanged,
    required this.onChoosePlace,
    required this.onDone,
    required this.onInteraction,
    this.questionsDone = false,
    this.ready = false,
    this.placeName,
  });
  final String message;
  final ScanRecordAnswers answers;
  final VoidCallback onChanged, onDone, onInteraction;
  final Future<void> Function() onChoosePlace;
  final bool questionsDone, ready;
  final String? placeName;
  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => onInteraction(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .48,
        ),
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B2034).withValues(alpha: .68),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: .2)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 14,
                      child: ready
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Color(0xFFFFD86B),
                            )
                          : const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFFD86B),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (!questionsDone) ...[
                  const SizedBox(height: 20),
                  ScanRecordQuestions(
                    answers: answers,
                    onChanged: onChanged,
                    onChoosePlace: onChoosePlace,
                    onDone: onDone,
                    doneLabel: ready ? '候補を見る' : 'あとで',
                    onPhoto: true,
                    placeName: placeName,
                  ),
                ] else
                  const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
