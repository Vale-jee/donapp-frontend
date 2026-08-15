import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.profile, super.key});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DonApp')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Hola, ${profile.nombreVisible}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('${profile.nombreCompleto} · ${profile.ciudad}'),
            const SizedBox(height: 8),
            Text(
              'Tu perfil está conectado. Muy pronto podrás compartir y encontrar artículos dentro de tu comunidad.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            const _FutureArea(
              icon: Icons.volunteer_activism_outlined,
              title: 'Publicar una donación',
            ),
            const _FutureArea(
              icon: Icons.search_outlined,
              title: 'Buscar donaciones',
            ),
            const _FutureArea(
              icon: Icons.handshake_outlined,
              title: 'Solicitar una donación',
            ),
          ],
        ),
      ),
    );
  }
}

class _FutureArea extends StatelessWidget {
  const _FutureArea({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: const Text('Próximamente'),
      ),
    );
  }
}
