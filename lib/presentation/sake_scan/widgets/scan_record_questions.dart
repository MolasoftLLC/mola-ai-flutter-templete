import 'package:flutter/material.dart';

/// Answers remain a draft until the user confirms the record form.
class ScanRecordAnswers {
  int step = 0;
  bool? drank;
  bool? liked;
  bool? here;
  bool? again;
  int? stars;

  String get memo {
    if (drank != true) return '';
    return [
      '飲んだ',
      if (liked != null) liked! ? '好きな味だった' : '好みの味ではなかった',
      if (again != null) again! ? 'また飲みたい' : 'また飲みたい：いいえ',
      if (stars != null) '自分の評価：${List.filled(stars!, '★').join()}（$stars/5）',
    ].join('\n');
  }
}

class ScanRecordQuestions extends StatefulWidget {
  const ScanRecordQuestions({
    super.key,
    required this.answers,
    required this.onChanged,
    required this.onChoosePlace,
    required this.onDone,
    this.doneLabel = 'あとで',
    this.onPhoto = false,
    this.placeName,
  });
  final ScanRecordAnswers answers;
  final VoidCallback onChanged;
  final Future<void> Function() onChoosePlace;
  final VoidCallback onDone;
  final String doneLabel;
  final bool onPhoto;
  final String? placeName;

  @override
  State<ScanRecordQuestions> createState() => _ScanRecordQuestionsState();
}

class _ScanRecordQuestionsState extends State<ScanRecordQuestions> {
  bool _choosingPlace = false;

  Future<void> _choosePlace() async {
    if (_choosingPlace) return;
    setState(() => _choosingPlace = true);
    try {
      // Choosing a location does not imply drinking, liking, or rating the sake.
      await widget.onChoosePlace();
    } finally {
      if (mounted) setState(() => _choosingPlace = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.onPhoto ? Colors.white : const Color(0xFF143861);
    final selected = widget.placeName?.trim().isNotEmpty == true;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selected ? '場所を選びました' : 'どこで出会ったお酒？',
          style: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '場所だけ、先にメモできます。',
          style: TextStyle(color: ink.withValues(alpha: .8), fontSize: 13),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _choosingPlace ? null : _choosePlace,
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            disabledForegroundColor: ink.withValues(alpha: .65),
            backgroundColor: widget.onPhoto
                ? Colors.white.withValues(alpha: .10)
                : const Color(0xFFF4F6F7),
            side: BorderSide(color: ink.withValues(alpha: .4)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: Icon(
            selected ? Icons.check_circle_outline : Icons.place_outlined,
          ),
          label: Text(
            _choosingPlace
                ? '場所を選択中…'
                : selected
                ? widget.placeName!
                : 'お店・場所を選ぶ',
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: _choosingPlace ? null : widget.onDone,
          style: TextButton.styleFrom(
            foregroundColor: ink.withValues(alpha: .8),
          ),
          child: Text(
            selected && widget.doneLabel == 'あとで'
                ? 'この場所で続ける'
                : widget.doneLabel,
          ),
        ),
      ],
    );
  }
}
