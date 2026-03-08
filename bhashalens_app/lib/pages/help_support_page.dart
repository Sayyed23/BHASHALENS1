import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.live_help),
            title: Text('FAQ'),
            trailing: Icon(Icons.arrow_forward_ios),
            // TODO: Navigate to FAQ page
          ),
          ListTile(
            leading: Icon(Icons.book),
            title: Text('Tutorials'),
            trailing: Icon(Icons.arrow_forward_ios),
            // TODO: Navigate to tutorials page
          ),
          ListTile(
            leading: Icon(Icons.contact_support),
            title: Text('Contact Support'),
            trailing: Icon(Icons.arrow_forward_ios),
            // TODO: Navigate to contact support page
          ),
          ListTile(
            leading: Icon(Icons.feedback),
            title: Text('Send Feedback'),
            trailing: Icon(Icons.arrow_forward_ios),
            // TODO: Navigate to feedback system
          ),
        ],
      ),
    );
  }
}
