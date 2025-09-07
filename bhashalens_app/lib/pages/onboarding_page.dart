import 'package:flutter/material.dart'; // Keep material.dart for other widgets
import 'package:carousel_slider/carousel_slider.dart'; // For swipeable tutorial cards
import 'package:bhashalens_app/services/local_storage_service.dart'; // Import LocalStorageService
import 'package:provider/provider.dart'; // Import Provider

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentTutorialIndex = 0;
  late LocalStorageService _localStorageService; // Declare LocalStorageService

  final List<Map<String, dynamic>> tutorialSlides = [
    {
      'icon': Icons.camera_alt,
      'caption': 'Translate text instantly using your camera.',
    },
    {
      'icon': Icons.mic,
      'caption': 'Speak and get real-time voice translations.',
    },
    {
      'icon': Icons.offline_bolt,
      'caption': 'Access essential features even without internet.',
    },
  ];

  final List<String> availableLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Hindi',
  ];
  String? selectedLanguage;

  @override
  void initState() {
    super.initState();
    selectedLanguage =
        availableLanguages.first; // Default to the first language
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _localStorageService = Provider.of<LocalStorageService>(
      context,
      listen: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Header Block
                _buildHeaderBlock(),
                const SizedBox(height: 40),

                // 2. Welcome / Introduction Block
                _buildWelcomeBlock(),
                const SizedBox(height: 40),

                // 3. Feature Highlights Block
                _buildFeatureHighlightsBlock(),
                const SizedBox(height: 40),

                // 4. Language Selection Block
                _buildLanguageSelectionBlock(),
                const SizedBox(height: 40),

                // 5. Tutorial / Walkthrough Block
                _buildTutorialBlock(),
                const SizedBox(height: 40),

                // 6. Action Block
                _buildActionBlock(),
                const SizedBox(height: 20),

                // 7. Footer Block
                _buildFooterBlock(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBlock() {
    return Column(
      children: [
        Image.asset(
          'assets/logo2.png',
          height: 120, // Adjust height as needed
        ),
        const SizedBox(height: 12),
        Text(
          'BhashaLens',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your World, Understood.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWelcomeBlock() {
    return const Column(
      children: [
        Text(
          'Welcome to BhashaLens!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Translate signs, speech, and documents instantly with advanced AI.',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFeatureHighlightsBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Features:',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _buildFeatureRow(
          Icons.camera_alt,
          'Camera Translate',
          'Point, snap, translate – real-time accuracy.',
        ),
        const SizedBox(height: 15),
        _buildFeatureRow(
          Icons.mic,
          'Voice Translate',
          'Speak naturally and understand instantly.',
        ),
        const SizedBox(height: 15),
        _buildFeatureRow(
          Icons.offline_bolt,
          'Offline Mode',
          'Translate anytime, anywhere, without internet.',
        ),
      ],
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, size: 30, color: Colors.blueAccent),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSelectionBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Preferred Language:',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: selectedLanguage,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Language',
          ),
          items: availableLanguages.map((String lang) {
            return DropdownMenuItem<String>(value: lang, child: Text(lang));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedLanguage = newValue;
            });
          },
        ),
      ],
    );
  }

  Widget _buildTutorialBlock() {
    return Column(
      children: [
        Text(
          'Quick Tutorial',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 200,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentTutorialIndex = index;
              });
            },
          ),
          items: tutorialSlides.map((slide) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        slide['icon'] as IconData,
                        size: 50,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          slide['caption'] as String,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: tutorialSlides.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _carouselController.animateToPage(entry.key),
              child: Container(
                width: 12.0,
                height: 12.0,
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.blueAccent)
                          .withOpacity(
                            _currentTutorialIndex == entry.key ? 0.9 : 0.4,
                          ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionBlock() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              await _localStorageService.saveOnboardingCompleted(true);
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/home');
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () async {
            await _localStorageService.saveOnboardingCompleted(true);
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
          child: Text(
            'Skip Tutorial',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterBlock() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            // TODO: Navigate to Terms of Service
            print('Navigate to Terms of Service');
          },
          child: Text(
            'Terms of Service',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Text('|', style: TextStyle(color: Colors.grey[600])),
        TextButton(
          onPressed: () {
            // TODO: Navigate to Privacy Policy
            print('Navigate to Privacy Policy');
          },
          child: Text(
            'Privacy Policy',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }
}
