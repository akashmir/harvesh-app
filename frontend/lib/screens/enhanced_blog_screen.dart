import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EnhancedBlogScreen extends StatefulWidget {
  const EnhancedBlogScreen({super.key});

  @override
  State<EnhancedBlogScreen> createState() => _EnhancedBlogScreenState();
}

class _EnhancedBlogScreenState extends State<EnhancedBlogScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> blogs = [
    {
      "title":
          "The Best Weed Control Timing Strategies for Farmers to Increase Crop Yield and Reduce Labor",
      "content":
          "The Significance of Timings in Weed ControlIt takes more than merely pulling undesired plants to control weeds. The goal is to control them before they become an issue. Using pre-emergent herbicides is one of the best tactics. These products save you time and effort later on by stopping weed seeds from sprouting in the first place. Before weed seeds start to grow in the early spring, pre-emergent weed herbicides are particularly helpful. If applied too late, weeds may have already started growing, which makes them much harder to control. By understanding the growth cycles of common weeds in your area, you can plan your weed management to hit them at the most vulnerable stages, ensuring effective control with minimal labor.",
      "url":
          "https://www.dhanuka.com/blogs/the-best-weed-control-timing-strategies-for-farmers-to-increase-crop-yield-and-reduce-labor",
      "category": "Weed Control",
      "readTime": "5 min read",
      "date": "2024-01-15",
      "image":
          "https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=400",
    },
    {
      "title":
          "Using Biological Solutions to Boost Soil Health Before Winter Planting",
      "content":
          "It is important to get your soil ready for the upcoming growing season as winter draws near. Higher crop yields and a decreased need for artificial fertilizers are both results of healthy soil. Using agricultural biologicals is one of the best strategies to enhance soil health. These biological solutions, like natural fertilizers and beneficial microbes, help build soil fertility, ensuring your crops are off to a great start when the spring arrives.In this blog, we will explore why bio-agriculture is becoming an important part of sustainable farming and how you can use biological solutions to give your soil the boost it needs before winter planting.",
      "url":
          "https://www.dhanuka.com/blogs/using-biological-solutions-to-boost-soil-health-before-winter-planting",
      "category": "Soil Health",
      "readTime": "7 min read",
      "date": "2024-01-10",
      "image":
          "https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=400",
    },
    {
      "title": "Understanding Herbicides: Types, Uses and Environmental Impact",
      "content":
          "Herbicides are potent chemicals designed to manage or eradicate unwanted plant growth, commonly known as weeds. Herbicide chemical methods are used to kill plants or weeds. They are crucial in agricultural settings, landscapes, and gardens, allowing for the controlled growth of desirable plants and efficient production of crops. Herbicides work by interfering with specific plant processes or structures, ultimately causing the weeds to wither and die. Given their effectiveness and widespread use, it's essential to understand the various types of herbicides, their applications, and their impact on the environment.",
      "url":
          "https://www.dhanuka.com/blogs/understanding-herbicides-types-uses-and-environmental-impact",
      "category": "Herbicides",
      "readTime": "6 min read",
      "date": "2024-01-05",
      "image":
          "https://images.unsplash.com/photo-1586771107445-d3ca888129ce?w=400",
    },
    {
      "title": "Understanding and managing common diseases in paddy fields",
      "content":
          "The cultivation of paddy crops is a cornerstone of Indian agriculture, requiring significant investments of time, effort, and resources from farmers. Their diligent work ensures that each paddy field produces a bountiful harvest, underscoring the importance of their contributions. Despite dedicated endeavours, stealth diseases pose a threat to the success of these efforts. This guide addresses prevalent paddy diseases, shedding light on insights and presenting solutions, focusing on the expertise offered by Dhanuka Agritech Limited in the agri-input sector.",
      "url":
          "https://www.dhanuka.com/blogs/understanding-and-managing-common-diseases-in-paddy-fields",
      "category": "Disease Management",
      "readTime": "8 min read",
      "date": "2024-01-01",
      "image":
          "https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?w=400",
    },
  ];

  String selectedCategory = "All";
  final List<String> categories = [
    "All",
    "Weed Control",
    "Soil Health",
    "Herbicides",
    "Disease Management"
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredBlogs {
    if (selectedCategory == "All") {
      return blogs;
    }
    return blogs.where((blog) => blog["category"] == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildCategoryFilter(),
              Expanded(
                child: _buildBlogList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF9C27B0),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Agriculture Blogs',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Search feature coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9C27B0),
            Color(0xFFBA68C8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.article,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Expert Farming Insights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Discover the latest agricultural tips, techniques, and best practices from farming experts.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${blogs.length} Articles',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Updated Daily',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategory = category;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF9C27B0) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF9C27B0)
                        : Colors.grey[300]!,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF9C27B0).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlogList() {
    final filteredBlogs = this.filteredBlogs;

    if (filteredBlogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No articles found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredBlogs.length,
      itemBuilder: (context, index) {
        return _buildBlogCard(filteredBlogs[index], index);
      },
    );
  }

  Widget _buildBlogCard(Map<String, dynamic> blog, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToBlogDetail(blog),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBlogImage(blog),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBlogCategory(blog["category"]),
                    const SizedBox(height: 8),
                    Text(
                      blog["title"],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      blog["content"],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          blog["readTime"],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(blog["date"]),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBlogImage(Map<String, dynamic> blog) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getCategoryColor(blog["category"]).withOpacity(0.8),
              _getCategoryColor(blog["category"]).withOpacity(0.6),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background image
            Positioned.fill(
              child: Image.network(
                blog["image"],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _getCategoryColor(blog["category"]).withOpacity(0.3),
                  child: Icon(
                    Icons.article,
                    size: 48,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Category badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  blog["category"],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlogCategory(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor(category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _getCategoryColor(category),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Weed Control":
        return const Color(0xFF4CAF50);
      case "Soil Health":
        return const Color(0xFF8BC34A);
      case "Herbicides":
        return const Color(0xFFFF9800);
      case "Disease Management":
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      final now = DateTime.now();
      final difference = now.difference(parsedDate).inDays;

      if (difference == 0) {
        return "Today";
      } else if (difference == 1) {
        return "Yesterday";
      } else if (difference < 7) {
        return "$difference days ago";
      } else {
        return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
      }
    } catch (e) {
      return date;
    }
  }

  void _navigateToBlogDetail(Map<String, dynamic> blog) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedBlogDetailScreen(
          title: blog["title"],
          content: blog["content"],
          url: blog["url"],
          category: blog["category"],
          readTime: blog["readTime"],
          date: blog["date"],
          image: blog["image"],
        ),
      ),
    );
  }
}

class EnhancedBlogDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String url;
  final String category;
  final String readTime;
  final String date;
  final String image;

  const EnhancedBlogDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.url,
    required this.category,
    required this.readTime,
    required this.date,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF9C27B0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Article Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryBadge(),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildArticleMeta(),
                  const SizedBox(height: 24),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildReadMoreButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor().withOpacity(0.8),
            _getCategoryColor().withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: _getCategoryColor().withOpacity(0.3),
                child: Icon(
                  Icons.article,
                  size: 64,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor().withOpacity(0.3),
        ),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getCategoryColor(),
        ),
      ),
    );
  }

  Widget _buildArticleMeta() {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 16,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          readTime,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.calendar_today,
          size: 16,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(date),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildReadMoreButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open the article')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9C27B0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: const Color(0xFF9C27B0).withOpacity(0.3),
        ),
        icon: const Icon(Icons.open_in_new, size: 20),
        label: const Text(
          'Read Full Article',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (category) {
      case "Weed Control":
        return const Color(0xFF4CAF50);
      case "Soil Health":
        return const Color(0xFF8BC34A);
      case "Herbicides":
        return const Color(0xFFFF9800);
      case "Disease Management":
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  String _formatDate(String date) {
    try {
      final DateTime parsedDate = DateTime.parse(date);
      return "${parsedDate.day}/${parsedDate.month}/${parsedDate.year}";
    } catch (e) {
      return date;
    }
  }
}
