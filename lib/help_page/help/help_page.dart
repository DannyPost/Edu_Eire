import 'package:flutter/material.dart';
import 'faq_widget.dart';
import 'contact_us_form.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  HelpPage({super.key});

  // ── FAQ data ────────────────────────────────────────────────────
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How do I apply for a SUSI grant?',
      answer:
          'You can apply for a SUSI grant online at susi.ie. Our SUSI Calculator can help you check your eligibility before you apply.',
    ),
    FAQItem(
      question: 'What is the DARE scheme?',
      answer:
          'DARE (Disability Access Route to Education) is a college and university admissions scheme for students with disabilities. Use our DARE calculator to see if you qualify.',
    ),
    FAQItem(
      question: 'Who can use the student deals listed in this app?',
      answer:
          'All current secondary school students in Ireland can access these deals. Some deals may require a valid student ID at purchase.',
    ),
    FAQItem(
      question: 'How do I use the chatbot?',
      answer:
          'Tap on the Chatbot tab and type your question. You can ask about grants, colleges, deadlines, or general support.',
    ),
    FAQItem(
      question: 'What information do I need for the SUSI calculator?',
      answer:
          'You’ll need your family income, the number of children in your household, and your parents’ occupation. The calculator will guide you step by step.',
    ),
    FAQItem(
      question: 'Is my personal data safe?',
      answer:
          'Yes, we use secure systems and never share your data with third parties. Read our Privacy Policy for more details.',
    ),
    FAQItem(
      question: 'How do I contact support?',
      answer:
          'Scroll down to the “Contact Us” section on the Help page and fill out the form. We’ll reply to your email as soon as possible.',
    ),
    FAQItem(
      question: 'Can I use this app on my phone and my computer?',
      answer: 'Yes, the app works on both mobile devices and computers.',
    ),
    FAQItem(
      question: 'What is the difference between SUSI and HEAR?',
      answer:
          'SUSI is the national grant authority for student grants. HEAR (Higher Education Access Route) is a college admissions scheme for students from socio-economically disadvantaged backgrounds.',
    ),
    FAQItem(
      question: 'How often are student deals updated?',
      answer: 'We update the deals regularly. Check back often for new offers!',
    ),
  ];

  // ── UI ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.primaryColor; // → your brand blue
    final onBack = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: brand,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───────────────── Academic Support (ADDED) ─────────────────
            _HelpSectionHeader('Academic Support', color: brand),

            const _SupportCard(
              icon: Icons.volunteer_activism,
              title: '1916 Bursary Fund',
              body:
                  'Financial support for students who are socio-economically disadvantaged and from target groups under the National Access Plan.',
              actionText: 'Learn more / apply',
              url: 'https://1916bursary.ie/',
            ),
            const SizedBox(height: 12),

            const _SupportCard(
              icon: Icons.account_balance_wallet,
              title: 'SUSI (Student Grants)',
              body:
                  'SUSI is Ireland’s national grant authority. Use our SUSI Calculator in the app to check eligibility, then apply on the official site.',
              actionText: 'Open SUSI website',
              url: 'https://www.susi.ie/',
            ),
            const SizedBox(height: 12),

            const _SupportCard(
              icon: Icons.school,
              title: 'HEAR Scheme',
              body:
                  'Higher Education Access Route (HEAR) for students from socio-economically disadvantaged backgrounds.',
              actionText: 'Visit HEAR',
              url: 'https://accesscollege.ie/hear/',
            ),
            const SizedBox(height: 12),

            const _SupportCard(
              icon: Icons.accessibility_new,
              title: 'DARE Scheme',
              body:
                  'Disability Access Route to Education (DARE) for students with disabilities entering higher education.',
              actionText: 'Visit DARE',
              url: 'https://accesscollege.ie/dare/',
            ),
            const SizedBox(height: 12),

            const _SupportCard(
              icon: Icons.menu_book,
              title: 'Study Tips & Essay Writing',
              body:
                  'Practical techniques to study smarter and write stronger essays. Curated tips from Harvard.',
              actionText: 'Open study tips',
              url:
                  'https://summer.harvard.edu/blog/top-10-study-tips-to-study-like-a-harvard-student/',
            ),
            const SizedBox(height: 12),

            const _SupportCard(
              icon: Icons.health_and_safety,
              title: 'Mental Health & Wellbeing',
              body:
                  'Free, confidential 24/7 supports are available via the HSE and your college counselling service.',
              actionText: 'HSE mental health services',
              url: 'https://www2.hse.ie/mental-health/',
            ),
            const SizedBox(height: 12),

            const _SupportCard(
              icon: Icons.mail_outline,
              title: 'Contact Support',
              body:
                  'Have a question about grants, access routes, or wellbeing? Email us and we’ll point you in the right direction.',
              actionText: 'Email support',
              url:
                  'mailto:support@example.com?subject=Academic%20Support&body=Hi%20team%2C%0A%0A',
            ),
            const SizedBox(height: 24),
            // ─────────────── END Academic Support (ADDED) ───────────────

            // FAQ header
            Text(
              'Frequently Asked Questions',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: brand,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            FAQWidget(items: _faqItems),
            const SizedBox(height: 32),

            // Contact header
            Text(
              'Contact Us',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: brand,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const ContactUsForm(),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── helpers (ADDED) ─────────────────────────

class _HelpSectionHeader extends StatelessWidget {
  final String text;
  final Color? color;
  const _HelpSectionHeader(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: Text(
        text,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: color ?? theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String actionText;
  final String url;

  const _SupportCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionText,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () =>
                launchUrlString(url, mode: LaunchMode.externalApplication),
            child: Text(actionText),
          ),
        ]),
      ),
    );
  }
}
