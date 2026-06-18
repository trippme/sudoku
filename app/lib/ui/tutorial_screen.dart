import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../tutorial/tutorial_content.dart';

/// The offline "Learn" section (issue #49): an index of guides written for this
/// app and structured after Sudopedia, with links back to Sudopedia as the
/// reference.
class TutorialIndexScreen extends StatelessWidget {
  const TutorialIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Play')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
        children: [
          for (final s in tutorialSections)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Icon(s.icon,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(s.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s.blurb),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TutorialSectionScreen(section: s),
                )),
              ),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 16, 8, 4),
            child: _Attribution(),
          ),
        ],
      ),
    );
  }
}

/// One section: its blurb, its article(s), and a Sudopedia reference link.
/// A single-article section renders inline; multi-article sections list their
/// articles.
class TutorialSectionScreen extends StatelessWidget {
  final TutorialSection section;
  const TutorialSectionScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final single = section.articles.length == 1;
    return Scaffold(
      appBar: AppBar(title: Text(section.title)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 16 + MediaQuery.of(context).padding.bottom),
        children: [
          Text(section.blurb,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (single) ...[
            ...renderTutorialMarkup(context, section.articles.first.body),
          ] else
            for (final a in section.articles)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(a.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        _ArticleScreen(article: a, referenceUrl: section.referenceUrl),
                  )),
                ),
              ),
          const SizedBox(height: 8),
          _ReferenceLink(url: section.referenceUrl),
        ],
      ),
    );
  }
}

class _ArticleScreen extends StatelessWidget {
  final TutorialArticle article;
  final String referenceUrl;
  const _ArticleScreen({required this.article, required this.referenceUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        children: [
          ...renderTutorialMarkup(context, article.body),
          const SizedBox(height: 8),
          _ReferenceLink(url: referenceUrl),
        ],
      ),
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution();
  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'These guides are written for offline use in this app. Sudopedia is '
          'the reference — its content is under the GNU Free Documentation '
          'License. Tap any section\'s link to read more there.',
          style: TextStyle(color: muted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _ReferenceLink(url: sudopediaHome, label: 'sudopedia.org'),
      ],
    );
  }
}

/// A tappable external link to a Sudopedia page.
class _ReferenceLink extends StatelessWidget {
  final String url;
  final String label;
  const _ReferenceLink({required this.url, this.label = 'Reference: Sudopedia'});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open $url')),
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.open_in_new, size: 16, color: primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  style: TextStyle(
                      color: primary, decoration: TextDecoration.underline)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the tiny tutorial markup (see tutorial_content.dart) into widgets:
/// "## " headings, "- " bullets, ``` fenced monospace blocks, blank-line-
/// separated paragraphs. Theme-aware, so it follows light/dark mode.
List<Widget> renderTutorialMarkup(BuildContext context, String body) {
  final theme = Theme.of(context);
  final bodyStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.45);
  final out = <Widget>[];
  final para = <String>[];
  final bullets = <String>[];
  final code = <String>[];
  var inCode = false;

  void flushPara() {
    if (para.isEmpty) return;
    out.add(Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(para.join(' '), style: bodyStyle),
    ));
    para.clear();
  }

  void flushBullets() {
    if (bullets.isEmpty) return;
    out.add(Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in bullets)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: bodyStyle),
                  Expanded(child: Text(b, style: bodyStyle)),
                ],
              ),
            ),
        ],
      ),
    ));
    bullets.clear();
  }

  void flushCode() {
    if (code.isEmpty) return;
    out.add(Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(code.join('\n'),
          style: const TextStyle(fontFamily: 'monospace', height: 1.4)),
    ));
    code.clear();
  }

  for (final raw in body.trim().split('\n')) {
    if (raw.trim() == '```') {
      if (inCode) {
        flushCode();
      } else {
        flushPara();
        flushBullets();
      }
      inCode = !inCode;
      continue;
    }
    if (inCode) {
      code.add(raw);
      continue;
    }
    if (raw.trim().isEmpty) {
      flushPara();
      flushBullets();
      continue;
    }
    if (raw.startsWith('## ')) {
      flushPara();
      flushBullets();
      out.add(Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: Text(raw.substring(3),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ));
      continue;
    }
    if (raw.startsWith('- ')) {
      flushPara();
      bullets.add(raw.substring(2).trim());
      continue;
    }
    flushBullets();
    para.add(raw.trim());
  }
  flushPara();
  flushBullets();
  flushCode();
  return out;
}
