import 'package:flutter/material.dart';
import 'faq_widget.dart';
import 'contact_us_form.dart';

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
    final theme  = Theme.of(context);
    final brand  = theme.primaryColor;               // → exact #3AB6FF
    final onBack = theme.colorScheme.onSurface;   // adapts to dark mode

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
