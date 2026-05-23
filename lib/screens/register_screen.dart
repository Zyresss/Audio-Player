import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _selectedDate;
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // Fonction pour afficher le calendrier
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      // On ouvre le calendrier par défaut 13 ans dans le passé pour faciliter la saisie
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Vérification de l'âge (>= 13 ans)
  bool _isOldEnough(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    // Si le mois de naissance n'est pas encore passé, ou si c'est le mois courant mais que le jour n'est pas passé, on retire 1 an
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age >= 13;
  }

  void _register() async {
    // 1. Vérifier si tous les champs textuels sont remplis
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
      );
      return;
    }

    // 2. Vérifier si la date de naissance est sélectionnée
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner votre date de naissance')),
      );
      return;
    }

    // 3. Vérifier la contrainte d'âge (>= 13 ans)
    if (!_isOldEnough(_selectedDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez avoir au moins 13 ans pour utiliser cette application.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 4. Créer le compte via notre AuthService
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nomController.text.trim(),
        _prenomController.text.trim(),
        _selectedDate!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte créé avec succès ! Vous pouvez vous connecter.'), backgroundColor: Colors.green),
      );

      // Retour à la page de connexion
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Erreur lors de l\'inscription')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: SingleChildScrollView( // Permet de scroller si le clavier prend de la place
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _prenomController,
                decoration: const InputDecoration(labelText: 'Prénom *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),

              // Sélecteur de date de naissance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Date de naissance *'
                          : 'Né(e) le: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(color: _selectedDate == null ? Colors.grey[600] : Colors.black, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month, color: Colors.indigo),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mot de passe *', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 30),

              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('S\'inscrire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}