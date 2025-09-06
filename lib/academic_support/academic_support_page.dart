import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AcademicSupportPage extends StatelessWidget {
  const AcademicSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = theme.primaryColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Academic Support'),
        backgroundColor: brand,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _HelpSectionHeader('Academic Support'),
            SizedBox(height: 8),

            _SupportCard(
              icon: Icons.volunteer_activism,
              title: '1916 Bursary Fund',
              body:
                  'The 1916 Bursary provides multi-year financial support to students who are socio-economically disadvantaged and who belong to priority groups identified in the National Access Plan.',
              actionText: 'Learn more / apply',
              url: 'https://1916bursary.ie/',
            ),
            SizedBox(height: 12),

            _SupportCard(
              icon: Icons.account_balance_wallet,
              title: 'SUSI (Student Grants)',
              body:
                  'SUSI is Ireland’s national authority for student grants. Eligible students can apply online for maintenance and/or fee supports; our in-app SUSI Calculator helps you estimate eligibility first.',
              actionText: 'Open SUSI website',
              url: 'https://www.susi.ie/',
            ),
            SizedBox(height: 12),

            _SupportCard(
              icon: Icons.school,
              title: 'HEAR Scheme',
              body:
                  'Higher Education Access Route (HEAR) for students from socio-economically disadvantaged backgrounds. May include reduced points offers and tailored supports.',
              actionText: 'Visit HEAR',
              url: 'https://accesscollege.ie/hear/',
            ),
            SizedBox(height: 12),

            _SupportCard(
              icon: Icons.accessibility_new,
              title: 'DARE Scheme',
              body:
                  'Disability Access Route to Education (DARE) for school-leavers with verified long-term disabilities. Consideration for reduced points entry and on-campus supports.',
              actionText: 'Visit DARE',
              url: 'https://accesscollege.ie/dare/',
            ),
            SizedBox(height: 12),

            _SupportCard(
              icon: Icons.menu_book,
              title: 'Study Tips & Essay Writing',
              body:
                  'Build strong study habits and academic writing skills (e.g., Harvard’s top study strategies).',
              actionText: 'Open study tips',
              url: 'https://summer.harvard.edu/blog/top-10-study-tips-to-study-like-a-harvard-student/',
            ),
            SizedBox(height: 12),

            _SupportCard(
              icon: Icons.health_and_safety,
              title: 'Mental Health & Wellbeing',
              body:
                  'Free, confidential 24/7 supports via the HSE and your college counselling service.',
              actionText: 'HSE mental health services',
              url: 'https://www.mentalhealthireland.ie/',
            ),
            SizedBox(height: 12),

            // --- New cards added below ---

            _SupportCard(
              icon: Icons.menu_book,
              title: 'Writing & Referencing Hub',
              body:
                  'Harvard/APA referencing guides, citation tools, and tips to avoid plagiarism.',
              actionText: 'Open referencing guide',
              url: 'https://libguides.ul.ie/cite',
            ),
            SizedBox(height: 12),

            _SupportCard(
              icon: Icons.inventory_2,
              title: 'Past Papers & Marking Guides',
              body:
                  'Find previous exam papers and, where available, marking schemes to practice effectively.',
              actionText: 'Browse past papers',
              url: 'https://ncirl.libguides.com/exampapers',
            ),
            SizedBox(height: 12),

            _SupportCard(
              icon: Icons.public,
              title: 'International Student Starter Pack',
              body:
                  'Visas, PPSN, banking, and healthcare information for studying in Ireland.',
              actionText: 'Open checklist',
              url: 'https://www.irishimmigration.ie/study-in-ireland/',
            ),
            SizedBox(height: 12),

            _SupportCard(
              icon: Icons.work_outline,
              title: 'Careers & CV Drop-In',
              body:
                  'Quick CV and LinkedIn reviews, internship/job search support, and 1:1 appointments.',
              actionText: 'Book careers slot',
              url: 'https://www.ncirl.ie/Students/Careers',
            ),
          ],
        ),
      ),
    );
  }
}

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
      color: theme.colorScheme.surface.withOpacity(0.6),
      elevation: 0,
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

// ----- Back-compat wrapper (keeps old calls working) -----
class AcademicSupport extends AcademicSupportPage {
  const AcademicSupport({super.key});
}
