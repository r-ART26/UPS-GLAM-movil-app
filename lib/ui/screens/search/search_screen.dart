import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../widgets/effects/gradient_background.dart';
import '../../../services/users/user_search_service.dart';
import '../../../services/posts/random_posts_service.dart';
import '../../../models/user_model.dart';
import '../../widgets/user_list_item.dart';
import '../post/post_detail_screen.dart';

/// Pantalla de búsqueda de usuarios estilo Instagram.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  String _currentQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _currentQuery = value.trim();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.welcomeBackground),
      child: SafeArea(
        child: Column(
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar usuarios...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _currentQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _currentQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            // Contenido: Cuadrícula de fotos o resultados de búsqueda
            Expanded(
              child: Stack(
                children: [
                  // Cuadrícula de fotos aleatorias (siempre visible)
                  _buildPhotosGrid(),

                  // Overlay de resultados de búsqueda
                  if (_currentQuery.isNotEmpty) _buildSearchResults(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la cuadrícula de fotos aleatorias
  Widget _buildPhotosGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: RandomPostsService.getRandomPostsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No hay fotos disponibles',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final posts = snapshot.data!;

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final imageUrl = post['imageUrl'] as String;

            return GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(
                      postId: post['postId'],
                      imageUrl: imageUrl,
                      description: post['description'],
                      authorUid: post['authorUid'],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.white.withOpacity(0.1),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white24,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.white.withOpacity(0.1),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white24,
                      size: 24,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Construye el overlay de resultados de búsqueda
  Widget _buildSearchResults() {
    return Container(
      color: AppColors.upsBlueDark.withOpacity(0.95),
      child: StreamBuilder<List<UserModel>>(
        stream: UserSearchService.searchUsersStream(_currentQuery),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al buscar: ${snapshot.error}',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No se encontraron usuarios',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final users = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: users.length,
            itemBuilder: (context, index) {
              return UserListItem(user: users[index]);
            },
          );
        },
      ),
    );
  }
}
