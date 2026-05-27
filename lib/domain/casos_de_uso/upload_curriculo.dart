import 'package:file_picker/file_picker.dart';
import 'package:rh_os/domain/casos_de_uso/extrair_dados_curriculo.dart';

class UploadCurriculo {
  UploadCurriculo({ExtrairDadosCurriculo? extrator})
      : _extrator = extrator ?? ExtrairDadosCurriculo();

  final ExtrairDadosCurriculo _extrator;

  // Abre o seletor e extrai dados do curriculo.
  Future<Map<String, dynamic>?> executar() async {
    try {
      final resultado = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
      );

      if (resultado == null || resultado.files.isEmpty) return null;

      final caminho = resultado.files.single.path;
      if (caminho == null) return null;

      return await _extrator.executar(caminho);
    } catch (_) {
      return null;
    }
  }
}
