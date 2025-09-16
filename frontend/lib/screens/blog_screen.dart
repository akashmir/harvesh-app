// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BlogScreen extends StatelessWidget {
  final List<Map<String, String>> blogs = [
    {
      "title": "The Best Weed Control Timing Strategies for Farmers to Increase Crop Yield and Reduce Labor",
      "content": "The Significance of Timings in Weed ControlIt takes more than merely pulling undesired plants to control weeds. The goal is to control them before they become an issue. Using pre-emergent herbicides is one of the best tactics. These products save you time and effort later on by stopping weed seeds from sprouting in the first place. Before weed seeds start to grow in the early spring, pre-emergent weed herbicides are particularly helpful. If applied too late, weeds may have already started growing, which makes them much harder to control. By understanding the growth cycles of common weeds in your area, you can plan your weed management to hit them at the most vulnerable stages, ensuring effective control with minimal labor.",
      "url": "https://www.dhanuka.com/blogs/the-best-weed-control-timing-strategies-for-farmers-to-increase-crop-yield-and-reduce-labor"
    },
    {
      "title": "Using Biological Solutions to Boost Soil Health Before Winter Planting",
      "content": "It is important to get your soil ready for the upcoming growing season as winter draws near. Higher crop yields and a decreased need for artificial fertilizers are both results of healthy soil. Using agricultural biologicals is one of the best strategies to enhance soil health. These biological solutions, like natural fertilizers and beneficial microbes, help build soil fertility, ensuring your crops are off to a great start when the spring arrives.In this blog, we will explore why bio-agriculture is becoming an important part of sustainable farming and how you can use biological solutions to give your soil the boost it needs before winter planting.",
      "url": "https://www.dhanuka.com/blogs/using-biological-solutions-to-boost-soil-health-before-winter-planting"
    },
    {
      "title": "Understanding Herbicides: Types, Uses and Environmental Impact",
      "content": "Herbicides are potent chemicals designed to manage or eradicate unwanted plant growth, commonly known as weeds. Herbicide chemical methods are used to kill plants or weeds. They are crucial in agricultural settings, landscapes, and gardens, allowing for the controlled growth of desirable plants and efficient production of crops. Herbicides work by interfering with specific plant processes or structures, ultimately causing the weeds to wither and die. Given their effectiveness and widespread use, it's essential to understand the various types of herbicides, their applications, and their impact on the environment.",
      "url": "https://www.dhanuka.com/blogs/understanding-herbicides-types-uses-and-environmental-impact"
    },
    {
      "title": "Understanding and managing common diseases in paddy fields",
      "content": "The cultivation of paddy crops is a cornerstone of Indian agriculture, requiring significant investments of time, effort, and resources from farmers. Their diligent work ensures that each paddy field produces a bountiful harvest, underscoring the importance of their contributions. Despite dedicated endeavours, stealth diseases pose a threat to the success of these efforts. This guide addresses prevalent paddy diseases, shedding light on insights and presenting solutions, focusing on the expertise offered by Dhanuka Agritech Limited in the agri-input sector.",
      "url": "https://www.dhanuka.com/blogs/understanding-and-managing-common-diseases-in-paddy-fields"
    },
  ];

  BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agriculture Blogs'),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        itemCount: blogs.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 5,
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(blogs[index]["title"]!),
              subtitle: Text(blogs[index]["content"]!, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Navigate to Blog Detail Screen or Open the URL
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlogDetailScreen(
                      title: blogs[index]["title"]!,
                      content: blogs[index]["content"]!,
                      url: blogs[index]["url"]!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class BlogDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String url;

  const BlogDetailScreen({super.key, required this.title, required this.content, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Read Full Blog'),
              onPressed: () async {
                if (await canLaunch(url)) {  // Directly launch the URL (String)
                  await launch(url);
                } else {
                  throw 'Could not launch $url';
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
