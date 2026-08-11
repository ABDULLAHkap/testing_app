import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../widgets/home_navigation_action.dart';
import '../communications/support_chat_screen.dart';

class AdminCommunicationsScreen extends StatefulWidget {
  const AdminCommunicationsScreen({super.key});

  @override
  State<AdminCommunicationsScreen> createState() =>
      _AdminCommunicationsScreenState();
}

class _AdminCommunicationsScreenState extends State<AdminCommunicationsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  final _title = TextEditingController();
  final _message = TextEditingController();
  late final TabController _tabs;
  List<Map<String, dynamic>> _conversations = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final items = await _api.getSupportConversations();
      if (mounted) setState(() => _conversations = items);
    } catch (_) {}
  }

  Future<void> _sendAnnouncement() async {
    if (_title.text.trim().length < 3 || _message.text.trim().length < 3)
      return;
    setState(() => _sending = true);
    try {
      await _api.sendAnnouncement(_title.text.trim(), _message.text.trim());
      _title.clear();
      _message.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Announcement sent to all students')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send announcement: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communication'),
        actions: const [HomeNavigationAction()],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Announcement'),
            Tab(text: 'Student Chats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Send an announcement to every student',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Announcement title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _message,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _sending ? null : _sendAnnouncement,
                icon: const Icon(Icons.campaign),
                label: Text(_sending ? 'Sending...' : 'Send to all students'),
              ),
            ],
          ),
          RefreshIndicator(
            onRefresh: _loadConversations,
            child: _conversations.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 180),
                      Center(child: Text('No student conversations yet')),
                    ],
                  )
                : ListView.builder(
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final item = _conversations[index];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text('${item['username']}'),
                        subtitle: Text(
                          '${item['email']}\n${item['last_message']}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SupportChatScreen(
                                studentId: item['student_id'] as int,
                                studentName: '${item['username']}',
                              ),
                            ),
                          );
                          _loadConversations();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
