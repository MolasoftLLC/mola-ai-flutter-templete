import 'package:flutter/material.dart';

/// Answers remain a draft until the user confirms the record form.
class ScanRecordAnswers {
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
  });
  final ScanRecordAnswers answers;
  final VoidCallback onChanged;
  final Future<void> Function() onChoosePlace;
  final VoidCallback onDone;

  @override
  State<ScanRecordQuestions> createState() => _ScanRecordQuestionsState();
}

class _ScanRecordQuestionsState extends State<ScanRecordQuestions> {
  int _step = 0;
  double _drag = 0;
  bool _choosingPlace = false;
  static const _questions = [
    'このお酒、飲んだ？',
    '好きな味だった？',
    '今いるお店で飲んだ？',
    'また飲みたい？',
    '星で評価するなら？',
  ];

  Future<void> _answer(bool? answer) async {
    if (_choosingPlace) return;
    final answers = widget.answers;
    switch (_step) {
      case 0:
        answers.drank = answer;
        if (answer != true) {
          answers.liked = answers.here = answers.again = null;
          answers.stars = null;
          widget.onChanged();
          widget.onDone();
          return;
        }
      case 1:
        answers.liked = answer;
      case 2:
        answers.here = answer;
      case 3:
        answers.again = answer;
    }
    widget.onChanged();
    if (_step == 2 && answer == true) {
      setState(() => _choosingPlace = true);
      try {
        await widget.onChoosePlace();
      } finally {
        if (mounted) setState(() => _choosingPlace = false);
      }
    }
    if (!mounted) return;
    if (_step == 4) {
      widget.onDone();
    } else {
      setState(() {
        _step++;
        _drag = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1D3567);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '答えられるものだけでOK。あとで編集できます。',
          style: TextStyle(color: Color(0xFF697386), fontSize: 12),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onHorizontalDragStart: _step == 4 ? null : (_) => _drag = 0,
          onHorizontalDragUpdate: _step == 4
              ? null
              : (event) {
                  setState(
                    () => _drag = (_drag + event.delta.dx).clamp(-80, 80),
                  );
                },
          onHorizontalDragCancel: () => setState(() => _drag = 0),
          onHorizontalDragEnd: _step == 4
              ? null
              : (event) {
                  final answer =
                      _drag.abs() >= 48 || event.primaryVelocity!.abs() >= 450
                      ? (_drag.abs() >= 48
                            ? _drag > 0
                            : event.primaryVelocity! > 0)
                      : null;
                  setState(() => _drag = 0);
                  if (answer != null) _answer(answer);
                },
          child: Transform.translate(
            offset: Offset(_drag * .35, 0),
            child: Container(
              key: ValueKey('scan-question-$_step'),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFEAD9BA)),
              ),
              child: Column(
                children: [
                  Icon(
                    _step == 2
                        ? Icons.place_outlined
                        : Icons.local_bar_outlined,
                    color: const Color(0xFFFF914D),
                    size: 36,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _questions[_step],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_step == 4)
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        for (var star = 1; star <= 5; star++)
                          IconButton(
                            tooltip: '$starつ星',
                            onPressed: () {
                              widget.answers.stars = star;
                              widget.onChanged();
                              widget.onDone();
                            },
                            icon: const Icon(
                              Icons.star_outline,
                              color: Color(0xFFD49A20),
                            ),
                          ),
                      ],
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _choosingPlace
                                ? null
                                : () => _answer(false),
                            child: const Text('← NO'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: navy,
                            ),
                            onPressed: _choosingPlace
                                ? null
                                : () => _answer(true),
                            child: const Text('YES →'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '左右にフリックでも回答',
                      style: TextStyle(color: Color(0xFF697386), fontSize: 12),
                    ),
                  ],
                  TextButton(
                    onPressed: _choosingPlace ? null : () => _answer(null),
                    child: const Text('あとで'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: widget.onDone, child: const Text('記録フォームへ')),
      ],
    );
  }
}
