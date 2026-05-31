import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:news_admin/components/custom_buttons.dart';
import 'package:news_admin/mixins/textfields.dart';
import 'package:news_admin/mixins/user_mixin.dart';
import 'package:news_admin/models/poll.dart';
import 'package:news_admin/providers/user_data_provider.dart';
import 'package:news_admin/services/firebase_service.dart';
import 'package:news_admin/utils/toasts.dart';
import 'package:rounded_loading_button_plus/rounded_loading_button.dart';

class PollForm extends ConsumerStatefulWidget {
  final String eventId;
  final Poll? poll;

  const PollForm({super.key, required this.eventId, this.poll});

  @override
  ConsumerState<PollForm> createState() => _PollFormState();
}

class _PollFormState extends ConsumerState<PollForm> with TextFields {
  final _formKey = GlobalKey<FormState>();
  final _questionCtlr = TextEditingController();
  final _btnCtlr = RoundedLoadingButtonController();

  // Each entry: { 'id': String, 'controller': TextEditingController, 'voteCount': int }
  final List<Map<String, dynamic>> _options = [];

  bool _allowMultiple = false;
  String _status = 'open';

  @override
  void initState() {
    super.initState();
    if (widget.poll != null) {
      _questionCtlr.text = widget.poll!.question;
      _allowMultiple = widget.poll!.allowMultiple;
      _status = widget.poll!.status;
      for (final opt in widget.poll!.options) {
        _options.add({
          'id': opt.id,
          'controller': TextEditingController(text: opt.text),
          'voteCount': opt.voteCount,
        });
      }
    } else {
      _addOption();
      _addOption();
    }
  }

  @override
  void dispose() {
    _questionCtlr.dispose();
    for (final o in _options) {
      (o['controller'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add({
        'id': FirebaseService.getUID('options'),
        'controller': TextEditingController(),
        'voteCount': 0,
      });
    });
  }

  void _removeOption(int index) {
    if (_options.length <= 2) {
      openFailureToast(context, 'A poll must have at least 2 options');
      return;
    }
    setState(() {
      (_options[index]['controller'] as TextEditingController).dispose();
      _options.removeAt(index);
    });
  }

  void _handleSubmit() async {
    if (!UserMixin.hasAccess(ref.read(userDataProvider))) {
      openTestingToast(context);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    // Reject duplicate option texts
    final texts = _options
        .map((o) => (o['controller'] as TextEditingController)
            .text
            .trim()
            .toLowerCase())
        .toList();
    if (texts.toSet().length != texts.length) {
      openFailureToast(context, 'Duplicate option text not allowed');
      return;
    }

    _btnCtlr.start();

    final pollId = widget.poll?.id ?? FirebaseService.getUID('polls');
    final createdAt = widget.poll?.createdAt ?? DateTime.now().toUtc();

    final List<PollOption> opts = _options.map((o) {
      return PollOption(
        id: o['id'] as String,
        text: (o['controller'] as TextEditingController).text.trim(),
        voteCount: o['voteCount'] as int,
      );
    }).toList();

    final poll = Poll(
      id: pollId,
      eventId: widget.eventId,
      question: _questionCtlr.text.trim(),
      options: opts,
      allowMultiple: _allowMultiple,
      status: _status,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
    );

    try {
      await FirebaseService().savePoll(poll);
      _btnCtlr.success();
      if (!mounted) return;
      Navigator.pop(context);
      openSuccessToast(
          context, widget.poll == null ? 'Poll created' : 'Poll updated');
    } catch (e) {
      _btnCtlr.reset();
      if (!mounted) return;
      openFailureToast(context, 'Failed to save poll');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.poll != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(isEdit ? 'Edit Poll' : 'Create Poll'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: CustomButtons.submitButton(
          context,
          width: 250,
          buttonController: _btnCtlr,
          text: isEdit ? 'Update Poll' : 'Create Poll',
          onPressed: _handleSubmit,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildTextField(
                context,
                controller: _questionCtlr,
                hint: 'Enter poll question',
                title: 'Question *',
                maxLines: null,
                minLines: 1,
              ),
              const SizedBox(height: 30),
              Text('Options *', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final ctlr =
                      _options[i]['controller'] as TextEditingController;
                  final voteCount = _options[i]['voteCount'] as int;
                  return Row(
                    children: [
                      Expanded(
                        child: Container(
                          color: Colors.grey.shade200,
                          child: TextFormField(
                            controller: ctlr,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Option text required'
                                : null,
                            decoration: InputDecoration(
                              hintText: 'Option ${i + 1}',
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.fromLTRB(20, 15, 20, 15),
                              suffixText:
                                  voteCount > 0 ? '$voteCount votes' : null,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove option',
                        icon: const Icon(Icons.remove_circle_outline,
                            color: Colors.redAccent),
                        onPressed: () => _removeOption(i),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add option'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _allowMultiple,
                    onChanged: (v) =>
                        setState(() => _allowMultiple = v ?? false),
                  ),
                  const Text('Allow multiple selections'),
                  const SizedBox(width: 30),
                  const Text('Status:'),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Open')),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (v) => setState(() => _status = v ?? 'open'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
