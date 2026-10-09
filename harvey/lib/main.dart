import 'package:flutter/material.dart';
import 'core/settings/settings_service.dart';
import 'features/contracts/contract_service.dart';
import 'features/matters/matter_repository.dart';
import 'features/qa/legal_qa_service.dart';
import 'features/ui/matter_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = await SettingsService.init();
  final repository = MatterRepository();
  final contractService = ContractService(settingsService);
  final qaService = LegalQaService(settingsService);

  runApp(HarveyApp(
    settingsService: settingsService,
    repository: repository,
    contractService: contractService,
    qaService: qaService,
  ));
}

class HarveyApp extends StatelessWidget {
  final SettingsService settingsService;
  final MatterRepository repository;
  final ContractService contractService;
  final LegalQaService qaService;

  const HarveyApp({
    super.key,
    required this.settingsService,
    required this.repository,
    required this.contractService,
    required this.qaService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harvey Legal AI Clone',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.indigoAccent,
          secondary: Colors.indigo,
          surface: const Color(0xFF161925),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F111C),
        useMaterial3: true,
      ),
      home: MatterListScreen(
        settingsService: settingsService,
        repository: repository,
        contractService: contractService,
        qaService: qaService,
      ),
    );
  }
}
