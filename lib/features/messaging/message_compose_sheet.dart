import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/post.dart';
import '../dm/new_dm_repos.dart';

class MessageComposeBottomSheet extends StatefulWidget {
  final PostModel post;
  final String type; // 'invest', 'collab', 'contact'

  const MessageComposeBottomSheet({
    super.key,
    required this.post,
    required this.type,
  });

  static Future<void> show({
    required BuildContext context,
    required PostModel post,
    required String type,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => MessageComposeBottomSheet(post: post, type: type),
    );
  }

  @override
  State<MessageComposeBottomSheet> createState() =>
      _MessageComposeBottomSheetState();
}

class _MessageComposeBottomSheetState extends State<MessageComposeBottomSheet> {
  final _threadRepo = ThreadRepository();
  final _msgRepo = MessageRepository();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _subjectCtrl;
  late final TextEditingController _investAmountCtrl;
  late final TextEditingController _investMsgCtrl;
  late final TextEditingController _collabSkillsCtrl;
  late final TextEditingController _collabHelpCtrl;
  late final TextEditingController _contactMsgCtrl;

  bool _sending = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    final userName =
        user?.userMetadata?['full_name'] ?? user?.email?.split('@')[0] ?? '';
    _email = user?.email ?? '';

    _nameCtrl =
        TextEditingController(text: userName.isNotEmpty ? userName : _email);
    _subjectCtrl = TextEditingController();
    _investAmountCtrl = TextEditingController();
    _investMsgCtrl = TextEditingController();
    _collabSkillsCtrl = TextEditingController();
    _collabHelpCtrl = TextEditingController();
    _contactMsgCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subjectCtrl.dispose();
    _investAmountCtrl.dispose();
    _investMsgCtrl.dispose();
    _collabSkillsCtrl.dispose();
    _collabHelpCtrl.dispose();
    _contactMsgCtrl.dispose();
    super.dispose();
  }

  String _computedSubject() {
    switch (widget.type) {
      case 'invest':
        return 'Investment interest in ${widget.post.title}';
      case 'collab':
        return 'Collaboration interest in ${widget.post.title}';
      case 'contact':
        return _subjectCtrl.text.trim().isEmpty
            ? 'Message about ${widget.post.title}'
            : _subjectCtrl.text.trim();
      default:
        return 'Message about ${widget.post.title}';
    }
  }

  String _buildContent() {
    if (widget.type == 'invest') {
      final amount = _investAmountCtrl.text.trim();
      final body = _investMsgCtrl.text.trim();
      return 'INVEST_AMOUNT: $amount\n\n${body.isEmpty ? '' : body}';
    } else if (widget.type == 'collab') {
      final skills = _collabSkillsCtrl.text.trim();
      final help = _collabHelpCtrl.text.trim();
      return 'SKILLS: $skills\nCONTRIBUTION: $help';
    } else {
      // contact
      return _contactMsgCtrl.text.trim();
    }
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _sending = true);

    try {
      final threadId =
          await _threadRepo.ensure1to1(user.id, widget.post.userId);
      final messageContent =
          '[${widget.type.toUpperCase()}] ${_computedSubject()}\n\n${_buildContent()}';

      await _msgRepo.send(
        threadId: threadId,
        senderId: user.id,
        body: messageContent,
      );

      if (mounted) {
        FocusManager.instance.primaryFocus?.unfocus();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${widget.type[0].toUpperCase()}${widget.type.substring(1)} message sent! Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside form fields
        FocusScope.of(context).unfocus();
      },
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      switch (widget.type) {
                        'invest' => 'Invest in ${widget.post.title}',
                        'collab' => 'Collaborate on ${widget.post.title}',
                        'contact' => 'Contact about ${widget.post.title}',
                        _ => 'Send Message'
                      },
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      switch (widget.type) {
                        'invest' =>
                          'Express your investment interest and connect with the founder!',
                        'collab' =>
                          'Share your skills and propose a collaboration!',
                        'contact' =>
                          'Send a personalized message to the founder!',
                        _ => 'Send a message to the founder'
                      },
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Name field
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name required'
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Email field (read-only)
                    TextFormField(
                      initialValue: _email,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Type-specific fields
                    if (widget.type == 'invest') ...[
                      TextFormField(
                        controller: _investAmountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Investment Amount (\$)',
                          hintText: 'Minimum 100',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Amount required';
                          }
                          final amount = double.tryParse(v.trim());
                          if (amount == null || amount < 100) {
                            return 'Minimum \$100';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _investMsgCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Message to Founder (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    if (widget.type == 'collab') ...[
                      TextFormField(
                        controller: _collabSkillsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Your Skills/Expertise',
                          hintText:
                              'e.g., Web Development, Marketing, Design...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Skills required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _collabHelpCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'How You Can Help',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Describe your contribution'
                            : null,
                      ),
                    ],

                    if (widget.type == 'contact') ...[
                      TextFormField(
                        controller: _subjectCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          hintText: 'What\'s this about?',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Subject required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _contactMsgCtrl,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Message required'
                            : null,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _sending ? null : _sendMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _sending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                switch (widget.type) {
                                  'invest' => 'Submit Investment Interest',
                                  'collab' => 'Offer Collaboration',
                                  'contact' => 'Send Message',
                                  _ => 'Send'
                                },
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
